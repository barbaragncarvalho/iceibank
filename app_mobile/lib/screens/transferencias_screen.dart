import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/iceibank_navbar.dart';

class TransferenciasScreen extends StatefulWidget {
  const TransferenciasScreen({super.key});

  @override
  State<TransferenciasScreen> createState() => _TransferenciasScreenState();
}

class _TransferenciasScreenState extends State<TransferenciasScreen> {
  int _agenciaOrigem = 0;
  int _agenciaDestino = 1;
  final _contaOrigemController = TextEditingController();
  final _contaDestinoController = TextEditingController();
  final _valorController = TextEditingController();
  String? _mensagem;
  String _tipoMensagem = 'sucesso';
  bool _isLoading = false;

  Future<void> _transferir() async {
    final contaOrigem = int.tryParse(_contaOrigemController.text.trim());
    final contaDestino = int.tryParse(_contaDestinoController.text.trim());
    final valor =
        double.tryParse(_valorController.text.replaceAll(',', '.').trim());

    if (contaOrigem == null ||
        contaDestino == null ||
        valor == null ||
        valor <= 0) {
      setState(() {
        _tipoMensagem = 'erro';
        _mensagem = 'Preencha todos os dados da transferência corretamente.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mensagem = null;
    });

    try {
      await ApiService.transferir(
        agenciaOrigemId: _agenciaOrigem,
        origemId: contaOrigem,
        agenciaDestinoId: _agenciaDestino,
        destinoId: contaDestino,
        valor: valor,
      );
      setState(() {
        _tipoMensagem = 'sucesso';
        _mensagem =
            'Transferência de R\$ ${valor.toStringAsFixed(2)} enviada da Conta #$contaOrigem (Ag. $_agenciaOrigem) para a Conta #$contaDestino (Ag. $_agenciaDestino)!';
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
      paginaAtiva: 'transferencias',
      titulo: 'Transferência Bancária',
      subtitulo: 'Envie valores entre contas e agências',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildWebLabel('Agência de Origem:'),
          DropdownButtonFormField<int>(
            value: _agenciaOrigem,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Agência 0 (Porta 4047)')),
              DropdownMenuItem(value: 1, child: Text('Agência 1 (Porta 4048)')),
              DropdownMenuItem(value: 2, child: Text('Agência 2 (Porta 4049)')),
            ],
            onChanged: (v) => setState(() => _agenciaOrigem = v ?? 0),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Conta de Origem (ID):'),
          TextField(
            controller: _contaOrigemController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(hintText: 'ID da sua conta de origem'),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Agência de Destino:'),
          DropdownButtonFormField<int>(
            value: _agenciaDestino,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Agência 0 (Porta 4047)')),
              DropdownMenuItem(value: 1, child: Text('Agência 1 (Porta 4048)')),
              DropdownMenuItem(value: 2, child: Text('Agência 2 (Porta 4049)')),
            ],
            onChanged: (v) => setState(() => _agenciaDestino = v ?? 1),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Conta de Destino (ID):'),
          TextField(
            controller: _contaDestinoController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(hintText: 'ID da conta recebedora'),
          ),
          const SizedBox(height: 14),
          buildWebLabel('Valor da Transferência (R\$):'),
          TextField(
            controller: _valorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '0.00'),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _isLoading ? null : _transferir,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Realizar Transferência'),
          ),
          if (_mensagem != null)
            buildWebMensagem(texto: _mensagem!, tipo: _tipoMensagem),
        ],
      ),
    );
  }
}
