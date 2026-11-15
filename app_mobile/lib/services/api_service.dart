import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conta_model.dart';
import 'local_db.dart';

typedef JsonMap = Map<String, dynamic>;
typedef HeaderMap = Map<String, String>;

class ConflitoSincronizacaoException implements Exception {
  final String mensagem;
  final JsonMap contaAtual;
  final List<int> vetorConhecido;
  final List<int> vetorAtual;

  ConflitoSincronizacaoException({
    required this.mensagem,
    required this.contaAtual,
    required this.vetorConhecido,
    required this.vetorAtual,
  });

  @override
  String toString() => mensagem;
}

class OperacaoOfflineSalvaException implements Exception {
  final String mensagem;
  OperacaoOfflineSalvaException(this.mensagem);

  @override
  String toString() => mensagem;
}

class ApiService {
  static const String host = 'http://10.0.2.2';
  static int portaBase = 4047;

  static String urlAgencia(int idAgencia) => '$host:${portaBase + idAgencia}';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<HeaderMap> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> detectarPortaBase() async {
    for (int base in [4047, 4000]) {
      for (int id = 0; id < 3; id++) {
        try {
          final res = await http
              .get(Uri.parse('$host:${base + id}/bully/lider'))
              .timeout(const Duration(milliseconds: 800));
          if (res.statusCode == 200) {
            portaBase = base;
            return;
          }
        } catch (_) {}
      }
    }
  }

  static Future<void> registrarUsuario(
      int idAgencia, String usuario, String senha) async {
    await detectarPortaBase();
    try {
      final response = await http
          .post(
            Uri.parse('${urlAgencia(idAgencia)}/auth/registrar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'usuario': usuario, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 404) return;

      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ??
            'Erro ao registrar usuário (${response.statusCode})');
      }
    } on FormatException catch (_) {}
  }

