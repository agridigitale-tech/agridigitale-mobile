//permet de représenter les données météorologiques pour une zone donnée

class Meteo {
  final String zone, description, icone;
  final double temperature;
  final int humidite;

  Meteo({required this.zone, required this.description, required this.icone,
         required this.temperature, required this.humidite});

  factory Meteo.fromJson(Map<String, dynamic> json) => Meteo(
    zone: json['zone'], description: json['description'], icone: json['icone'],
    temperature: (json['temperature'] as num).toDouble(),
    humidite: json['humidite'] ?? 0,
  );
}