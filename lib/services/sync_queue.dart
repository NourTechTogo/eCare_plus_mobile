import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_session.dart';
import 'care_api.dart';

/// Pending operations remain in this authenticated session only; no health payload
/// is written unencrypted to shared preferences or browser localStorage.
class SyncQueue extends ChangeNotifier {
  final ApiSession api;
  late final String device = 'session-${DateTime.now().microsecondsSinceEpoch}';
  int _generation;
  final Map<String, Map<String, dynamic>> _pending = {};
  final Map<String, String> _directRoutes = {};
  final Map<String, Map<String, dynamic>> results = {};
  bool busy = false, _closed = false;
  SyncQueue(this.api) : _generation = api.generation {
    api.addListener(_sessionChanged);
  }
  List<Map<String, dynamic>> get pending => _pending.values
      .map((r) => Map<String, dynamic>.from(jsonDecode(jsonEncode(r)) as Map))
      .toList();
  String _key(String id, String type) => '$type:$id';
  void _sessionChanged() {
    if (api.generation != _generation) {
      _generation = api.generation;
      _pending.clear();
      _directRoutes.clear();
      results.clear();
      if (!_closed) notifyListeners();
    }
  }

  void enqueueDirectMeasurement(String id, Map<String, dynamic> content) {
    enqueue(id, 'CREER_MESURE', content);
    _directRoutes[_key(id, 'CREER_MESURE')] = '/mobile/me/mesures';
  }

  void enqueueDirectReply(
    String id,
    String occurrenceId,
    Map<String, dynamic> content,
  ) {
    enqueue(id, 'REPONDRE_PRISE', content);
    _directRoutes[_key(id, 'REPONDRE_PRISE')] =
        '/mobile/me/prises/$occurrenceId/reponse';
  }

  void enqueue(String id, String type, Map<String, dynamic> content) {
    if (_closed || !api.authenticated) throw StateError('Session fermée.');
    if (!['CREER_MESURE', 'REPONDRE_PRISE'].contains(type)) {
      throw ArgumentError('Opération inconnue');
    }
    final key = _key(id, type), existing = _pending[key];
    if (existing != null) {
      if (jsonEncode(existing['contenu']) != jsonEncode(content)) {
        throw StateError(
          'Une opération différente attend déjà une réponse sous cette clé.',
        );
      }
      return;
    }
    if (_pending.length >= 100) {
      throw StateError('100 opérations en attente au maximum.');
    }
    _pending[key] = {
      'identifiantLocal': id,
      'typeOperation': type,
      'versionSchema': 1,
      'dateCreationLocale': DateTime.now().toUtc().toIso8601String(),
      'contenu': jsonDecode(jsonEncode(content)),
    };
    notifyListeners();
  }

  Future<void> flush() async {
    if (busy || _pending.isEmpty || _closed) return;
    busy = true;
    final generation = api.generation;
    try {
      // An uncertain response to the direct route MUST retry that route with its
      // original sourceRef; the batch API deliberately derives a different key.
      for (final operation in pending) {
        final id = '${operation['identifiantLocal']}',
            key = _key(id, '${operation['typeOperation']}');
        final route = _directRoutes[key];
        if (route == null) continue;
        dynamic saved;
        try {
          saved = await api.request(
            'POST',
            route,
            body: Map<String, dynamic>.from(operation['contenu'] as Map),
          );
        } on ApiException catch (e) {
          if (e.status != null && ![401, 503].contains(e.status)) {
            results[id] = {
              'identifiantLocal': id,
              'typeOperation': operation['typeOperation'],
              'statut': e.status == 409 ? 'CONFLIT' : 'REJETE',
              'message': e.message,
            };
            continue;
          }
          rethrow;
        }
        if (_closed || generation != api.generation) return;
        results[id] = {
          'identifiantLocal': id,
          'typeOperation': operation['typeOperation'],
          'statut': 'SUCCES',
          'ressourceId': saved['id'],
        };
        _pending.remove(key);
        _directRoutes.remove(key);
      }
      final batch = pending
          .where(
            (o) => !_directRoutes.containsKey(
              _key('${o['identifiantLocal']}', '${o['typeOperation']}'),
            ),
          )
          .toList();
      if (batch.isEmpty) return;
      final result = await CareApi(api).sync(device, batch);
      if (_closed || generation != api.generation) return;
      for (final raw in result['elements'] as List) {
        final r = Map<String, dynamic>.from(raw as Map),
            id = '${r['identifiantLocal']}',
            key = _key(id, '${r['typeOperation']}');
        results[id] = r;
        if (r['statut'] == 'SUCCES') _pending.remove(key);
      }
    } finally {
      busy = false;
      if (!_closed) notifyListeners();
    }
  }

  void discard(String id, String type) {
    _pending.remove(_key(id, type));
    _directRoutes.remove(_key(id, type));
    results.remove(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    api.removeListener(_sessionChanged);
    _pending.clear();
    results.clear();
    super.dispose();
  }
}