  static Future<JsonMap> login(
      int idAgencia, String usuario, String senha) async {
    await detectarPortaBase();
    final response = await http
        .post(
          Uri.parse('${urlAgencia(idAgencia)}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'usuario': usuario, 'senha': senha}),
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 404) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', 'token-node-teste');
      return {'token': 'token-node-teste'};
    }

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
      return JsonMap.from(data);
    } else {
      throw Exception(data['erro'] ?? 'Usuário ou senha inválidos.');
    }
  }

  static Future<JsonMap> obterLider() async {
    for (int base in [portaBase, if (portaBase == 4047) 4000 else 4047]) {
      for (int id = 0; id < 3; id++) {
        try {
          final response = await http
              .get(Uri.parse('$host:${base + id}/bully/lider'))
              .timeout(const Duration(seconds: 2));

          if (response.statusCode == 200) {
            portaBase = base;
            final body = jsonDecode(response.body);
            return {
              'idAgenciaConsultada': body['idAgencia'] ?? id,
              'liderAtual': body['liderAtual'],
              'online': true,
            };
          }
        } catch (_) {}
      }
    }
    return {'idAgenciaConsultada': -1, 'liderAtual': null, 'online': false};
  }

  static Future<JsonMap> obterStatusCluster() async {
    for (int base in [portaBase, if (portaBase == 4047) 4000 else 4047]) {
      List<bool> statusAgencias = [false, false, false];
      int? liderDetectado;
      bool algumaOnline = false;

      for (int id = 0; id < 3; id++) {
        try {
          final response = await http
              .get(Uri.parse('$host:${base + id}/bully/lider'))
              .timeout(const Duration(milliseconds: 900));

          if (response.statusCode == 200) {
            portaBase = base;
            statusAgencias[id] = true;
            algumaOnline = true;
            final body = jsonDecode(response.body);
            if (body['liderAtual'] != null) {
              liderDetectado = body['liderAtual'];
            }
          }
        } catch (_) {}
      }

      if (algumaOnline) {
        return {
          'online': true,
          'liderAtual': liderDetectado,
          'agenciasOnline': statusAgencias,
        };
      }
    }
    return {
      'online': false,
      'liderAtual': null,
      'agenciasOnline': [false, false, false],
    };
  }

  static Future<String> forcarEleicaoManual() async {
    for (int id = 0; id < 3; id++) {
      try {
        final res = await http.post(
          Uri.parse('${urlAgencia(id)}/bully/forcar-eleicao'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 2));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return 'Eleição manual disparada na Agência $id! Líder atual: Agência ${data['liderAtual'] ?? '?'}';
        }

        final resFallback = await http
            .post(
              Uri.parse('${urlAgencia(id)}/bully/eleicao'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'origemId': id,
                'vetor': [0, 0, 0]
              }),
            )
            .timeout(const Duration(seconds: 2));

        if (resFallback.statusCode == 200) {
          return 'Eleição manual disparada com sucesso via Agência $id!';
        }
      } catch (_) {}
    }
    throw Exception('Nenhuma agência está online para iniciar a eleição.');
  }

  static Future<JsonMap> criarConta(
      int idAgencia, int idConta, String titular, double saldoInicial) async {
    final response = await http
        .post(
          Uri.parse('${urlAgencia(idAgencia)}/contas'),
          headers: await _headers(),
          body: jsonEncode({
            'id': idConta,
            'nomeAluno': titular,
            'titular': titular,
            'saldoInicial': saldoInicial,
          }),
        )
        .timeout(const Duration(seconds: 4));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (saldoInicial > 0 &&
          ((data['saldo'] as num?)?.toDouble() ?? 0.0) == 0.0) {
        try {
          await operarConta(
            idAgencia: idAgencia,
            idConta: idConta,
            tipo: 'DEPOSITO',
            valor: saldoInicial,
          );
          data['saldo'] = saldoInicial;
        } catch (_) {}
      }
      final conta = ContaModel.fromJson(data, idAgencia);
      await salvarContaLocal(conta);
      return JsonMap.from(data);
    } else {
      throw Exception(data['erro'] ?? 'Erro ao criar conta.');
    }
  }

  static Future<ContaModel> consultarSaldo(int idAgencia, int idConta) async {
    try {
      final response = await http
          .get(
            Uri.parse('${urlAgencia(idAgencia)}/contas/$idConta'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 3));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final conta = ContaModel.fromJson(data, idAgencia);
        await salvarContaLocal(conta);
        return conta;
      } else {
        throw Exception(data['erro'] ?? 'Conta não encontrada nesta agência.');
      }
    } on SocketException catch (_) {
      return await _obterContaCacheOuErro(idAgencia, idConta);
    } on http.ClientException catch (_) {
      return await _obterContaCacheOuErro(idAgencia, idConta);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return await _obterContaCacheOuErro(idAgencia, idConta);
      }
      rethrow;
    }
  }

  static Future<ContaModel> _obterContaCacheOuErro(
      int idAgencia, int idConta) async {
    final cache = await lerContaLocal(idAgencia, idConta);
    if (cache != null) {
      return cache;
    }
    throw Exception(
        'Sem conexão com a Agência $idAgencia e nenhum dado salvo no SQLite para a conta $idConta.');
  }

  static Future<ContaModel> operarConta({
    required int idAgencia,
    required int idConta,
    required String tipo,
    required double valor,
  }) async {
    final rota = tipo == 'DEPOSITO' ? 'depositar' : 'sacar';
    try {
      final response = await http
          .post(
            Uri.parse('${urlAgencia(idAgencia)}/contas/$idConta/$rota'),
            headers: await _headers(),
            body: jsonEncode({'valor': valor}),
          )
          .timeout(const Duration(seconds: 3));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        try {
          return await consultarSaldo(idAgencia, idConta);
        } catch (_) {
          final conta = ContaModel.fromJson(data, idAgencia);
          await salvarContaLocal(conta);
          return conta;
        }
      } else {
        throw Exception(data['erro'] ?? 'Erro ao realizar operação.');
      }
    } on SocketException catch (_) {
      return await _enfileirarOperacaoOffline(idAgencia, idConta, tipo, valor);
    } on http.ClientException catch (_) {
      return await _enfileirarOperacaoOffline(idAgencia, idConta, tipo, valor);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return await _enfileirarOperacaoOffline(
            idAgencia, idConta, tipo, valor);
      }
      rethrow;
    }
  }

  static Future<ContaModel> _enfileirarOperacaoOffline(
      int idAgencia, int idConta, String tipo, double valor) async {
    ContaModel? contaLocal = await lerContaLocal(idAgencia, idConta);
    contaLocal ??= ContaModel(
      id: idConta,
      agencia: idAgencia,
      titular: 'Titular (Offline)',
      saldo: 0.0,
      vetorAtual: [0, 0, 0],
    );

    if (tipo == 'SAQUE' && contaLocal.saldo < valor) {
      throw Exception('Saldo provisório insuficiente para saque offline.');
    }

    final op = OperacaoPendente(
      agenciaId: idAgencia,
      contaId: idConta,
      tipo: tipo,
      valor: valor,
      vetorConhecido: List<int>.from(contaLocal.vetorAtual),
      criadoEm: DateTime.now().toIso8601String(),
    );

    await adicionarOperacaoPendente(op);

    if (tipo == 'DEPOSITO') {
      contaLocal.saldo += valor;
    } else {
      contaLocal.saldo -= valor;
    }
    contaLocal.provisorio = true;
    await salvarContaLocal(contaLocal);

    throw OperacaoOfflineSalvaException(
      'Modo Offline (SQLite): $tipo de R\$ ${valor.toStringAsFixed(2)} guardado como pendente! Saldo provisório: R\$ ${contaLocal.saldo.toStringAsFixed(2)}',
    );
  }

  static Future<List<String>> sincronizarFilaPendente() async {
    final fila = await listarOperacoesPendentes();
    if (fila.isEmpty) return [];

    List<String> resultados = [];

    for (final op in fila) {
      try {
        final response = await http
            .post(
              Uri.parse(
                  '${urlAgencia(op.agenciaId)}/contas/${op.contaId}/sincronizar'),
              headers: await _headers(),
              body: jsonEncode({
                'tipo': op.tipo,
                'valor': op.valor,
                'vetorConhecido': op.vetorConhecido,
              }),
            )
            .timeout(const Duration(seconds: 3));

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (op.dbId != null) {
            await LocalDb.removerOperacaoPendente(op.dbId!);
          }
          await consultarSaldo(op.agenciaId, op.contaId);
          resultados.add(
              'Operação pendente sincronizada automaticamente: ${op.tipo} de R\$ ${op.valor.toStringAsFixed(2)} (Conta #${op.contaId}).');
        } else if (response.statusCode == 409) {
          if (op.dbId != null) {
            await LocalDb.removerOperacaoPendente(op.dbId!);
          }

          final contaReal = data['contaAtual'] ?? {};
          final vetorReal = List<int>.from(data['vetorAtual'] ?? [0, 0, 0]);
          final modeloReal = ContaModel(
            id: contaReal['id'] ?? op.contaId,
            agencia: contaReal['agencia'] ?? op.agenciaId,
            titular:
                contaReal['nomeAluno'] ?? contaReal['titular'] ?? 'Titular',
            saldo: (contaReal['saldo'] as num?)?.toDouble() ?? 0.0,
            vetorAtual: vetorReal,
            provisorio: false,
          );
          await salvarContaLocal(modeloReal);

          throw ConflitoSincronizacaoException(
            mensagem: data['erro'] ??
                'Conflito detectado: o estado da conta mudou desde a última sincronização do app.',
            contaAtual: JsonMap.from(contaReal),
            vetorConhecido:
                List<int>.from(data['vetorConhecido'] ?? op.vetorConhecido),
            vetorAtual: vetorReal,
          );
        } else {
          if (op.dbId != null) {
            await LocalDb.removerOperacaoPendente(op.dbId!);
          }
          resultados.add(
              'Sincronização recusada (${response.statusCode}): ${data['erro'] ?? 'Erro'}');
        }
      } on ConflitoSincronizacaoException {
        rethrow;
      } catch (_) {}
    }
    return resultados;
  }

  static Future<JsonMap> transferir({
    required int agenciaOrigemId,
    required int origemId,
    required int agenciaDestinoId,
    required int destinoId,
    required double valor,
  }) async {
    final response = await http
        .post(
          Uri.parse(
              '${urlAgencia(agenciaOrigemId)}/contas/$origemId/transferir'),
          headers: await _headers(),
          body: jsonEncode({
            'agenciaDestino': agenciaDestinoId,
            'contaDestino': destinoId,
            'valor': valor,
          }),
        )
        .timeout(const Duration(seconds: 4));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return JsonMap.from(data);
    } else {
      throw Exception(data['erro'] ?? 'Falha na transferência.');
    }
  }

  static Future<void> salvarContaLocal(ContaModel conta) async {
    await LocalDb.salvarConta(conta);
  }

  static Future<ContaModel?> lerContaLocal(int agencia, int conta) async {
    return await LocalDb.lerConta(agencia, conta);
  }

  static Future<List<OperacaoPendente>> listarOperacoesPendentes() async {
    return await LocalDb.listarOperacoesPendentes();
  }

  static Future<void> adicionarOperacaoPendente(OperacaoPendente op) async {
    await LocalDb.inserirOperacaoPendente(op);
  }
}
