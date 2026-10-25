import 'package:flutter/foundation.dart';
import 'doctor_message.dart';
import '../services/api_session.dart';
import '../services/sync_queue.dart';

enum NotificationCategory { medication, appointment, measurement, alert }

class CareNotification {
  final String title;
  final String message;
  final DateTime date;
  final NotificationCategory category;
  const CareNotification({
    required this.title,
    required this.message,
    required this.date,
    required this.category,
  });
}

class CareAppointment {
  final String doctor;
  final DateTime date;
  const CareAppointment({required this.doctor, required this.date});
}

class GlucoseReading {
  final double value;
  final DateTime date;
  const GlucoseReading({required this.value, required this.date});
}

class BloodPressureReading {
  final double systolic;
  final double diastolic;
  final DateTime date;
  const BloodPressureReading({
    required this.systolic,
    required this.diastolic,
    required this.date,
  });
}

/// Local session data until the patient services are connected.
class CareData extends ChangeNotifier {
  SyncQueue? syncQueue;
  ApiSession? _session;
  String? _account;
  String? syncError;
  List<Map<String, dynamic>> measurements = [];
  void bind(ApiSession session) {
    _session = session;
    final account = session.authenticated ? session.userId : null;
    if (_account == account) return;
    syncQueue?.removeListener(notifyListeners);
    syncQueue?.dispose();
    syncQueue = account == null ? null : SyncQueue(session);
    syncQueue?.addListener(notifyListeners);
    _account = account;
    clear();
    if (account != null) refresh();
  }

  Future<void> refresh() async {
    final session = _session;
    if (session == null || !session.authenticated) return;
    final generation = session.generation;
    try {
      final rows = await session.all('/mobile/me/mesures');
      if (generation != session.generation) return;
      measurements = rows;
      _readings.clear();
      _bloodPressureReadings.clear();
      for (final row in rows) {
        final date = DateTime.parse(row['dateMesure'] as String).toLocal();
        final value = (row['valeurPrincipale'] as num).toDouble();
        if (row['typeMesure'] == 'GLYCEMIE') {
          _readings.add(GlucoseReading(value: value, date: date));
        } else if (row['typeMesure'] == 'TENSION_ARTERIELLE') {
          _bloodPressureReadings.add(
            BloodPressureReading(
              systolic: value,
              diastolic: (row['valeurSecondaire'] as num).toDouble(),
              date: date,
            ),
          );
        }
      }
      _readings.sort((a, b) => b.date.compareTo(a.date));
      _bloodPressureReadings.sort((a, b) => b.date.compareTo(a.date));
      syncError = null;
    } catch (e) {
      if (generation != session.generation) return;
      syncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> submitMeasurement(
    String type,
    double value,
    String unit, {
    double? secondary,
    DateTime? date,
    String? sourceRef,
  }) async {
    final session = _session;
    if (session == null) {
      throw const ApiException('Connectez-vous pour transmettre une mesure.');
    }
    final key =
        sourceRef ?? 'measurement-${DateTime.now().microsecondsSinceEpoch}';
    final body = <String, dynamic>{
      'typeMesure': type,
      'valeurPrincipale': value,
      'valeurSecondaire': ?secondary,
      'unite': unit,
      'dateMesure': (date ?? DateTime.now()).toUtc().toIso8601String(),
      'sourceRef': key,
    };
    try {
      await session.request('POST', '/mobile/me/mesures', body: body);
    } on ApiException catch (e) {
      if (e.status == null || e.status == 503) {
        syncQueue?.enqueueDirectMeasurement(key, body);
        throw const ApiException(
          'Transmission non confirmée. Mesure conservée dans la file de cette session : ouvrez Paramètres > Synchronisation pour réessayer avant de fermer l’application.',
        );
      }
      rethrow;
    }
    await refresh();
  }

  @override
  void dispose() {
    syncQueue?.removeListener(notifyListeners);
    syncQueue?.dispose();
    super.dispose();
  }

  final Map<String, List<DoctorMessage>> _conversations = {};
  final Set<String> _blockedDoctors = {};

  List<DoctorMessage> messagesFor(String doctor) =>
      List.unmodifiable(_conversations[doctor] ?? const <DoctorMessage>[]);

  void addDoctorMessage(String doctor, DoctorMessage message) {
    if (isDoctorBlocked(doctor)) return;
    (_conversations[doctor] ??= []).add(message);
    notifyListeners();
  }

  bool isDoctorBlocked(String doctor) => _blockedDoctors.contains(doctor);

  void toggleDoctorBlocked(String doctor) {
    if (!_blockedDoctors.remove(doctor)) _blockedDoctors.add(doctor);
    notifyListeners();
  }

  void clearConversation(String doctor) {
    _conversations.remove(doctor);
    notifyListeners();
  }

  final List<CareAppointment> _appointments = [];
  final List<CareNotification> _notifications = [];
  final List<GlucoseReading> _readings = [];
  final List<BloodPressureReading> _bloodPressureReadings = [];
  bool remindersEnabled = true;
  Uint8List? _profilePhoto;
  Uint8List? get profilePhoto => _profilePhoto;

  void setProfilePhoto(Uint8List bytes) {
    _profilePhoto = Uint8List.fromList(bytes).asUnmodifiableView();
    notifyListeners();
  }

  List<CareNotification> get notifications {
    final items = [
      ..._notifications.where(
        (item) =>
            remindersEnabled ||
            item.category != NotificationCategory.appointment,
      ),
      for (final appointment
          in remindersEnabled ? _appointments : <CareAppointment>[])
        CareNotification(
          title: appointment.doctor,
          message: 'Rendez-vous dans votre agenda personnel',
          date: appointment.date,
          category: NotificationCategory.appointment,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(items);
  }

  void addNotification(CareNotification notification) {
    _notifications.add(notification);
    notifyListeners();
  }

  List<CareAppointment> get appointments => List.unmodifiable(_appointments);
  List<GlucoseReading> get readings => List.unmodifiable(_readings);
  List<BloodPressureReading> get bloodPressureReadings =>
      List.unmodifiable(_bloodPressureReadings);

  void addAppointment(CareAppointment appointment) {
    _appointments.add(appointment);
    _appointments.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  void removeAppointment(CareAppointment appointment) {
    _appointments.remove(appointment);
    notifyListeners();
  }

  void addReading(double value, {DateTime? date}) {
    _readings.add(GlucoseReading(value: value, date: date ?? DateTime.now()));
    _readings.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void addBloodPressure(double systolic, double diastolic, {DateTime? date}) {
    _bloodPressureReadings.add(
      BloodPressureReading(
        systolic: systolic,
        diastolic: diastolic,
        date: date ?? DateTime.now(),
      ),
    );
    _bloodPressureReadings.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void setReminders(bool value) {
    remindersEnabled = value;
    notifyListeners();
  }

  void clear() {
    measurements = [];
    syncError = null;
    _conversations.clear();
    _blockedDoctors.clear();
    _profilePhoto = null;
    _appointments.clear();
    _notifications.clear();
    _readings.clear();
    _bloodPressureReadings.clear();
    remindersEnabled = true;
    notifyListeners();
  }
}
