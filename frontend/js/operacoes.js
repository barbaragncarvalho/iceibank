import { API } from './api.js';

if (!API.getToken()) {
    alert('Você precisa fazer login primeiro!');
    window.location.href = 'index.html';
}

document.getElementById('btn-sair').addEventListener('click', () => API.logout());
const form = document.getElementById('form-operacao');
const msg = document.getElementById('mensagem');

form.addEventListener('submit', async (e) => {
    e.preventDefault();
    msg.style.display = 'none';

    const id = document.getElementById('conta-id').value;
    const tipo = document.getElementById('tipo-operacao').value;
    const valor = parseFloat(document.getElementById('valor').value);

    try {
        const data = await API.request(`/contas/${id}/${tipo}`, 'POST', { valor });
        msg.className = 'alerta sucesso';
        msg.innerText = `${tipo.toUpperCase()} realizado! Novo saldo: R$ ${data.saldoInicial.toFixed(2)}`;
        msg.style.display = 'block';
    } catch (err) {
        msg.className = 'alerta erro';
        msg.innerText = err.message;
        msg.style.display = 'block';
    }
});