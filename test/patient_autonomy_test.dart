import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/widgets/session_guard.dart';
import 'package:ecare_plus_mobile/views/dashbord/treatments_page.dart';
import 'package:ecare_plus_mobile/widgets/personal_treatment_form.dart';
import 'package:ecare_plus_mobile/widgets/care_components.dart';
import 'support/api_fixture.dart';

void main() {
  testWidgets(
    'expired personal treatment cannot expose or resend previous account data',
    (tester) async {
      final owners = <String?>[];
      late ApiSession session;
      session = await signedInSession(
        handler: (r) async {
          owners.add(session.userId);
          return jsonResponse('{"detail":"Transmission incertaine"}', 503);
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>.value(
          value: session,
          child: const MaterialApp(home: PersonalTreatmentForm()),
        ),
      );
      await tester.pumpAndSettle();
      final controllers = <TextEditingController>[];
      for (final entry in {
        'treatment-name': 'Traitement privé A',
        'medicine-name': 'Médicament privé A',
        'medicine-dose': '10',
        'medicine-dose-unit': 'mg',
        'medicine-form': 'comprimé',
        'intake-unit': 'comprimé',
      }.entries) {
        final finder = find.byKey(Key(entry.key));
        controllers.add(tester.widget<TextFormField>(finder).controller!);
        await tester.enterText(finder, entry.value);
      }
      await tester.ensureVisible(find.text('Enregistrer ma déclaration'));
      await tester.tap(find.text('Enregistrer ma déclaration'));
      await tester.pumpAndSettle();
      expect(owners, ['patient-a']);
      final staleSave = tester
          .widget<CareAction>(find.byType(CareAction))
          .onPressed!;
      session.clear();
      await session.login('patient-b@example.com', 'Password123!');
      session.profile = {...patientFixture(), 'id': 'patient-b'};
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(controllers.every((c) => c.text.isEmpty), isTrue);
      expect(find.textContaining('Session expirée'), findsOneWidget);
      staleSave();
      await tester.pumpAndSettle();
      expect(owners, ['patient-a']);
      await tester.pumpWidget(const SizedBox.shrink());
      session.clear();
    },
  );
  for (final consent in [true, false]) {
    testWidgets('personal dossier preserves consent gate: $consent', (
      tester,
    ) async {
      final session = await signedInSession(
        handler: (r) async => jsonResponse(
          jsonEncode({
            ...patientFixture(),
            'professionnelId': null,
            'structureId': null,
            'consentementAccepte': consent,
          }),
          200,
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>.value(
          value: session,
          child: const MaterialApp(
            home: SessionGuard(child: Text('Personal dashboard')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Personal dashboard'),
        consent ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Votre consentement'),
        consent ? findsNothing : findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      session.clear();
    });
  }
  testWidgets('missing dossier stays blocked and session clearing hides data', (
    tester,
  ) async {
    final session = await signedInSession(
      handler: (r) async => jsonResponse(
        jsonEncode({
          ...patientFixture(),
          'dossierId': null,
          'professionnelId': null,
        }),
        200,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>.value(
        value: session,
        child: const MaterialApp(
          home: SessionGuard(child: Text('Private patient data')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private patient data'), findsNothing);
    expect(find.text('Dossier en préparation'), findsOneWidget);
    session.clear();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Private patient data'), findsNothing);
    expect(find.text('Dossier en préparation'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('personal treatment is clearly distinguished from prescription', (
    tester,
  ) async {
    final session = await signedInSession(
      handler: (r) async {
        if (r.url.path.endsWith('/observance')) {
          return jsonResponse(
            '{"taux":null,"prisesConfirmees":0,"prisesPrevues":0}',
            200,
          );
        }
        return jsonResponse(
          '{"traitements":[{"libelle":"Personnel","declarationPersonnelle":true}],"occurrences":[]}',
          200,
        );
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>.value(
        value: session,
        child: const MaterialApp(home: TreatmentsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Personnel · Déclaration personnelle'), findsOneWidget);
    expect(
      find.textContaining('ne constitue pas une prescription médicale'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    session.clear();
  });
  testWidgets('patient records daily treatment with stable retry identity', (
    tester,
  ) async {
    final submitted = <Map<String, dynamic>>[];
    final session = await signedInSession(
      handler: (r) async {
        if (r.method == 'POST' && r.url.path.endsWith('/traitements')) {
          submitted.add(jsonDecode(r.body) as Map<String, dynamic>);
          return jsonResponse(
            submitted.length == 1 ? '{"detail":"Réessayez"}' : '{}',
            submitted.length == 1 ? 503 : 201,
          );
        }
        if (r.url.path.endsWith('/observance')) {
          return jsonResponse(
            '{"taux":null,"prisesConfirmees":0,"prisesPrevues":0}',
            200,
          );
        }
        return jsonResponse('{"traitements":[],"occurrences":[]}', 200);
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>.value(
        value: session,
        child: const MaterialApp(home: TreatmentsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Déclarer un traitement'));
    await tester.tap(find.text('Déclarer un traitement'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('treatment-name')),
      'Traitement personnel',
    );
    await tester.enterText(
      find.byKey(const Key('medicine-name')),
      'Médicament test',
    );
    await tester.enterText(find.byKey(const Key('medicine-dose')), '10');
    await tester.enterText(find.byKey(const Key('medicine-dose-unit')), 'mg');
    await tester.enterText(find.byKey(const Key('medicine-form')), 'comprimé');
    await tester.enterText(find.byKey(const Key('intake-unit')), 'comprimé');
    await tester.ensureVisible(find.text('Enregistrer ma déclaration'));
    await tester.tap(find.text('Enregistrer ma déclaration'));
    await tester.pumpAndSettle();
    expect(find.text('Réessayez'), findsOneWidget);
    await tester.ensureVisible(find.text('Enregistrer ma déclaration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer ma déclaration'));
    await tester.pumpAndSettle();
    expect(submitted, hasLength(2));
    expect(submitted[1], submitted[0]);
    expect(submitted[0]['libelle'], 'Traitement personnel');
    expect((submitted[0]['prise'] as Map)['joursSemaine'], [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
    expect(
      (submitted[0]['medicament'] as Map)['nomCommercial'],
      'Médicament test',
    );
    expect(submitted[0]['sourceRef'], matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(find.text('Enregistrer ma déclaration'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    session.clear();
  });
}
