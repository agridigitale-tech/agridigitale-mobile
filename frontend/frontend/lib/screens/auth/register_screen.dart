import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

// Map nom de pays (en anglais, retourné par geocoding) → continent
const _continentParPays = <String, String>{
  // Afrique de l'Ouest
  'Togo': 'Afrique', 'Benin': 'Afrique', 'Bénin': 'Afrique',
  'Ivory Coast': 'Afrique', "Côte d'Ivoire": 'Afrique',
  'Senegal': 'Afrique', 'Sénégal': 'Afrique',
  'Mali': 'Afrique', 'Burkina Faso': 'Afrique',
  'Ghana': 'Afrique', 'Nigeria': 'Afrique', 'Niger': 'Afrique',
  'Guinea': 'Afrique', 'Guinée': 'Afrique',
  'Sierra Leone': 'Afrique', 'Liberia': 'Afrique',
  'Gambia': 'Afrique', 'Gambie': 'Afrique',
  'Guinea-Bissau': 'Afrique', 'Cape Verde': 'Afrique',
  'Mauritania': 'Afrique', 'Mauritanie': 'Afrique',
  // Afrique Centrale
  'Cameroon': 'Afrique', 'Cameroun': 'Afrique',
  'Democratic Republic of the Congo': 'Afrique', 'Congo': 'Afrique',
  'Gabon': 'Afrique', 'Chad': 'Afrique', 'Tchad': 'Afrique',
  'Central African Republic': 'Afrique',
  // Afrique du Nord
  'Morocco': 'Afrique', 'Maroc': 'Afrique',
  'Algeria': 'Afrique', 'Algérie': 'Afrique',
  'Tunisia': 'Afrique', 'Tunisie': 'Afrique',
  'Egypt': 'Afrique', 'Égypte': 'Afrique', 'Libya': 'Afrique',
  // Afrique de l'Est & Sud
  'South Africa': 'Afrique', 'Kenya': 'Afrique',
  'Ethiopia': 'Afrique', 'Éthiopie': 'Afrique',
  'Tanzania': 'Afrique', 'Tanzanie': 'Afrique',
  'Uganda': 'Afrique', 'Ouganda': 'Afrique',
  'Rwanda': 'Afrique', 'Madagascar': 'Afrique',
  'Mozambique': 'Afrique', 'Zimbabwe': 'Afrique',
  'Zambia': 'Afrique', 'Angola': 'Afrique',
  // Europe
  'France': 'Europe', 'Belgium': 'Europe', 'Belgique': 'Europe',
  'Switzerland': 'Europe', 'Suisse': 'Europe',
  'Germany': 'Europe', 'Allemagne': 'Europe',
  'Spain': 'Europe', 'Espagne': 'Europe',
  'Italy': 'Europe', 'Italie': 'Europe',
  'United Kingdom': 'Europe', 'Portugal': 'Europe',
  'Netherlands': 'Europe', 'Pays-Bas': 'Europe',
  'Poland': 'Europe', 'Pologne': 'Europe',
  'Romania': 'Europe', 'Roumanie': 'Europe',
  'Sweden': 'Europe', 'Suède': 'Europe',
  // Amérique du Nord
  'United States': 'Amérique du Nord', 'Canada': 'Amérique du Nord',
  'Mexico': 'Amérique du Nord', 'Mexique': 'Amérique du Nord',
  // Amérique du Sud
  'Brazil': 'Amérique du Sud', 'Brésil': 'Amérique du Sud',
  'Argentina': 'Amérique du Sud', 'Argentine': 'Amérique du Sud',
  'Colombia': 'Amérique du Sud', 'Colombie': 'Amérique du Sud',
  'Peru': 'Amérique du Sud', 'Pérou': 'Amérique du Sud',
  'Chile': 'Amérique du Sud', 'Chili': 'Amérique du Sud',
  'Venezuela': 'Amérique du Sud',
  // Asie
  'China': 'Asie', 'Chine': 'Asie',
  'India': 'Asie', 'Inde': 'Asie',
  'Japan': 'Asie', 'Japon': 'Asie',
  'South Korea': 'Asie', 'Corée du Sud': 'Asie',
  'Indonesia': 'Asie', 'Indonésie': 'Asie',
  'Pakistan': 'Asie', 'Bangladesh': 'Asie', 'Vietnam': 'Asie',
  // Océanie
  'Australia': 'Océanie', 'Australie': 'Océanie',
  'New Zealand': 'Océanie', 'Nouvelle-Zélande': 'Océanie',
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
  bool _gpsEnCours = false;
  String? _erreur;
  bool _mdpVisible = false;

  @override
  void initState() {
    super.initState();
    _recupererPaysParGPS();
  }

  Future<void> _recupererPaysParGPS() async {
    setState(() => _gpsEnCours = true);
    try {
      // 1. Vérifier si le service GPS est activé
      final serviceActif = await Geolocator.isLocationServiceEnabled();
      if (!serviceActif) {
        _appliquerFallback();
        return;
      }

      // 2. Vérifier / demander la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _appliquerFallback();
        return;
      }

      // 3. Récupérer la position GPS
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 4. Reverse geocoding → nom du pays
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final pays = placemarks.first.country ?? 'Togo';
        final continent = _continentParPays[pays] ?? 'Afrique';
        if (mounted) {
          setState(() {
            _paysCtrl.text = pays;
            _continent = continent;
          });
        }
      } else {
        _appliquerFallback();
      }
    } catch (_) {
      _appliquerFallback();
    } finally {
      if (mounted) setState(() => _gpsEnCours = false);
    }
  }

  void _appliquerFallback() {
    if (mounted) {
      setState(() {
        if (_paysCtrl.text.isEmpty) _paysCtrl.text = 'Togo';
        _continent ??= 'Afrique';
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
                decoration: InputDecoration(
                  labelText: 'Pays',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  helperText: 'Détecté via GPS — modifiable',
                  suffixIcon: _gpsEnCours
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location, size: 20),
                          tooltip: 'Relancer la détection GPS',
                          onPressed: _recupererPaysParGPS,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Continent',
                  prefixIcon: Icon(Icons.public_outlined),
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  helperText: 'Déduit automatiquement — modifiable',
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
