//permet d'afficher les informations météorologiques et les archives des bulletins météo

import 'package:flutter/material.dart';
import '../../services/meteo_service.dart';
import '../../models/meteo.dart';
import '../../core/design/app_colors.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _service = MeteoService();
  late Future<Meteo> _future;
  bool _archivesOuvertes = false;

  @override
  void initState() { super.initState(); _future = _service.consulter(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather', style: Theme.of(context).textTheme.displaySmall)),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _service.consulter()),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FutureBuilder<Meteo>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire)));
                }
                final m = snapshot.data!;
                return Text(m.description, style: Theme.of(context).textTheme.bodyLarge);
              },
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: () => setState(() => _archivesOuvertes = !_archivesOuvertes),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFF9E9E9E), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.archive_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Archives', style: TextStyle(color: Colors.white, fontSize: 16))),
                  Icon(_archivesOuvertes ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                ]),
              ),
            ),
            if (_archivesOuvertes)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Les bulletins précédents apparaîtront ici.',
                  style: TextStyle(color: AppColors.grisTexte)),
              ),
          ],
        ),
      ),
    );
  }
}