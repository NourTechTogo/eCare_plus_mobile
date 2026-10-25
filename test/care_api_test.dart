import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ecare_plus_mobile/services/care_api.dart';
import 'support/api_fixture.dart';

void main() {
  test(
    'planning dates are civil and intake carries stable source, version and report',
    () async {
      final calls = <http.Request>[];
      final api = await signedInSession(
        handler: (r) async {
          calls.add(r);
          return jsonResponse('{}', 200);
        },
      );
      final care = CareApi(api);
      await care.planning(DateTime(2026, 10, 25), DateTime(2026, 10, 26));
      expect(calls.last.url.queryParameters, {
        'du': '2026-10-25',
        'au': '2026-10-26',
      });
      await care.reply(
        {'id': 'dose', 'version': 7},
        'REPORTER',
        sourceRef: 'retry-1',
        dateAction: DateTime.utc(2026, 10, 25, 8),
        reporteeAu: DateTime.utc(2026, 10, 25, 10),
      );
      final body = jsonDecode(calls.last.body);
      expect(calls.last.url.path, endsWith('/mobile/me/prises/dose/reponse'));
      expect(body, {
        'action': 'REPORTER',
        'version': 7,
        'sourceRef': 'retry-1',
        'dateAction': '2026-10-25T08:00:00.000Z',
        'reporteeAu': '2026-10-25T10:00:00.000Z',
      });
    },
  );
  test('preferences and QR use account and self routes', () async {
    final calls = <http.Request>[];
    final api = await signedInSession(
      handler: (r) async {
        calls.add(r);
        return jsonResponse('{}', 200);
      },
    );
    final care = CareApi(api);
    await care.preferences();
    expect(calls.last.url.path, endsWith('/compte/preferences-notifications'));
    await care.savePreferences(push: true, whatsapp: false);
    expect(jsonDecode(calls.last.body)['whatsappActif'], false);
    await care.reference();
    expect(calls.last.method, 'POST');
    expect(calls.last.url.path, endsWith('/mobile/me/referencements'));
    await care.deleteRequest();
    expect(calls.last.url.path, endsWith('/compte/demandes-effacement'));
  });
}
