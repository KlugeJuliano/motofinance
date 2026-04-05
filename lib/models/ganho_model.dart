class Ganho {
  final int? id;
  final int jornadaId;
  final double valor;
  final String descricao;
  final String tipo;

  Ganho({
    required this.id,
    required this.jornadaId,
    required this.valor,
    required this.descricao,
    this.tipo = 'extra',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jornada_id': jornadaId,
      'valor': valor,
      'descricao': descricao,
      'tipo': tipo,
    };
  }

  factory Ganho.fromMap(Map<String, dynamic> map) {
    return Ganho(
      id: map['id'],
      jornadaId: map['jornada_id'] ?? map['jornadaId'],
      valor: (map['valor'] as num).toDouble(),
      descricao: map['descricao'],
      tipo: map['tipo'] ?? 'extra',
    );
  }
}
