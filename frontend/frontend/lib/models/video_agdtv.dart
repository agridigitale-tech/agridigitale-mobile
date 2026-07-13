//permet de représenter une vidéo AGDTV

class VideoAGDTV {
  final String idYoutube, titre, vignette;
  VideoAGDTV({required this.idYoutube, required this.titre, required this.vignette});

  factory VideoAGDTV.fromJson(Map<String, dynamic> json) => VideoAGDTV(
    idYoutube: json['idYoutube'], titre: json['titre'], vignette: json['vignette'],
  );

  String get urlYoutube => 'https://www.youtube.com/watch?v=$idYoutube';
}