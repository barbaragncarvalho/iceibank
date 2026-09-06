package br.iceibank.agenciaJava.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class AgenciaConfig {

    public static final int NUMERO_AGENCIAS = 3;
    public static final int OFFSET = 47;
    public static final int PORTA_BASE = 4000 + OFFSET;

    @Value("${agencia.id:0}")
    private int idAgencia;

    public int getIdAgencia() {
        return idAgencia;
    }

    public static int agenciaResponsavel(int idConta) {
        return idConta % NUMERO_AGENCIAS;
    }

    public static String getUrlAgencia(int idAgenciaDestino) {
        int porta = PORTA_BASE + idAgenciaDestino;
        return "http://localhost:" + porta;
    }
}