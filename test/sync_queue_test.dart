import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecare_plus_mobile/services/sync_queue.dart';
import 'support/api_fixture.dart';

void main() {
  test(
    'direct intake conflict remains visible and is never converted to a new batch key',
    () async {
      final paths = <String>[];
      final api = await signedInSession(
        handler: (r) async {
          paths.add(r.url.path);
          return jsonResponse('{"detail":"Version modifiée"}', 409);
        },
      );
      final queue = SyncQueue(api);
      addTearDown(queue.dispose);
      queue.enqueueDirectReply('reply-1', 'occurrence', {
        'sourceRef': 'reply-1',
        'version': 2,
        'action': 'PRIS',
      });
      await queue.flush();
      expect(paths.single, endsWith('/prises/occurrence/reponse'));
      expect(queue.pending.length, 1);
      expect(queue.results['reply-1']?['statut'], 'CONFLIT');
    },
  );
  test(
    'uncertain direct measurement retries original route and key, never a batch-derived key',
    () async {
      final calls = <String>[];
      final api = await signedInSession(
        handler: (r) async {
          calls.add(r.url.path);
          expect(jsonDecode(r.body)['sourceRef'], 'original-key');
          return jsonResponse('{"id":"saved"}', 201);
        },
      );
      final queue = SyncQueue(api);
      addTearDown(queue.dispose);
      queue.enqueueDirectMeasurement('original-key', {
        'sourceRef': 'original-key',
        'unite': 'kg',
      });
      await queue.flush();
      expect(calls.single, endsWith('/mobile/me/mesures'));
      expect(queue.pending, isEmpty);
    },
  );
  test(
    'partial acknowledgement removes only successes and retains conflicts',
    () async {
      final api = await signedInSession(
        handler: (r) async {
          final body = jsonDecode(r.body);
          expect(body['elements'][0]['versionSchema'], 1);
          return jsonResponse(
            '{"elements":[{"identifiantLocal":"a","typeOperation":"CREER_MESURE","statut":"SUCCES","ressourceId":"server-a"},{"identifiantLocal":"b","typeOperation":"REPONDRE_PRISE","statut":"CONFLIT","message":"Version modifiée"}]}',
            200,
          );
        },
      );
      final queue = SyncQueue(api);
      addTearDown(queue.dispose);
      queue.enqueue('a', 'CREER_MESURE', {'unite': 'kg'});
      queue.enqueue('b', 'REPONDRE_PRISE', {'action': 'PRIS'});
      await queue.flush();
      expect(queue.pending.length, 1);
      expect(queue.pending.single['identifiantLocal'], 'b');
      expect(queue.results['b']?['statut'], 'CONFLIT');
      api.clear();
      expect(queue.pending, isEmpty);
    },
  );
  test(
    'network failure retains exact operation and changed payload under same key conflicts',
    () async {
      final api = await signedInSession(
        handler: (_) async => throw Exception('offline'),
      );
      final queue = SyncQueue(api);
      addTearDown(queue.dispose);
      queue.enqueue('a', 'CREER_MESURE', {'unite': 'kg'});
      expect(
        () => queue.enqueue('a', 'CREER_MESURE', {'unite': 'lb'}),
        throwsStateError,
      );
      await expectLater(queue.flush(), throwsException);
      expect(queue.pending.single['contenu'], {'unite': 'kg'});
    },
  );
}
