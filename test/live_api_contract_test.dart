// Explicit opt-in only: requires the local isolated backend and dummy test fixtures.
import 'dart:convert';
import 'dart:io';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class _RecordedClient extends http.BaseClient {
  final http.Client delegate = IOClient(HttpClient());
  String? bearer;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    bearer = request.headers['Authorization'] ?? bearer;
    return delegate.send(request);
  }

  @override
  void close() => delegate.close();
}

void main() {
  test(
    'LIVE patient adapter profile, six measures, conversation, notifications and revoked logout',
    () async {
      final secrets =
          jsonDecode(
                await File(
                  '../.maintenance/runtime-secrets.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final fixture =
          jsonDecode(
                await File('../.maintenance/smoke-state.json').readAsString(),
              )
              as Map<String, dynamic>;
      final client = _RecordedClient();
      final session = ApiSession(
        baseUrl: 'http://127.0.0.1:8080/api/v1',
        client: client,
      );
      addTearDown(session.dispose);
      await session.login(
        fixture['patientEmail'] as String,
        secrets['APP_DEMO_PASSWORD'] as String,
      );
      await session.refreshProfile();
      expect(session.userId, fixture['patientId']);
      expect(session.profile?['consentementAccepte'], isTrue);
      await session.saveProfile({'ville': session.profile?['ville']});
      final unique = 'mobile-live-${DateTime.now().microsecondsSinceEpoch}';
      const measurements = [
        ('GLYCEMIE', 107.0, 'mg/dL', null),
        ('TENSION_ARTERIELLE', 120.0, 'mmHg', 80.0),
        ('POIDS', 70.0, 'kg', null),
        ('FREQUENCE_CARDIAQUE', 72.0, 'bpm', null),
        ('TEMPERATURE', 36.7, '°C', null),
        ('SPO2', 98.0, '%', null),
      ];
      for (final m in measurements) {
        final saved = await session.request(
          'POST',
          '/mobile/me/mesures',
          body: {
            'typeMesure': m.$1,
            'valeurPrincipale': m.$2,
            'unite': m.$3,
            if (m.$4 != null) 'valeurSecondaire': m.$4,
            'dateMesure': DateTime.now().toUtc().toIso8601String(),
            'sourceRef': '$unique-${m.$1}',
          },
        );
        expect(saved['typeMesure'], m.$1);
        expect(saved['patientId'], fixture['patientId']);
      }
      final history = await session.all('/mobile/me/mesures');
      for (final m in measurements) {
        expect(history.any((r) => r['sourceRef'] == '$unique-${m.$1}'), isTrue);
      }
      final doctors = await session.all('/mobile/me/professionnels');
      expect(doctors.any((r) => r['id'] == fixture['doctorId']), isTrue);
      final conversation = await session.request(
        'POST',
        '/mobile/conversations',
        body: {'professionnelId': fixture['doctorId']},
      );
      final id = conversation['id'];
      final sent = await session.request(
        'POST',
        '/mobile/conversations/$id/messages',
        body: {'contenu': 'Validation adaptateur mobile $unique'},
      );
      final messages = await session.all('/mobile/conversations/$id/messages');
      expect(messages.any((r) => r['id'] == sent['id']), isTrue);
      await session.request('POST', '/mobile/conversations/$id/lecture');
      await session.all('/mobile/me/notifications');
      await session.all('/mobile/me/alertes');
      final bearer = client.bearer!;
      await session.logout();
      expect(session.authenticated, isFalse);
      final response = await client.delegate.get(
        Uri.parse('http://127.0.0.1:8080/api/v1/mobile/me'),
        headers: {'Authorization': bearer},
      );
      expect(response.statusCode, 401);
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_API_TEST'),
  );
}
