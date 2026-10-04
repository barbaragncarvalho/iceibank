package br.iceibank.agenciaJava.controller;

import br.iceibank.agenciaJava.config.AgenciaConfig;
import br.iceibank.agenciaJava.dto.TransferenciaDTO;
import br.iceibank.agenciaJava.model.ContaModel;
import br.iceibank.agenciaJava.services.RegistroEventos;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import br.iceibank.agenciaJava.services.RelogioVetorial;
import java.io.IOException;
import java.util.Map;

@RestController
public class TransferenciaController {

    private final RelogioVetorial relogio;
    private final RegistroEventos registro;
    private final AgenciaConfig config;
    private final RabbitTemplate rabbitTemplate;

    public TransferenciaController(RelogioVetorial relogio, RegistroEventos registro, AgenciaConfig config,
            RabbitTemplate rabbitTemplate) {
        this.relogio = relogio;
        this.registro = registro;
        this.config = config;
        this.rabbitTemplate = rabbitTemplate;
    }

    @PostMapping("/transferencias")
    public ResponseEntity<?> transferir(@RequestBody TransferenciaDTO body) throws IOException {
        ContaModel contaOrigem = ContaController.contas.get(body.getIdOrigem());
        if (contaOrigem == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta de origem não encontrada nesta agência."));
        }
        if (contaOrigem.getSaldoInicial() < body.getValor()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("erro", "Saldo insuficiente."));
        }

        int agenciaDestino = AgenciaConfig.agenciaResponsavel(body.getIdDestino());

        // Débito local
        int[] tsDebito = relogio.eventoLocal();
        contaOrigem.setSaldoInicial(contaOrigem.getSaldoInicial() - body.getValor());
        registro.registrar("TRANSFERENCIA_DEBITO", tsDebito, Map.of(
                "idOrigem", body.getIdOrigem(),
                "idDestino", body.getIdDestino(),
                "valor", body.getValor()));
                
        // Disparar alerta se saldo da conta for menor que 50 reais
        if (contaOrigem.getSaldoInicial() < 50.0) {
            Map<String, Object> alerta = Map.of(
                    "idConta", body.getIdOrigem(),
                    "saldoAtual", contaOrigem.getSaldoInicial(),
                    "agencia", config.getIdAgencia()
            );
            rabbitTemplate.convertAndSend("iceibank.eventos", "alerta.saldo.baixo", alerta);
        }

        // Transferência dentro da mesma agência
        if (agenciaDestino == config.getIdAgencia()) {
            ContaModel contaDestino = ContaController.contas.get(body.getIdDestino());
            if (contaDestino == null) {
                contaOrigem.setSaldoInicial(contaOrigem.getSaldoInicial() + body.getValor());
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("erro", "Conta de destino não encontrada."));
            }
            int[] tsCredito = relogio.eventoLocal();
            contaDestino.setSaldoInicial(contaDestino.getSaldoInicial() + body.getValor());
            registro.registrar("TRANSFERENCIA_CREDITO", tsCredito, Map.of(
                    "idOrigem", body.getIdOrigem(),
                    "idDestino", body.getIdDestino(),
                    "valor", body.getValor()));
            return ResponseEntity.ok(Map.of("mensagem", "Transferência concluída (mesma agência)."));
        }

        // Transferência entre agências diferentes
        int[] tsEnvio = relogio.aoEnviar();
        String routingKey = "agencia." + agenciaDestino + ".creditar";

        Map<String, Object> mensagemRabbit = Map.of(
                "idConta", body.getIdDestino(),
                "valor", body.getValor(),
                "vetorEnvio", tsEnvio,
                "origemAgencia", config.getIdAgencia());

        rabbitTemplate.convertAndSend("iceibank.eventos", routingKey, mensagemRabbit);

        return ResponseEntity.ok(Map.of(
                "mensagem", "Transferência publicada para a agência de destino (entrega assíncrona)."));
    }
}