import 'support/care_fixture.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/main.dart';
import 'package:ecare_plus_mobile/widgets/raised_navigation_bar.dart';

import 'package:ecare_plus_mobile/views/dashbord/articles_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> open(WidgetTester tester) async {
    final data = CareData();
    final session = await careSession(data);
    await tester.pumpWidget(ECarePlusApp(initialData: data, session: session));
    await tester.pumpAndSettle();
  }

  testWidgets('Central add stays fixed and saves either type of constant', (
    tester,
  ) async {
    await open(tester);
    final add = find.byTooltip('Ajouter mes constantes');
    expect(add, findsOneWidget);
    final position = tester.getCenter(add);
    await tester.tap(find.text('Articles').last);
    await tester.pumpAndSettle();
    expect(tester.getCenter(add), position);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une constante'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '98,5');
    await tester.tap(find.text('Glycémie').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '98,5',
    );
    await tester.ensureVisible(find.text('Enregistrer la mesure'));
    await tester.tap(find.text('Enregistrer la mesure'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une constante'), findsNothing);
    expect(find.byType(ArticlesPage), findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tension artérielle'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).first, '120');
    await tester.enterText(find.byType(TextFormField).last, '80');
    await tester.ensureVisible(find.text('Enregistrer la mesure'));
    await tester.tap(find.text('Enregistrer la mesure'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une constante'), findsNothing);
    expect(find.byType(ArticlesPage), findsOneWidget);
    final data = tester
        .element(find.byType(RaisedNavigationBar))
        .read<CareData>();
    expect(data.readings.single.value, 98.5);
    expect(data.bloodPressureReadings.single.systolic, 120);
    expect(data.bloodPressureReadings.single.diastolic, 80);
    await tester.tap(add);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Ajouter une constante'))).pop();
    await tester.pumpAndSettle();
    expect(data.readings, hasLength(1));
    expect(data.bloodPressureReadings, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'Large labels, screen reader selection and reduced motion work on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final semantics = tester.ensureSemantics();
      try {
        await open(tester);
        for (final label in [
          'Rendez-vous',
          'Articles',
          'Paramètres',
          'Accueil',
        ]) {
          expect(find.text(label).last.hitTestable(), findsOneWidget);
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
          expect(
            tester
                .getSemantics(
                  find.descendant(
                    of: find.byType(RaisedNavigationBar),
                    matching: find.bySemanticsLabel(label),
                  ),
                )
                .flagsCollection
                .isSelected,
            ui.Tristate.isTrue,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
      } finally {
        semantics.dispose();
      }
    },
  );
}
