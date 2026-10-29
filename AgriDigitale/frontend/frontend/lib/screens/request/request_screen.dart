// Écran de demande et suggestion modernisé :
// Permet de soumettre une proposition de sujet d'article, question agronomique ou partenariat à la rédaction.
// Pré-remplit automatiquement le contexte de l'article si ouvert depuis l'écran de détail d'un article.
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../services/demande_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_gate.dart';
import '../../core/design/app_colors.dart';

class RequestScreen extends StatefulWidget {
  final String? sujetPredefini;

  const RequestScreen({super.key, this.sujetPredefini});

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

  String _typeDemande = 'Article / Sujet';
  bool _envoi = false;

  final List<String> _types = [
    'Article / Sujet',
    'Question agronomie',
    'Partenariat',
    'Autre suggestion',
  ];

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs si l'utilisateur est connecté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.connecte) {
        if (_nomCtrl.text.isEmpty && auth.nomUtilisateur != null && auth.nomUtilisateur!.isNotEmpty) {
          _nomCtrl.text = auth.nomUtilisateur!;
        }
        if (_emailCtrl.text.isEmpty && auth.emailUtilisateur != null && auth.emailUtilisateur!.isNotEmpty) {
          _emailCtrl.text = auth.emailUtilisateur!;
        }
      }
    });

    if (widget.sujetPredefini != null) {
      _messageCtrl.text = 'Concernant : ${widget.sujetPredefini}\n\n';
    }
  }

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
      final corpsMessage = '[$_typeDemande] ${_messageCtrl.text.trim()}';

      await _service.envoyer({
        'nomComplet': _nomCtrl.text.trim(),
        'profession': _professionCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
        'message': corpsMessage,
      });

      if (mounted) {
        _afficherDialogueSucces();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Erreur lors de l\'envoi. Réessayez.';
      if (e.response?.statusCode == 429) {
        msg = 'Trop de demandes. Veuillez patienter avant de réessayer.';
      } else if (e.response?.statusCode == 401) {
        msg = 'Session expirée. Veuillez vous reconnecter.';
      } else if (e.response?.statusCode == 400) {
        msg = e.response?.data['message'] ?? 'Veuillez vérifier les champs obligatoires.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.erreur,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _afficherDialogueSucces() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.vertPrimaire, size: 28),
            SizedBox(width: 10),
            Text('Demande envoyée !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Votre demande a été transmise avec succès à l\'équipe d\'AgriDigitale. Nos journalistes et agronomes l\'examineront avec attention.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vertPrimaire,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _champ(
    TextEditingController ctrl,
    String label,
    IconData icone, {
    bool obligatoire = false,
    TextInputType clavier = TextInputType.text,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validatorExtra,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                ),
              ),
              if (obligatoire)
                const Text(' *', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: clavier,
            maxLines: maxLines,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.texteFort),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey.shade400),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 12, right: 10, top: 10, bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 18, color: isDark ? AppColors.vertClair : AppColors.vertPrimaire),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              filled: true,
              fillColor: isDark ? AppColors.surfaceSombre : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.vertPrimaire,
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.erreur, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.erreur, width: 1.8),
              ),
            ),
            validator: (v) {
              if (obligatoire && (v == null || v.trim().isEmpty)) {
                return 'Ce champ est obligatoire';
              }
              if (validatorExtra != null) return validatorExtra(v);
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faire une demande', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte d'en-tête moderne avec dégradé doux
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A2B), const Color(0xFF152A1F)]
                        : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.vertPrimaire.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.vertPrimaire,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'La rédaction à votre écoute',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.texteFort,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Proposez un sujet d\'investigation, demandez un éclairage agronomique ou sollicitez une couverture.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: isDark ? Colors.white70 : AppColors.grisTexte,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contexte pré-défini si ouvert depuis un article
              if (widget.sujetPredefini != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceSombre : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.article_outlined, size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.sujetPredefini!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Type de demande
              Text(
                'Type de demande',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _types.map((type) {
                  final actif = _typeDemande == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: actif,
                    onSelected: (val) {
                      if (val) setState(() => _typeDemande = type);
                    },
                    selectedColor: AppColors.vertPrimaire,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: actif ? FontWeight.bold : FontWeight.w600,
                      color: actif ? Colors.white : (isDark ? Colors.white70 : AppColors.texteFort),
                    ),
                    backgroundColor: isDark ? AppColors.surfaceSombre : Colors.grey.shade100,
                    side: BorderSide(
                      color: actif
                          ? Colors.transparent
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Champs du formulaire
              _champ(
                _nomCtrl,
                'Nom complet',
                Icons.person_outline,
                obligatoire: true,
                hint: 'Ex: Koffi Mensah',
              ),
              _champ(
                _professionCtrl,
                'Profession / Activité',
                Icons.work_outline,
                obligatoire: true,
                hint: 'Ex: Producteur de maïs, Agronome, Commerçant...',
              ),
              _champ(
                _emailCtrl,
                'Adresse e-mail',
                Icons.mail_outline,
                obligatoire: true,
                clavier: TextInputType.emailAddress,
                hint: 'Ex: contact@exemple.tg',
                validatorExtra: (v) {
                  if (v != null && !RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(v.trim())) {
                    return 'Adresse e-mail invalide';
                  }
                  return null;
                },
              ),
              _champ(
                _telephoneCtrl,
                'Numéro de téléphone (WhatsApp)',
                Icons.phone_outlined,
                obligatoire: true,
                clavier: TextInputType.phone,
                hint: 'Ex: +228 90 00 00 00',
                validatorExtra: (v) {
                  if (v != null && !RegExp(r'^\+?[0-9\s]{8,18}$').hasMatch(v.trim())) {
                    return 'Format de numéro invalide';
                  }
                  return null;
                },
              ),
              _champ(
                _messageCtrl,
                'Votre message détaillé',
                Icons.chat_outlined,
                obligatoire: true,
                maxLines: 5,
                hint: 'Décrivez précisément votre demande, votre localisation ou vos questions...',
                validatorExtra: (v) {
                  if (v != null && v.trim().length < 10) {
                    return 'Veuillez saisir au moins 10 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Bouton d'envoi principal
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _envoi
                    ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
                    : ElevatedButton(
                        onPressed: _envoyer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vertPrimaire,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Transmettre ma demande',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Vos coordonnées restent strictement confidentielles.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
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
