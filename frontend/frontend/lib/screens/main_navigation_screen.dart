// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'weather/weather_screen.dart';
import 'agdtv/agdtv_screen.dart';
import 'request/request_screen.dart';
import 'settings/settings_screen.dart';
import '../core/design/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;
  final _icones = [Icons.home, Icons.cloud, Icons.tv, Icons.chat_bubble_outline, Icons.settings];
  final _labels = ['Home', 'Weather', 'AGDTV', 'Request', 'Settings'];
  final _ecrans = const [HomeScreen(), WeatherScreen(), AgdtvScreen(), RequestScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _ecrans),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
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
                      Icon(_icones[i], color: actif ? AppColors.vertPrimaire : Colors.black87, size: 24),
                      const SizedBox(height: 3),
                      if (actif)
                        Text(_labels[i], style: const TextStyle(
                          color: AppColors.vertPrimaire, fontWeight: FontWeight.w600, fontSize: 11)),
                      const SizedBox(height: 3),
                      Container(width: 5, height: 5, decoration: BoxDecoration(
                        color: actif ? AppColors.vertPrimaire : Colors.transparent, shape: BoxShape.circle)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}