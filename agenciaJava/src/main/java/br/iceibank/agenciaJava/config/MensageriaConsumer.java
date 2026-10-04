package br.iceibank.agenciaJava.config;

import br.iceibank.agenciaJava.controller.ContaController;
import br.iceibank.agenciaJava.model.ContaModel;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;
import br.iceibank.agenciaJava.services.RegistroEventos;
import br.iceibank.agenciaJava.services.RelogioVetorial;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@Component
public class MensageriaConsumer {

    private final RelogioVetorial relogio;
    private final RegistroEventos registro;

    public MensageriaConsumer(RelogioVetorial relogio, RegistroEventos registro) {
        this.relogio = relogio;
        this.registro = registro;
    }

    @RabbitListener(queues = "#{filaAgencia.name}")
    public void receberCreditoRemoto(Map<String, Object> mensagem) throws IOException {
        int idConta = (Integer) mensagem.get("idConta");
        double valor = (Double) mensagem.get("valor");
        int origemAgencia = (Integer) mensagem.get("origemAgencia");

        List<Integer> vetorList = (List<Integer>) mensagem.get("vetorEnvio");
        int[] vetorEnvio = vetorList.stream().mapToInt(i -> i).toArray();

        int[] ts = relogio.aoReceber(vetorEnvio);

        ContaModel conta = ContaController.contas.get(idConta);
        if (conta == null) {
            registro.registrar("CREDITO_REMOTO_FALHOU", ts, Map.of(
                    "idConta", idConta,
                    "valor", valor,
                    "origemAgencia", origemAgencia,
                    "motivo", "conta não encontrada"));
            return;
        }

        conta.setSaldoInicial(conta.getSaldoInicial() + valor);
        registro.registrar("TRANSFERENCIA_CREDITO_REMOTO", ts, Map.of(
                "idConta", idConta,
                "valor", valor,
                "origemAgencia", origemAgencia));
    }

    @RabbitListener(queues = "#{filaAlertas.name}")
    public void receberAlertaSaldoBaixo(Map<String, Object> alerta) {
        int idConta = (Integer) alerta.get("idConta");
        double saldoAtual = (Double) alerta.get("saldoAtual");

        String textoAlerta = "⚠️ Atenção! Conta com saldo baixo: R$ " + saldoAtual + "!";

        System.out.println("\n" + textoAlerta + "\n");

        ContaController.alertas.put(idConta, textoAlerta);
    }
}