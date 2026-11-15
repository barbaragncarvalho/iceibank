package br.iceibank.agenciaJava.services;

import br.iceibank.agenciaJava.config.AgenciaConfig;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

@Service
public class BullyService {

    @Autowired
    private AgenciaConfig config;

    @Autowired
    private RelogioVetorial relogio;

    @Autowired
    private RegistroEventos registro;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(1))
            .build();

    private final AtomicInteger liderAtual = new AtomicInteger(-1);
    private final AtomicBoolean eleicaoEmAndamento = new AtomicBoolean(false);
    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();

    @PostConstruct
    public void inicializar() {
        scheduler.schedule(this::iniciarEleicao, 1500, TimeUnit.MILLISECONDS);
        scheduler.scheduleAtFixedRate(this::verificarHeartbeatLider, 3000, 3000, TimeUnit.MILLISECONDS);
    }

    @PreDestroy
    public void encerrar() {
        scheduler.shutdownNow();
    }

    public Integer getLiderAtual() {
        int atual = liderAtual.get();
        return atual == -1 ? null : atual;
    }

    public synchronized void setLiderAtual(Integer novoLider) {
        liderAtual.set(novoLider == null ? -1 : novoLider);
    }

    private String vetorParaJson(int[] vetor) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < vetor.length; i++) {
            if (i > 0)
                sb.append(",");
            sb.append(vetor[i]);
        }
        sb.append("]");
        return sb.toString();
    }

    public synchronized Integer iniciarEleicao() {
        if (!eleicaoEmAndamento.compareAndSet(false, true)) {
            return getLiderAtual();
        }

        try {
            int meuId = config.getIdAgencia();
            var maiores = new ArrayList<Integer>();
            for (int id = meuId + 1; id < AgenciaConfig.NUMERO_AGENCIAS; id++) {
                maiores.add(id);
            }

            int[] tsInicio = relogio.eventoLocal();
            var logInicio = new LinkedHashMap<String, Object>();
            logInicio.put("candidata", meuId);
            logInicio.put("maioresConsultadas", maiores);
            registro.registrar("ELEICAO_INICIADA", tsInicio, logInicio);

            if (maiores.isEmpty()) {
                declararVitoria();
                return meuId;
            }

            boolean algumaRespondeuOk = false;
            for (int idMaior : maiores) {
                try {
                    int[] vetorEnvio = relogio.aoEnviar();
                    String url = AgenciaConfig.getUrlAgencia(idMaior) + "/bully/eleicao";
                    String body = "{\"origemId\":" + meuId + ",\"vetor\":" + vetorParaJson(vetorEnvio) + "}";

                    HttpRequest request = HttpRequest.newBuilder()
                            .uri(URI.create(url))
                            .timeout(Duration.ofSeconds(1))
                            .header("Content-Type", "application/json")
                            .POST(HttpRequest.BodyPublishers.ofString(body))
                            .build();

                    var response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                    if (response.statusCode() == 200) {
                        algumaRespondeuOk = true;
                    }
                } catch (Exception ignored) {
                }
            }

            if (!algumaRespondeuOk) {
                declararVitoria();
            }

            return getLiderAtual();
        } finally {
            eleicaoEmAndamento.set(false);
        }
    }

    public synchronized void declararVitoria() {
        int meuId = config.getIdAgencia();
        setLiderAtual(meuId);

        int[] tsVitoria = relogio.eventoLocal();
        registro.registrar("LIDER_ELEITO", tsVitoria, Map.of("novoLider", meuId));
        System.out.println("[Bully] Agência " + meuId + " assumiu a liderança!");

        for (int id = 0; id < AgenciaConfig.NUMERO_AGENCIAS; id++) {
            if (id == meuId)
                continue;
            final int destinoId = id;
            CompletableFuture.runAsync(() -> {
                try {
                    int[] vetorEnvio = relogio.aoEnviar();
                    String url = AgenciaConfig.getUrlAgencia(destinoId) + "/bully/coordenador";
                    String body = "{\"liderId\":" + meuId + ",\"vetor\":" + vetorParaJson(vetorEnvio) + "}";

                    HttpRequest request = HttpRequest.newBuilder()
                            .uri(URI.create(url))
                            .timeout(Duration.ofSeconds(1))
                            .header("Content-Type", "application/json")
                            .POST(HttpRequest.BodyPublishers.ofString(body))
                            .build();

                    httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                } catch (Exception ignored) {
                }
            });
        }
    }

    public void aoReceberEleicao(int origemId, int[] vetorRemoto) {
        int meuId = config.getIdAgencia();
        int[] ts = (vetorRemoto != null && vetorRemoto.length == AgenciaConfig.NUMERO_AGENCIAS)
                ? relogio.aoReceber(vetorRemoto)
                : relogio.eventoLocal();

        registro.registrar("ELEICAO_RECEBIDA", ts, Map.of("de", origemId));

        if (meuId > origemId) {
            CompletableFuture.runAsync(this::iniciarEleicao);
        }
    }

    public synchronized void aoReceberCoordenador(int liderId, int[] vetorRemoto) {
        int[] ts = (vetorRemoto != null && vetorRemoto.length == AgenciaConfig.NUMERO_AGENCIAS)
                ? relogio.aoReceber(vetorRemoto)
                : relogio.eventoLocal();

        setLiderAtual(liderId);
        registro.registrar("COORDENADOR_RECEBIDO", ts, Map.of("novoLider", liderId));
        System.out.println(
                "[Bully] Agência " + config.getIdAgencia() + " reconheceu Agência " + liderId + " como líder.");
    }

    private void verificarHeartbeatLider() {
        try {
            int meuId = config.getIdAgencia();
            Integer lider = getLiderAtual();

            if (lider == null) {
                iniciarEleicao();
                return;
            }
            if (lider == meuId) {
                return;
            }

            String url = AgenciaConfig.getUrlAgencia(lider) + "/bully/lider";
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(1))
                    .GET()
                    .build();

            var response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                tratarFalhaLider(lider);
            }
        } catch (Exception e) {
            Integer liderSuspeito = getLiderAtual();
            if (liderSuspeito != null && liderSuspeito != config.getIdAgencia()) {
                tratarFalhaLider(liderSuspeito);
            }
        }
    }

    private synchronized void tratarFalhaLider(int liderFalho) {
        System.out.println("[Heartbeat] Agência " + config.getIdAgencia() + " detectou falha da líder " + liderFalho
                + ". Iniciando eleição...");
        int[] ts = relogio.eventoLocal();
        registro.registrar("FALHA_LIDER_DETECTADA", ts, Map.of("liderSuspeito", liderFalho));
        setLiderAtual(null);
        CompletableFuture.runAsync(this::iniciarEleicao);
    }

    public Map<String, Object> consultarStatusCluster() {
        var nos = new ArrayList<Object>();
        Integer lider = getLiderAtual();

        for (int id = 0; id < AgenciaConfig.NUMERO_AGENCIAS; id++) {
            boolean online = false;
            if (id == config.getIdAgencia()) {
                online = true;
            } else {
                try {
                    String url = AgenciaConfig.getUrlAgencia(id) + "/bully/lider";
                    HttpRequest req = HttpRequest.newBuilder()
                            .uri(URI.create(url))
                            .timeout(Duration.ofMillis(700))
                            .GET()
                            .build();
                    var res = httpClient.send(req, HttpResponse.BodyHandlers.ofString());
                    if (res.statusCode() == 200) {
                        online = true;
                    }
                } catch (Exception ignored) {
                }
            }
            var infoNo = new LinkedHashMap<String, Object>();
            infoNo.put("idAgencia", id);
            infoNo.put("url", AgenciaConfig.getUrlAgencia(id));
            infoNo.put("online", online);
            infoNo.put("ehLider", lider != null && lider == id);
            nos.add(infoNo);
        }

        var resposta = new LinkedHashMap<String, Object>();
        resposta.put("agenciaConsultada", config.getIdAgencia());
        resposta.put("liderAtual", lider);
        resposta.put("nos", nos);
        return resposta;
    }
}