class ContaModel {
  final int id;
  final int agencia;
  final String titular;
  double saldo;
  List<int> vetorAtual;
  bool provisorio;

  ContaModel({
    required this.id,
    required this.agencia,
    required this.titular,
    required this.saldo,
    required this.vetorAtual,
    this.provisorio = false,
  });

  factory ContaModel.fromJson(Map<String, dynamic> json, int agenciaPadrao) {
    return ContaModel(
      id: json['id'] ?? json['numero'] ?? 0,
      agencia: json['agencia'] ?? agenciaPadrao,
      titular: json['nomeAluno'] ?? json['titular'] ?? 'Nome não informado',
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      vetorAtual: json['vetorAtual'] != null
          ? List<int>.from(json['vetorAtual'])
          : [0, 0, 0],
      provisorio: json['provisorio'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'agencia': agencia,
        'nomeAluno': titular,
        'titular': titular,
        'saldo': saldo,
        'vetorAtual': vetorAtual,
        'provisorio': provisorio,
      };
}

class OperacaoPendente {
  final int? dbId;
  final int agenciaId;
  final int contaId;
  final String tipo;
  final double valor;
  final List<int> vetorConhecido;
  final String criadoEm;

  OperacaoPendente({
    this.dbId,
    required this.agenciaId,
    required this.contaId,
    required this.tipo,
    required this.valor,
    required this.vetorConhecido,
    required this.criadoEm,
  });

  factory OperacaoPendente.fromJson(Map<String, dynamic> json) {
    return OperacaoPendente(
      dbId: json['dbId'],
      agenciaId: json['agenciaId'],
      contaId: json['contaId'],
      tipo: json['tipo'],
      valor: (json['valor'] as num).toDouble(),
      vetorConhecido: List<int>.from(json['vetorConhecido']),
      criadoEm: json['criadoEm'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (dbId != null) 'dbId': dbId,
        'agenciaId': agenciaId,
        'contaId': contaId,
        'tipo': tipo,
        'valor': valor,
        'vetorConhecido': vetorConhecido,
        'criadoEm': criadoEm,
      };
}
