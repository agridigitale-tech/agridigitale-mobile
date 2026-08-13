// Provider auth : gère l'état de connexion de l'utilisateur (connecte/déconnecté/admin).
// Appelé au démarrage via verifierSession() pour restaurer la session depuis SharedPreferences.
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  bool connecte = false;
  bool enVerification = true;
  String? nomUtilisateur;
  String? emailUtilisateur;
  String? role;

  bool get estAdmin => role == 'administrateur';

  // Charge le profil depuis SharedPreferences et notifie les widgets
  Future<void> verifierSession() async {
    connecte = await _service.estConnecte();
    if (connecte) {
      final profil = await _service.lireProfil();
      nomUtilisateur = profil['nom'];
      emailUtilisateur = profil['email'];
      role = profil['role'];
    }
    enVerification = false;
    notifyListeners();
  }

  Future<void> connecter(String email, String mdp) async {
    final data = await _service.connecter(email, mdp);
    connecte = true;
    nomUtilisateur = data['utilisateur']?['nom'] ?? data['nom'];
    emailUtilisateur = data['utilisateur']?['email'] ?? data['email'];
    role = data['utilisateur']?['role'] ?? data['role'];
    notifyListeners();
  }

  Future<void> inscrire(String nom, String email, String mdp) async {
    final data = await _service.inscrire(nom, email, mdp);
    connecte = true;
    nomUtilisateur = data['utilisateur']?['nom'] ?? data['nom'] ?? nom;
    emailUtilisateur = data['utilisateur']?['email'] ?? data['email'] ?? email;
    role = data['utilisateur']?['role'] ?? data['role'] ?? 'utilisateur';
    notifyListeners();
  }

  Future<void> deconnecter() async {
    await _service.deconnecter();
    connecte = false;
    nomUtilisateur = null;
    emailUtilisateur = null;
    role = null;
    notifyListeners();
  }
}
