//permet de vérifier si l'utilisateur est connecté, et sinon, lui demander de se connecter ou de s'inscrire.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/design/app_colors.dart';

/// Retourne true si l'utilisateur est (ou vient de se rendre) connecté.
/// Si non connecté, ouvre une feuille de connexion/inscription contextuelle.
/// À appeler avant toute action protégée : favori, envoi de demande.
Future<bool> exigerConnexion(BuildContext context, {String motif = "continuer"}) async {
  final auth = context.read<AuthProvider>();
  if (auth.connecte) return true;

  final resultat = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeuilleConnexion(motif: motif),
  );
  return resultat ?? false;
}

class _FeuilleConnexion extends StatefulWidget {
  final String motif;
  const _FeuilleConnexion({required this.motif});

  @override
  State<_FeuilleConnexion> createState() => _FeuilleConnexionState();
}

class _FeuilleConnexionState extends State<_FeuilleConnexion> {
  bool _modeInscription = false;
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      final auth = context.read<AuthProvider>();
      if (_modeInscription) {
        await auth.inscrire(_nom.text.trim(), _email.text.trim(), _mdp.text);
      } else {
        await auth.connecter(_email.text.trim(), _mdp.text);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _erreur = _modeInscription
          ? "Cet e-mail est peut-être déjà utilisé"
          : "E-mail ou mot de passe incorrect");
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Connecte-toi pour ${widget.motif}',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Ça prend 30 secondes, et tu peux continuer ta lecture juste après.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 20),
                if (_modeInscription)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _nom,
                      decoration: const InputDecoration(labelText: 'Nom complet'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    ),
                  ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _mdp,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 8),
                  Text(_erreur!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _chargement ? null : _valider,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertPrimaire,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _chargement
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_modeInscription ? "S'inscrire" : "Se connecter",
                            style: const TextStyle(color: Colors.white)),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _modeInscription = !_modeInscription),
                    child: Text(_modeInscription
                        ? 'J\'ai déjà un compte — me connecter'
                        : 'Pas de compte — s\'inscrire'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
