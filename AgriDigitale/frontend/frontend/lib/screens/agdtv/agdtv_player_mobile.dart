import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

dynamic creerController(String idYoutube) {
  return YoutubePlayerController(
    initialVideoId: idYoutube,
    flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
  );
}

void chargerVideo(dynamic controller, String idYoutube) {
  (controller as YoutubePlayerController).load(idYoutube);
}

Widget buildPlayer(dynamic controller) {
  if (controller == null) return const SizedBox.shrink();
  return YoutubePlayerBuilder(
    player: YoutubePlayer(
      controller: controller as YoutubePlayerController,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.green,
    ),
    builder: (context, player) => player,
  );
}
