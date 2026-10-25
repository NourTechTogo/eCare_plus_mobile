import 'dart:convert';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> patientFixture() => {
  'id': 'patient-a',
  'numeroPatient': 'P001',
  'nom': 'Dupont',
  'prenoms': 'Gloria',
  'email': 'gloria@example.com',
  'telephone': '+22890123456',
  'sexe': 'FEMININ',
  'dossierId': 'dossier-a',
  'professionnelId': 'doctor-a',
  'consentementAccepte': true,
};
ApiSession testSession({
  Future<http.Response> Function(http.Request)? handler,
}) => ApiSession(
  baseUrl: 'https://test.invalid/api/v1',
  client: MockClient((request) async {
    if (request.url.path.endsWith('/auth/connexion')) {
      return http.Response(
        jsonEncode({
          'jeton': 'test-token',
          'expireLe': DateTime.now()
              .add(const Duration(hours: 1))
              .toUtc()
              .toIso8601String(),
          'profil': patientFixture(),
        }),
        200,
      );
    }
    if (handler != null) return handler(request);
    if (request.url.path.endsWith('/mobile/me')) {
      return http.Response(jsonEncode(patientFixture()), 200);
    }
    if (request.method == 'POST') return http.Response('{}', 200);
    return http.Response('{"content":[],"totalPages":1}', 200);
  }),
);
Future<ApiSession> signedInSession({
  Future<http.Response> Function(http.Request)? handler,
}) async {
  final session = testSession(handler: handler);
  addTearDown(session.dispose);
  await session.login('gloria@example.com', 'Password123!');
  return session;
}

http.Response jsonResponse(String body, int status) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
