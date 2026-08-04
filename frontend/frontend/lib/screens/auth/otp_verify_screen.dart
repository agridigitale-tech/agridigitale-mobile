import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../core/design/app_colors.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _service = AuthService();

  bool _chargement = false;
  bool _renvoi = false;
  bool _mdpVisible = false;
  bool _confirmVisible = false;
  String? _erreur;
  String? _succes;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _mdpCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _renvoyerCode() async {
    setState(() { _renvoi = true; _erreur = null; _succes = null; });
    try {
      await _service.envoyerOTP(widget.email);
      if (mounted) setState(() => _succes = 'Nouveau code envoyé !');
    } catch (_) {
      if (mounted) setState(() => _erreur = 'Impossible de renvoyer le code.');
    } finally {
      if (mounted) setState(() => _renvoi = false);
    }
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; _succes = null; });
    try {
      await _service.verifierOTPetReset(
        widget.email,
        _otpCtrl.text.trim(),
        _mdpCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
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
        title: const Text('Vérification du code'),
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
                const SizedBox(height: 16),
                const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.vertPrimaire),
                const SizedBox(height: 16),
                const Text(
                  'Code envoyé !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Un code à 6 chiffres a été envoyé à\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 28),

                // Champ OTP
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
                  decoration: const InputDecoration(
                    labelText: 'Code à 6 chiffres',
                    counterText: '',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                  validator: (v) =>
                      (v == null || v.length != 6) ? 'Entrez le code à 6 chiffres' : null,
                ),
                const SizedBox(height: 20),

                // Nouveau mot de passe
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

                // Confirmer mot de passe
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

                // Messages erreur / succès
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_erreur!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],
                if (_succes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(_succes!, style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),

                // Bouton valider
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
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Réinitialiser le mot de passe', style: TextStyle(fontSize: 15)),
                          onPressed: _valider,
                        ),
                ),
                const SizedBox(height: 16),

                // Renvoyer le code
                Center(
                  child: _renvoi
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertPrimaire),
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Renvoyer le code'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.vertPrimaire),
                          onPressed: _renvoyerCode,
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
