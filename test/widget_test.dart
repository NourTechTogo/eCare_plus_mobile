import 'dart:convert';
import 'package:ecare_plus_mobile/main.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/auth/login_page.dart';
import 'package:ecare_plus_mobile/views/dashbord/home_page.dart';
import 'package:ecare_plus_mobile/views/onbording/onboarding_screen.dart';
import 'package:ecare_plus_mobile/views/onbording/splash_screen.dart';
import 'package:ecare_plus_mobile/views/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';

void main() {
  testWidgets('Splash navigates to onboarding', (tester) async {
    await tester.pumpWidget(const ECarePlusApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
  testWidgets('Protected route rejects anonymous access', (tester) async {
    await tester.pumpWidget(const ECarePlusApp());
    Navigator.of(
      tester.element(find.byType(SplashScreen)),
    ).pushReplacementNamed('/home');
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });
  testWidgets(
    'Profile loads server fields and saves full values after acknowledgement',
    (tester) async {
      final profile = patientFixture();
      Map<String, dynamic>? saved;
      final session = await signedInSession(
        handler: (r) async {
          if (r.method == 'PATCH') {
            saved = jsonDecode(r.body) as Map<String, dynamic>;
            profile.addAll(saved!);
          }
          return jsonResponse(jsonEncode(profile), 200);
        },
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ApiSession>(create: (_) => session),
            ChangeNotifierProvider(create: (_) => CareData()),
          ],
          child: const MaterialApp(home: ProfilePage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dupont'), findsOneWidget);
      final name = find.byKey(const ValueKey('profile-nom'));
      await tester.enterText(name, 'Nouveau');
      await tester.scrollUntilVisible(
        find.text('Enregistrer'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(saved?['nom'], 'Nouveau');
      expect(saved, contains('telephoneUrgence'));
      expect(find.text('Profil enregistré sur le serveur.'), findsOneWidget);
      expect(session.profile?['nom'], 'Nouveau');
    },
  );
  for (final phoneOnly in [true, false]) {
    testWidgets(
      'Profile accepts ${phoneOnly ? 'phone-only' : 'email-only'} account and preserves contact',
      (tester) async {
        final profile = patientFixture();
        profile[phoneOnly ? 'email' : 'telephone'] = null;
        Map<String, dynamic>? saved;
        final session = await signedInSession(
          handler: (r) async {
            if (r.method == 'PATCH') {
              saved = jsonDecode(r.body) as Map<String, dynamic>;
              profile.addAll(saved!);
            }
            return jsonResponse(jsonEncode(profile), 200);
          },
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ApiSession>(create: (_) => session),
              ChangeNotifierProvider(create: (_) => CareData()),
            ],
            child: const MaterialApp(home: ProfilePage()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Enregistrer'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        expect(saved, isNotNull);
        expect(
          saved?[phoneOnly ? 'telephone' : 'email'],
          profile[phoneOnly ? 'telephone' : 'email'],
        );
        expect(saved?[phoneOnly ? 'email' : 'telephone'], isNull);
        expect(find.text('Profil enregistré sur le serveur.'), findsOneWidget);
      },
    );
  }
}
