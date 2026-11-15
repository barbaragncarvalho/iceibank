package br.iceibank.agenciaJava.config;

import br.iceibank.agenciaJava.controller.ContaController;
import br.iceibank.agenciaJava.model.ContaModel;
import br.iceibank.agenciaJava.services.RegistroEventos;
import br.iceibank.agenciaJava.services.RelogioVetorial;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
public class MensageriaConsumer {

    private final RelogioVetorial relogio;
    private final RegistroEventos registro;
    private final ContaController contaController;

    public MensageriaConsumer(RelogioVetorial relogio, RegistroEventos registro, ContaController contaController) {
        this.relogio = relogio;
        this.registro = registro;
        this.contaController = contaController;
    }

    @RabbitListener(queues = "#{filaAgencia.name}")
    public void receberCreditoRemoto(Map<String, Object> mensagem) {
        int idConta = ((Number) mensagem.get("idConta")).intValue();
        double valor = ((Number) mensagem.get("valor")).doubleValue();
        int origemAgencia = ((Number) mensagem.get("origemAgencia")).intValue();

        List<?> vetorList = (List<?>) mensagem.get("vetorEnvio");
        int[] vetorEnvio = vetorList.stream()
                .mapToInt(item -> ((Number) item).intValue())
                .toArray();

        int[] ts = relogio.aoReceber(vetorEnvio);

        ContaModel conta = contaController.getContas().get(idConta);
        if (conta == null) {
            registro.registrar("CREDITO_REMOTO_FALHOU", ts, Map.of(
                    "idConta", idConta,
                    "valor", valor,
                    "origemAgencia", origemAgencia,
                    "motivo", "conta não encontrada"));
            return;
        }

        synchronized (conta) {
            conta.setSaldoInicial(conta.getSaldoInicial() + valor);
        }

        registro.registrar("TRANSFERENCIA_CREDITO_REMOTO", ts, Map.of(
                "idConta", idConta,
                "valor", valor,
                "origemAgencia", origemAgencia));
    }

    @RabbitListener(queues = "#{filaAlertas.name}")
    public void receberAlertaSaldoBaixo(Map<String, Object> alerta) {
        int idConta = ((Number) alerta.get("idConta")).intValue();
        double saldoAtual = ((Number) alerta.get("saldoAtual")).doubleValue();

        String textoAlerta = "⚠️ Atenção! Conta com saldo baixo: R$ " + saldoAtual + "!";
        System.out.println("\n" + textoAlerta + "\n");

        contaController.adicionarAlerta(idConta, textoAlerta);
    }
}