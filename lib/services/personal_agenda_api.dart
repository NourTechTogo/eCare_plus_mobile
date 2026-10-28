import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/personal_appointment.dart';
import 'api_session.dart';

class AgendaCommand {
  final String sourceRef, motif;
  final String? id, professional, location, comment;
  final DateTime date;
  final int? version, rappelMinutes;
  AgendaCommand({
    required String motif,
    required DateTime date,
    this.id,
    this.version,
    String? professional,
    String? location,
    String? comment,
    this.rappelMinutes,
  }) : sourceRef = const Uuid().v4(),
       motif = motif.trim(),
       date = date.toUtc(),
       professional = _optional(professional),
       location = _optional(location),
       comment = _optional(comment) {
    if (this.motif.isEmpty ||
        this.motif.length > 200 ||
        (this.professional?.length ?? 0) > 200 ||
        (this.location?.length ?? 0) > 300 ||
        (this.comment?.length ?? 0) > 2000 ||
        (rappelMinutes != null &&
            (rappelMinutes! < 0 || rappelMinutes! > 10080)) ||
        this.date.year < 1 ||
        this.date.year > 9999 ||
        (id == null ? version != null : version == null || version! < 0)) {
      throw const ApiException(
        'Vérifiez le motif, la date et les informations du rendez-vous.',
      );
    }
  }
  static String? _optional(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();
  Map<String, dynamic> toJson() => {
    'sourceRef': sourceRef,
    'motif': motif,
    'dateHeure': date.toIso8601String(),
    'fuseau': 'UTC',
    'professionnelNom': professional,
    'lieu': location,
    'commentaire': comment,
    'rappelMinutes': rappelMinutes,
    if (version != null) 'version': version,
  };
}

class AgendaCancellation {
  final String id, sourceRef;
  final int version;
  AgendaCancellation({required this.id, required this.version})
    : sourceRef = const Uuid().v4() {
    if (id.isEmpty || version < 0) {
      throw const ApiException('Version de rendez-vous invalide.');
    }
  }
  Map<String, dynamic> toJson() => {'sourceRef': sourceRef, 'version': version};
}

class PersonalAgendaApi extends ChangeNotifier {
  static const root = '/mobile/me/rendez-vous';
  final ApiSession session;
  final int _generation;
  final String? _owner;
  bool _closed = false;
  PersonalAgendaApi(this.session)
    : _generation = session.generation,
      _owner = session.userId {
    session.addListener(_changed);
  }
  bool get valid =>
      !_closed &&
      _owner != null &&
      session.authenticated &&
      session.generation == _generation &&
      session.userId == _owner &&
      session.profile?['consentementAccepte'] == true;
  void _check() {
    if (!valid) {
      throw const ApiException(
        'Session ou consentement modifié. Reconnectez-vous.',
        401,
      );
    }
  }

  void _changed() {
    if (!valid && !_closed) notifyListeners();
  }

  PersonalAppointment _entry(dynamic data) {
    if (data is! Map) throw const ApiException('Réponse d’agenda invalide.');
    return PersonalAppointment.fromServer(
      Map<String, dynamic>.from(data),
      _owner!,
    );
  }

  Future<List<PersonalAppointment>> list() async {
    _check();
    final rows = await session.all('$root?inclureAnnules=true');
    _check();
    return rows.map(_entry).toList();
  }

  Future<PersonalAppointment> read(String id) async {
    _check();
    final data = await session.request(
      'GET',
      '$root/${Uri.encodeComponent(id)}',
    );
    _check();
    final entry = _entry(data);
    if (entry.id != id) {
      throw const ApiException('Réponse d’agenda inattendue.');
    }
    return entry;
  }

  Future<PersonalAppointment> save(AgendaCommand command) async {
    _check();
    final data = await session.request(
      command.id == null ? 'POST' : 'PATCH',
      command.id == null ? root : '$root/${Uri.encodeComponent(command.id!)}',
      body: command.toJson(),
    );
    _check();
    final entry = _entry(data);
    if (command.id != null && entry.id != command.id) {
      throw const ApiException(
        'Enregistrement non confirmé. Actualisez votre agenda.',
      );
    }
    return entry;
  }

  Future<PersonalAppointment> cancel(AgendaCancellation command) async {
    _check();
    final data = await session.request(
      'POST',
      '$root/${Uri.encodeComponent(command.id)}/annulation',
      body: command.toJson(),
    );
    _check();
    final entry = _entry(data);
    if (entry.id != command.id || !entry.cancelled) {
      throw const ApiException('Annulation non confirmée. Réessayez.');
    }
    return entry;
  }

  Future<Map<String, String>> reminders() async {
    _check();
    final rows = await session.all('/mobile/me/rappels');
    _check();
    final result = <String, String>{};
    for (final row in rows) {
      if (row['id'] is! String || row['statut'] is! String) {
        throw const ApiException('État des rappels invalide.');
      }
      result[row['id'] as String] = row['statut'] as String;
    }
    return result;
  }

  @override
  void dispose() {
    _closed = true;
    session.removeListener(_changed);
    super.dispose();
  }
}
