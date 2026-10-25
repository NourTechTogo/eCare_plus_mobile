import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'package:ecare_plus_mobile/services/document_library.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/models/medical_document.dart';
import 'support/api_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const dto = {
    'id': 'doc-1',
    'titre': 'Bilan',
    'nomOriginal': 'bilan.pdf',
    'tailleOctets': 6,
    'dateDocument': '2026-10-25',
    'typeDocument': 'RESULTAT_ANALYSE',
  };
  test(
    'remote library uploads authenticated multipart and downloads private bytes',
    () async {
      final requests = <http.Request>[];
      final api = await signedInSession(
        handler: (r) async {
          requests.add(r);
          if (r.url.path.endsWith('/contenu')) {
            return http.Response.bytes([37, 80, 68, 70, 45, 49], 200);
          }
          if (r.method == 'POST') return jsonResponse(jsonEncode(dto), 201);
          if (r.method == 'DELETE') return http.Response('', 204);
          return jsonResponse(
            jsonEncode({
              'content': [dto],
              'totalPages': 1,
            }),
            200,
          );
        },
      );
      final library = DocumentLibrary(session: api, patientId: api.userId);
      addTearDown(library.dispose);
      await library.load();
      final item = await library.importFile(
        XFile.fromData(
          Uint8List.fromList([37, 80, 68, 70, 45, 49]),
          path: 'bilan.pdf',
          name: 'bilan.pdf',
        ),
        title: 'Bilan',
        category: DocumentCategory.results,
        conditions: {},
        date: DateTime(2026, 10, 25),
      );
      final upload = requests.singleWhere((r) => r.method == 'POST');
      expect(upload.headers['Authorization'], 'Bearer test-token');
      expect(
        upload.headers.containsKey('Cache-Control'),
        false,
        reason:
            'La réponse serveur porte no-store ; un header de requête superflu est refusé par CORS.',
      );
      expect(
        upload.headers['content-type'],
        startsWith('multipart/form-data;'),
      );
      expect(upload.body, contains('name="typeDocument"'));
      expect(upload.body, contains('RESULTAT_ANALYSE'));
      expect(upload.body, contains('name="sourceRef"'));
      expect(upload.body, contains('content-type: application/pdf'));
      expect(await library.read(item), [37, 80, 68, 70, 45, 49]);
      await library.remove(item);
      expect(library.documents, isEmpty);
    },
  );
  test('private binary ignores an old session response', () async {
    final pending = Completer<http.Response>();
    final api = await signedInSession(handler: (_) => pending.future);
    final future = api.bytes('/mobile/me/documents/doc-1/contenu');
    final assertion = expectLater(future, throwsA(isA<ApiException>()));
    api.clear();
    pending.complete(http.Response.bytes([1, 2], 200));
    await assertion;
  });
  test(
    'remote formats match backend and 413 error remains meaningful',
    () async {
      final api = await signedInSession(
        handler: (_) async =>
            jsonResponse('{"detail":"Fichier trop volumineux"}', 413),
      );
      await expectLater(
        api.upload(
          '/mobile/me/documents',
          bytes: Uint8List(1),
          fileName: 'a.pdf',
          fields: {},
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 413)),
      );
    },
  );
}
