# IceiBank

Sistema bancário distribuído particionado em três agências independentes, desenvolvido em Java com Spring Boot no backend e uma interface web moderna e desacoplada em HTML, CSS e JavaScript no frontend.

O projeto conta com autenticação baseada em JWT (JSON Web Token), sincronização de eventos lógicos via Relógios de Lamport, controle de concorrência e transferências financeiras locais e entre agências.

## Como Executar o Backend

O sistema precisa que as três instâncias das agências estejam rodando simultaneamente. Abra três terminais separados na pasta do backend (iceibank/agenciaJava):

Terminal 1 — Agência 0 (Porta 4047):

```
$env:AGENCIA_ID="0"; ./mvnw spring-boot:run
```

Terminal 2 — Agência 1 (Porta 4048):
```
$env:AGENCIA_ID="1"; ./mvnw spring-boot:run
```

Terminal 3 — Agência 2 (Porta 4049):
```
$env:AGENCIA_ID="2"; ./mvnw spring-boot:run
```

## Como Executar o Frontend
Após ter o backend executando, faça:

1. Abra a pasta do projeto no VS Code.

2. Navegue até o diretório frontend/.

3. Clique com o botão direito sobre o arquivo ``index.html`` e selecione Open with Live Server.

Prontinho, basta usar.

