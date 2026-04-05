class Despesa {
  final int? id;
  final int jornadaId;
  final double valor;
  final String categoria;

  Despesa({
    required this.id,
    required this.jornadaId,
    required this.valor,
    required this.categoria,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jornada_id': jornadaId,
      'valor': valor,
      'categoria': categoria,
    };
  }

  factory Despesa.fromMap(Map<String, dynamic> map) {
    return Despesa(
      id: map['id'],
      jornadaId: map['jornada_id'] ?? map['jornalId'],
      valor: (map['valor'] as num).toDouble(),
      categoria: map['categoria'],
    );
  }
}
