import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

// Map code ISO pays → (nom français, continent)
const _paysParCode = <String, (String, String)>{
  'TG': ('Togo', 'Afrique'),
  'BJ': ('Bénin', 'Afrique'),
  'CI': ("Côte d'Ivoire", 'Afrique'),
  'SN': ('Sénégal', 'Afrique'),
  'ML': ('Mali', 'Afrique'),
  'BF': ('Burkina Faso', 'Afrique'),
  'GH': ('Ghana', 'Afrique'),
  'NG': ('Nigeria', 'Afrique'),
  'NE': ('Niger', 'Afrique'),
  'CM': ('Cameroun', 'Afrique'),
  'CD': ('Congo (RDC)', 'Afrique'),
  'CG': ('Congo', 'Afrique'),
  'GA': ('Gabon', 'Afrique'),
  'TD': ('Tchad', 'Afrique'),
  'GN': ('Guinée', 'Afrique'),
  'SL': ('Sierra Leone', 'Afrique'),
  'LR': ('Liberia', 'Afrique'),
  'GM': ('Gambie', 'Afrique'),
  'GW': ('Guinée-Bissau', 'Afrique'),
  'CV': ('Cap-Vert', 'Afrique'),
  'MR': ('Mauritanie', 'Afrique'),
  'MA': ('Maroc', 'Afrique'),
  'DZ': ('Algérie', 'Afrique'),
  'TN': ('Tunisie', 'Afrique'),
  'EG': ('Égypte', 'Afrique'),
  'LY': ('Libye', 'Afrique'),
  'ZA': ('Afrique du Sud', 'Afrique'),
  'KE': ('Kenya', 'Afrique'),
  'ET': ('Éthiopie', 'Afrique'),
  'TZ': ('Tanzanie', 'Afrique'),
  'UG': ('Ouganda', 'Afrique'),
  'RW': ('Rwanda', 'Afrique'),
  'MG': ('Madagascar', 'Afrique'),
  'MZ': ('Mozambique', 'Afrique'),
  'ZW': ('Zimbabwe', 'Afrique'),
  'ZM': ('Zambie', 'Afrique'),
  'AO': ('Angola', 'Afrique'),
  'FR': ('France', 'Europe'),
  'BE': ('Belgique', 'Europe'),
  'CH': ('Suisse', 'Europe'),
  'DE': ('Allemagne', 'Europe'),
  'ES': ('Espagne', 'Europe'),
  'IT': ('Italie', 'Europe'),
  'GB': ('Royaume-Uni', 'Europe'),
  'PT': ('Portugal', 'Europe'),
  'NL': ('Pays-Bas', 'Europe'),
  'PL': ('Pologne', 'Europe'),
  'RO': ('Roumanie', 'Europe'),
  'SE': ('Suède', 'Europe'),
  'US': ('États-Unis', 'Amérique du Nord'),
  'CA': ('Canada', 'Amérique du Nord'),
  'MX': ('Mexique', 'Amérique du Nord'),
  'BR': ('Brésil', 'Amérique du Sud'),
  'AR': ('Argentine', 'Amérique du Sud'),
  'CO': ('Colombie', 'Amérique du Sud'),
  'PE': ('Pérou', 'Amérique du Sud'),
  'CL': ('Chili', 'Amérique du Sud'),
  'VE': ('Venezuela', 'Amérique du Sud'),
  'CN': ('Chine', 'Asie'),
  'IN': ('Inde', 'Asie'),
  'JP': ('Japon', 'Asie'),
  'KR': ('Corée du Sud', 'Asie'),
  'ID': ('Indonésie', 'Asie'),
  'PK': ('Pakistan', 'Asie'),
  'BD': ('Bangladesh', 'Asie'),
  'VN': ('Vietnam', 'Asie'),
  'AU': ('Australie', 'Océanie'),
  'NZ': ('Nouvelle-Zélande', 'Océanie'),
};

const _continents = [
  'Afrique',
  'Amérique du Nord',
  'Amérique du Sud',
  'Asie',
  'Europe',
  'Océanie',
];

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
  final _paysCtrl = TextEditingController();
  final _service = AuthService();
  String? _continent;
  bool _chargement = false;
  String? _erreur;
  bool _mdpVisible = false;

  @override
  void initState() {
    super.initState();
    // Détection via locale système — fiable, sans permission, sans internet
    WidgetsBinding.instance.addPostFrameCallback((_) => _detecterLocale());
  }

  void _detecterLocale() {
    // Récupère le code pays depuis la locale du système (ex: fr_TG → TG)
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final code = locale.countryCode?.toUpperCase() ?? '';
    final data = _paysParCode[code];
    if (data != null && mounted) {
      setState(() {
        _paysCtrl.text = data.$1;
        _continent = data.$2;
      });
    } else if (mounted) {
      // Fallback : Togo par défaut (cible principale de l'app)
      setState(() {
        _paysCtrl.text = 'Togo';
        _continent = 'Afrique';
      });
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    _paysCtrl.dispose();
    super.dispose();
  }

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _chargement = true; _erreur = null; });
    try {
      await _service.inscrire(
        _nomCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _mdpCtrl.text,
        pays: _paysCtrl.text.trim(),
        continent: _continent ?? 'Afrique',
      );
      if (!mounted) return;
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
    final couleurPrimaire = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _mdpCtrl,
                obscureText: !_mdpVisible,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mdpVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _mdpVisible = !_mdpVisible),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Minimum 6 caractères'
                    : null,
              ),
              const SizedBox(height: 16),

              // Champ pays — pré-rempli par la locale
              TextFormField(
                controller: _paysCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pays',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Détecté automatiquement — modifiable',
                ),
              ),
              const SizedBox(height: 16),

              // Dropdown continent — pré-sélectionné par la locale
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Continent',
                  prefixIcon: Icon(Icons.public_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Déduit automatiquement — modifiable',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButton<String>(
                  value: _continent,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: const Text('Sélectionner'),
                  items: _continents
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _continent = v),
                ),
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
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: _chargement
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: couleurPrimaire,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _sInscrire,
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(fontSize: 16),
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
