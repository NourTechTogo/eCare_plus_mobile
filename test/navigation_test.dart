import 'support/care_fixture.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/main.dart';
import 'package:ecare_plus_mobile/services/document_library.dart';
import 'package:ecare_plus_mobile/widgets/raised_navigation_bar.dart';

import 'package:ecare_plus_mobile/views/dashbord/home_page.dart';
import 'package:ecare_plus_mobile/views/dashbord/articles_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openHome(WidgetTester tester) async {
  final data = CareData();
  final session = await careSession(data);
  await tester.pumpWidget(
    ECarePlusApp(
      session: session,
      initialData: data,
      documentLibrary: _EmptyDocuments(),
    ),
  );
  await tester.pumpAndSettle();
}

class _EmptyDocuments extends DocumentLibrary {
  @override
  Future<void> load() async {
    loaded = true;
  }
}

Future<void> tapHomeShortcut(WidgetTester tester, String label) async {
  final target = find.text(label).first;
  for (
    var attempt = 0;
    attempt < 6 && target.hitTestable().evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(
      find.byKey(const PageStorageKey('home-scroll')),
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
}

void main() {
  testWidgets('Home remains usable with enlarged system text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openHome(tester);
    await tester.drag(
      find.byKey(const PageStorageKey('home-scroll')),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('home-scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aucun professionnel affecté'), findsWidgets);
    expect(tester.takeException(), isNull);
    expect(find.text('Accueil').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
  testWidgets('Footer opens all four destinations', (tester) async {
    await openHome(tester);
    expect(find.byType(RaisedNavigationBar), findsOneWidget);
    await tester.tap(find.text('Rendez-vous').last);
    await tester.pumpAndSettle();
    expect(find.text('Mes rendez-vous'), findsOneWidget);
    await tester.tap(find.text('Articles').last);
    await tester.pumpAndSettle();
    expect(find.byType(ArticlesPage), findsOneWidget);
    await tester.tap(find.text('Paramètres').last);
    await tester.pumpAndSettle();
    expect(find.text('Mon espace'), findsOneWidget);
    await tester.tap(find.text('Accueil').last);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Notifications and follow-up shortcuts open dedicated pages', (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Mes notifications'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await tapHomeShortcut(tester, 'Suivi');
    await tester.pumpAndSettle();
    expect(find.text('Mon suivi'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Footer stays visible when home scrolls on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openHome(tester);
    await tester.drag(
      find.byKey(const PageStorageKey('home-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Accueil').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Articles').last);
    await tester.pumpAndSettle();
    expect(find.byType(ArticlesPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Follow-up validates values and updates its chart and history', (
    tester,
  ) async {
    await openHome(tester);
    await tapHomeShortcut(tester, 'Suivi');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter une mesure'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-1');
    await tester.tap(find.text('Enregistrer la mesure'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez une valeur positive en mg/dL'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '98,5');
    await tester.tap(find.text('Enregistrer la mesure'));
    await tester.pumpAndSettle();
    expect(find.text('1 mesure sur la période'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('98.5 mg/dL'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('98.5 mg/dL'), findsWidgets);
    expect(find.text('Mes statistiques'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Documents and doctors can be reached by horizontal shortcuts', (
    tester,
  ) async {
    await openHome(tester);
    await tapHomeShortcut(tester, 'Documents');
    await tester.pumpAndSettle();
    expect(find.text('Mes documents'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('shortcut-scroll')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Médecins'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun professionnel affecté'), findsOneWidget);
    expect(find.text('Dr Lawson Jennifer'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
