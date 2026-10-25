import 'dart:async';
import 'dart:convert';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'support/api_fixture.dart';

void main() {
  test(
    'login sends exact DTO and Bearer is attached only to private calls',
    () async {
      final calls = <http.Request>[];
      final session = ApiSession(
        baseUrl: 'https://example.test/api/v1',
        client: MockClient((r) async {
          calls.add(r);
          if (r.url.path.endsWith('/connexion')) {
            return jsonResponse(
              jsonEncode({
                'jeton': 'secret',
                'expireLe': DateTime.now()
                    .add(const Duration(minutes: 1))
                    .toUtc()
                    .toIso8601String(),
                'profil': patientFixture(),
              }),
              200,
            );
          }
          return jsonResponse(jsonEncode(patientFixture()), 200);
        }),
      );
      addTearDown(session.dispose);
      await session.login(' Gloria ', 'pass');
      await session.refreshProfile();
      expect(jsonDecode(calls.first.body), {
        'identifiant': 'Gloria',
        'motDePasse': 'pass',
      });
      expect(calls.first.headers['Authorization'], isNull);
      expect(calls.last.headers['Authorization'], 'Bearer secret');
    },
  );
  test(
    'HTTP 401 ends session, 403 preserves it and exposes actual error',
    () async {
      var status = 403;
      final session = await signedInSession(
        handler: (r) async => jsonResponse('{"detail":"Accès refusé"}', status),
      );
      addTearDown(session.dispose);
      await expectLater(
        session.refreshProfile(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
      expect(session.authenticated, isTrue);
      status = 401;
      await expectLater(session.refreshProfile(), throwsA(isA<ApiException>()));
      expect(session.authenticated, isFalse);
      expect(session.profile, isNull);
    },
  );
  test(
    'late response from a previous session cannot restore patient data',
    () async {
      final pending = Completer<http.Response>();
      final session = await signedInSession(handler: (r) => pending.future);
      addTearDown(session.dispose);
      final result = session.refreshProfile();
      final failure = expectLater(result, throwsA(isA<ApiException>()));
      session.clear();
      pending.complete(jsonResponse(jsonEncode(patientFixture()), 200));
      await failure;
      expect(session.profile, isNull);
    },
  );
  test('logout purges memory even when server revocation fails', () async {
    final session = await signedInSession(
      handler: (r) async => jsonResponse('{"detail":"Indisponible"}', 503),
    );
    addTearDown(session.dispose);
    await expectLater(session.logout(), throwsA(isA<ApiException>()));
    expect(session.authenticated, isFalse);
    expect(session.userId, isNull);
  });
  test(
    'all pages are fetched instead of silently truncating history',
    () async {
      final session = await signedInSession(
        handler: (r) async {
          final page = int.parse(r.url.queryParameters['page']!);
          return jsonResponse(
            jsonEncode({
              'content': [
                {'id': 'item-$page'},
              ],
              'totalPages': 2,
            }),
            200,
          );
        },
      );
      addTearDown(session.dispose);
      final rows = await session.all('/mobile/me/mesures');
      expect(rows.map((e) => e['id']), ['item-0', 'item-1']);
    },
  );
  test(
    'measurement failure never creates local reading; success restores canonical server value',
    () async {
      var fail = true;
      final calls = <Map<String, dynamic>>[];
      final session = await signedInSession(
        handler: (r) async {
          if (r.method == 'POST') {
            calls.add(jsonDecode(r.body) as Map<String, dynamic>);
            return jsonResponse(
              fail ? '{"detail":"Valeur impossible"}' : '{}',
              fail ? 422 : 201,
            );
          }
          return jsonResponse(
            jsonEncode({
              'content': fail
                  ? []
                  : [
                      {
                        'id': 'm1',
                        'typeMesure': 'GLYCEMIE',
                        'valeurPrincipale': 110,
                        'unite': 'mg/dL',
                        'dateMesure': '2026-10-24T10:00:00Z',
                      },
                    ],
              'totalPages': 1,
            }),
            200,
          );
        },
      );
      addTearDown(session.dispose);
      final data = CareData();
      addTearDown(data.dispose);
      data.bind(session);
      await data.refresh();
      await expectLater(
        data.submitMeasurement('GLYCEMIE', 110, 'mg/dL'),
        throwsA(isA<ApiException>()),
      );
      expect(data.readings, isEmpty);
      fail = false;
      await data.submitMeasurement(
        'GLYCEMIE',
        110,
        'mg/dL',
        sourceRef: 'unique',
      );
      expect(data.readings.single.value, 110);
      expect(calls.last['sourceRef'], 'unique');
      expect(calls.last['dateMesure'], endsWith('Z'));
      session.clear();
      data.bind(session);
      expect(data.readings, isEmpty);
    },
  );
}
