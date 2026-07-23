import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/demande_service.dart';
import '../../widgets/auth_gate.dart';
import '../../core/design/app_colors.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});
  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = DemandeService();
  final _nomCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _professionCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;

    final connecte = await exigerConnexion(context, motif: 'envoyer votre demande');
    if (!connecte) return;

    setState(() => _envoi = true);
    try {
      await _service.envoyer({
        'nomComplet': _nomCtrl.text.trim(),
        'profession': _professionCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _nomCtrl.clear();
        _professionCtrl.clear();
        _emailCtrl.clear();
        _telephoneCtrl.clear();
        _messageCtrl.clear();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Erreur lors de l\'envoi. Réessayez.';
      if (e.response?.statusCode == 429) msg = 'Trop de demandes. Attendez 1h avant de réessayer.';
      if (e.response?.statusCode == 401) msg = 'Veuillez vous reconnecter.';
      if (e.response?.statusCode == 400) {
        msg = e.response?.data['message'] ?? 'Vérifiez les champs obligatoires.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Widget _champ(TextEditingController ctrl, String label, IconData icone,
      {bool obligatoire = false,
      TextInputType clavier = TextInputType.text,
      int maxLines = 1,
      String? Function(String?)? validatorExtra}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: clavier,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: obligatoire ? '$label *' : label,
          prefixIcon: Icon(icone),
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (obligatoire && (v == null || v.trim().isEmpty)) return 'Champ obligatoire';
          if (validatorExtra != null) return validatorExtra(v);
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faire une demande'),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Remplissez ce formulaire pour nous faire part de votre suggestion, réclamation ou demande de partenariat.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              _champ(_nomCtrl, 'Nom complet', Icons.person, obligatoire: true),
              _champ(_professionCtrl, 'Profession', Icons.work, obligatoire: true),
              _champ(_emailCtrl, 'E-mail', Icons.email,
                  obligatoire: true,
                  clavier: TextInputType.emailAddress,
                  validatorExtra: (v) {
                    if (v != null && !RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(v.trim())) {
                      return 'Adresse e-mail invalide';
                    }
                    return null;
                  }),
              _champ(_telephoneCtrl, 'Téléphone', Icons.phone,
                  obligatoire: true,
                  clavier: TextInputType.phone,
                  validatorExtra: (v) {
                    if (v != null && !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(v.trim())) {
                      return 'Format invalide. Ex: +22890000000';
                    }
                    return null;
                  }),
              _champ(_messageCtrl, 'Message', Icons.message,
                  obligatoire: true, maxLines: 4),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _envoi
                    ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
                    : ElevatedButton(
                        onPressed: _envoyer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vertPrimaire,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Envoyer la demande',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text('Les champs avec * sont obligatoires',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
