# ICEIBank

## 2.1 Funcionalidade adicional: Limite de Saque

Foi escolhida esta regra de negócio que define o limite do saque como R$1.000,00, porque, em sistemas bancários reais, normalmente se há limites de movimentações, por questões de segurança.

## Parte B

1. O relógio de Lamport usa `max(contador_local, timestampRecebido) + 1` ao receber uma mensagem em vez de simplesmente adotar o timestamp recebido, porque assim se garante que haja a relação de causa e efeito, em que o evento de receber mensagem sempre terá um horário maior que o horário do evento que enviou a mensagem. Além disso, isso evita que o relógio não volte no tempo, já que a agência que recebeu a mensagem pode ter realizado operações localmente e estar com o horário maior do que quem enviou. Então, implementado dessa forma, garante que sempre pegará o horário maior.

2. O novo valor do contador da Agência 0 será 10 + 1 = 11, pois 10 é o horário de maior valor, então será usado pela função `max` para somar o seu tempo. Isso mostra que uma agência que processa muitos eventos rapidamente nunca tem seu horário voltando no tempo ao receber mensagens de agências mais lentas. E que agências mais lentas realizam pulos no tempo sempre que recebem mensagens de agências mais rápidas, se sincronizando para o tempo mais atual.

## Parte D

1. A transferência entre mesma agência não precisa da lógica de aoEnviar()/aoReceber() do relógio de Lamport, enquanto a transferência entre agências precisa, porque estes métodos servem para sincronizar o relógio entre processos diferentes quando há troca de mensagem na rede. Como cada agência é um processo, no primeiro cenário o débito e crédito das contas são regulados pela mesma variável contadora na memória (relógio local), então não há perigo de haver inconsistência de horário entre qual processo ocorreu primeiro. Já no segundo cenário, como são processos diferentes, pode ocorrer de uma agência estar com o horário bem maior que o da outra (pois ela realizou mais operações) e, para manter o registro consistente de qual operação foi realizada primeiro, é necessário sincronizar os relógios delas por meio dos métodos aoEnviar()/aoReceber().

2. Depois do erro, o saldo da conta de origem não foi revertido, ficando faltando o valor da transferência que deu erro. Em termos de consistência, isso significa que o sistema violou a propriedade de atomicidade, pois a transferência foi executada pela metade, deixando o banco em um estado inconsistente. Assim, o valor da transferência foi subtraído da conta de origem, mas nunca creditado no destino, impactando a integridade.

3. Duas formas possíveis de corrigir esse problema são: 
- usar o 2PC (Two-Phase Commit), na qual há um coordenador controlando a transação, que ocorre em 2 etapas: fase de preparação, em que ele pergunta à agência de origem se ela tem saldo e, caso sim, ela bloqueia o saldo, enquanto a de destino verifica se a conta existe e está apta a receber; e a fase de confirmação, em que, se ambas responderem positivamente, o coordenador envia uma mensagem para efetivar a operação e, se qualquer uma falhar ou não responder no tempo limite, o coordenador envia uma mensagem de cancelamento (rollback), garantindo que nada seja alterado;

- usar o padrão SAGA, em que a transferência é dividida em etapas locais independentes. Assim, a agência de origem debita o valor da conta e tenta chamar o crédito na agência de destino. Caso a chamada para o destino falhe ou demore demais, a própria agência de origem cancela a operação realizando o rollback, devolvendo o dinheiro e restaurando a consistência.

## Parte E

### 10.2

1. Foi encontrado eventos com mesmo valor de timestampLamport, como o criar conta na agência 0 e 1, que possuem o timestampLamport igual a 1. Esses dois eventos de mesmo tempo são concorrentes, pois não existe nenhuma dependência entre a criação da conta na Agência 0 e a criação da conta na Agência 1, já que uma ação não causou nem foi influenciada pela outra. Além disso, analisando a hora parede de cada evento, dá para perceber que os eventos de mesmo dia estão ordenados pelo de menor hora ao de maior, o que bate com a ordem de Lamport. E também, eventos que ocorreram em horários do mundo real diferente (criou-se uma conta na agência 0 às 19:59 e na agência 1 às 20:00) ficaram com o mesmo horário no relógio de lamport. Isso evidencia que o relógio de Lamport não mede passagem de tempo real, mas apenas o ordenamento causal de operações em cada processo. Assim, como estes 2 processos não são dependentes, assume-se que são concorrentes.

### 10.3 

1. Isso significa que se um evento A tem o timestamp menor que o de B, ou o de A causou o evento B, ou eles são eventos que não dependem um do outro e que o relógio de B somente avançou o seu tempo local mais rápido, por ter ocorrido mais operações. Com isso, nem sempre é possível afirmar que houve relação causal entre 2 eventos com timestamp diferentes, como é o caso do evento de criar conta na agência 1 no timestamp 2 e realizar transferência (débito) entre contas no timestamp 3, que são eventos totalmente independentes.

2. O relógio de Lamport, sozinho, não seria suficiente para um sistema que precisa distinguir eventos causais e independentes. Isso motiva o uso do relógio vetorial, porque ele armazena um vetor de contadores, em que cada posição representa uma agência, permitindo comparar posição a posição e determinar com certeza se dois eventos possuem relação causal ou se são eventos concorrentes.


## Parte F

### 11.1

• Para a Sprint 1 eu escolhi o formato das credenciais sendo usuário e senha, pois este é um formato mais simples e usado na maioria dos aplicativos. Além de que, com este modelo, o usuário não fica limitado ao acesso de somente uma conta bancária por vez (como no modelo conta e senha), podendo teoricamente acessar todas as contas que ele possui.

• A chamada entre agências (creditar-remoto), por ser interna, não precisa de estar protegida, considerando que ela só é feita pelos servidores de cada agência entre si e não diretamente pelo usuário. Além de que, para que o usuário consiga fazer uma transferência, ele deve ter criado sua conta que, por sua vez, exige que ele esteja logado. Assim, a autenticação já é garantida.

### 11.3

1. Autenticação é a comprovação de identidade, feita no login ao validar o usuário e senha. Já autorização é a checagem se aquele usuário específico tem direito de acessar ou modificar um recurso específico dentro do sistema. A minha implementação atual verifica apenas a autenticação, conferindo se a requisição possui um token JWT válido (validarToken()). Isso significa que, no momento, um usuário autenticado consegue sim sacar de uma conta que não é dele, pois não é checado se o usuário identificado no token é de fato o proprietário da conta informada no ID da URL.

2. O servidor não precisa consultar o banco de dados, porque o JWT carrega em seu próprio texto as informações necessárias (como identidade e data de validade) protegidas por uma assinatura criptografada, que pode ser validada com a chave secreta. Assim, quando a requisição chega, o servidor apenas aplica a fórmula matemática da chave secreta (HMAC-SHA256) para verificar se a assinatura confere e se a data não passou (validarToken()). Em questão de escalabilidade, com JWT, o servidor não precisa guardar nada na memória e nem consultar o banco de dados, pois basta ele saber a chave secreta para validar o token, o que torna tudo mais leve e rápido. Já no modo de guardar sessões em memória, é mais lento, porque o servidor tem que consultar o banco de dados ou memória para ver se a sessão é válida, o que, com muitos registros, é muito demorado (pouca escalabilidade).

3. Se a chave secreta usada para assinar o JWT vazasse, a segurança do sistema estaria em risco, pois qualquer um poderia pegar a chave e criar tokens para fingir ser outros usuários, podendo fazer as operações que quiser dentro do sistema.
