import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

// Map code pays ISO → (nom pays, continent)
const _paysData = <String, (String, String)>{
  'TG': ('Togo', 'Afrique'),
  'BJ': ('Bénin', 'Afrique'),
  'CI': ("Côte d'Ivoire", 'Afrique'),
  'SN': ('Sénégal', 'Afrique'),
  'ML': ('Mali', 'Afrique'),
  'BF': ('Burkina Faso', 'Afrique'),
  'GH': ('Ghana', 'Afrique'),
  'NG': ('Nigeria', 'Afrique'),
  'CM': ('Cameroun', 'Afrique'),
  'CD': ('Congo (RDC)', 'Afrique'),
  'CG': ('Congo', 'Afrique'),
  'GA': ('Gabon', 'Afrique'),
  'NE': ('Niger', 'Afrique'),
  'TD': ('Tchad', 'Afrique'),
  'GN': ('Guinée', 'Afrique'),
  'MR': ('Mauritanie', 'Afrique'),
  'MA': ('Maroc', 'Afrique'),
  'DZ': ('Algérie', 'Afrique'),
  'TN': ('Tunisie', 'Afrique'),
  'EG': ('Égypte', 'Afrique'),
  'ZA': ('Afrique du Sud', 'Afrique'),
  'KE': ('Kenya', 'Afrique'),
  'ET': ('Éthiopie', 'Afrique'),
  'TZ': ('Tanzanie', 'Afrique'),
  'UG': ('Ouganda', 'Afrique'),
  'RW': ('Rwanda', 'Afrique'),
  'MG': ('Madagascar', 'Afrique'),
  'FR': ('France', 'Europe'),
  'BE': ('Belgique', 'Europe'),
  'CH': ('Suisse', 'Europe'),
  'DE': ('Allemagne', 'Europe'),
  'ES': ('Espagne', 'Europe'),
  'IT': ('Italie', 'Europe'),
  'GB': ('Royaume-Uni', 'Europe'),
  'PT': ('Portugal', 'Europe'),
  'NL': ('Pays-Bas', 'Europe'),
  'US': ('États-Unis', 'Amérique du Nord'),
  'CA': ('Canada', 'Amérique du Nord'),
  'MX': ('Mexique', 'Amérique du Nord'),
  'BR': ('Brésil', 'Amérique du Sud'),
  'AR': ('Argentine', 'Amérique du Sud'),
  'CO': ('Colombie', 'Amérique du Sud'),
  'CN': ('Chine', 'Asie'),
  'IN': ('Inde', 'Asie'),
  'JP': ('Japon', 'Asie'),
  'AU': ('Australie', 'Océanie'),
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
  bool _geoDetecte = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_geoDetecte) {
      _geoDetecte = true;
      _detecterLocale();
    }
  }

  void _detecterLocale() {
    final locale = Localizations.localeOf(context);
    final code = locale.countryCode?.toUpperCase() ?? '';
    final data = _paysData[code];
    if (data != null) {
      setState(() {
        _paysCtrl.text = data.$1;
        _continent = data.$2;
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
        continent: _continent ?? '',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mdpCtrl,
                obscureText: !_mdpVisible,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mdpVisible ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    onPressed: () => setState(() => _mdpVisible = !_mdpVisible),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paysCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pays',
                  prefixIcon: Icon(Icons.flag_outlined),
                  helperText: 'Détecté automatiquement — modifiable',
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Continent',
                  prefixIcon: Icon(Icons.public_outlined),
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  helperText: 'Détecté automatiquement — modifiable',
                ),
                child: DropdownButton<String>(
                  value: _continent,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: const Text('Sélectionner'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('— Aucun —')),
                    ..._continents.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => _continent = v),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _chargement
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _sInscrire,
                        child: const Text("S'inscrire"),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
