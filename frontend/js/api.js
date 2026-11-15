export const API = {
  PORTA_BASE: 4047,

  getUrlAgencia(idAgencia) {
    return `http://localhost:${this.PORTA_BASE + Number(idAgencia)}`;
  },

  getBaseUrl() {
    return localStorage.getItem('agencia_url') || this.getUrlAgencia(0);
  },

  setBaseUrl(url) {
    localStorage.setItem('agencia_url', url);
  },

  getToken() {
    return localStorage.getItem('jwt_token');
  },

  setToken(token) {
    localStorage.setItem('jwt_token', token);
  },

  logout() {
    localStorage.removeItem('jwt_token');
    window.location.href = 'index.html';
  },

  async request(endpoint, method = 'GET', body = null) {
    const token = this.getToken();
    const urlCompleta = `${this.getBaseUrl()}${endpoint}`;

    const headers = { 'Content-Type': 'application/json' };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const config = { method, headers };
    if (body) {
      config.body = JSON.stringify(body);
    }

    const response = await fetch(urlCompleta, config);

    const rawText = await response.text();
    let data = null;
    try {
      data = JSON.parse(rawText);
    } catch {
      data = rawText ? { mensagem: rawText } : {};
    }

    if (!response.ok) {
      console.error(`[API ERRO ${response.status}]`, data || rawText);
      const detalhe = data?.erro || data?.mensagem || data?.message || rawText;
      if (detalhe && typeof detalhe === 'string' && detalhe.trim() !== '') {
        throw new Error(detalhe);
      }
      if (response.status === 401) {
        throw new Error('Acesso não autorizado. Faça login novamente nesta agência.');
      }
      throw new Error(`Erro ${response.status}: Operação inválida.`);
    }

    return data;
  }
};

function inicializarPainelBullyWeb() {
  if (document.getElementById('bully-panel-web')) return;

  const painel = document.createElement('div');
  painel.id = 'bully-panel-web';
  painel.className = 'bully-panel';
  painel.innerHTML = `
    <div class="bully-row">
      <span class="bully-title">Líder Atual (Bully):</span>
      <span id="bully-lider-texto" class="bully-lider-badge">Consultando...</span>
    </div>
    <div class="bully-row">
      <div class="bully-nodes">
        <span id="no-pill-0" class="bully-node-pill"><span class="bully-dot"></span>Ag. 0</span>
        <span id="no-pill-1" class="bully-node-pill"><span class="bully-dot"></span>Ag. 1</span>
        <span id="no-pill-2" class="bully-node-pill"><span class="bully-dot"></span>Ag. 2</span>
      </div>
      <button type="button" id="btn-forcar-eleicao" class="btn-forcar-eleicao">⚡ Forçar Eleição</button>
    </div>
  `;

  const primeiroElemento = document.body.firstElementChild;
  document.body.insertBefore(painel, primeiroElemento);

  document.getElementById('btn-forcar-eleicao').addEventListener('click', async () => {
    const btn = document.getElementById('btn-forcar-eleicao');
    btn.textContent = 'Eleição...';
    btn.disabled = true;

    let disparou = false;
    for (let id = 0; id < 3; id++) {
      try {
        const res = await fetch(`${API.getUrlAgencia(id)}/bully/forcar-eleicao`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
        });
        if (res.ok) {
          disparou = true;
          break;
        }
        const resFallback = await fetch(`${API.getUrlAgencia(id)}/bully/eleicao`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ origemId: id, vetor: [0, 0, 0] }),
        });
        if (resFallback.ok) {
          disparou = true;
          break;
        }
      } catch (_) { }
    }

    await atualizarStatusBullyWeb();
    btn.textContent = disparou ? '✓ Eleição Disparada!' : 'Sem conexão';
    setTimeout(() => {
      btn.textContent = '⚡ Forçar Eleição';
      btn.disabled = false;
    }, 1500);
  });

  atualizarStatusBullyWeb();
  setInterval(atualizarStatusBullyWeb, 2000);
}

async function atualizarStatusBullyWeb() {
  const badgeLider = document.getElementById('bully-lider-texto');
  if (!badgeLider) return;

  let liderDetectado = null;
  let algumaOnline = false;

  for (let id = 0; id < 3; id++) {
    const pill = document.getElementById(`no-pill-${id}`);
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 900);
      const res = await fetch(`${API.getUrlAgencia(id)}/bully/lider`, {
        signal: controller.signal,
      });
      clearTimeout(timeout);

      if (res.ok) {
        algumaOnline = true;
        if (pill) pill.classList.add('online');
        const data = await res.json();
        if (data.liderAtual !== null && data.liderAtual !== undefined) {
          liderDetectado = data.liderAtual;
        }
      } else if (pill) {
        pill.classList.remove('online');
      }
    } catch (_) {
      if (pill) pill.classList.remove('online');
    }
  }

  if (algumaOnline && liderDetectado !== null) {
    const porta = API.PORTA_BASE + Number(liderDetectado);
    badgeLider.textContent = `Agência ${liderDetectado} (Porta ${porta})`;
    badgeLider.classList.remove('offline');
  } else if (algumaOnline) {
    badgeLider.textContent = 'Eleição em andamento...';
    badgeLider.classList.remove('offline');
  } else {
    badgeLider.textContent = 'Offline (Sem conexão)';
    badgeLider.classList.add('offline');
  }
}

document.addEventListener('DOMContentLoaded', inicializarPainelBullyWeb);