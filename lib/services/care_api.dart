import 'api_session.dart';

String civilDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class CareApi {
  final ApiSession session;
  CareApi(this.session);
  Future<Map<String, dynamic>> _map(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async => Map<String, dynamic>.from(
    await session.request(method, path, body: body) as Map,
  );
  Future<Map<String, dynamic>> planning(DateTime from, DateTime to) => _map(
    'GET',
    '/mobile/me/planning-traitements?du=${civilDate(from)}&au=${civilDate(to)}',
  );
  Future<Map<String, dynamic>> observance(DateTime from, DateTime to) => _map(
    'GET',
    '/mobile/me/observance?du=${civilDate(from)}&au=${civilDate(to)}',
  );
  Future<Map<String, dynamic>> reply(
    Map<String, dynamic> occurrence,
    String action, {
    required String sourceRef,
    required DateTime dateAction,
    DateTime? reporteeAu,
  }) => _map(
    'POST',
    '/mobile/me/prises/${occurrence['id']}/reponse',
    body: {
      'action': action,
      'version': occurrence['version'],
      'sourceRef': sourceRef,
      'dateAction': dateAction.toUtc().toIso8601String(),
      if (reporteeAu != null)
        'reporteeAu': reporteeAu.toUtc().toIso8601String(),
    },
  );
  Future<Map<String, dynamic>> preferences() =>
      _map('GET', '/compte/preferences-notifications');
  Future<Map<String, dynamic>> savePreferences({
    required bool push,
    required bool whatsapp,
  }) => _map(
    'PATCH',
    '/compte/preferences-notifications',
    body: {
      'pushActif': push,
      'whatsappActif': whatsapp,
      'versionConsentement': '2026-10-25',
    },
  );
  Future<Map<String, dynamic>> reference() =>
      _map('POST', '/mobile/me/referencements');
  Future<Map<String, dynamic>> deleteRequest() =>
      _map('POST', '/compte/demandes-effacement');
  Future<void> withdrawConsent() async {
    await session.request(
      'POST',
      '/mobile/me/consentement',
      body: {'accepte': false},
    );
    await session.refreshProfile();
  }

  Future<Map<String, dynamic>> sync(
    String device,
    List<Map<String, dynamic>> elements,
  ) => _map(
    'POST',
    '/mobile/me/synchronisations',
    body: {'identifiantAppareil': device, 'elements': elements},
  );
}
