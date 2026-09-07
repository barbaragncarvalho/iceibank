import { API } from './api.js';

if (!API.getToken()) {
    alert('Você precisa fazer login primeiro!');
    window.location.href = 'index.html';
}

document.getElementById('btn-sair').addEventListener('click', () => API.logout());
const form = document.getElementById('form-saldo');
const msg = document.getElementById('mensagem');

form.addEventListener('submit', async (e) => {
    e.preventDefault();
    msg.style.display = 'none';

    const id = document.getElementById('conta-id').value;

    try {
        const conta = await API.request(`/contas/${id}`, 'GET');
        msg.className = 'alerta sucesso';
        msg.innerHTML = `<strong>Conta:</strong> ${conta.id}<br><strong>Titular:</strong> ${conta.nomeAluno}<br><strong>Saldo Atual:</strong> R$ ${conta.saldoInicial.toFixed(2)}`;
        msg.style.display = 'block';
    } catch (err) {
        msg.className = 'alerta erro';
        msg.innerText = err.message;
        msg.style.display = 'block';
    }
});