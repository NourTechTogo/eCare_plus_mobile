import '../services/api_session.dart';

class PersonalAppointment {
  final String id, patientId, motif, fuseau, status;
  final String? professional, location, comment, reminderId;
  final DateTime date;
  final DateTime? reminderAt;
  final int version;
  final int? reminderMinutes;
  const PersonalAppointment._(
    this.id,
    this.patientId,
    this.motif,
    this.date,
    this.fuseau,
    this.status,
    this.professional,
    this.location,
    this.comment,
    this.version,
    this.reminderMinutes,
    this.reminderId,
    this.reminderAt,
  );
  bool get cancelled => status == 'ANNULE';
  factory PersonalAppointment.fromServer(
    Map<String, dynamic> json,
    String owner,
  ) {
    try {
      final id = json['id'] as String,
          motif = json['motif'] as String,
          zone = json['fuseau'] as String,
          status = json['statut'] as String;
      final version = json['version'] as int;
      if (id.isEmpty ||
          motif.isEmpty ||
          zone.isEmpty ||
          version < 0 ||
          json['patientId'] != owner ||
          json['personnel'] != true ||
          !const [
            'PLANIFIE',
            'CONFIRME',
            'REPORTE',
            'ANNULE',
            'REALISE',
          ].contains(status)) {
        throw const FormatException();
      }
      DateTime instant(String value) {
        if (!RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value)) {
          throw const FormatException();
        }
        return DateTime.parse(value).toUtc();
      }

      final minutes = json['rappelMinutes'] as int?;
      if (minutes != null && (minutes < 0 || minutes > 10080)) {
        throw const FormatException();
      }
      return PersonalAppointment._(
        id,
        owner,
        motif,
        instant(json['dateHeure'] as String),
        zone,
        status,
        json['professionnelNom'] as String?,
        json['lieu'] as String?,
        json['commentaire'] as String?,
        version,
        minutes,
        json['rappelId'] as String?,
        json['rappelLe'] == null ? null : instant(json['rappelLe'] as String),
      );
    } catch (_) {
      throw const ApiException(
        'Réponse d’agenda invalide. Actualisez votre agenda.',
      );
    }
  }
}
