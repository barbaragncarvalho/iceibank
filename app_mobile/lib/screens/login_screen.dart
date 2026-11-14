import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/iceibank_navbar.dart';
import 'criar_conta_screen.dart';
import 'saldo_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _agenciaSelecionada = 0;
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  String? _mensagem;
  String _tipoMensagem = 'erro';

  Future<void> _fazerLogin() async {
    final usuario = _usuarioController.text.trim();
    final senha = _senhaController.text.trim();

    if (usuario.isEmpty || senha.isEmpty) {
      setState(() {
        _tipoMensagem = 'erro';
        _mensagem = 'Preencha usuário e senha.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mensagem = null;
    });

    try {
      await ApiService.login(_agenciaSelecionada, usuario, senha);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SaldoScreen()),
      );
    } catch (e) {
      setState(() {
        _tipoMensagem = 'erro';
        _mensagem = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IceiBankLayout(
      paginaAtiva: null,
      titulo: 'ICEIBank',
      subtitulo: 'Sistema Bancário Distribuído',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildWebLabel('Agência de Acesso:'),
          DropdownButtonFormField<int>(
            value: _agenciaSelecionada,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Agência 0 (Porta 4047)')),
              DropdownMenuItem(value: 1, child: Text('Agência 1 (Porta 4048)')),
              DropdownMenuItem(value: 2, child: Text('Agência 2 (Porta 4049)')),
            ],
            onChanged: (v) => setState(() => _agenciaSelecionada = v ?? 0),
          ),
          const SizedBox(height: 16),
          buildWebLabel('Usuário:'),
          TextField(
            controller: _usuarioController,
            decoration: const InputDecoration(hintText: 'Digite seu usuário'),
          ),
          const SizedBox(height: 16),
          buildWebLabel('Senha:'),
          TextField(
            controller: _senhaController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Digite sua senha'),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _isLoading ? null : _fazerLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Acessar Conta'),
          ),
          if (_mensagem != null)
            buildWebMensagem(texto: _mensagem!, tipo: _tipoMensagem),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ainda não tem conta? ',
                style: TextStyle(color: Color(0xFF6C757D), fontSize: 13.5),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CriarContaScreen()),
                  );
                },
                child: const Text(
                  'Abra sua conta aqui',
                  style: TextStyle(
                    color: Color(0xFF0D6EFD),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
