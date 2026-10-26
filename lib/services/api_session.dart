import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const legalDocumentVersion = '2026-10-25';

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// JWT intentionally stays in memory. A restart requires authentication again.
class ApiSession extends ChangeNotifier {
  final http.Client client;
  final String baseUrl;
  String? _token;
  DateTime? _expires;
  Timer? _expiryTimer;
  int _generation = 0;
  bool _disposed = false;
  Map<String, dynamic>? profile;
  ApiSession({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl =
          baseUrl ?? const String.fromEnvironment('API_URL', defaultValue: '') {
    if (this.baseUrl.isNotEmpty && !Uri.parse(this.baseUrl).hasScheme) {
      throw ArgumentError('API_URL doit être une URL absolue');
    }
  }
  String get endpoint => baseUrl.isNotEmpty
      ? baseUrl.replaceAll(RegExp(r'/$'), '')
      : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8080/api/v1'
            : 'http://localhost:8080/api/v1');
  bool get authenticated =>
      _token != null && _expires != null && DateTime.now().isBefore(_expires!);
  int get generation => _generation;
  String? get userId => profile?['id'] as String?;

  Future<http.Response> _transfer(http.BaseRequest req) async {
    if (_disposed || !authenticated) {
      throw const ApiException(
        'Votre session a expiré. Reconnectez-vous.',
        401,
      );
    }
    final generation = _generation;
    req.headers['Authorization'] = 'Bearer $_token';
    try {
      final response = await http.Response.fromStream(
        await client.send(req),
      ).timeout(const Duration(seconds: 30));
      if (_disposed || generation != _generation) {
        throw const ApiException('Session remplacée. Reconnectez-vous.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) clear();
        dynamic problem;
        try {
          problem = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {}
        throw ApiException(
          problem is Map
              ? '${problem['detail'] ?? problem['title'] ?? 'Transfert refusé'}'
              : 'Transfert refusé (${response.statusCode}).',
          response.statusCode,
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Connexion impossible. Réessayez le transfert.');
    }
  }

  Future<Map<String, dynamic>> upload(
    String path, {
    required Uint8List bytes,
    required String fileName,
    required Map<String, String> fields,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$endpoint$path'));
    req.fields.addAll(fields);
    final ext = fileName.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'wav'
          when RegExp(
            r'^/mobile/conversations/[^/]+/pieces-jointes$',
          ).hasMatch(path) =>
        'audio/wav',
      _ => throw const ApiException('Formats autorisés : PDF, JPG et PNG.'),
    };
    req.files.add(
      http.MultipartFile.fromBytes(
        'fichier',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mime),
      ),
    );
    final response = await _transfer(req);
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map,
    );
  }

  Future<Uint8List> bytes(String path) async => (await _transfer(
    http.Request('GET', Uri.parse('$endpoint$path')),
  )).bodyBytes;

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool public = false,
  }) async {
    if (_disposed) throw const ApiException('Session fermée.');
    final generation = _generation;
    final token = _token;
    if (!public && !authenticated) {
      clear();
      throw const ApiException(
        'Votre session a expiré. Reconnectez-vous.',
        401,
      );
    }
    try {
      final req = http.Request(method, Uri.parse('$endpoint$path'));
      req.headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        if (!public) 'Authorization': 'Bearer $token',
      });
      if (body != null) req.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await client.send(req).timeout(const Duration(seconds: 20)),
      );
      if (generation != _generation) {
        throw const ApiException('Session remplacée. Reconnectez-vous.');
      }
      dynamic data;
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {
          data = null;
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401 && !public) clear();
        final errors = data is Map ? data['erreurs'] : null;
        final fields = errors is List
            ? errors
                  .whereType<Map>()
                  .map((e) => '${e['champ']}: ${e['message']}')
                  .join('\n')
            : '';
        throw ApiException(
          fields.isNotEmpty
              ? fields
              : data is Map
              ? '${data['detail'] ?? data['title'] ?? 'Requête refusée'}'
              : 'Service indisponible (${response.statusCode}).',
          response.statusCode,
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Connexion impossible. Vérifiez le réseau et réessayez.',
      );
    }
  }

  Future<void> login(String identifier, String password) async {
    clear();
    final data = await request(
      'POST',
      '/auth/connexion',
      public: true,
      body: {'identifiant': identifier.trim(), 'motDePasse': password},
    );
    final expires = DateTime.parse(data['expireLe'] as String);
    if (!expires.isAfter(DateTime.now())) {
      throw const ApiException('Session expirée.');
    }
    _token = data['jeton'] as String;
    _expires = expires;
    profile = Map<String, dynamic>.from(data['profil'] as Map);
    _expiryTimer = Timer(expires.difference(DateTime.now()), clear);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final generation = _generation;
    final response = await request('GET', '/mobile/me');
    if (_disposed || generation != _generation) {
      throw const ApiException('Session remplacée.');
    }
    profile = Map<String, dynamic>.from(response as Map);
    notifyListeners();
  }

  Future<void> saveProfile(Map<String, dynamic> values) async {
    final generation = _generation;
    await request('PATCH', '/mobile/me', body: values);
    if (_disposed || generation != _generation) {
      throw const ApiException('Session remplacée.');
    }
    await refreshProfile();
  }

  Future<void> consent() async {
    await request(
      'POST',
      '/mobile/me/consentement',
      body: {
        'versionDocument': legalDocumentVersion,
        'cguLues': true,
        'confidentialiteLue': true,
        'accepte': true,
      },
    );
    await refreshProfile();
  }

  Future<List<Map<String, dynamic>>> all(String path) async {
    final generation = _generation;
    final items = <Map<String, dynamic>>[];
    var page = 0;
    while (true) {
      if (generation != _generation) {
        throw const ApiException('Session remplacée.');
      }
      final data = await request(
        'GET',
        '$path${path.contains('?') ? '&' : '?'}page=$page&size=100',
      );
      if (_disposed || generation != _generation) {
        throw const ApiException('Session remplacée.');
      }
      final list = data is List ? data : data['content'] as List;
      items.addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
      if (data is List ||
          data['last'] == true ||
          page + 1 >= (data['totalPages'] as int? ?? 1)) {
        break;
      }
      page++;
    }
    return items;
  }

  Future<void> logout() async {
    final generation = _generation;
    try {
      if (authenticated) await request('POST', '/auth/deconnexion');
    } finally {
      if (!_disposed && generation == _generation) clear();
    }
  }

  void clear() {
    if (_disposed) return;
    _generation++;
    _expiryTimer?.cancel();
    _token = null;
    _expires = null;
    profile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _expiryTimer?.cancel();
    client.close();
    super.dispose();
  }
}
