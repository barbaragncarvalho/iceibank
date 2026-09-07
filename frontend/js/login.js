import { API } from './api.js';

const form = document.getElementById('form-login');
const msg = document.getElementById('mensagem');

form.addEventListener('submit', async (e) => {
    e.preventDefault();
    msg.style.display = 'none';

    API.setBaseUrl(document.getElementById('agencia').value);
    const usuario = document.getElementById('usuario').value;
    const senha = document.getElementById('senha').value;

    try {
        const data = await API.request('/auth/login', 'POST', { usuario, senha });
        API.setToken(data.token);
        msg.className = 'alerta sucesso';
        msg.innerText = 'Login realizado! Redirecionando...';
        msg.style.display = 'block';
        setTimeout(() => window.location.href = 'saldo.html', 1000);
    } catch (err) {
        msg.className = 'alerta erro';
        msg.innerText = err.message;
        msg.style.display = 'block';
    }
});