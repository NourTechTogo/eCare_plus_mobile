import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:file_selector/file_selector.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/services/care_api.dart';
import 'package:ecare_plus_mobile/services/document_library.dart';
import 'package:ecare_plus_mobile/models/medical_document.dart';
import 'package:ecare_plus_mobile/services/server_calls.dart';

void main() {
  test(
    'LIVE new Flutter adapters use the same isolated backend and private files',
    () async {
      final fixture =
          jsonDecode(
                await File(
                  '../.maintenance/integration-clients/fixture.json',
                ).readAsString(),
              )
              as Map;
      final secrets =
          jsonDecode(
                await File(
                  '../.maintenance/runtime-secrets.json',
                ).readAsString(),
              )
              as Map;
      final api = ApiSession(
        baseUrl: 'http://127.0.0.1:8081/api/v1',
        client: IOClient(HttpClient()),
      );
      addTearDown(api.dispose);
      await api.login(
        fixture['patientEmail'] as String,
        secrets['APP_DEMO_PASSWORD'] as String,
      );
      final library = DocumentLibrary(session: api, patientId: api.userId);
      addTearDown(library.dispose);
      await library.load();
      expect(library.documents.any((d) => d.id == fixture['documentId']), true);
      final bytes = Uint8List.fromList(utf8.encode('%PDF-1.4\n%%EOF\n'));
      final doc = await library.importFile(
        XFile.fromData(
          bytes,
          name: 'flutter-live.pdf',
          path: 'flutter-live.pdf',
        ),
        title: 'Document Flutter fictif',
        category: DocumentCategory.other,
        conditions: {},
        date: DateTime.now(),
      );
      expect(await library.read(doc), bytes);
      final care = CareApi(api),
          day = DateTime.parse(fixture['today'] as String);
      final planning = await care.planning(day, day);
      expect((planning['occurrences'] as List).isNotEmpty, true);
      final occurrence = Map<String, dynamic>.from(
        (planning['occurrences'] as List).first as Map,
      );
      final response = await care.reply(
        occurrence,
        'PRIS',
        sourceRef: 'flutter-live-${DateTime.now().microsecondsSinceEpoch}',
        dateAction: DateTime.now(),
      );
      expect(response['statut'], 'PRISE');
      expect(
        (await care.observance(day, day))['prisesConfirmees'],
        greaterThan(0),
      );
      final reference = await care.reference();
      expect(reference['jeton'], isNotEmpty);
      final history = await api.all(
        '/mobile/conversations/${fixture['conversationId']}/messages',
      );
      expect(
        history.any((m) => (m['piecesJointes'] as List? ?? []).isNotEmpty),
        true,
      );
      await expectLater(
        ServerCalls(api).create(
          fixture['conversationId'] as String,
          'AUDIO',
          'flutter-live-call-${DateTime.now().microsecondsSinceEpoch}',
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
      await care.preferences();
      await api.all('/compte/notifications');
      await library.remove(doc);
      await api.logout();
      expect(api.authenticated, false);
    },
    skip: !const bool.fromEnvironment('RUN_CLIENTS_LIVE_TEST'),
  );
}
