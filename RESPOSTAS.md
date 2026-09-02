# ICEIBank

## Parte B

1. O relógio de Lamport usa `max(contador_local, timestampRecebido) + 1` ao receber uma mensagem em vez de simplesmente adotar o timestamp recebido, porque assim se garante que haja a relação de causa e efeito, em que o evento de receber mensagem sempre terá um horário maior que o horário do evento que enviou a mensagem. Além disso, isso evita que o relógio não volte no tempo, já que a agência que recebeu a mensagem pode ter realizado operações localmente e estar com o horário maior do que quem enviou. Então, implementado dessa forma, garante que sempre pegará o horário maior.

2. O novo valor do contador da Agência 0 será 10 + 1 = 11, pois 10 é o horário de maior valor, então será usado pela função `max` para somar o seu tempo. Isso mostra que uma agência que processa muitos eventos rapidamente nunca tem seu horário voltando no tempo ao receber mensagens de agências mais lentas. E que agências mais lentas realizam pulos no tempo sempre que recebem mensagens de agências mais rápidas, se sincronizando para o tempo mais atual.

## Parte D

1. A transferência entre mesma agência não precisa da lógica de aoEnviar()/aoReceber() do relógio de Lamport, enquanto a transferência entre agências precisa, porque estes métodos servem para sincronizar o relógio entre processos diferentes quando há troca de mensagem na rede. Como cada agência é um processo, no primeiro cenário o débito e crédito das contas são regulados pela mesma variável contadora na memória (relógio local), então não há perigo de haver inconsistência de horário entre qual processo ocorreu primeiro. Já no segundo cenário, como são processos diferentes, pode ocorrer de uma agência estar com o horário bem maior que o da outra (pois ela realizou mais operações) e, para manter o registro consistente de qual operação foi realizada primeiro, é necessário sincronizar os relógios delas por meio dos métodos aoEnviar()/aoReceber().

2. Depois do erro, o saldo da conta de origem não foi revertido, ficando faltando o valor da transferência que deu erro. Em termos de consistência, isso significa que o sistema violou a propriedade de atomicidade, pois a transferência foi executada pela metade, deixando o banco em um estado inconsistente. Assim, o valor da transferência foi subtraído da conta de origem, mas nunca creditado no destino, impactando a integridade.

3. Duas formas possíveis de corrigir esse problema são: 
- usar o 2PC (Two-Phase Commit), na qual há um coordenador controlando a transação, que ocorre em 2 etapas: fase de preparação, em que ele pergunta à agência de origem se ela tem saldo e, caso sim, ela bloqueia o saldo, enquanto a de destino verifica se a conta existe e está apta a receber; e a fase de confirmação, em que, se ambas responderem positivamente, o coordenador envia uma mensagem para efetivar a operação e, se qualquer uma falhar ou não responder no tempo limite, o coordenador envia uma mensagem de cancelamento (rollback), garantindo que nada seja alterado;

- usar o padrão SAGA, em que a transferência é dividida em etapas locais independentes. Assim, a agência de origem debita o valor da conta e tenta chamar o crédito na agência de destino. Caso a chamada para o destino falhe ou demore demais, a própria agência de origem cancela a operação realizando o rollback, devolvendo o dinheiro e restaurando a consistência.

