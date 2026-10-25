import 'services/api_session.dart';
import 'widgets/session_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/care_data.dart';

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
import 'views/dashbord/treatments_page.dart';
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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  final data = CareData();
  runApp(ECarePlusApp(initialData: data));
}

class ECarePlusApp extends StatelessWidget {
  final CareData? initialData;
  final DocumentLibrary? documentLibrary;
  final ApiSession? session;
  const ECarePlusApp({
    super.key,
    this.initialData,
    this.documentLibrary,
    this.session,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session ?? ApiSession(),
        ),
        ChangeNotifierProxyProvider<ApiSession, CareData>(
          create: (_) => initialData ?? CareData(),
          update: (_, session, data) => data!..bind(session),
        ),
        ChangeNotifierProxyProvider<ApiSession, DocumentLibrary>(
          create: (_) => documentLibrary ?? DocumentLibrary(locked: true),
          update: (_, session, library) {
            if (documentLibrary != null) return documentLibrary!;
            if (library?.patientId == session.userId &&
                library?.locked == !session.authenticated) {
              return library!;
            }
            library?.lockSession();
            return DocumentLibrary(
              patientId: session.userId,
              locked: !session.authenticated,
              session: session,
            );
          },
        ),
      ],
      child: Consumer<ApiSession>(
        builder: (context, session, _) => MaterialApp(
          key: ValueKey(session.userId ?? 'guest'),
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
          initialRoute: session.authenticated
              ? AppRoutes.home
              : AppRoutes.splash,
          onGenerateInitialRoutes: (initialRoute) => [
            MaterialPageRoute<void>(
              settings: RouteSettings(name: initialRoute),
              builder: (_) => session.authenticated
                  ? const SessionGuard(child: MainShell())
                  : const SplashScreen(),
            ),
          ],
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
            AppRoutes.home: (_) => const SessionGuard(child: MainShell()),
            AppRoutes.profile: (_) =>
                SessionGuard(child: ProfilePage(firstTime: true)),
            AppRoutes.appointments: (_) =>
                SessionGuard(child: AppointmentsPage()),
            AppRoutes.notifications: (_) =>
                SessionGuard(child: NotificationsPage()),
            AppRoutes.followUp: (_) => SessionGuard(child: FollowUpPage()),
            AppRoutes.glucoseFollowUp: (_) =>
                SessionGuard(child: GlucoseFollowUpPage()),
            AppRoutes.bloodPressureFollowUp: (_) =>
                const SessionGuard(child: BloodPressureFollowUpPage()),
            AppRoutes.documents: (_) => SessionGuard(child: DocumentsPage()),
            AppRoutes.treatments: (_) =>
                const SessionGuard(child: TreatmentsPage()),
            AppRoutes.doctors: (_) => SessionGuard(child: DoctorsPage()),
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
      ),
    );
  }
}
