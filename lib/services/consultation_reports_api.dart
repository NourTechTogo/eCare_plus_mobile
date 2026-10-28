import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'api_session.dart';
import 'care_api.dart' show civilDate;

class ReportRequest {
  final DateTime from, to;
  final String zone, sourceRef;
  ReportRequest({
    required DateTime from,
    required DateTime to,
    required String zone,
  }) : from = DateTime.utc(from.year, from.month, from.day),
       to = DateTime.utc(to.year, to.month, to.day),
       zone = zone.trim(),
       sourceRef = const Uuid().v4() {
    final days = this.to.difference(this.from).inDays + 1;
    if (days < 1 || days > 90 || this.zone.isEmpty || this.zone.length > 80) {
      throw const ApiException(
        'Choisissez une période de 1 à 90 jours et un fuseau IANA.',
      );
    }
  }
  Map<String, dynamic> toJson() => {
    'sourceRef': sourceRef,
    'du': civilDate(from),
    'au': civilDate(to),
    'fuseau': zone,
  };
}

class _CopyDraft {
  final Uint8List bytes;
  final Map<String, String> fields;
  _CopyDraft(this.bytes, this.fields);
}

/// Each instance belongs to one authenticated session and releases transient PDFs on logout.
class ConsultationReportsApi {
  static const root = '/mobile/me/rapports-consultation';
  final ApiSession session;
  final int _generation;
  final String? _owner;
  bool _closed = false;
  String? _pdfId;
  Uint8List? _pdfBytes;
  final _pending = <String, _CopyDraft>{};
  final _sent = <String, Map<String, dynamic>>{};
  ConsultationReportsApi(this.session)
    : _generation = session.generation,
      _owner = session.userId {
    session.addListener(_sessionChanged);
  }
  bool get valid =>
      !_closed &&
      session.authenticated &&
      session.generation == _generation &&
      session.userId == _owner &&
      session.profile?['consentementAccepte'] == true;
  void _check() {
    if (!valid) {
      throw const ApiException('Session modifiée. Reconnectez-vous.', 401);
    }
  }

  void _sessionChanged() {
    if (!valid) {
      _pdfBytes = null;
      _pdfId = null;
      _pending.clear();
      _sent.clear();
    }
  }

  void dispose() {
    _closed = true;
    session.removeListener(_sessionChanged);
    _sessionChanged();
  }

  Future<Map<String, dynamic>> _map(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    _check();
    final result = await session.request(method, path, body: body);
    _check();
    if (result is! Map) {
      throw const ApiException('Réponse de rapport invalide.');
    }
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> generate(ReportRequest request) async {
    final report = await _map('POST', root, body: request.toJson());
    if (report['id'] is! String || (report['id'] as String).isEmpty) {
      throw const ApiException(
        'Génération non confirmée par le serveur. Réessayez.',
      );
    }
    return report;
  }

  Future<Map<String, dynamic>> list({int page = 0}) =>
      _map('GET', '$root?page=$page&size=20');
  Future<Map<String, dynamic>> read(String id) =>
      _map('GET', '$root/${Uri.encodeComponent(id)}');
  static String filename(String id) =>
      'ecare-consultation-${id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf';
  Future<Uint8List> pdf(String id) async {
    _check();
    if (_pdfId == id && _pdfBytes != null) {
      return Uint8List.fromList(_pdfBytes!);
    }
    final data = await session.bytes('$root/${Uri.encodeComponent(id)}/pdf');
    _check();
    if (data.length < 12 ||
        data.length > 16 * 1024 * 1024 ||
        ascii.decode(data.take(5).toList(), allowInvalid: true) != '%PDF-' ||
        !latin1
            .decode(data.sublist(data.length > 1024 ? data.length - 1024 : 0))
            .contains('%%EOF')) {
      throw const ApiException(
        'Le serveur n’a pas renvoyé un PDF valide. Réessayez.',
      );
    }
    _pdfId = id;
    _pdfBytes = Uint8List.fromList(data);
    return Uint8List.fromList(data);
  }

  Future<Map<String, dynamic>> depositCopy(Map<String, dynamic> report) async {
    _check();
    final id = report['id'] as String;
    if (_sent.containsKey(id)) return Map.of(_sent[id]!);
    var draft = _pending[id];
    if (draft == null) {
      if (_pending.length >= 3) {
        throw const ApiException(
          'Réessayez un dépôt en attente avant de transmettre un autre rapport.',
        );
      }
      final bytes = await pdf(id);
      _check();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const ApiException(
          'Le carnet accepte 5 Mo maximum. Téléchargez le PDF ou générez une période plus courte.',
        );
      }
      final date = DateTime.parse(report['genereLe'] as String).toUtc();
      draft = _CopyDraft(bytes, {
        'titre':
            'Synthèse de consultation du ${report['du']} au ${report['au']}',
        'typeDocument': 'COMPTE_RENDU',
        'dateDocument': civilDate(date),
        'sourceRef': 'rapport-${const Uuid().v4()}',
      });
      _pending[id] = draft;
    }
    final document = await session.upload(
      '/mobile/me/documents',
      bytes: draft.bytes,
      fileName: filename(id),
      fields: draft.fields,
    );
    _check();
    if (document['id'] is! String) {
      throw const ApiException('Dépôt non confirmé par le serveur. Réessayez.');
    }
    _pending.remove(id);
    _sent[id] = document;
    return Map.of(document);
  }
}
