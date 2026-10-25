import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/settings/pending_sync_page.dart';
import 'package:ecare_plus_mobile/views/settings/server_preferences_page.dart';
import 'package:ecare_plus_mobile/views/profile/reference_page.dart';
import 'package:ecare_plus_mobile/views/measurement/measure_notes_page.dart';
import 'package:ecare_plus_mobile/views/dashbord/treatments_page.dart';
import 'package:ecare_plus_mobile/widgets/care_components.dart';
import 'support/api_fixture.dart';
import 'package:ecare_plus_mobile/views/measurement/follow_up_page.dart';

void main() {
  testWidgets(
    'Measurement dialog keeps save reachable with keyboard and enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider<CareData>(
          create: (_) => CareData(),
          child: MaterialApp(
            builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                textScaler: const TextScaler.linear(1.5),
                viewInsets: const EdgeInsets.only(bottom: 180),
              ),
              child: w!,
            ),
            home: Builder(
              builder: (c) => Scaffold(
                body: TextButton(
                  onPressed: () => showMeasurementSheet(c),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Enregistrer la mesure').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Fermer').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  final pages = <String, Widget Function()>{
    'traitements': () => const TreatmentsPage(),
    'notes': () => const MeasureNotesPage(),
    'synchronisation': () => const PendingSyncPage(),
    'référencement': () => const ReferencePage(),
    'préférences': () => const ServerPreferencesPage(),
  };
  for (final variant in [(320.0, 640.0, 2.0), (633.0, 628.0, 1.0)]) {
    for (final page in pages.entries) {
      testWidgets(
        '${page.key} keeps eCare cards usable at ${variant.$1}px / ${variant.$3}x',
        (tester) async {
          tester.view.physicalSize = Size(variant.$1, variant.$2);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final session = await signedInSession(
            handler: (r) async {
              if (r.url.path.endsWith('planning-traitements')) {
                return jsonResponse('{"traitements":[],"occurrences":[]}', 200);
              }
              if (r.url.path.endsWith('observance')) {
                return jsonResponse(
                  '{"taux":null,"prisesConfirmees":0,"prisesPrevues":0}',
                  200,
                );
              }
              if (r.url.path.endsWith('preferences-notifications')) {
                return jsonResponse(
                  '{"pushActif":true,"whatsappActif":false}',
                  200,
                );
              }
              if (r.url.path.endsWith('referencements')) {
                return jsonResponse(
                  jsonEncode({
                    'jeton': 'test-reference-code-long-but-not-a-secret',
                    'expireLe': DateTime.now()
                        .add(const Duration(minutes: 5))
                        .toUtc()
                        .toIso8601String(),
                  }),
                  200,
                );
              }
              return jsonResponse('{"content":[],"totalPages":1}', 200);
            },
          );
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<ApiSession>(
                  lazy: false,
                  create: (_) => session,
                ),
                ChangeNotifierProvider<CareData>(create: (_) => CareData()),
              ],
              child: MaterialApp(
                builder: (c, w) => MediaQuery(
                  data: MediaQuery.of(
                    c,
                  ).copyWith(textScaler: TextScaler.linear(variant.$3)),
                  child: w!,
                ),
                home: page.value(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(CareSummary), findsOneWidget);
          if (page.key == 'référencement') {
            await tester.ensureVisible(find.text('Générer mon code'));
            await tester.tap(find.text('Générer mon code'));
            await tester.pumpAndSettle();
            expect(find.text('Code temporaire actif'), findsOneWidget);
          }
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -1600),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
