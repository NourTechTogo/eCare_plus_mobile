import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/dashbord/settings_page.dart';
import 'package:ecare_plus_mobile/views/settings/ecare_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CareData(),
        child: MaterialApp(
          home: const SettingsPage(),
          routes: {
            '/documents': (_) => const Scaffold(body: Text('Carnet ouvert')),
            '/follow-up': (_) => const Scaffold(body: Text('Suivi ouvert')),
            '/appointments': (_) => const Scaffold(body: Text('Agenda ouvert')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'eCare entry opens a real page with working guide and document navigation',
    (tester) async {
      await start(tester);
      await tester.scrollUntilVisible(find.text('À propos de eCARE+'), 300);
      await tester.tap(find.text('À propos de eCARE+'));
      await tester.pumpAndSettle();
      expect(find.byType(ECarePage), findsOneWidget);
      expect(find.byType(AboutDialog), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Ajouter et retrouver un document'),
        200,
      );
      await tester.tap(find.text('Ajouter et retrouver un document'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('PDF, JPG et PNG jusqu’à 5 Mo'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Mon carnet de documents'),
        -200,
      );
      await tester.tap(find.text('Mon carnet de documents'));
      await tester.pumpAndSettle();
      expect(find.text('Carnet ouvert'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Local data screen distinguishes durable documents and session data',
    (tester) async {
      await start(tester);
      await tester.scrollUntilVisible(
        find.text('Mes données sur cet appareil'),
        300,
      );
      await tester.tap(find.text('Mes données sur cet appareil'));
      await tester.pumpAndSettle();
      expect(find.text('Documents et suivis médicaux'), findsOneWidget);
      expect(find.text('Mesures et agenda'), findsOneWidget);
      expect(
        find.textContaining('séparé par identifiant patient'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('eCare and expanded help fit a narrow phone with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(home: const ECarePage()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Personnaliser mes suivis'), 250);
    await tester.tap(find.text('Personnaliser mes suivis'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
