package br.iceibank.agenciaJava.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    private final AgenciaConfig agenciaConfig;

    public RabbitMQConfig(AgenciaConfig agenciaConfig) {
        this.agenciaConfig = agenciaConfig;
    }

    @Bean
    public TopicExchange eventosExchange() {
        return new TopicExchange("iceibank.eventos", true, false);
    }

    @Bean
    public Queue filaAgencia() {
        String nomeFila = "fila-agencia-" + agenciaConfig.getIdAgencia();
        return new Queue(nomeFila, true);
    }

    @Bean
    public Binding binding(Queue filaAgencia, TopicExchange eventosExchange) {
        String routingKey = "agencia." + agenciaConfig.getIdAgencia() + ".creditar";
        return BindingBuilder.bind(filaAgencia).to(eventosExchange).with(routingKey);
    }

    @Bean
    public org.springframework.amqp.support.converter.MessageConverter jsonMessageConverter() {
        return new org.springframework.amqp.support.converter.Jackson2JsonMessageConverter();
    }

    @Bean
    public Queue filaAlertas() {
        return new Queue("fila-alertas-"+ agenciaConfig.getIdAgencia(), true);
    }

    @Bean
    public Binding bindingAlertas(Queue filaAlertas, TopicExchange eventosExchange) {
        return BindingBuilder.bind(filaAlertas).to(eventosExchange).with("alerta.saldo.baixo");
    }
}