import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ecare_plus_mobile/services/server_calls.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'support/api_fixture.dart';

void main() {
  test(
    'call transitions and access use backend, stable source and private token',
    () async {
      final calls = <http.Request>[];
      final api = await signedInSession(
        handler: (r) async {
          calls.add(r);
          return jsonResponse('{}', 200);
        },
      );
      final service = ServerCalls(api);
      await service.create('c', 'AUDIO', 'same');
      expect(jsonDecode(calls.last.body), {
        'type': 'AUDIO',
        'sourceRef': 'same',
      });
      await service.action('call', 'acceptation');
      expect(calls.last.url.path, endsWith('/appels/call/acceptation'));
      await service.connection('call');
      expect(calls.last.headers['Authorization'], 'Bearer test-token');
    },
  );
  test('503 provider failure remains visible', () async {
    final api = await signedInSession(
      handler: (_) async =>
          jsonResponse('{"detail":"Service non configuré"}', 503),
    );
    await expectLater(
      ServerCalls(api).create('c', 'VIDEO', 'key'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
    );
  });
}
