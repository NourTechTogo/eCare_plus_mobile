import 'package:ecare_plus_mobile/models/personal_appointment.dart';
import 'dart:convert';
import 'package:ecare_plus_mobile/services/personal_agenda_api.dart';
import 'package:ecare_plus_mobile/widgets/appointment_availability_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/api_fixture.dart';
import 'personal_agenda_api_test.dart' show agendaFixture;

void main() {
  testWidgets(
    'Personal form accepts optional professional and confirms after API ACK',
    (tester) async {
      Map<String, dynamic>? sent;
      final session = await signedInSession(
        handler: (r) async {
          sent = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(jsonEncode({...agendaFixture(), ...sent!}), 201);
        },
      );
      final api = PersonalAgendaApi(session);
      addTearDown(api.dispose);
      var saved = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppointmentAvailabilityForm(
                api: api,
                onSaved: (_) {
                  saved = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Motif'),
        'Bilan de suivi',
      );
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(saved, true);
      expect(sent!['professionnelNom'], isNull);
      expect(sent!['sourceRef'], isNotEmpty);
      expect(sent!['dateHeure'], endsWith('Z'));
      expect(sent!['fuseau'], 'UTC');
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Uncertain save freezes fields and retries identical command', (
    tester,
  ) async {
    final bodies = <String>[];
    final session = await signedInSession(
      handler: (r) async {
        bodies.add(r.body);
        if (bodies.length == 1) return jsonResponse('{}', 503);
        return jsonResponse(
          jsonEncode({
            ...agendaFixture(),
            ...jsonDecode(r.body) as Map<String, dynamic>,
          }),
          201,
        );
      },
    );
    final api = PersonalAgendaApi(session);
    addTearDown(api.dispose);
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppointmentAvailabilityForm(
              api: api,
              onSaved: (_) {
                saved = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motif'),
      'Bilan',
    );
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved, false);
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'Motif'))
          .enabled,
      false,
    );
    await tester.ensureVisible(find.text('Réessayer le même enregistrement'));
    await tester.tap(find.text('Réessayer le même enregistrement'));
    await tester.pumpAndSettle();
    expect(bodies.length, 2);
    expect(bodies[1], bodies[0]);
    expect(saved, true);
    session.clear();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Consent withdrawal hides an open form and clears private fields immediately',
    (tester) async {
      var consent = true;
      final session = await signedInSession(
        handler: (r) async => jsonResponse(
          jsonEncode({...patientFixture(), 'consentementAccepte': consent}),
          200,
        ),
      );
      final api = PersonalAgendaApi(session);
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppointmentAvailabilityForm(api: api, onSaved: (_) {}),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Motif'),
        'Informations privées du rendez-vous',
      );
      consent = false;
      await session.refreshProfile();
      await tester.pumpAndSettle();
      expect(find.text('Informations privées du rendez-vous'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(
        find.textContaining('Session ou consentement modifié'),
        findsOneWidget,
      );
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Unicode length validation shows an inline error without an uncaught exception or request',
    (tester) async {
      var writes = 0;
      final session = await signedInSession(
        handler: (r) async {
          writes++;
          return jsonResponse('{}', 500);
        },
      );
      final api = PersonalAgendaApi(session);
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppointmentAvailabilityForm(api: api, onSaved: (_) {}),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Motif'),
        List.filled(101, '😀').join(),
      );
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(writes, 0);
      expect(find.textContaining('200 unités'), findsOneWidget);
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Existing server dates before 1900 can open the date picker', (
    tester,
  ) async {
    final session = await signedInSession();
    final api = PersonalAgendaApi(session);
    addTearDown(api.dispose);
    final appointment = PersonalAppointment.fromServer({
      ...agendaFixture(),
      'dateHeure': '1899-12-30T10:30:00Z',
    }, 'patient-a');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppointmentAvailabilityForm(
              api: api,
              appointment: appointment,
              onSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    final date = find.text('30/12/1899');
    await tester.ensureVisible(date);
    await tester.tap(date);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    session.clear();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
