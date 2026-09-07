package br.iceibank.agenciaJava.controller;

import br.iceibank.agenciaJava.services.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/auth")
public class AuthController {
    private static final Map<String, String> usuarios = new ConcurrentHashMap<>();

    private final JwtService jwtService;

    public AuthController(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @PostMapping("/registro")
    public ResponseEntity<?> registrar(@RequestBody Map<String, String> body) {
        String usuario = body.get("usuario");
        String senha = body.get("senha");

        if (usuario == null || senha == null || usuario.isBlank() || senha.isBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("erro", "Usuario e senha sao obrigatorios."));
        }

        if (usuarios.containsKey(usuario)) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("erro", "Usuario ja cadastrado."));
        }

        usuarios.put(usuario, senha);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("mensagem", "Usuario cadastrado com sucesso!"));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        String usuario = body.get("usuario");
        String senha = body.get("senha");

        if (usuario != null && usuarios.containsKey(usuario) && usuarios.get(usuario).equals(senha)) {
            String token = jwtService.gerarToken(usuario);
            return ResponseEntity.ok(Map.of("token", token));
        }

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("erro", "Usuário ou senha incorretos."));
    }
}