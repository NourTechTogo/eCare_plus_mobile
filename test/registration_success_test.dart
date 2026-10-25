import 'support/api_fixture.dart';
import 'package:ecare_plus_mobile/main.dart';
import 'package:ecare_plus_mobile/views/onbording/splash_screen.dart';
import 'package:ecare_plus_mobile/views/auth/registration_success_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecare_plus_mobile/services/registration_welcome_service.dart';

Future<void> openSuccess(WidgetTester tester, {bool first = true}) async {
  await tester.pumpWidget(ECarePlusApp(session: testSession()));
  Navigator.of(
    tester.element(find.byType(SplashScreen)),
  ).pushReplacementNamed('/registration-success', arguments: first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('First registration marker persists per normalized account', () async {
    expect(
      await RegistrationWelcomeService.takeFirstRegistration(
        ' patient@example.com ',
      ),
      isTrue,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    expect(
      await RegistrationWelcomeService.takeFirstRegistration(
        'PATIENT@example.com',
      ),
      isFalse,
    );
    expect(
      await RegistrationWelcomeService.takeFirstRegistration(
        'autre@example.com',
      ),
      isTrue,
    );
    expect(await RegistrationWelcomeService.takeFirstRegistration(''), isFalse);
  });
  testWidgets(
    'First registration opens login after celebration and home after login',
    (tester) async {
      await openSuccess(tester);
      expect(find.byType(RegistrationSuccessPage), findsOneWidget);
      expect(find.text('Accéder au tableau de bord'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(RegistrationSuccessPage), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationSuccessPage), findsNothing);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Accueil'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        'patient@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Password123!');
      await tester.ensureVisible(find.text('Se connecter'));
      await tester.tap(find.text('Se connecter'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenue'), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Success route skips celebration outside a first registration', (
    tester,
  ) async {
    await openSuccess(tester, first: false);
    await tester.pumpAndSettle();
    expect(find.byType(RegistrationSuccessPage), findsNothing);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Accueil'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Leaving the celebration cancels automatic navigation', (
    tester,
  ) async {
    await openSuccess(tester);
    await tester.pumpWidget(const MaterialApp(home: Text('Autre écran')));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Autre écran'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
