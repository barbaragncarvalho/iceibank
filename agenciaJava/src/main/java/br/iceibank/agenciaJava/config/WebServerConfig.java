package br.iceibank.agenciaJava.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.boot.web.server.servlet.ConfigurableServletWebServerFactory;
import org.springframework.stereotype.Component;

@Component
public class WebServerConfig implements WebServerFactoryCustomizer<ConfigurableServletWebServerFactory> {

    @Value("${app.offset:47}")
    private int offset;

    @Value("${agencia.id:0}")
    private int idAgencia;

    @Override
    public void customize(ConfigurableServletWebServerFactory factory) {
        int porta = 4000 + offset + idAgencia;
        factory.setPort(porta);
    }
}