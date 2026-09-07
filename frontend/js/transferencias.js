import { API } from './api.js';

if (!API.getToken()) {
    alert('Você precisa fazer login primeiro!');
    window.location.href = 'index.html';
}

document.getElementById('btn-sair').addEventListener('click', () => API.logout());
const form = document.getElementById('form-transferencia');
const msg = document.getElementById('mensagem');

function obterUrlAgenciaPorConta(idConta) {
    const agencias = {
        0: 'http://localhost:4047',
        1: 'http://localhost:4048',
        2: 'http://localhost:4049'
    };
    const idAgencia = ((idConta % 3) + 3) % 3;
    return agencias[idAgencia];
}

form.addEventListener('submit', async (e) => {
    e.preventDefault();
    msg.style.display = 'none';

    const idOrigem = parseInt(document.getElementById('id-origem').value, 10);
    const idDestino = parseInt(document.getElementById('id-destino').value, 10);
    const valor = parseFloat(document.getElementById('valor').value);

    const urlOrigem = obterUrlAgenciaPorConta(idOrigem);
    API.setBaseUrl(urlOrigem);

    try {
        const data = await API.request('/transferencias', 'POST', { idOrigem, idDestino, valor });
        msg.className = 'alerta sucesso';
        msg.innerText = data.mensagem || 'Transferência realizada com sucesso!';
        msg.style.display = 'block';
    } catch (err) {
        msg.className = 'alerta erro';
        msg.innerText = err.message;
        msg.style.display = 'block';
    }
});