const btnCriar = document.getElementById('btn-criar');
const msg = document.getElementById('mensagem');

btnCriar.addEventListener('click', async () => {
    msg.style.display = 'none';

    const agenciaDestinoUrl = document.getElementById('agencia').value;
    const usuario = document.getElementById('usuario').value.trim();
    const senha = document.getElementById('senha').value.trim();
    const idRaw = document.getElementById('conta-id').value;
    const nomeAluno = document.getElementById('nome-aluno').value.trim();
    const saldoRaw = document.getElementById('saldo-inicial').value;

    if (!usuario || !senha || !idRaw || !nomeAluno || !saldoRaw) {
        msg.className = 'alerta erro';
        msg.innerText = 'Preencha todos os campos do formulário.';
        msg.style.display = 'block';
        return;
    }

    const id = parseInt(idRaw, 10);
    const saldoInicial = parseFloat(saldoRaw);

    btnCriar.disabled = true;
    btnCriar.innerText = 'Criando conta...';

    try {
        try {
            await fetch(`${agenciaDestinoUrl}/auth/registro`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ usuario, senha })
            });
        } catch {
        }

        const respLogin = await fetch(`${agenciaDestinoUrl}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ usuario, senha })
        });

        const loginData = await respLogin.json();
        if (!respLogin.ok || !loginData?.token) {
            throw new Error(loginData?.erro || 'Falha ao autenticar na agência de destino.');
        }

        const tokenTemporarioCriacao = loginData.token;

        const respConta = await fetch(`${agenciaDestinoUrl}/contas`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${tokenTemporarioCriacao}`
            },
            body: JSON.stringify({ id, nomeAluno, saldoInicial })
        });

        const dataConta = await respConta.json();
        if (!respConta.ok) {
            throw new Error(dataConta?.erro || 'Falha ao abrir conta.');
        }

        msg.className = 'alerta sucesso';
        msg.innerText = `Conta ${id} criada com sucesso para ${nomeAluno}!`;
        msg.style.display = 'block';

    } catch (err) {
        msg.className = 'alerta erro';
        msg.innerText = err.message;
        msg.style.display = 'block';
    } finally {
        btnCriar.disabled = false;
        btnCriar.innerText = 'Criar Conta';
    }
});