// Navigation principale de l'app : 6 onglets (Home, Météo, AGDTV, Favoris, Demande, Paramètres).
// Utilise IndexedStack pour garder l'état de chaque écran en mémoire.
// Affiche un bouton "Panneau administrateur" en haut de la barre si l'utilisateur est admin.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'weather/weather_screen.dart';
import 'agdtv/agdtv_screen.dart';
import 'favoris/favoris_screen.dart';
import 'request/request_screen.dart';
import 'settings/settings_screen.dart';
import 'admin/admin_screen.dart';
import '../widgets/banner_carousel.dart';
import '../providers/auth_provider.dart';
import '../core/design/app_colors.dart';
import '../core/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;
  // Ne charge un onglet que lorsqu'il est visité pour la première fois (évite 7 requêtes simultanées au démarrage)
  final Set<int> _ongletsVisites = {0};

  // Permet à HomeScreen de naviguer vers l'onglet favoris (index 3) depuis l'AppBar
  void changerOnglet(int index) {
    setState(() {
      _index = index;
      _ongletsVisites.add(index);
    });
  }

  final _icones = [
    Icons.home,
    Icons.cloud,
    Icons.tv,
    Icons.bookmark_border,
    Icons.chat_bubble_outline,
    Icons.settings,
  ];

  final _ecrans = const [
    HomeScreen(),
    WeatherScreen(),
    AgdtvScreen(),
    FavorisScreen(),
    RequestScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final labels = [
      l.t('home'),
      l.t('weather'),
      l.t('agdtv'),
      l.t('favorites'),
      l.t('request'),
      l.t('settings'),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vertActif = isDark ? AppColors.vertClair : AppColors.vertPrimaire;
    final inactifColor = isDark ? AppColors.texteSombreMoyen : Colors.black54;
    final navBg = isDark ? AppColors.surfaceSombre : Colors.white;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(
          _ecrans.length,
          (i) => _ongletsVisites.contains(i) ? _ecrans[i] : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.bordureSombre : const Color(0xFFEAEAEA),
                width: 0.8,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (auth.estAdmin)
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    );
                    BannerCarousel.actualiser();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.vertPrimaire,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Panneau administrateur',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                height: 62,
                child: Row(
                  children: List.generate(_icones.length, (i) {
                    final actif = i == _index;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _index = i;
                            _ongletsVisites.add(i);
                          });
                          if (i == 0) {
                            BannerCarousel.actualiser();
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_icones[i],
                                color: actif ? vertActif : inactifColor,
                                size: 22),
                            const SizedBox(height: 2),
                            if (actif)
                              Text(labels[i],
                                  style: TextStyle(
                                      color: vertActif,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10)),
                            const SizedBox(height: 2),
                            Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: actif
                                        ? vertActif
                                        : Colors.transparent,
                                    shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
