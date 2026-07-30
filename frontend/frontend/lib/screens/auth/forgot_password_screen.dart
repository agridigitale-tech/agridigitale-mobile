import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/design/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _service = AuthService();

  bool _chargement = false;
  bool _etapeReset = false; // false = saisie email, true = saisie token + nouveau mdp
  String? _erreur;
  bool _mdpVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyerDemande() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _service.motDePasseOublie(_emailCtrl.text.trim());
      setState(() { _etapeReset = true; });
    } catch (e) {
      setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _reinitialiser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _service.reinitialiserMotDePasse(
        _tokenCtrl.text.trim(),
        _mdpCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_reset, size: 64, color: AppColors.vertPrimaire),
                const SizedBox(height: 24),
                if (!_etapeReset) ...[
                  const Text(
                    'Entrez votre e-mail pour recevoir un lien de réinitialisation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.grisTexte),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                  ),
                ] else ...[
                  const Text(
                    'Entrez le token reçu et votre nouveau mot de passe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.grisTexte),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _tokenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Token de réinitialisation',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Token obligatoire' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mdpCtrl,
                    obscureText: !_mdpVisible,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_mdpVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _mdpVisible = !_mdpVisible),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                  ),
                ],
                if (_erreur != null) ...[
                  const SizedBox(height: 10),
                  Text(_erreur!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                _chargement
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.vertPrimaire))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vertPrimaire,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed:
                            _etapeReset ? _reinitialiser : _envoyerDemande,
                        child: Text(
                          _etapeReset
                              ? 'Réinitialiser le mot de passe'
                              : 'Envoyer la demande',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                if (_etapeReset) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        setState(() { _etapeReset = false; _erreur = null; }),
                    child: const Text('Retour'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
