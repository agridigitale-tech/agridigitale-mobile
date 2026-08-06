import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'weather/weather_screen.dart';
import 'agdtv/agdtv_screen.dart';
import 'favoris/favoris_screen.dart';
import 'request/request_screen.dart';
import 'settings/settings_screen.dart';
import 'admin/admin_screen.dart';
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

  void changerOnglet(int index) {
    setState(() => _index = index);
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

    return Scaffold(
      body: IndexedStack(index: _index, children: _ecrans),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth.estAdmin)
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
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
                      onTap: () => setState(() => _index = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_icones[i],
                              color: actif ? AppColors.vertPrimaire : Colors.black54,
                              size: 22),
                          const SizedBox(height: 2),
                          if (actif)
                            Text(labels[i],
                                style: const TextStyle(
                                    color: AppColors.vertPrimaire,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10)),
                          const SizedBox(height: 2),
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: actif
                                      ? AppColors.vertPrimaire
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
    );
  }
}
