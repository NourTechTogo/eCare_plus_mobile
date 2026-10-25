import 'api_session.dart';

bool activeServerCall(Map<String, dynamic> call) =>
    ['PREPARATION', 'EN_ATTENTE', 'ACCEPTE'].contains(call['statut']);

class ServerCalls {
  final ApiSession api;
  ServerCalls(this.api);
  Future<Map<String, dynamic>> _map(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async => Map<String, dynamic>.from(
    await api.request(method, path, body: body) as Map,
  );
  Future<List<Map<String, dynamic>>> history(String conversation) async {
    final page = await _map(
      'GET',
      '/mobile/conversations/$conversation/appels?page=0&size=30&sort=dateCreation,desc',
    );
    return (page['content'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Future<Map<String, dynamic>> create(
    String conversation,
    String type,
    String source,
  ) => _map(
    'POST',
    '/mobile/conversations/$conversation/appels',
    body: {'type': type, 'sourceRef': source},
  );
  Future<Map<String, dynamic>> action(String id, String action) =>
      _map('POST', '/appels/$id/$action');
  Future<Map<String, dynamic>> connection(String id) =>
      _map('GET', '/appels/$id/connexion');
}
