class Jornada {
  final int? id;
  final DateTime inicio;
  final DateTime? fim;
  final double kmInicial;
  final double? kmFinal;
  final km_rodados;

  Jornada({
    this.id,
    required this.inicio,
    required this.fim,
    required this.kmInicial,
    this.kmFinal,
    this.km_rodados,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inicio': inicio.toIso8601String(),
      'fim': fim?.toIso8601String(),
      'km_inicial': kmInicial,
      'km_final': kmFinal,
    };
  }

  factory Jornada.fromMap(Map<String, dynamic> map) {
    return Jornada(
      id: map['id'] as int?,
      inicio: DateTime.parse(map['inicio'] as String),
      fim: map['fim'] != null ? DateTime.parse(map['fim'] as String) : null,
      kmInicial: (map['km_inicial'] as num).toDouble(),
      kmFinal:
          map['km_final'] != null ? (map['km_final'] as num).toDouble() : null,
      km_rodados: map['km_rodados'] != null
          ? (map['km_rodados'] as num).toDouble()
          : null,
    );
  }
}
