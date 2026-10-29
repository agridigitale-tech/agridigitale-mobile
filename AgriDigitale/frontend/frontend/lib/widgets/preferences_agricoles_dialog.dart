// Dialogue / Modalité des Préférences Agricoles de l'utilisateur.
// Permet de cibler les alertes météo, prix et ravageurs par OneSignal Tags (Pilier 2).
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design/app_colors.dart';

class PreferencesAgricolesDialog extends StatefulWidget {
  const PreferencesAgricolesDialog({super.key});

  static Future<void> afficher(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PreferencesAgricolesDialog(),
    );
  }

  @override
  State<PreferencesAgricolesDialog> createState() => _PreferencesAgricolesDialogState();
}

class _PreferencesAgricolesDialogState extends State<PreferencesAgricolesDialog> {
  static const _kKeyRegion = 'pref_agri_region';
  static const _kKeyFilieres = 'pref_agri_filieres';

  static const List<String> _regions = [
    'Région Maritime (Lomé, Aného, Tsévié)',
    'Région des Plateaux (Kpalimé, Atakpamé, Notsè)',
    'Région Centrale (Sokodé, Tchamba, Sotouboua)',
    'Région de la Kara (Kara, Bassar, Bafilo)',
    'Région des Savanes (Dapaong, Mango, Cinkassé)',
  ];

  static const List<Map<String, String>> _filieres = [
    {'id': 'maraichage', 'nom': 'Maraîchage (Tomate, Piment, Oignon)', 'icone': '🍅'},
    {'id': 'cereales', 'nom': 'Céréales (Maïs, Soja, Sorgho, Riz)', 'icone': '🌽'},
    {'id': 'elevage', 'nom': 'Élevage & Aviculture (Poulets, Moutons)', 'icone': '🐔'},
    {'id': 'rente', 'nom': 'Cultures de rente (Café, Cacao, Coton)', 'icone': '☕'},
    {'id': 'tubercules', 'nom': 'Tubercules (Igname, Manioc, Patate)', 'icone': '🥔'},
  ];

  String _regionSelectionnee = _regions[0];
  final Set<String> _filieresSelectionnees = {'maraichage', 'cereales'};
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerPreferences();
  }

  Future<void> _chargerPreferences() async {
    final sp = await SharedPreferences.getInstance();
    final r = sp.getString(_kKeyRegion);
    final f = sp.getStringList(_kKeyFilieres);

    if (mounted) {
      setState(() {
        if (r != null && _regions.contains(r)) {
          _regionSelectionnee = r;
        }
        if (f != null && f.isNotEmpty) {
          _filieresSelectionnees.clear();
          _filieresSelectionnees.addAll(f);
        }
        _chargement = false;
      });
    }
  }

  Future<void> _enregistrer() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kKeyRegion, _regionSelectionnee);
    await sp.setStringList(_kKeyFilieres, _filieresSelectionnees.toList());

    // Synchronisation avec OneSignal Tags pour notifications ciblées
    try {
      final codeRegion = _regionSelectionnee.split('(').first.trim().toLowerCase().replaceAll('région ', '').replaceAll('des ', '').replaceAll('de la ', '');
      await OneSignal.User.addTags({
        'region': codeRegion,
        'filieres': _filieresSelectionnees.join(','),
      });
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préférences agricoles enregistrées ! Vos alertes seront ciblées.'),
          backgroundColor: AppColors.vertPrimaire,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSombre : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: _chargement
          ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.vertPrimaire)))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre de tirage
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Titre
                  const Row(
                    children: [
                      Text('🎯', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 8),
                      Text(
                        'Mes Préférences Agricoles',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Recevez des alertes météo et phytosanitaires ciblées sur votre localité et vos activités.',
                    style: TextStyle(fontSize: 12, color: AppColors.grisTexte),
                  ),
                  const SizedBox(height: 16),

                  // 1. Ma Région
                  const Text(
                    '1. Votre Région d\'Activité',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceSombreLegere : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grisLigne),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _regionSelectionnee,
                        isExpanded: true,
                        icon: const Icon(Icons.location_on, color: AppColors.vertPrimaire),
                        items: _regions.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _regionSelectionnee = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Mes Filières
                  const Text(
                    '2. Vos Filières & Cultures Principales',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ..._filieres.map((f) {
                    final id = f['id']!;
                    final estCoche = _filieresSelectionnees.contains(id);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.vertPrimaire,
                      value: estCoche,
                      secondary: Text(f['icone']!, style: const TextStyle(fontSize: 20)),
                      title: Text(f['nom']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      onChanged: (coche) {
                        setState(() {
                          if (coche == true) {
                            _filieresSelectionnees.add(id);
                          } else {
                            if (_filieresSelectionnees.length > 1) {
                              _filieresSelectionnees.remove(id);
                            }
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),

                  // Bouton Enregistrer
                  ElevatedButton(
                    onPressed: _enregistrer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertPrimaire,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Valider mes préférences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
    );
  }
}
