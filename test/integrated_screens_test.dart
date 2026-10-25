import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/dashbord/treatments_page.dart';
import 'package:ecare_plus_mobile/views/profile/reference_page.dart';
import 'package:ecare_plus_mobile/widgets/session_guard.dart';
import 'support/api_fixture.dart';
import 'package:ecare_plus_mobile/main.dart';
import 'package:ecare_plus_mobile/views/dashbord/home_page.dart';

void main() {
  testWidgets(
    'treatments route is reachable from the authenticated application',
    (tester) async {
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/mobile/me')) {
            return jsonResponse(jsonEncode(patientFixture()), 200);
          }
          if (r.url.path.endsWith('/planning-traitements')) {
            return jsonResponse('{"traitements":[],"occurrences":[]}', 200);
          }
          if (r.url.path.endsWith('/observance')) {
            return jsonResponse(
              '{"prisesPrevues":0,"prisesConfirmees":0,"taux":null}',
              200,
            );
          }
          if (r.url.path.endsWith('/conversations')) {
            return jsonResponse('[]', 200);
          }
          return jsonResponse('{"content":[],"totalPages":1}', 200);
        },
      );
      await tester.pumpWidget(ECarePlusApp(session: session));
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byType(HomePage)),
      ).pushNamed('/treatments');
      await tester.pumpAndSettle();
      expect(find.text('Mes traitements'), findsOneWidget);
      expect(find.text('Aucune prise prévue pour ce jour.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'dose confirmation sends its version and reflects only server acknowledgement',
    (tester) async {
      var confirmed = false;
      Map<String, dynamic>? sent;
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/reponse')) {
            sent = jsonDecode(r.body) as Map<String, dynamic>;
            confirmed = true;
            return jsonResponse('{}', 200);
          }
          if (r.url.path.endsWith('/observance')) {
            return jsonResponse(
              '{"prisesPrevues":1,"prisesConfirmees":${confirmed ? 1 : 0},"taux":${confirmed ? 100 : 0}}',
              200,
            );
          }
          return jsonResponse(
            jsonEncode({
              'traitements': [],
              'occurrences': [
                {
                  'id': 'dose-1',
                  'version': 4,
                  'medicament': 'Test fictif',
                  'quantite': 1,
                  'unite': 'comprimé',
                  'prevueLe': '2026-10-25T08:00:00Z',
                  'fuseau': 'Africa/Lome',
                  'annulee': false,
                  'statut': confirmed ? 'PRISE' : 'ATTENTE',
                },
              ],
            }),
            200,
          );
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: const MaterialApp(home: TreatmentsPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pris'));
      await tester.tap(find.text('Pris'));
      await tester.pumpAndSettle();
      expect(sent?['version'], 4);
      expect(sent?['action'], 'PRIS');
      expect(sent?['sourceRef'], isNotEmpty);
      expect(find.text('Prise confirmée'), findsOneWidget);
      expect(find.text('Pris'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('conflict remains an error and never displays a confirmed dose', (
    tester,
  ) async {
    final session = await signedInSession(
      handler: (r) async {
        if (r.method == 'POST') {
          return jsonResponse(
            '{"detail":"Occurrence modifiée : recharger sa version"}',
            409,
          );
        }
        if (r.url.path.endsWith('/observance')) {
          return jsonResponse(
            '{"prisesPrevues":1,"prisesConfirmees":0,"taux":0}',
            200,
          );
        }
        return jsonResponse(
          '{"traitements":[],"occurrences":[{"id":"dose","version":2,"medicament":"Test","quantite":1,"unite":"comprimé","prevueLe":"2026-10-25T08:00:00Z","fuseau":"UTC","annulee":false,"statut":"ATTENTE"}]}',
          200,
        );
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: const MaterialApp(home: TreatmentsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pris'));
    await tester.tap(find.text('Pris'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Occurrence modifiée'), findsOneWidget);
    expect(find.text('Prise confirmée'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'administrative QR remains accessible without dossier or clinical consent',
    (tester) async {
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/mobile/me')) {
            return jsonResponse(
              jsonEncode({
                ...patientFixture(),
                'dossierId': null,
                'professionnelId': null,
                'consentementAccepte': false,
              }),
              200,
            );
          }
          return jsonResponse(
            jsonEncode({
              'jeton': 'opaque-temporary-test-code',
              'expireLe': DateTime.now()
                  .add(const Duration(minutes: 10))
                  .toUtc()
                  .toIso8601String(),
            }),
            201,
          );
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: const MaterialApp(
            home: SessionGuard(child: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Votre consentement'), findsOneWidget);
      await tester.ensureVisible(find.text('Mon code de référencement'));
      await tester.tap(find.text('Mon code de référencement'));
      await tester.pumpAndSettle();
      expect(find.byType(ReferencePage), findsOneWidget);
      await tester.ensureVisible(find.text('Générer mon code'));
      await tester.tap(find.text('Générer mon code'));
      await tester.pumpAndSettle();
      expect(find.text('opaque-temporary-test-code'), findsOneWidget);
      expect(find.text('Votre consentement'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
