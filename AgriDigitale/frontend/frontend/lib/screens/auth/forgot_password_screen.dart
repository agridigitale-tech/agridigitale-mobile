//permet de réinitialiser le mot de passe en envoyant un lien par email

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
  final _service = AuthService();
  bool _chargement = false;
  bool _envoye = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyerLien() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);
    try {
      await _service.motDePasseOublie(_emailCtrl.text.trim());
      if (mounted) setState(() => _envoye = true);
    } catch (_) {
      // Toujours afficher le succès (sécurité : ne pas révéler si l'email existe)
      if (mounted) setState(() => _envoye = true);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: _envoye ? _buildSucces() : _buildFormulaire(),
        ),
      ),
    );
  }

  Widget _buildFormulaire() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.lock_reset, size: 72, color: AppColors.vertPrimaire),
          const SizedBox(height: 24),
          const Text(
            'Réinitialiser le mot de passe',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Entrez votre adresse e-mail. Vous recevrez un lien valable 15 minutes pour réinitialiser votre mot de passe.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse e-mail',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: _chargement
                ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertPrimaire,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text('Envoyer le lien', style: TextStyle(fontSize: 15)),
                    onPressed: _envoyerLien,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSucces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.vertPrimaire),
        const SizedBox(height: 24),
        const Text(
          'Email envoyé !',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Si votre adresse e-mail est enregistrée, vous recevrez un lien pour réinitialiser votre mot de passe.\n\nOuvrez le lien depuis votre téléphone pour continuer.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour à la connexion'),
        ),
      ],
    );
  }
}
