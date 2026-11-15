import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/iceibank_navbar.dart';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  int _agencia = 0;
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  final _idContaController = TextEditingController();
  final _titularController = TextEditingController();
  final _depositoInicialController = TextEditingController();

  String? _mensagem;
  String _tipoMensagem = 'erro';
  bool _isLoading = false;

  Future<void> _criarConta() async {
    final usuario = _usuarioController.text.trim();
    final senha = _senhaController.text.trim();
    final idContaTexto = _idContaController.text.trim();
    final titular = _titularController.text.trim();
    final saldoTexto =
        _depositoInicialController.text.replaceAll(',', '.').trim();

    if (usuario.isEmpty ||
        senha.isEmpty ||
        idContaTexto.isEmpty ||
        titular.isEmpty ||
        saldoTexto.isEmpty) {
      setState(() {
        _tipoMensagem = 'erro';
        _mensagem = 'Preencha todos os campos do formulário.';
      });
      return;
    }

    final idConta = int.tryParse(idContaTexto);
    final saldoInicial = double.tryParse(saldoTexto);

    if (idConta == null || saldoInicial == null) {
      setState(() {
        _tipoMensagem = 'erro';
        _mensagem = 'Preencha todos os campos do formulário.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mensagem = null;
    });

    try {
      await ApiService.registrarUsuario(_agencia, usuario, senha);
      await ApiService.login(_agencia, usuario, senha);

      final dados =
          await ApiService.criarConta(_agencia, idConta, titular, saldoInicial);

      final saldoFormatado =
          ((dados['saldo'] as num?)?.toDouble() ?? saldoInicial)
              .toStringAsFixed(2);

      setState(() {
        _tipoMensagem = 'sucesso';
        _mensagem =
            'Conta #${dados['id'] ?? idConta} e usuário "$usuario" criados com sucesso! Saldo: R\$ $saldoFormatado. Redirecionando para o login...';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
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
      titulo: 'Abertura de Conta',
      subtitulo: 'Cadastre seu acesso e abra sua conta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildWebLabel('Agência:'),
          DropdownButtonFormField<int>(
            value: _agencia,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Agência 0 (Porta 4047)')),
              DropdownMenuItem(value: 1, child: Text('Agência 1 (Porta 4048)')),
              DropdownMenuItem(value: 2, child: Text('Agência 2 (Porta 4049)')),
            ],
            onChanged: (v) => setState(() => _agencia = v ?? 0),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Nome de Usuário (Acesso):'),
          TextField(
            controller: _usuarioController,
            decoration: const InputDecoration(hintText: 'Usuário'),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Senha de Acesso:'),
          TextField(
            controller: _senhaController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Crie uma senha'),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Número da Conta (ID):'),
          TextField(
            controller: _idContaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Ex: 0'),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Nome do Titular:'),
          TextField(
            controller: _titularController,
            decoration: const InputDecoration(hintText: 'Nome completo'),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Depósito Inicial (R\$):'),
          TextField(
            controller: _depositoInicialController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '100.00'),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _isLoading ? null : _criarConta,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Criar Conta'),
          ),
          if (_mensagem != null)
            buildWebMensagem(texto: _mensagem!, tipo: _tipoMensagem),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Já possui conta? ',
                style: TextStyle(color: Color(0xFF6C757D), fontSize: 13.5),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Voltar para o Login',
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
