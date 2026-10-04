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
    const alertasAntigos = document.querySelectorAll('.alerta-extra');
    alertasAntigos.forEach(el => el.remove());

    const id = parseInt(document.getElementById('conta-id').value, 10);
    const tipo = document.getElementById('tipo-operacao').value;
    const valor = parseFloat(document.getElementById('valor').value);

    try {
        const data = await API.request(`/contas/${id}/${tipo}`, 'POST', { valor });

        msg.className = 'alerta sucesso';
        msg.innerText = `${tipo.toUpperCase()} realizado! Novo saldo: R$ ${data.saldoInicial.toFixed(2)}`;
        msg.style.display = 'block';

        form.reset();

        if (tipo === 'sacar') {
            let tentativas = 0;
            const intervalo = setInterval(async () => {
                tentativas++;
                try {
                    const alertaData = await API.request(`/contas/${id}/alertas`, 'GET');
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
                    console.log("Aguardando mensagem assíncrona...");
                }

                if (tentativas >= 3) clearInterval(intervalo);
            }, 1000);
        }
    } catch (err) {
        msg.className = 'alerta erro';
        msg.innerText = err.message;
        msg.style.display = 'block';
    }
});