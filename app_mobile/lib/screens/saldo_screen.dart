import 'package:flutter/material.dart';
import '../models/conta_model.dart';
import '../services/api_service.dart';
import '../widgets/iceibank_navbar.dart';

class SaldoScreen extends StatefulWidget {
  const SaldoScreen({super.key});

  @override
  State<SaldoScreen> createState() => _SaldoScreenState();
}

class _SaldoScreenState extends State<SaldoScreen> {
  int _agencia = 0;
  final _idContaController = TextEditingController();
  ContaModel? _conta;
  String? _erro;
  bool _isLoading = false;

  Future<void> _consultar() async {
    final idConta = int.tryParse(_idContaController.text.trim());
    if (idConta == null) {
      setState(() {
        _conta = null;
        _erro = 'Informe o ID da conta.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final conta = await ApiService.consultarSaldo(_agencia, idConta);
      setState(() => _conta = conta);
    } catch (e) {
      setState(() {
        _conta = null;
        _erro = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IceiBankLayout(
      paginaAtiva: 'saldo',
      titulo: 'Consulta de Saldo',
      subtitulo: 'Verifique os dados da sua conta em tempo real',
      onSyncCompleted: () {
        if (_idContaController.text.trim().isNotEmpty) {
          _consultar();
        }
      },
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
            decoration: const InputDecoration(hintText: 'Digite o ID da conta'),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _isLoading ? null : _consultar,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Consultar Saldo'),
          ),
          if (_conta != null)
            buildWebMensagem(
              tipo: _conta!.provisorio ? 'pendente' : 'sucesso',
              texto:
                  'Titular: ${_conta!.titular}\nConta: #${_conta!.id} (Agência ${_conta!.agencia})\nSaldo Atual: R\$ ${_conta!.saldo.toStringAsFixed(2)}${_conta!.provisorio ? " (Provisório Offline)" : ""}\nVetor Atual: ${_conta!.vetorAtual}',
            ),
          if (_erro != null) buildWebMensagem(texto: _erro!, tipo: 'erro'),
        ],
      ),
    );
  }
}
