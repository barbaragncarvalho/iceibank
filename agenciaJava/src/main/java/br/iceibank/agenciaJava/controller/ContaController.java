package br.iceibank.agenciaJava.controller;

import br.iceibank.agenciaJava.config.AgenciaConfig;
import br.iceibank.agenciaJava.model.ContaModel;
import br.iceibank.agenciaJava.services.RegistroEventos;
import br.iceibank.agenciaJava.services.RelogioLamport;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/contas")
public class ContaController {

    public static final Map<Integer, ContaModel> contas = new ConcurrentHashMap<>();

    private final RelogioLamport relogio;
    private final RegistroEventos registro;
    private final AgenciaConfig config;

    public ContaController(RelogioLamport relogio, RegistroEventos registro, AgenciaConfig config) {
        this.relogio = relogio;
        this.registro = registro;
        this.config = config;
    }

    @PostMapping
    public ResponseEntity<?> criarConta(@RequestBody ContaModel conta) throws IOException {
        if (AgenciaConfig.agenciaResponsavel(conta.getId()) != config.getIdAgencia()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("erro", "Conta " + conta.getId() + " não pertence a esta agência."));
        }
        if (contas.containsKey(conta.getId())) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("erro", "Conta já existe."));
        }

        int ts = relogio.eventoLocal();
        contas.put(conta.getId(), conta);
        registro.registrar("CRIAR_CONTA", ts, Map.of(
                "id", conta.getId(),
                "nomeAluno", conta.getNomeAluno(),
                "saldoInicial", conta.getSaldoInicial()
        ));

        return ResponseEntity.status(HttpStatus.CREATED).body(conta);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> consultarSaldo(@PathVariable int id) {
        ContaModel conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }
        return ResponseEntity.ok(conta);
    }

    @PostMapping("/{id}/depositar")
    public ResponseEntity<?> depositar(@PathVariable int id, @RequestBody Map<String, Double> payload) throws IOException {
        ContaModel conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        double valor = payload.get("valor");
        int ts = relogio.eventoLocal();
        conta.setSaldoInicial(conta.getSaldoInicial() + valor);
        registro.registrar("DEPOSITO", ts, Map.of("id", id, "valor", valor, "novoSaldo", conta.getSaldoInicial()));

        return ResponseEntity.ok(conta);
    }

    @PostMapping("/{id}/sacar")
    public ResponseEntity<?> sacar(@PathVariable int id, @RequestBody Map<String, Double> payload) throws IOException {
        ContaModel conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        double valor = payload.get("valor");
        if (valor > 1000) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("erro", "Operação cancelada. O valor máximo permitido por saque é de R$ 1.000,00."));
        }

        if (conta.getSaldoInicial() < valor) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("erro", "Saldo insuficiente."));
        }

        int ts = relogio.eventoLocal();
        conta.setSaldoInicial(conta.getSaldoInicial() - valor);
        registro.registrar("SAQUE", ts, Map.of("id", id, "valor", valor, "novoSaldo", conta.getSaldoInicial()));

        return ResponseEntity.ok(conta);
    }
}