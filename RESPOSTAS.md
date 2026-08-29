# ICEIBank

## Parte B

1. O relógio de Lamport usa `max(contador_local, timestampRecebido) + 1` ao receber uma mensagem em vez de simplesmente adotar o timestamp recebido, porque assim se garante que haja a relação de causa e efeito, em que o evento de receber mensagem sempre terá um horário maior que o horário do evento que enviou a mensagem. Além disso, isso evita que o relógio não volte no tempo, já que a agência que recebeu a mensagem pode ter realizado operações localmente e estar com o horário maior do que quem enviou. Então, implementado dessa forma, garante que sempre pegará o horário maior.

2. O novo valor do contador da Agência 0 será 10 + 1 = 11, pois 10 é o horário de maior valor, então será usado pela função `max` para somar o seu tempo. Isso mostra que uma agência que processa muitos eventos rapidamente nunca tem seu horário voltando no tempo ao receber mensagens de agências mais lentas. E que agências mais lentas realizam pulos no tempo sempre que recebem mensagens de agências mais rápidas, se sincronizando para o tempo mais atual.

