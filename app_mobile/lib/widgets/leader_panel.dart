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
  List<bool> agenciasOnline = [false, false, false];
  List<OperacaoPendente> pendentes = [];
  Timer? _timer;
  StreamSubscription? _connSub;
  bool _sincronizando = false;
  bool _forcandoEleicao = false;

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
    final resultado = await ApiService.obterStatusCluster();
    if (!mounted) return;

    final estaOnline = resultado['online'] == true;
    final idLider = resultado['liderAtual'];
    final listaNos =
        List<bool>.from(resultado['agenciasOnline'] ?? [false, false, false]);

    setState(() {
      pendentes = fila;
      online = estaOnline;
      agenciasOnline = listaNos;
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

  Future<void> _acionarForcarEleicao() async {
    setState(() => _forcandoEleicao = true);
    try {
      final msg = await ApiService.forcarEleicaoManual();
      await _atualizarPainel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF0D6EFD),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    } finally {
      if (mounted) setState(() => _forcandoEleicao = false);
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
              Text(
                  'Titular: ${conflito.contaAtual['nomeAluno'] ?? conflito.contaAtual['titular']}'),
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

  Widget _buildNoBadge(int id, bool ativo) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ativo ? const Color(0xFFE8F5E9) : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: ativo ? const Color(0xFF198754) : const Color(0xFFDC3545),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Ag. $id',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ativo ? const Color(0xFF1B5E20) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Row(
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildNoBadge(0, agenciasOnline[0]),
                      _buildNoBadge(1, agenciasOnline[1]),
                      _buildNoBadge(2, agenciasOnline[2]),
                    ],
                  ),
                  SizedBox(
                    height: 26,
                    child: ElevatedButton(
                      onPressed:
                          _forcandoEleicao ? null : _acionarForcarEleicao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0A2E65),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        _forcandoEleicao ? 'Eleição...' : '⚡ Forçar Eleição',
                      ),
                    ),
                  ),
                ],
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
