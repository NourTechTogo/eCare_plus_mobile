import 'dart:convert';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'api_fixture.dart';

Future<ApiSession> careSession(CareData data) async {
  final rows = <Map<String, dynamic>>[
    for (final r in data.readings)
      {
        'id': 'g-${r.date.microsecondsSinceEpoch}',
        'typeMesure': 'GLYCEMIE',
        'valeurPrincipale': r.value,
        'unite': 'mg/dL',
        'dateMesure': r.date.toUtc().toIso8601String(),
      },
    for (final r in data.bloodPressureReadings)
      {
        'id': 'p-${r.date.microsecondsSinceEpoch}',
        'typeMesure': 'TENSION_ARTERIELLE',
        'valeurPrincipale': r.systolic,
        'valeurSecondaire': r.diastolic,
        'unite': 'mmHg',
        'dateMesure': r.date.toUtc().toIso8601String(),
      },
  ];
  final session = await signedInSession(
    handler: (r) async {
      if (r.url.path.endsWith('/mobile/me')) {
        return jsonResponse(jsonEncode(patientFixture()), 200);
      }
      if (r.url.path.endsWith('/mesures')) {
        if (r.method == 'POST') {
          rows.add({
            ...jsonDecode(r.body) as Map<String, dynamic>,
            'id': 'server-${rows.length}',
          });
          return jsonResponse(jsonEncode(rows.last), 201);
        }
        return jsonResponse(
          jsonEncode({'content': rows, 'totalPages': 1}),
          200,
        );
      }
      return jsonResponse(
        r.method == 'POST' ? '{}' : '{"content":[],"totalPages":1}',
        200,
      );
    },
  );
  data.bind(session);
  await data.refresh();
  return session;
}
