import { API } from './api.js';

if (!API.getToken()) {
    alert('Você precisa fazer login primeiro!');
    window.location.href = 'index.html';
}

document.getElementById('btn-sair').addEventListener('click', () => API.logout());
const form = document.getElementById('form-transferencia');
const msg = document.getElementById('mensagem');

form.addEventListener('submit', async (e) => {
    e.preventDefault();

    msg.style.display = 'none';
    const alertasAntigos = document.querySelectorAll('.alerta-extra');
    alertasAntigos.forEach(el => el.remove());

    const idOrigem = parseInt(document.getElementById('id-origem').value, 10);
    const idDestino = parseInt(document.getElementById('id-destino').value, 10);
    const valor = parseFloat(document.getElementById('valor').value);

    try {
        const data = await API.request('/transferencias', 'POST', { idOrigem, idDestino, valor });

        msg.className = 'alerta sucesso';
        msg.innerText = data.mensagem || 'Transferência realizada com sucesso!';
        msg.style.display = 'block';

        form.reset();

        let tentativas = 0;
        const intervalo = setInterval(async () => {
            tentativas++;

            try {
                const alertaData = await API.request(`/contas/${idOrigem}/alertas`, 'GET');
                if (alertaData && alertaData.alerta) {
                    clearInterval(intervalo);

                    const divAlerta = document.createElement('div');
                    divAlerta.className = 'alerta erro alerta-extra';
                    divAlerta.style.marginTop = '10px';
                    divAlerta.style.display = 'block';
                    divAlerta.innerText = alertaData.alerta;
                    msg.parentNode.appendChild(divAlerta);
                }
            } catch (err) {
            }

            if (tentativas >= 3) {
                clearInterval(intervalo);
            }
        }, 1000);

    } catch (err) {
        console.error("Erro na operação:", err);
        msg.className = 'alerta erro';
        msg.innerText = err.message;
        msg.style.display = 'block';
    }
});