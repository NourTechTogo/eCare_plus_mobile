import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/care_data.dart';
import 'services/profile_photo_service.dart';
import 'services/chat_media_service.dart';
import 'services/document_library.dart';
import 'widgets/main_shell.dart';
import 'utils/app_colors.dart';
import 'routes/app_routes.dart';

// Views — Onboarding
import 'views/onbording/splash_screen.dart';
import 'views/onbording/onboarding_screen.dart';

// Views — Auth
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/auth/forgot_password_page.dart';
import 'views/auth/registration_success_page.dart';
import 'views/profile/profile_page.dart';
import 'views/dashbord/appointments_page.dart';
import 'views/dashbord/documents_page.dart';
import 'views/dashbord/doctors_page.dart';
import 'views/notification/notifications_page.dart';
import 'views/measurement/follow_up_page.dart';
import 'views/measurement/glucose_follow_up_page.dart';
import 'views/measurement/blood_pressure_follow_up_page.dart';
import 'views/error/page_not_found_page.dart';
import 'views/error/no_connection_page.dart';
import 'views/legal/privacy_policy_page.dart';
import 'views/legal/terms_of_use_page.dart';
import 'views/settings/ecare_page.dart';
import 'views/settings/local_data_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  final data = CareData();
  // Profile recovery must run before consuming the chat marker.
  final photo = await ProfilePhotoService.recoverPhoto();
  if (photo != null) data.setProfilePhoto(photo);
  final chatPhoto = await ChatMediaService.recoverPhoto();
  if (chatPhoto != null) data.addDoctorMessage(chatPhoto.$1, chatPhoto.$2);
  runApp(ECarePlusApp(initialData: data));
}

class ECarePlusApp extends StatelessWidget {
  final CareData? initialData;
  final DocumentLibrary? documentLibrary;
  const ECarePlusApp({super.key, this.initialData, this.documentLibrary});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CareData>(
          create: (_) => initialData ?? CareData(),
        ),
        ChangeNotifierProvider<DocumentLibrary>.value(
          value: documentLibrary ?? DocumentLibrary.instance,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'eCARE+',
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            primaryContainer: AppColors.primaryLighter,
            onPrimaryContainer: AppColors.primaryDeep,
            secondary: AppColors.primaryAccent,
            onSecondary: Colors.white,
            secondaryContainer: AppColors.primaryLight,
            onSecondaryContainer: AppColors.primaryDeep,
            surface: AppColors.scaffoldBackground,
          ),
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
          textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Poppins'),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.register: (_) => const RegisterPage(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
          AppRoutes.registrationSuccess: (context) => RegistrationSuccessPage(
            firstRegistration:
                ModalRoute.of(context)?.settings.arguments == true,
          ),
          AppRoutes.home: (_) => const MainShell(),
          AppRoutes.profile: (_) => const ProfilePage(firstTime: true),
          AppRoutes.appointments: (_) => const AppointmentsPage(),
          AppRoutes.notifications: (_) => const NotificationsPage(),
          AppRoutes.followUp: (_) => const FollowUpPage(),
          AppRoutes.glucoseFollowUp: (_) => const GlucoseFollowUpPage(),
          AppRoutes.bloodPressureFollowUp: (_) =>
              const BloodPressureFollowUpPage(),
          AppRoutes.documents: (_) => const DocumentsPage(),
          AppRoutes.doctors: (_) => const DoctorsPage(),
          AppRoutes.pageNotFound: (_) => const PageNotFoundPage(),
          AppRoutes.noConnection: (_) => const NoConnectionPage(),
          AppRoutes.privacyPolicy: (_) => const PrivacyPolicyPage(),
          AppRoutes.termsOfUse: (_) => const TermsOfUsePage(),
          AppRoutes.about: (_) => const ECarePage(),
          AppRoutes.guide: (_) => const ECarePage(guideOnly: true),
          AppRoutes.localData: (_) => const LocalDataPage(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PageNotFoundPage(),
        ),
      ),
    );
  }
}
