import 'dart:convert';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/auth/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';
import 'package:ecare_plus_mobile/utils/password_rules.dart';

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('Password reset form remains readable at text scale $scale', (
      tester,
    ) async {
      final session = testSession();
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: MaterialApp(
            builder: (c, w) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: w!,
            ),
            home: const ForgotPasswordPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mot de passe\noublié ?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('OTP verified by server before new password can be submitted', (
    tester,
  ) async {
    final bodies = <Map<String, dynamic>>[];
    final session = testSession(
      handler: (r) async {
        bodies.add(jsonDecode(r.body) as Map<String, dynamic>);
        return jsonResponse(
          r.url.path.endsWith('/verifier')
              ? '{"jetonReinitialisation":"reset-token"}'
              : '',
          r.url.path.endsWith('/verifier') ? 200 : 204,
        );
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: const MaterialApp(home: ForgotPasswordPage()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'a@example.com');
    await tester.ensureVisible(find.text('Envoyer le code'));
    await tester.tap(find.text('Envoyer le code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.ensureVisible(find.text('Vérifier le code'));
    await tester.tap(find.text('Vérifier le code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'short1');
    await tester.ensureVisible(find.text('Enregistrer le mot de passe'));
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(find.text(newPasswordHint), findsNWidgets(2));
    expect(bodies.length, 2);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'short1',
    );
    await tester.enterText(find.byType(TextField), 'Password12345');
    await tester.ensureVisible(find.text('Enregistrer le mot de passe'));
    await tester.tap(find.text('Enregistrer le mot de passe'));
    await tester.pumpAndSettle();
    expect(bodies, [
      {'email': 'a@example.com'},
      {'email': 'a@example.com', 'code': '1234'},
      {'jeton': 'reset-token', 'nouveauMotDePasse': 'Password12345'},
    ]);
    expect(find.text('Mot de passe modifié !'), findsOneWidget);
  });
}
