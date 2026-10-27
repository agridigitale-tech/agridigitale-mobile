// Point d'entrée de l'application AgriDigitale.
// Initialise Firebase, les formats de date FR, et lance l'app avec Phoenix (restart propre).
// Gère aussi les deep links (ex: agridigitale://reset-password?token=...).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:app_links/app_links.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/home/article_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/auth_provider.dart' show AuthProvider;
import 'providers/notification_provider.dart';
import 'core/design/app_theme.dart';
import 'core/app_localizations.dart';
import 'services/notification_service.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force l'activation du Photo Picker AndroidX natif (compatibilité Android 11 à 16 sans permission stockage)
  final imagePickerPlatform = ImagePickerPlatform.instance;
  if (imagePickerPlatform is ImagePickerAndroid) {
    imagePickerPlatform.useAndroidPhotoPicker = true;
  }
  await initializeDateFormatting('fr_FR', null);
  await NotificationService().initialiser();
  NotificationService().ecouterRefreshToken();
  runApp(Phoenix(child: const MonApp()));
}

class MonApp extends StatefulWidget {
  const MonApp({super.key});
  @override
  State<MonApp> createState() => _MonAppState();
}

class _MonAppState extends State<MonApp> {
  final _navigatorKey = NotificationService.navigatorKey;  // clé partagée avec NotificationService
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    // Écoute les deep links quand l'app est déjà ouverte en arrière-plan
    _appLinks.uriLinkStream.listen(_gererLien);
    // Récupère le deep link qui a lancé l'app (cold start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _gererLien(uri);
    });
  }

  void _gererLien(Uri uri) {
    if (uri.scheme == 'agridigitale' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'] ?? '';
      if (token.isEmpty) return;
      // Uri.queryParameters décode automatiquement l'URL encoding
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Gestion session utilisateur (connexion / déconnexion / rôle)
        ChangeNotifierProvider(create: (_) => AuthProvider()..verifierSession()),
        // Thème clair / sombre persisté dans SharedPreferences
        ChangeNotifierProvider(create: (_) => ThemeProvider()..charger()),
        // Langue FR / EN persistée dans SharedPreferences
        ChangeNotifierProvider(create: (_) => LanguageProvider()..charger()),
        // Compteur de notifications non lues + badge icône
        ChangeNotifierProvider(create: (_) => NotificationProvider()..rafraichir()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) => MaterialApp(
          title: 'AgriDigitale',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.clair,
          themeMode: themeProvider.mode,
          locale: languageProvider.locale,
          navigatorKey: _navigatorKey,
          darkTheme: AppTheme.sombre,
          home: const _AuthGate(),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/main': (_) => const MainNavigationScreen(),
            '/article': (ctx) {
              final id = ModalRoute.of(ctx)!.settings.arguments as String?;
              if (id == null || id.isEmpty) return const MainNavigationScreen();
              return ArticleDetailScreen(articleId: id);
            },
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

// Ouvre directement l'application principale (mode invité/visiteur).
// L'authentification est contextuelle (demandée uniquement pour les favoris, commentaires, demandes).
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return const MainNavigationScreen();
  }
}
