package br.iceibank.agenciaJava.controller;

import br.iceibank.agenciaJava.config.AgenciaConfig;
import br.iceibank.agenciaJava.dto.CreditoRemotoDTO;
import br.iceibank.agenciaJava.dto.TransferenciaDTO;
import br.iceibank.agenciaJava.model.ContaModel;
import br.iceibank.agenciaJava.services.RegistroEventos;
import br.iceibank.agenciaJava.services.RelogioLamport;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.util.Map;

@RestController
public class TransferenciaController {

    private final RelogioLamport relogio;
    private final RegistroEventos registro;
    private final AgenciaConfig config;
    private final RestTemplate restTemplate = new RestTemplate();

    public TransferenciaController(RelogioLamport relogio, RegistroEventos registro, AgenciaConfig config) {
        this.relogio = relogio;
        this.registro = registro;
        this.config = config;
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
        int tsDebito = relogio.eventoLocal();
        contaOrigem.setSaldoInicial(contaOrigem.getSaldoInicial() - body.getValor());
        registro.registrar("TRANSFERENCIA_DEBITO", tsDebito, Map.of(
                "idOrigem", body.getIdOrigem(),
                "idDestino", body.getIdDestino(),
                "valor", body.getValor()
        ));

        // Transferência dentro da mesma agência
        if (agenciaDestino == config.getIdAgencia()) {
            ContaModel contaDestino = ContaController.contas.get(body.getIdDestino());
            if (contaDestino == null) {
                contaOrigem.setSaldoInicial(contaOrigem.getSaldoInicial() + body.getValor());
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("erro", "Conta de destino não encontrada."));
            }
            int tsCredito = relogio.eventoLocal();
            contaDestino.setSaldoInicial(contaDestino.getSaldoInicial() + body.getValor());
            registro.registrar("TRANSFERENCIA_CREDITO", tsCredito, Map.of(
                    "idOrigem", body.getIdOrigem(),
                    "idDestino", body.getIdDestino(),
                    "valor", body.getValor()
            ));
            return ResponseEntity.ok(Map.of("mensagem", "Transferência concluída (mesma agência)."));
        }

        // Transferência entre agências diferentes
        int tsEnvio = relogio.aoEnviar();
        String urlDestino = AgenciaConfig.getUrlAgencia(agenciaDestino);

        try {
            Map<String, Object> requisicaoRemota = Map.of(
                    "valor", body.getValor(),
                    "timestampLamport", tsEnvio,
                    "origemAgencia", config.getIdAgencia()
            );

            restTemplate.postForEntity(
                    urlDestino + "/contas/" + body.getIdDestino() + "/creditar-remoto",
                    requisicaoRemota,
                    Map.class
            );

            return ResponseEntity.ok(Map.of("mensagem", "Transferência concluída (entre agências)."));
        } catch (RestClientException erro) {
            // Limitação conhecida, em que o débito permanece e se registra o erro
            registro.registrar("TRANSFERENCIA_FALHOU", relogio.eventoLocal(), Map.of(
                    "idOrigem", body.getIdOrigem(),
                    "idDestino", body.getIdDestino(),
                    "valor", body.getValor(),
                    "erro", erro.getMessage()
            ));
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(Map.of(
                    "erro", "Falha ao contatar agência de destino. Débito já aplicado - inconsistência conhecida (ver Sprint 4)."
            ));
        }
    }

    @PostMapping("/contas/{id}/creditar-remoto")
    public ResponseEntity<?> creditarRemoto(@PathVariable int id, @RequestBody CreditoRemotoDTO body) throws IOException {
        int ts = relogio.aoReceber(body.getTimestampLamport());

        ContaModel conta = ContaController.contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        conta.setSaldoInicial(conta.getSaldoInicial() + body.getValor());
        registro.registrar("TRANSFERENCIA_CREDITO_REMOTO", ts, Map.of(
                "idConta", id,
                "valor", body.getValor(),
                "origemAgencia", body.getOrigemAgencia()
        ));

        return ResponseEntity.ok(Map.of("mensagem", "Crédito remoto aplicado.", "saldoAtual", conta.getSaldoInicial()));
    }
}