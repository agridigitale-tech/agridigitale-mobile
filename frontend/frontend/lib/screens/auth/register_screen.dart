// RAPPEL main.dart : ajouter `await CountryCodes.init();` dans main() avant runApp()
// Exemple :
//   WidgetsFlutterBinding.ensureInitialized();
//   await CountryCodes.init();
//   runApp(...);

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_codes/country_codes.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

// Map code pays ISO → continent
const _continentParCode = <String, String>{
  'TG': 'Afrique', 'BJ': 'Afrique', 'CI': 'Afrique', 'SN': 'Afrique',
  'ML': 'Afrique', 'BF': 'Afrique', 'GH': 'Afrique', 'NG': 'Afrique',
  'CM': 'Afrique', 'CD': 'Afrique', 'CG': 'Afrique', 'GA': 'Afrique',
  'NE': 'Afrique', 'TD': 'Afrique', 'GN': 'Afrique', 'MR': 'Afrique',
  'MA': 'Afrique', 'DZ': 'Afrique', 'TN': 'Afrique', 'EG': 'Afrique',
  'ZA': 'Afrique', 'KE': 'Afrique', 'ET': 'Afrique', 'TZ': 'Afrique',
  'UG': 'Afrique', 'RW': 'Afrique', 'MG': 'Afrique', 'SL': 'Afrique',
  'LR': 'Afrique', 'GW': 'Afrique', 'GM': 'Afrique', 'CV': 'Afrique',
  'FR': 'Europe', 'BE': 'Europe', 'CH': 'Europe', 'DE': 'Europe',
  'ES': 'Europe', 'IT': 'Europe', 'GB': 'Europe', 'PT': 'Europe',
  'NL': 'Europe', 'PL': 'Europe', 'RO': 'Europe', 'SE': 'Europe',
  'US': 'Amérique du Nord', 'CA': 'Amérique du Nord', 'MX': 'Amérique du Nord',
  'BR': 'Amérique du Sud', 'AR': 'Amérique du Sud', 'CO': 'Amérique du Sud',
  'PE': 'Amérique du Sud', 'CL': 'Amérique du Sud', 'VE': 'Amérique du Sud',
  'CN': 'Asie', 'IN': 'Asie', 'JP': 'Asie', 'KR': 'Asie',
  'ID': 'Asie', 'PK': 'Asie', 'BD': 'Asie', 'VN': 'Asie',
  'AU': 'Océanie', 'NZ': 'Océanie',
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detecterPaysAutomatiquement();
    });
  }

  void _detecterPaysAutomatiquement() {
    try {
      final details = CountryCodes.detailsForLocale();
      final nomPays = details?.name ?? 'Togo';
      final code = details?.alpha2Code?.toUpperCase() ?? '';
      final continent = _continentParCode[code] ?? 'Afrique';
      setState(() {
        _paysCtrl.text = nomPays;
        _continent = continent;
      });
    } catch (_) {
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
