// Constantes de l'application AgriDigitale
class AppConstants {
  // Configuration de l'API
 static const String baseUrl = 'https://agridigitale-backend.onrender.com/api';
  static const Duration timeoutDuration = Duration(seconds: 10);
 
  // Clés de stockage
  static const String jwtTokenKey = 'jwt_token';
  static const String themeModeKey = 'theme_mode';

  // Messages d'erreur
  static const String invalidEmail = 'E-mail invalide';
  static const String weakPassword = 'Minimum 6 caractères';
  static const String requiredField = 'Champ obligatoire';
  static const String loginError = 'E-mail ou mot de passe incorrect';
  static const String registerError = 'Cet e-mail est déjà utilisé';

  // Routes de l'API
  static const String apiAuthRegister = '/auth/inscription';
  static const String apiAuthLogin = '/auth/connexion';
  static const String apiAuthForgotPassword = '/auth/forgot-password';
  static const String apiAuthResetPassword = '/auth/reset-password';
  static const String apiAuthSendOtp = '/auth/send-otp';
  static const String apiAuthVerifyOtp = '/auth/verify-otp';
  static const String apiAuthDeleteAccount = '/auth/supprimer-compte';

  // Configuration de l'application
  static const String appName = 'AgriDigitale';
  static const String appTitle = 'AgriDigitale';
}