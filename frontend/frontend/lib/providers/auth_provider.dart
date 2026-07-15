//permet de gérer l'état de l'authentification de l'utilisateur et de notifier les widgets abonnés en cas de changement d'état.

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  bool connecte = false;
  bool enVerification = true;

  Future<void> verifierSession() async {
    connecte = await _service.estConnecte();
    enVerification = false;
    notifyListeners();
  }

  Future<void> connecter(String email, String mdp) async {
    await _service.connecter(email, mdp);
    connecte = true;
    notifyListeners();
  }

  Future<void> inscrire(String nom, String email, String mdp) async {
    await _service.inscrire(nom, email, mdp);
    connecte = true;
    notifyListeners();
  }

  Future<void> deconnecter() async {
    await _service.deconnecter();
    connecte = false;
    notifyListeners();
  }
}