import 'package:ecare_plus_mobile/main.dart';
import 'package:ecare_plus_mobile/views/onbording/splash_screen.dart';
import 'package:ecare_plus_mobile/views/auth/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openRegister(WidgetTester tester) async {
  await tester.pumpWidget(const ECarePlusApp());
  Navigator.of(
    tester.element(find.byType(SplashScreen)),
  ).pushReplacementNamed('/register');
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byType(Checkbox),
    250,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  testWidgets(
    'Registration consent is disabled until both documents were fully read',
    (tester) async {
      await openRegister(tester);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      for (final label in [
        'politique de confidentialité',
        'conditions générales d’utilisation',
      ]) {
        await tester.tapOnText(find.textRange.ofSubstring(label));
        await tester.pumpAndSettle();
        final done = find.text('J’ai lu ce document jusqu’à la fin');
        await tester.scrollUntilVisible(
          done,
          500,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(done);
        await tester.pumpAndSettle();
        if (label == 'politique de confidentialité') {
          expect(
            tester.widget<Checkbox>(find.byType(Checkbox)).onChanged,
            isNull,
          );
        }
      }
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox)).onChanged,
        isNotNull,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    },
  );
  testWidgets('Leaving a legal page before bottom cannot enable consent', (
    tester,
  ) async {
    await openRegister(tester);
    await tester.tapOnText(
      find.textRange.ofSubstring('politique de confidentialité'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
  });
  testWidgets(
    'Submitting without consent stays on registration without fictitious success',
    (tester) async {
      await openRegister(tester);
      await tester.ensureVisible(find.text("S'inscrire"));
      await tester.tap(find.text("S'inscrire"));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterPage), findsOneWidget);
      expect(
        find.text(
          'Cochez la case pour accepter ces documents et vous inscrire.',
        ),
        findsOneWidget,
      );
    },
  );
}
