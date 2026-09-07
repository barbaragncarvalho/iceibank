export const API = {
  getBaseUrl() {
    return localStorage.getItem('agencia_url') || 'http://localhost:4047';
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