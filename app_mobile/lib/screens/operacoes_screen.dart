import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/iceibank_navbar.dart';

class OperacoesScreen extends StatefulWidget {
  const OperacoesScreen({super.key});

  @override
  State<OperacoesScreen> createState() => _OperacoesScreenState();
}

class _OperacoesScreenState extends State<OperacoesScreen> {
  int _agencia = 0;
  String _tipo = 'DEPOSITO';
  final _idContaController = TextEditingController();
  final _valorController = TextEditingController();
  String? _mensagem;
  String _tipoMensagem = 'sucesso';
  bool _isLoading = false;

  Future<void> _executarOperacao() async {
    final idConta = int.tryParse(_idContaController.text.trim());
    final valor =
        double.tryParse(_valorController.text.replaceAll(',', '.').trim());

    if (idConta == null || valor == null || valor <= 0) {
      setState(() {
        _tipoMensagem = 'erro';
        _mensagem = 'Preencha a conta e um valor válido maior que zero.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mensagem = null;
    });

    try {
      final conta = await ApiService.operarConta(
        idAgencia: _agencia,
        idConta: idConta,
        tipo: _tipo,
        valor: valor,
      );
      final acao = _tipo == 'DEPOSITO' ? 'Depósito' : 'Saque';
      setState(() {
        _tipoMensagem = 'sucesso';
        _mensagem =
            '$acao realizado com sucesso! Novo saldo da conta #${conta.id}: R\$ ${conta.saldo.toStringAsFixed(2)}';
      });
    } on OperacaoOfflineSalvaException catch (offlineEx) {
      setState(() {
        _tipoMensagem = 'pendente';
        _mensagem = offlineEx.mensagem;
      });
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
      paginaAtiva: 'operacoes',
      titulo: 'Depósito e Saque',
      subtitulo: 'Movimente valores na sua agência',
      onSyncCompleted: () => setState(() {}),
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
          const SizedBox(height: 16),
          buildWebLabel('Número da Conta (ID):'),
          TextField(
            controller: _idContaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'ID da conta'),
          ),
          const SizedBox(height: 16),
          buildWebLabel('Tipo de Operação:'),
          DropdownButtonFormField<String>(
            value: _tipo,
            items: const [
              DropdownMenuItem(
                  value: 'DEPOSITO', child: Text('Depósito (Entrada)')),
              DropdownMenuItem(value: 'SAQUE', child: Text('Saque (Saída)')),
            ],
            onChanged: (v) => setState(() => _tipo = v ?? 'DEPOSITO'),
          ),
          const SizedBox(height: 16),
          buildWebLabel('Valor (R\$):'),
          TextField(
            controller: _valorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '0.00'),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _isLoading ? null : _executarOperacao,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Confirmar Operação'),
          ),
          if (_mensagem != null)
            buildWebMensagem(texto: _mensagem!, tipo: _tipoMensagem),
        ],
      ),
    );
  }
}
