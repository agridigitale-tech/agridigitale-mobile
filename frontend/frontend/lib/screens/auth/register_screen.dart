//permet de gérer l'inscription d'un nouvel utilisateur avec un formulaire et la validation des champs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _service = AuthService();
  bool _chargement = false;
  String? _erreur;

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _service.inscrire(_nomCtrl.text.trim(), _emailCtrl.text.trim(), _mdpCtrl.text);
      await context.read<AuthProvider>().verifierSession();
      if (mounted) Navigator.pop(context);
     } catch (e) {
       setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
     } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null),
              TextFormField(controller: _mdpCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe'),
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null),
              if (_erreur != null) Text(_erreur!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              _chargement
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _sInscrire, child: const Text("S'inscrire")),
            ],
          ),
        ),
      ),
    );
  }
}