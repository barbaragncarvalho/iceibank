import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/saldo_screen.dart';
import '../screens/operacoes_screen.dart';
import '../screens/transferencias_screen.dart';
import '../screens/login_screen.dart';
import 'leader_panel.dart';

class IceiBankLayout extends StatelessWidget {
  final String? paginaAtiva;
  final String titulo;
  final String subtitulo;
  final Widget child;
  final VoidCallback? onSyncCompleted;

  const IceiBankLayout({
    super.key,
    this.paginaAtiva,
    required this.titulo,
    required this.subtitulo,
    required this.child,
    this.onSyncCompleted,
  });

  void _navegar(BuildContext context, Widget tela) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => tela,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A2E65),
              Color(0xFF0D6EFD),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: LeaderPanel(onSyncCompleted: onSyncCompleted),
                  ),
                  if (paginaAtiva != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(50),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _navPill(
                                context, 'Saldo', 'saldo', const SaldoScreen()),
                            _navPill(context, 'Operações', 'operacoes',
                                const OperacoesScreen()),
                            _navPill(context, 'Transferência', 'transferencias',
                                const TransferenciasScreen()),
                            _sairPill(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 35,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '🏦',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 42),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A2E65),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF6C757D),
                            ),
                          ),
                          const SizedBox(height: 24),
                          child,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navPill(
      BuildContext context, String label, String chave, Widget tela) {
    final ativo = paginaAtiva == chave;
    return GestureDetector(
      onTap: ativo ? null : () => _navegar(context, tela),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: ativo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? const Color(0xFF0A2E65) : Colors.white,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _sairPill(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await ApiService.logout();
        if (!context.mounted) return;
        _navegar(context, const LoginScreen());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Text(
          'Sair',
          style: TextStyle(
            color: Color(0xFFFFD8D8),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

Widget buildWebLabel(String texto) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0A2E65),
      ),
    ),
  );
}

Widget buildWebMensagem({required String texto, required String tipo}) {
  Color bg;
  Color fg;
  Color border;

  if (tipo == 'sucesso') {
    bg = const Color(0xFFE8F5E9);
    fg = const Color(0xFF1B5E20);
    border = const Color(0xFF198754);
  } else if (tipo == 'pendente') {
    bg = const Color(0xFFFFF8E1);
    fg = const Color(0xFF854D0E);
    border = const Color(0xFFCA8A04);
  } else {
    bg = const Color(0xFFFDEDEC);
    fg = const Color(0xFF842029);
    border = const Color(0xFFDC3545);
  }

  return Container(
    margin: const EdgeInsets.only(top: 18),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border(left: BorderSide(color: border, width: 4)),
    ),
    child: Text(
      texto,
      style: TextStyle(
        color: fg,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    ),
  );
}
