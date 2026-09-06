package br.iceibank.agenciaJava;

import java.io.IOException;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import br.iceibank.agenciaJava.services.RegistroEventos;

import br.iceibank.agenciaJava.config.AgenciaConfig;

@SpringBootApplication
public class AgenciaJavaApplication {

	public static void main(String[] args) {
		SpringApplication.run(AgenciaJavaApplication.class, args);
	}

	@Bean
    public RegistroEventos registroEventos(AgenciaConfig config) throws IOException {
        return new RegistroEventos("agencia-" + config.getIdAgencia());
    }
}