package br.iceibank.agenciaJava.controller;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import br.iceibank.agenciaJava.config.AgenciaConfig;
import br.iceibank.agenciaJava.model.ContaModel;
import br.iceibank.agenciaJava.services.CompararVetoresService;
import br.iceibank.agenciaJava.services.RegistroEventos;
import br.iceibank.agenciaJava.services.RelogioVetorial;

@RestController
@RequestMapping("/contas")
public class ContaController {

    private final Map<Integer, ContaModel> contas = new ConcurrentHashMap<>();
    private final Map<Integer, String> alertas = new ConcurrentHashMap<>();

    @Autowired
    private AgenciaConfig config;

    @Autowired
    private RelogioVetorial relogio;

    @Autowired
    private RegistroEventos registro;

    @Autowired
    private CompararVetoresService compararVetoresService;

    @Autowired(required = false)
    private RabbitTemplate rabbitTemplate;

    public Map<Integer, ContaModel> getContas() {
        return contas;
    }

    @PostMapping
    public ResponseEntity<?> criarConta(@RequestBody Map<String, Object> body) {
        Integer id = body.get("id") != null ? ((Number) body.get("id")).intValue() : null;
        String nomeAluno = (String) body.get("nomeAluno");
        double saldoInicial = body.get("saldoInicial") != null
                ? ((Number) body.get("saldoInicial")).doubleValue()
                : 0.0;
        String senha = body.get("senha") != null ? (String) body.get("senha") : "";

        if (id == null || nomeAluno == null || nomeAluno.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("erro", "Informe id e nomeAluno da conta."));
        }

