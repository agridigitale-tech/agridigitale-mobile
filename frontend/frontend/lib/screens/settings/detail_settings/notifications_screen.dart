import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import '../../../core/design/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active_outlined,
                  size: 64, color: AppColors.vertPrimaire),
              const SizedBox(height: 24),
              const Text(
                'Gerer les notifications',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Activez ou desactivez les notifications depuis les reglages de votre appareil.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.notification),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vertPrimaire,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text('Ouvrir les parametres',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}