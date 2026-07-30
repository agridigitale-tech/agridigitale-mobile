import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/auth_provider.dart' show AuthProvider;
import 'core/design/app_theme.dart';
import 'core/app_localizations.dart';
import 'services/notification_service.dart';

// Point d'entrée de l'application.
// Initialise Firebase, les notifications FCM, et lance l'app avec les providers.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  try {
    await Firebase.initializeApp();
    await NotificationService().initialiser();
  } catch (e) {
    debugPrint('[Firebase] Non configuré : $e');
  }

  runApp(Phoenix(child: const MonApp()));
}

class MonApp extends StatelessWidget {
  const MonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..verifierSession()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..charger()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..charger()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) => MaterialApp(
          title: 'AgriDigitale',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.clair,
          themeMode: themeProvider.mode,
          locale: languageProvider.locale,
          // navigatorKey branché pour afficher les snackbars FCM depuis partout
          navigatorKey: NotificationService.navigatorKey,
          // Thème sombre activé ici pour que ThemeMode.dark fonctionne
          darkTheme: AppTheme.sombre,
          home: const _AuthGate(),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/main': (_) => const MainNavigationScreen(),
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
          ],
        ),
      ),
    );
  }
}

// Redirige vers LoginScreen si non connecté, MainNavigationScreen sinon.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Pendant la vérification de session → écran de chargement
    if (auth.enVerification) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Connecté → app principale
    if (auth.connecte) {
      return const MainNavigationScreen();
    }

    // Non connecté → écran de connexion
    return const LoginScreen();
  }
}
