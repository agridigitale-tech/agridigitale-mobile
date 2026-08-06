import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/design/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mdpCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _service = AuthService();
  bool _chargement = false;
  bool _mdpVisible = false;
  bool _confirmVisible = false;
  String? _erreur;

  @override
  void dispose() {
    _mdpCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reinitialiser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _service.reinitialiserMotDePasse(widget.token, _mdpCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
        title: const Text('Nouveau mot de passe'),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.lock_reset, size: 64, color: AppColors.vertPrimaire),
                const SizedBox(height: 16),
                const Text(
                  'Définir un nouveau mot de passe',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _mdpCtrl,
                  obscureText: !_mdpVisible,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_mdpVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _mdpVisible = !_mdpVisible),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_confirmVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_confirmVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
                    ),
                  ),
                  validator: (v) =>
                      v != _mdpCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                ),

                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _erreur!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                SizedBox(
                  height: 48,
                  child: _chargement
                      ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.vertPrimaire,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _reinitialiser,
                          child: const Text(
                            'Réinitialiser le mot de passe',
                            style: TextStyle(fontSize: 15),
                          ),
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
