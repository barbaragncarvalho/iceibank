import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/conta_model.dart';
import '../services/api_service.dart';

class LeaderPanel extends StatefulWidget {
  final VoidCallback? onSyncCompleted;
  const LeaderPanel({super.key, this.onSyncCompleted});

  @override
  State<LeaderPanel> createState() => _LeaderPanelState();
}

class _LeaderPanelState extends State<LeaderPanel> {
  String liderTexto = 'Consultando...';
  bool online = true;
  List<OperacaoPendente> pendentes = [];
  Timer? _timer;
  StreamSubscription? _connSub;
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _atualizarPainel();
    _timer =
        Timer.periodic(const Duration(seconds: 2), (_) => _atualizarPainel());

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final reconectou = results.any((r) => r != ConnectivityResult.none);
      if (reconectou) {
        _atualizarPainel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _atualizarPainel() async {
    final fila = await ApiService.listarOperacoesPendentes();
    final resultado = await ApiService.obterLider();
    if (!mounted) return;

    final estaOnline = resultado['online'] == true;
    final idLider = resultado['liderAtual'];

    setState(() {
      pendentes = fila;
      online = estaOnline;
      if (estaOnline && idLider != null) {
        liderTexto =
            'Agência $idLider (Porta ${ApiService.portaBase + (idLider as int)})';
      } else if (estaOnline && idLider == null) {
        liderTexto = 'Eleição em andamento...';
      } else {
        liderTexto = 'Offline (Sem conexão)';
      }
    });

    if (estaOnline && fila.isNotEmpty && !_sincronizando) {
      await _executarSincronizacaoAutomatica();
    }
  }

  Future<void> _executarSincronizacaoAutomatica() async {
    _sincronizando = true;
    try {
      final mensagens = await ApiService.sincronizarFilaPendente();
      final novaFila = await ApiService.listarOperacoesPendentes();
      if (!mounted) return;
      setState(() => pendentes = novaFila);

      if (mensagens.isNotEmpty) {
        for (final msg in mensagens) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: const Color(0xFF198754),
            ),
          );
        }
        widget.onSyncCompleted?.call();
      }
    } on ConflitoSincronizacaoException catch (conflito) {
      final novaFila = await ApiService.listarOperacoesPendentes();
      if (!mounted) return;
      setState(() => pendentes = novaFila);
      widget.onSyncCompleted?.call();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            'Conflito Detectado (HTTP 409)',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF842029)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conflito.mensagem),
              const SizedBox(height: 12),
              Text('Vetor conhecido pelo App: ${conflito.vetorConhecido}',
                  style: const TextStyle(fontSize: 13)),
              Text('Vetor atual da Agência: ${conflito.vetorAtual}',
                  style: const TextStyle(fontSize: 13)),
              const Divider(height: 20),
              const Text('Estado Real Atual da Conta:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF0A2E65))),
              Text('Conta ID: ${conflito.contaAtual['id']}'),
              Text('Titular: ${conflito.contaAtual['nomeAluno']}'),
              Text(
                'Saldo Real: R\$ ${((conflito.contaAtual['saldo'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF0A2E65)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      _sincronizando = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Líder Atual (Bully):',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: online
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFDEDEC),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  liderTexto,
                  style: TextStyle(
                    color: online
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF842029),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (pendentes.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCA8A04)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_problem,
                    color: Color(0xFF854D0E), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pendente Offline (${pendentes.length}): ${pendentes.last.tipo} R\$ ${pendentes.last.valor.toStringAsFixed(2)} na Conta #${pendentes.last.contaId}',
                    style: const TextStyle(
                      color: Color(0xFF854D0E),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
