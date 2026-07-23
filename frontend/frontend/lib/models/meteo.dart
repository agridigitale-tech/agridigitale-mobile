class Meteo {
  final String icone;

  Meteo({required this.icone});

  factory Meteo.fromJson(Map<String, dynamic> json) => Meteo(
        icone: json['icone'] ?? '',
      );
}
