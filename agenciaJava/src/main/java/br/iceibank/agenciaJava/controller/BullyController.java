package br.iceibank.agenciaJava.controller;

import br.iceibank.agenciaJava.config.AgenciaConfig;
import br.iceibank.agenciaJava.services.BullyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/bully")
public class BullyController {

    @Autowired
    private BullyService bullyService;

    @Autowired
    private AgenciaConfig config;

    @PostMapping("/eleicao")
    public ResponseEntity<?> receberEleicao(@RequestBody Map<String, Object> body) {
        int origemId = ((Number) body.get("origemId")).intValue();
        int[] vetor = extrairVetor(body.get("vetor"));
        bullyService.aoReceberEleicao(origemId, vetor);
        return ResponseEntity.ok(Map.of("ok", true, "idAgencia", config.getIdAgencia()));
    }

    @PostMapping("/coordenador")
    public ResponseEntity<?> receberCoordenador(@RequestBody Map<String, Object> body) {
        int liderId = ((Number) body.get("liderId")).intValue();
        int[] vetor = extrairVetor(body.get("vetor"));
        bullyService.aoReceberCoordenador(liderId, vetor);
        return ResponseEntity.ok(Map.of("ok", true));
    }

    @GetMapping("/lider")
    public ResponseEntity<?> obterLider() {
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("idAgencia", config.getIdAgencia());
        res.put("liderAtual", bullyService.getLiderAtual());
        return ResponseEntity.ok(res);
    }

    @PostMapping("/forcar-eleicao")
    public ResponseEntity<?> forcarEleicao() {
        Integer lider = bullyService.iniciarEleicao();
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("mensagem", "Eleição disparada manualmente na Agência " + config.getIdAgencia());
        res.put("idAgencia", config.getIdAgencia());
        res.put("liderAtual", lider);
        return ResponseEntity.ok(res);
    }

    @GetMapping("/status-cluster")
    public ResponseEntity<?> statusCluster() {
        return ResponseEntity.ok(bullyService.consultarStatusCluster());
    }

    private int[] extrairVetor(Object raw) {
        if (raw instanceof List<?> lista) {
            int[] arr = new int[lista.size()];
            for (int i = 0; i < lista.size(); i++) {
                arr[i] = ((Number) lista.get(i)).intValue();
            }
            return arr;
        }
        return null;
    }
}