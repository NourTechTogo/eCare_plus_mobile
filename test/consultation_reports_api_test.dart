import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ecare_plus_mobile/services/consultation_reports_api.dart';
import 'support/api_fixture.dart';

void main() {
  test('civil period bound is enforced without a request', () {
    expect(
      () => ReportRequest(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 4, 1),
        zone: 'UTC',
      ),
      throwsException,
    );
    expect(
      () => ReportRequest(
        from: DateTime(2026, 1, 2),
        to: DateTime(2026, 1, 1),
        zone: 'UTC',
      ),
      throwsException,
    );
    final request = ReportRequest(
      from: DateTime(2026, 10, 20, 23),
      to: DateTime(2026, 10, 22, 1),
      zone: ' UTC ',
    );
    expect(request.toJson()['du'], '2026-10-20');
    expect(request.toJson()['au'], '2026-10-22');
    expect(request.zone, 'UTC');
  });
  test(
    'withdrawn consent blocks even a PDF previously cached in this session',
    () async {
      var calls = 0;
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/mobile/me')) {
            return jsonResponse(
              jsonEncode({...patientFixture(), 'consentementAccepte': false}),
              200,
            );
          }
          calls++;
          return http.Response('%PDF-1.4\nFictif\n%%EOF', 200);
        },
      );
      final api = ConsultationReportsApi(session);
      addTearDown(api.dispose);
      await api.pdf('report-a');
      await session.refreshProfile();
      await expectLater(api.pdf('report-a'), throwsException);
      expect(calls, 1);
    },
  );
  test(
    'generation keeps civil dates, explicit timezone and retry reference',
    () async {
      final calls = <http.Request>[];
      final session = await signedInSession(
        handler: (r) async {
          calls.add(r);
          return jsonResponse('{"id":"report-a"}', 201);
        },
      );
      final api = ConsultationReportsApi(session);
      final request = ReportRequest(
        from: DateTime(2026, 10, 20),
        to: DateTime(2026, 10, 22),
        zone: 'Africa/Lome',
      );
      await api.generate(request);
      await api.generate(request);
      expect(calls.last.url.path, endsWith('/mobile/me/rapports-consultation'));
      expect(jsonDecode(calls.first.body), jsonDecode(calls.last.body));
      expect(jsonDecode(calls.last.body), containsPair('du', '2026-10-20'));
      expect(
        jsonDecode(calls.last.body),
        containsPair('fuseau', 'Africa/Lome'),
      );
      expect(calls.last.headers['authorization'], 'Bearer test-token');
    },
  );
  test(
    'download is authenticated, validates PDF and reuses bytes for uncertain copy',
    () async {
      var uploads = 0, downloads = 0;
      final bodies = <String>[];
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/pdf')) {
            downloads++;
            return http.Response('%PDF-1.4\ncontenu fictif\n%%EOF', 200);
          }
          if (r.url.path.endsWith('/documents')) {
            uploads++;
            bodies.add(r.body);
            if (uploads == 1) {
              return jsonResponse('{"detail":"Réponse incertaine"}', 503);
            }
            return jsonResponse('{"id":"doc-a"}', 201);
          }
          return jsonResponse('{}', 200);
        },
      );
      final api = ConsultationReportsApi(session);
      final report = {
        'id': 'report-a',
        'du': '2026-10-20',
        'au': '2026-10-22',
        'genereLe': '2026-10-23T08:00:00Z',
      };
      await expectLater(api.depositCopy(report), throwsException);
      expect((await api.depositCopy(report))['id'], 'doc-a');
      expect(downloads, 1);
      expect(uploads, 2);
      String field(String body, String name) => RegExp(
        'name="$name"\\r\\n\\r\\n([^\\r]+)',
      ).firstMatch(body)!.group(1)!;
      expect(field(bodies.first, 'sourceRef'), field(bodies.last, 'sourceRef'));
      expect(field(bodies.first, 'typeDocument'), 'COMPTE_RENDU');
      expect(field(bodies.first, 'dateDocument'), '2026-10-23');
    },
  );
  test(
    'old page cannot issue requests or return bytes in replacement session',
    () async {
      final pending = Completer<http.Response>();
      var calls = 0;
      final session = await signedInSession(
        handler: (r) {
          calls++;
          return pending.future;
        },
      );
      final api = ConsultationReportsApi(session);
      final future = api.pdf('report-a');
      final assertion = expectLater(future, throwsException);
      session.clear();
      pending.complete(http.Response('%PDF-1.4\n%%EOF', 200));
      await assertion;
      await expectLater(api.list(), throwsException);
      expect(calls, 1);
    },
  );
  test('invalid binary is never exposed as a PDF', () async {
    final session = await signedInSession(
      handler: (r) async => jsonResponse('{"erreur":"pas un PDF"}', 200),
    );
    await expectLater(
      ConsultationReportsApi(session).pdf('report-a'),
      throwsException,
    );
  });
}