        if (AgenciaConfig.agenciaResponsavel(id) != config.getIdAgencia()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "erro", "Conta " + id + " não pertence a esta agência. Agência responsável: "
                            + AgenciaConfig.agenciaResponsavel(id)));
        }

        if (contas.containsKey(id)) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("erro", "Conta já existe."));
        }

        int[] ts = relogio.eventoLocal();
        ContaModel nova = new ContaModel(id, nomeAluno, saldoInicial, senha);
        contas.put(id, nova);

        registro.registrar("CRIAR_CONTA", ts, Map.of(
                "id", id,
                "nomeAluno", nomeAluno,
                "saldoInicial", saldoInicial));

        return ResponseEntity.status(HttpStatus.CREATED).body(montarRespostaConta(nova));
    }

    @PostMapping("/{id}/depositar")
    public ResponseEntity<?> depositar(@PathVariable int id, @RequestBody Map<String, Double> body) {
        ContaModel conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        double valor = body.getOrDefault("valor", 0.0);
        if (valor <= 0) {
            return ResponseEntity.badRequest().body(Map.of("erro", "O valor deve ser maior que zero."));
        }

        int[] ts = relogio.eventoLocal();
        synchronized (conta) {
            conta.setSaldoInicial(conta.getSaldoInicial() + valor);
        }

        registro.registrar("DEPOSITO", ts, Map.of("id", id, "valor", valor, "novoSaldo", conta.getSaldoInicial()));
        return ResponseEntity.ok(montarRespostaConta(conta));
    }

    @PostMapping("/{id}/sacar")
    public ResponseEntity<?> sacar(@PathVariable int id, @RequestBody Map<String, Double> body) {
        ContaModel conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        double valor = body.getOrDefault("valor", 0.0);
        if (valor <= 0) {
            return ResponseEntity.badRequest().body(Map.of("erro", "O valor deve ser maior que zero."));
        }

        synchronized (conta) {
            if (conta.getSaldoInicial() < valor) {
                return ResponseEntity.badRequest().body(Map.of("erro", "Saldo insuficiente."));
            }
            int[] ts = relogio.eventoLocal();
            conta.setSaldoInicial(conta.getSaldoInicial() - valor);
            registro.registrar("SAQUE", ts, Map.of("id", id, "valor", valor, "novoSaldo", conta.getSaldoInicial()));
        }

        return ResponseEntity.ok(montarRespostaConta(conta));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> consultarSaldo(@PathVariable int id) {
        ContaModel conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }
        return ResponseEntity.ok(montarRespostaConta(conta));
    }

    @PostMapping("/{id}/sincronizar")
    public ResponseEntity<?> sincronizarOperacaoPendente(
            @PathVariable int id,
            @RequestBody Map<String, Object> body) {

        ContaModel conta = contas.get(id);
        if (conta == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        String tipo = (String) body.get("tipo");
        double valor = body.get("valor") != null ? ((Number) body.get("valor")).doubleValue() : 0.0;

        int[] vetorConhecido = extrairVetor(body.get("vetorConhecido"));
        int[] vetorAtual = relogio.obterVetorAtual();
        String relacao = compararVetoresService.comparar(vetorConhecido, vetorAtual);

        if (!"IGUAIS".equals(relacao)) {
            var erroConflito = new LinkedHashMap<String, Object>();
            erroConflito.put("erro",
                    "Conflito detectado: o estado da conta mudou desde a última sincronização do app.");
            erroConflito.put("vetorConhecido", vetorConhecido);
            erroConflito.put("vetorAtual", vetorAtual);
            erroConflito.put("contaAtual", montarRespostaConta(conta));
            return ResponseEntity.status(HttpStatus.CONFLICT).body(erroConflito);
        }

        int[] novoVetor;
        synchronized (conta) {
            if ("DEPOSITO".equals(tipo)) {
                novoVetor = relogio.eventoLocal();
                conta.setSaldoInicial(conta.getSaldoInicial() + valor);
            } else if ("SAQUE".equals(tipo)) {
                if (conta.getSaldoInicial() < valor) {
                    return ResponseEntity.badRequest().body(Map.of("erro", "Saldo insuficiente."));
                }
                novoVetor = relogio.eventoLocal();
                conta.setSaldoInicial(conta.getSaldoInicial() - valor);
            } else if ("TRANSFERENCIA".equals(tipo)) {
                if (conta.getSaldoInicial() < valor) {
                    return ResponseEntity.badRequest().body(Map.of("erro", "Saldo insuficiente."));
                }
                int agenciaDestino = body.get("agenciaDestino") != null
                        ? ((Number) body.get("agenciaDestino")).intValue()
                        : config.getIdAgencia();
                int contaDestino = body.get("contaDestino") != null
                        ? ((Number) body.get("contaDestino")).intValue()
                        : -1;

                conta.setSaldoInicial(conta.getSaldoInicial() - valor);
                if (agenciaDestino == config.getIdAgencia()) {
                    novoVetor = relogio.eventoLocal();
                    ContaModel dest = contas.get(contaDestino);
                    if (dest != null) {
                        dest.setSaldoInicial(dest.getSaldoInicial() + valor);
                    }
                } else {
                    novoVetor = relogio.aoEnviar();
                    if (rabbitTemplate != null) {
                        var payload = new LinkedHashMap<String, Object>();
                        payload.put("idConta", contaDestino);
                        payload.put("valor", valor);
                        payload.put("vetorEnvio", novoVetor);
                        payload.put("origemAgencia", config.getIdAgencia());
                        String routingKey = "agencia." + agenciaDestino + ".creditar";
                        rabbitTemplate.convertAndSend("iceibank.eventos", routingKey, payload);
                    }
                }
            } else {
                return ResponseEntity.badRequest().body(Map.of("erro", "Tipo de operação pendente não suportado."));
            }
        }

        registro.registrar("SINCRONIZACAO_OFFLINE", novoVetor, Map.of(
                "id", id,
                "tipo", tipo,
                "valor", valor));

        return ResponseEntity.ok(montarRespostaConta(conta));
    }

    private int[] extrairVetor(Object raw) {
        if (raw instanceof List<?> lista) {
            int[] arr = new int[lista.size()];
            for (int i = 0; i < lista.size(); i++) {
                arr[i] = ((Number) lista.get(i)).intValue();
            }
            return arr;
        }
        return new int[0];
    }

    private Map<String, Object> montarRespostaConta(ContaModel conta) {
        var map = new LinkedHashMap<String, Object>();
        String alerta = consumirAlerta(conta.getId());
        if (alerta != null) {
            map.put("alerta", alerta);
        }
        map.put("id", conta.getId());
        map.put("agencia", config.getIdAgencia());
        map.put("nomeAluno", conta.getNomeAluno());
        map.put("saldo", conta.getSaldoInicial());
        map.put("saldoInicial", conta.getSaldoInicial());
        map.put("vetorAtual", relogio.obterVetorAtual());
        return map;
    }

    public void adicionarAlerta(int idConta, String textoAlerta) {
        alertas.put(idConta, textoAlerta);
    }

    public String consumirAlerta(int idConta) {
        return alertas.remove(idConta);
    }
}