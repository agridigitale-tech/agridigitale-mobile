/// Écran de demande - gestion des demandes utilisateur
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/demande_service.dart';
import '../../widgets/auth_gate.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});
  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = DemandeService();
  final _nom = TextEditingController(), 
        _profession = TextEditingController(),
        _adresse = TextEditingController(), 
        _email = TextEditingController(),
        _telephone = TextEditingController(), 
        _message = TextEditingController();
  String? _categorie;
  bool _envoi = false;

  final _categories = ['Suggestion', 'Réclamation', 'Partenariat', 'Autre'];

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier si l'utilisateur est connecté avant d'envoyer
    final connecte = await exigerConnexion(context, motif: "envoyer votre demande");
    if (!connecte) return;

    setState(() => _envoi = true);
    try {
      await _service.envoyer({
        'nom': _nom.text, 
        'profession': _profession.text, 
        'adresse': _adresse.text,
        'email': _email.text, 
        'telephone': _telephone.text,
        'categorie': _categorie, 
        'message': _message.text,
      });
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text(' Message envoyé avec succès'),
             backgroundColor: Colors.green,
             duration: Duration(seconds: 3),
           )
         );
        _formKey.currentState!.reset();
        _categorie = null;
        // Réinitialiser les champs
        _nom.clear();
        _profession.clear();
        _adresse.clear();
        _email.clear();
        _telephone.clear();
        _message.clear();
        setState(() {});
      }
    } on DioException catch (e) {
      if (mounted) {
        String messageErreur = ' Erreur lors de l\'envoi. Réessayez.';
        if (e.response?.statusCode == 429) {
          messageErreur = ' Trop de demandes envoyées. Attendez 1 minute avant de réessayer.';
        } else if (e.response?.statusCode == 401) {
          messageErreur = ' Veuillez vous reconnecter pour envoyer une demande.';
        } else if (e.response?.statusCode == 400) {
          messageErreur = ' Vérifiez que tous les champs sont correctement remplis.';
        } else if (e.response?.statusCode == 500) {
          messageErreur = ' Erreur serveur. Veuillez réessayer plus tard.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messageErreur),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(" Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          )
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faire une demande'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message d'information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Remplissez ce formulaire pour nous faire part de votre suggestion, réclamation ou demande de partenariat.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Champs du formulaire
              TextFormField(
                controller: _nom, 
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _profession, 
                decoration: const InputDecoration(
                  labelText: 'Profession',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _adresse, 
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _email, 
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _telephone, 
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c, 
                  child: Text(c)
                )).toList(),
                onChanged: (v) => setState(() => _categorie = v),
                validator: (v) => v == null ? 'Choisissez une catégorie' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _message, 
                maxLines: 4, 
                decoration: const InputDecoration(
                  labelText: 'Message *',
                  prefixIcon: Icon(Icons.message, size: 24),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 20),
              
              // Bouton d'envoi
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _envoi
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _envoyer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Envoyer la demande',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              
              // Petit texte informatif
              const Center(
                child: Text(
                  'Les champs avec * sont obligatoires',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}