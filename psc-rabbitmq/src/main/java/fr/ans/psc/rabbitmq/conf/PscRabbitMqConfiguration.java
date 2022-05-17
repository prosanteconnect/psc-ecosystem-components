package fr.ans.psc.rabbitmq.conf;

import org.springframework.amqp.core.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class PscRabbitMqConfiguration {

    /** The Constant QUEUE_PS_CREATE_MESSAGES. */
    public static final String QUEUE_PS_CREATE_MESSAGES = "ps-create-queue";

    /** The Constant QUEUE_PS_UPDATE_MESSAGES. */
    public static final String QUEUE_PS_UPDATE_MESSAGES = "ps-update-queue";

    /** The Constant QUEUE_PS_DELETE_MESSAGES. */
    public static final String QUEUE_PS_DELETE_MESSAGES = "ps-delete-queue";

    /** The Constant DLX_EXCHANGE_MESSAGES. */
    public static final String DLX_EXCHANGE_MESSAGES = "ps-queue.dlx";

    /** The Constant PS_QUEUE_CREATE_MESSAGES_DLQ. */
    public static final String PS_QUEUE_CREATE_MESSAGES_DLQ = QUEUE_PS_CREATE_MESSAGES + ".dlq";

    /** The Constant PS_QUEUE_UPDATE_MESSAGES_DLQ. */
    public static final String PS_QUEUE_UPDATE_MESSAGES_DLQ = QUEUE_PS_UPDATE_MESSAGES + ".dlq";

    /** The Constant PS_QUEUE_DELETE_MESSAGES_DLQ. */
    public static final String PS_QUEUE_DELETE_MESSAGES_DLQ = QUEUE_PS_DELETE_MESSAGES + ".dlq";

    /** The Constant EXCHANGE_MESSAGES. */
    public static final String EXCHANGE_MESSAGES = "ps-messages-exchange";

    /** The Constant MESSAGES_QUEUE_ROUTING_KEY_SUFFIX. */
    public static final String MESSAGES_QUEUE_ROUTING_KEY_SUFFIX = "MESSAGES_QUEUE_ROUTING_KEY";

    /** The Constant ROUTING_KEY_MESSAGES_QUEUE. */
    public static final String PS_CREATE_MESSAGES_QUEUE_ROUTING_KEY = "PS_CREATE_" + MESSAGES_QUEUE_ROUTING_KEY_SUFFIX;

    /** The Constant ROUTING_KEY_MESSAGES_QUEUE. */
    public static final String PS_UPDATE_MESSAGES_QUEUE_ROUTING_KEY = "PS_UPDATE_" + MESSAGES_QUEUE_ROUTING_KEY_SUFFIX;

    /** The Constant ROUTING_KEY_MESSAGES_QUEUE. */
    public static final String PS_DELETE_MESSAGES_QUEUE_ROUTING_KEY = "PS_DELETE_" + MESSAGES_QUEUE_ROUTING_KEY_SUFFIX;


    /**
     * Ps create messages queue.
     *
     * @return the queue
     */
    @Bean
    Queue psCreateMessagesQueue() {
        return QueueBuilder.durable(QUEUE_PS_CREATE_MESSAGES)
                .withArgument("x-dead-letter-exchange", DLX_EXCHANGE_MESSAGES)
                .build();
    }

    /**
     * Ps update messages queue.
     *
     * @return the queue
     */
    @Bean
    Queue psUpdateMessagesQueue() {
        return QueueBuilder.durable(QUEUE_PS_UPDATE_MESSAGES)
                .withArgument("x-dead-letter-exchange", DLX_EXCHANGE_MESSAGES)
                .build();
    }

    /**
     * Ps delete messages queue.
     *
     * @return the queue
     */
    @Bean
    Queue psDeleteMessagesQueue() {
        return QueueBuilder.durable(QUEUE_PS_DELETE_MESSAGES)
                .withArgument("x-dead-letter-exchange", DLX_EXCHANGE_MESSAGES)
                .build();
    }

    /**
     * Messages exchange.
     *
     * @return the direct exchange
     */
    @Bean
    DirectExchange messagesExchange() {
        return new DirectExchange(EXCHANGE_MESSAGES);
    }

    /**
     * Binding Ps create messages.
     *
     * @return the binding
     */
    @Bean
    Binding bindingPsCreateMessages() {
        return BindingBuilder.bind(psCreateMessagesQueue()).to(messagesExchange()).with(PS_CREATE_MESSAGES_QUEUE_ROUTING_KEY);
    }

    /**
     * Binding Ps create messages.
     *
     * @return the binding
     */
    @Bean
    Binding bindingPsUpdateMessages() {
        return BindingBuilder.bind(psUpdateMessagesQueue()).to(messagesExchange()).with(PS_UPDATE_MESSAGES_QUEUE_ROUTING_KEY);
    }

    /**
     * Binding Ps create messages.
     *
     * @return the binding
     */
    @Bean
    Binding bindingPsDeleteMessages() {
        return BindingBuilder.bind(psDeleteMessagesQueue()).to(messagesExchange()).with(PS_DELETE_MESSAGES_QUEUE_ROUTING_KEY);
    }

    /**
     * Dead letter exchange.
     *
     * @return the fanout exchange
     */
    @Bean
    FanoutExchange deadLetterExchange() {
        return new FanoutExchange(DLX_EXCHANGE_MESSAGES);
    }

    /**
     * Dead letter ps create queue.
     *
     * @return the queue
     */
    @Bean
    Queue deadLetterPsCreateQueue() {
        return QueueBuilder.durable(PS_QUEUE_CREATE_MESSAGES_DLQ).build();
    }

    /**
     * Dead letter binding.
     *
     * @return the binding
     */
    @Bean
    Binding deadLetterPsCreateBinding() {
        return BindingBuilder.bind(deadLetterPsCreateQueue()).to(deadLetterExchange());
    }

    /**
     * Dead letter ps create queue.
     *
     * @return the queue
     */
    @Bean
    Queue deadLetterPsUpdateQueue() {
        return QueueBuilder.durable(PS_QUEUE_UPDATE_MESSAGES_DLQ).build();
    }

    /**
     * Dead letter binding.
     *
     * @return the binding
     */
    @Bean
    Binding deadLetterPsUpdateBinding() {
        return BindingBuilder.bind(deadLetterPsUpdateQueue()).to(deadLetterExchange());
    }

    /**
     * Dead letter ps create queue.
     *
     * @return the queue
     */
    @Bean
    Queue deadLetterPsDeleteQueue() {
        return QueueBuilder.durable(PS_QUEUE_DELETE_MESSAGES_DLQ).build();
    }

    /**
     * Dead letter binding.
     *
     * @return the binding
     */
    @Bean
    Binding deadLetterPsDeleteBinding() {
        return BindingBuilder.bind(deadLetterPsDeleteQueue()).to(deadLetterExchange());
    }
}
