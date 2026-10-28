import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ecare_plus_mobile/services/personal_agenda_api.dart';
import 'support/api_fixture.dart';

Map<String, dynamic> agendaFixture({
  String id = 'event-a',
  int version = 2,
  String status = 'PLANIFIE',
}) => {
  'id': id,
  'patientId': 'patient-a',
  'motif': 'Consultation convenue',
  'dateHeure': '2026-11-12T10:30:00Z',
  'fuseau': 'UTC',
  'lieu': 'Lieu fictif',
  'professionnelNom': null,
  'commentaire': null,
  'statut': status,
  'personnel': true,
  'version': version,
  'rappelMinutes': 60,
  'rappelId': 'reminder-a',
  'rappelLe': '2026-11-12T09:30:00Z',
};
void main() {
  test(
    'create and edit keep an immutable reference, instant, version and optional professional',
    () async {
      final calls = <http.Request>[];
      final session = await signedInSession(
        handler: (r) async {
          calls.add(r);
          return jsonResponse(
            jsonEncode(agendaFixture()),
            r.method == 'POST' ? 201 : 200,
          );
        },
      );
      final api = PersonalAgendaApi(session);
      addTearDown(api.dispose);
      final create = AgendaCommand(
        motif: 'Consultation convenue',
        date: DateTime.utc(2026, 11, 12, 10, 30),
        rappelMinutes: 60,
      );
      await api.save(create);
      await api.save(create);
      expect(jsonDecode(calls.first.body), jsonDecode(calls.last.body));
      expect(
        jsonDecode(calls.last.body),
        containsPair('dateHeure', '2026-11-12T10:30:00.000Z'),
      );
      expect(jsonDecode(calls.last.body)['professionnelNom'], isNull);
      final edit = AgendaCommand(
        motif: 'Motif corrigé',
        date: DateTime.utc(2026, 11, 12, 10, 30),
        id: 'event-a',
        version: 2,
      );
      await api.save(edit);
      expect(calls.last.method, 'PATCH');
      expect(calls.last.url.path, endsWith('/rendez-vous/event-a'));
      expect(jsonDecode(calls.last.body)['version'], 2);
      expect(jsonDecode(calls.last.body)['rappelMinutes'], isNull);
    },
  );
  test(
    'cancellation uses the same source/version on retry and never rewrites a conflict',
    () async {
      final bodies = <Map>[];
      final session = await signedInSession(
        handler: (r) async {
          bodies.add(jsonDecode(r.body) as Map);
          return jsonResponse('{"detail":"Version modifiée"}', 409);
        },
      );
      final api = PersonalAgendaApi(session);
      addTearDown(api.dispose);
      final command = AgendaCancellation(id: 'event-a', version: 3);
      await expectLater(api.cancel(command), throwsException);
      await expectLater(api.cancel(command), throwsException);
      expect(bodies, hasLength(2));
      expect(bodies.first, bodies.last);
      expect(bodies.last['version'], 3);
    },
  );
  test(
    'all pages and actual reminder states are read on private self routes',
    () async {
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/rappels')) {
            return jsonResponse(
              '{"content":[{"id":"reminder-a","statut":"ENVOYE"}],"totalPages":1}',
              200,
            );
          }
          final page = r.url.queryParameters['page'];
          return jsonResponse(
            jsonEncode({
              'content': [agendaFixture(id: page == '0' ? 'a' : 'b')],
              'totalPages': 2,
            }),
            200,
          );
        },
      );
      final api = PersonalAgendaApi(session);
      addTearDown(api.dispose);
      expect((await api.list()).map((e) => e.id), ['a', 'b']);
      expect((await api.reminders())['reminder-a'], 'ENVOYE');
    },
  );
  test(
    'old account and withdrawn consent cannot return or write an appointment',
    () async {
      final pending = Completer<http.Response>();
      var calls = 0;
      final session = await signedInSession(
        handler: (r) {
          calls++;
          return pending.future;
        },
      );
      final api = PersonalAgendaApi(session);
      addTearDown(api.dispose);
      final future = api.list();
      final assertion = expectLater(future, throwsException);
      session.clear();
      pending.complete(
        jsonResponse(
          jsonEncode({
            'content': [agendaFixture()],
            'totalPages': 1,
          }),
          200,
        ),
      );
      await assertion;
      await expectLater(
        api.save(
          AgendaCommand(motif: 'Fictif', date: DateTime.utc(2026, 11, 12)),
        ),
        throwsException,
      );
      expect(calls, 1);
    },
  );
  test(
    'inconsistent personal-owner response is rejected instead of shown',
    () async {
      final session = await signedInSession(
        handler: (r) async => jsonResponse(
          jsonEncode({...agendaFixture(), 'patientId': 'patient-b'}),
          200,
        ),
      );
      final api = PersonalAgendaApi(session);
      addTearDown(api.dispose);
      await expectLater(api.read('event-a'), throwsException);
    },
  );
}
