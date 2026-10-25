class AppRoutes {
  // Onboarding
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String phoneVerification = '/phone-verification';
  static const String otpVerification = '/otp-verification';
  static const String registrationSuccess = '/registration-success';

  // Dashboard
  static const String home = '/home';
  static const String profile = '/profile';
  static const String appointments = '/appointments';
  static const String notifications = '/notifications';
  static const String followUp = '/follow-up';
  static const String glucoseFollowUp = '/follow-up/glucose';
  static const String bloodPressureFollowUp = '/follow-up/blood-pressure';
  static const String documents = '/documents';
  static const String treatments = '/treatments';
  static const String doctors = '/doctors';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfUse = '/terms-of-use';
  static const String about = '/ecare-plus';
  static const String guide = '/guide';
  static const String localData = '/local-data';

  // Recoverable errors
  static const String pageNotFound = '/error/not-found';
  static const String noConnection = '/error/no-connection';
}
