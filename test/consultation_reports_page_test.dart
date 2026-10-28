import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/reports/consultation_reports_page.dart';
import 'support/api_fixture.dart';

Map<String, dynamic> savedReport() => {
  'id': 'report-a',
  'du': '2026-10-20',
  'au': '2026-10-22',
  'fuseau': 'Africa/Lome',
  'genereLe': '2026-10-23T08:00:00Z',
  'patient': {'nom': 'Fictif', 'prenoms': 'Camille'},
  'nombreMesures': 0,
  'joursSansSaisie': 3,
  'seriesMesures': [],
  'traitements': [],
  'reponsesPrises': [],
  'alertes': [],
  'rendezVous': [],
  'avertissements': ['Synthèse descriptive, sans diagnostic.'],
};
void main() {
  testWidgets(
    'uncertain generation retries its reference, new explicit generation gets a new reference',
    (tester) async {
      final sources = <String>[];
      final session = await signedInSession(
        handler: (r) async {
          if (r.method == 'POST') {
            sources.add((jsonDecode(r.body) as Map)['sourceRef'] as String);
            if (sources.length == 1) {
              return jsonResponse('{"detail":"Réponse incertaine"}', 503);
            }
            return jsonResponse(jsonEncode(savedReport()), 201);
          }
          return jsonResponse('{"content":[],"totalPages":0}', 200);
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>.value(
          value: session,
          child: const MaterialApp(home: ConsultationReportsPage()),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(find.text('Générer la synthèse'));
        await tester.tap(find.text('Générer la synthèse'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Retour aux rapports'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Générer la synthèse'));
      await tester.tap(find.text('Générer la synthèse'));
      await tester.pumpAndSettle();
      expect(sources, hasLength(3));
      expect(sources[0], sources[1]);
      expect(sources[2], isNot(sources[1]));
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'small screen and large text support saved report and cancelled transmission',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var deposits = 0, saves = 0;
      final report = {
        ...savedReport(),
        'nombreMesures': 2,
        'joursSansSaisie': 1,
        'seriesMesures': [
          {
            'typeMesure': 'GLYCEMIE',
            'composante': 'PRINCIPALE',
            'unite': 'mg/dL',
            'nombre': 2,
            'minimum': 120,
            'maximum': 140,
            'moyenne': 130,
            'derniereValeur': 140,
            'derniereLe': '2026-10-22T08:00:00Z',
            'joursSansSaisie': 1,
            'points': [
              {
                'dateMesure': '2026-10-20T08:00:00Z',
                'valeur': 120,
                'contexte': 'Fictif',
              },
              {
                'dateMesure': '2026-10-22T08:00:00Z',
                'valeur': 140,
                'contexte': 'Fictif',
              },
            ],
          },
        ],
      };
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/documents')) {
            deposits++;
            return jsonResponse('{"id":"doc-a"}', 201);
          }
          if (r.url.path.endsWith('/pdf')) {
            return http.Response('%PDF-1.4\nFictif\n%%EOF', 200);
          }
          if (r.method == 'POST' || r.url.path.endsWith('/report-a')) {
            return jsonResponse(
              jsonEncode(report),
              r.method == 'POST' ? 201 : 200,
            );
          }
          return jsonResponse(
            jsonEncode({
              'content': [savedReport()],
              'totalPages': 1,
            }),
            200,
          );
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>.value(
          value: session,
          child: MaterialApp(
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: ConsultationReportsPage(
              savePdf: (Uint8List bytes, String name) async {
                saves++;
                return false;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Consulter le rapport').first);
      await tester.tap(find.text('Consulter le rapport').first);
      await tester.pumpAndSettle();
      expect(find.text('Camille Fictif'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Télécharger le PDF'));
      await tester.tap(find.text('Télécharger le PDF'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(find.text('PDF enregistré.'), findsNothing);
      expect(deposits, 0);
      await tester.ensureVisible(
        find.text('Déposer une copie dans mon carnet'),
      );
      await tester.tap(find.text('Déposer une copie dans mon carnet'));
      await tester.pumpAndSettle();
      expect(find.textContaining('professionnels autorisés'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(deposits, 0);
      expect(tester.takeException(), isNull);
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'session removal hides the report even after a late list response',
    (tester) async {
      final pending = Completer<http.Response>();
      final session = await signedInSession(handler: (r) => pending.future);
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>.value(
          value: session,
          child: const MaterialApp(home: ConsultationReportsPage()),
        ),
      );
      await tester.pump();
      session.clear();
      await tester.pump();
      pending.complete(
        jsonResponse(
          jsonEncode({
            'content': [savedReport()],
            'totalPages': 1,
          }),
          200,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Consulter le rapport'), findsNothing);
      expect(find.textContaining('Reconnectez-vous'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
