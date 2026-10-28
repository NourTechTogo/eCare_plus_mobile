import 'dart:convert';
import 'package:ecare_plus_mobile/views/dashbord/appointments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';
import 'personal_agenda_api_test.dart' show agendaFixture;

void main() {
  testWidgets('Agenda loads persistent entries and actual reminder state', (
    tester,
  ) async {
    final session = await signedInSession(
      handler: (r) async => jsonResponse(
        jsonEncode({
          'content': r.url.path.endsWith('/rappels')
              ? [
                  {'id': 'reminder-a', 'statut': 'ENVOYE'},
                ]
              : [agendaFixture()],
          'totalPages': 1,
        }),
        200,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: const MaterialApp(home: AppointmentsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Consultation convenue'), findsOneWidget);
    expect(find.textContaining('publié dans eCare+'), findsOneWidget);
    expect(find.textContaining('pour cette session'), findsNothing);
    session.clear();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Agenda without session cannot create fictitious local dates', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppointmentsPage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connectez-vous'), findsOneWidget);
    expect(find.byTooltip('Ajouter un rendez-vous'), findsNothing);
  });

  testWidgets(
    'Small screen and enlarged text preserve agenda and form without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = await signedInSession(
        handler: (r) async => jsonResponse(
          jsonEncode({
            'content': r.url.path.endsWith('/rappels')
                ? []
                : [
                    {
                      ...agendaFixture(),
                      'motif':
                          'Consultation de suivi avec un intitulé plus long',
                      'professionnelNom':
                          'Professionnel facultatif au nom long',
                    },
                  ],
            'totalPages': 1,
          }),
          200,
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: MaterialApp(
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(
                ctx,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: const AppointmentsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Ajouter une date'));
      await tester.tap(find.text('Ajouter une date'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Failed cancellation retains entry and reuses original version and reference',
    (tester) async {
      final bodies = <String>[];
      var cancelled = false;
      final session = await signedInSession(
        handler: (r) async {
          if (r.method == 'POST') {
            bodies.add(r.body);
            if (bodies.length == 1) return jsonResponse('{}', 503);
            cancelled = true;
            return jsonResponse(
              jsonEncode(agendaFixture(status: 'ANNULE', version: 3)),
              200,
            );
          }
          return jsonResponse(
            jsonEncode({
              'content': r.url.path.endsWith('/rappels')
                  ? []
                  : [
                      agendaFixture(
                        status: cancelled ? 'ANNULE' : 'PLANIFIE',
                        version: cancelled ? 3 : 2,
                      ),
                    ],
              'totalPages': 1,
            }),
            200,
          );
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: const MaterialApp(home: AppointmentsPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Annuler'));
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler la date'));
      await tester.pumpAndSettle();
      expect(find.text('Consultation convenue'), findsOneWidget);
      expect(cancelled, false);
      await tester.ensureVisible(find.text('Réessayer l’annulation'));
      await tester.tap(find.text('Réessayer l’annulation'));
      await tester.pumpAndSettle();
      expect(bodies.length, 2);
      expect(bodies[1], bodies[0]);
      expect(cancelled, true);
      await tester.ensureVisible(find.text('Annulées'));
      await tester.tap(find.text('Annulées'));
      await tester.pumpAndSettle();
      expect(find.text('Consultation convenue'), findsOneWidget);
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Notification target reads its current event including cancelled history',
    (tester) async {
      final paths = <String>[];
      final session = await signedInSession(
        handler: (r) async {
          paths.add(r.url.path);
          if (r.url.path.endsWith('/event-a')) {
            return jsonResponse(
              jsonEncode(agendaFixture(status: 'ANNULE')),
              200,
            );
          }
          return jsonResponse('{"content":[],"totalPages":1}', 200);
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: const MaterialApp(
            home: AppointmentsPage(initialAppointmentId: 'event-a'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Consultation convenue'), findsOneWidget);
      expect(find.textContaining('Date annulée'), findsOneWidget);
      expect(paths.any((s) => s.endsWith('/event-a')), true);
      expect(paths.any((s) => s.contains('conversations')), false);
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Calendar selection filters server dates and prefills creation without changing on refresh',
    (tester) async {
      final session = await signedInSession(
        handler: (r) async => jsonResponse(
          jsonEncode({
            'content': r.url.path.endsWith('/rappels')
                ? []
                : [
                    agendaFixture(),
                    {
                      ...agendaFixture(id: 'event-b'),
                      'motif': 'Suivi du lendemain',
                      'dateHeure': '2026-11-13T09:00:00Z',
                    },
                  ],
            'totalPages': 1,
          }),
          200,
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: const MaterialApp(home: AppointmentsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Consultation convenue'), findsOneWidget);
      expect(find.text('Suivi du lendemain'), findsNothing);
      final day = find.byKey(const ValueKey('calendar-day-2026-11-13'));
      await tester.ensureVisible(day);
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(find.text('Consultation convenue'), findsNothing);
      expect(find.text('Suivi du lendemain'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Actualiser'));
      await tester.tap(find.byTooltip('Actualiser'));
      await tester.pumpAndSettle();
      expect(find.text('Suivi du lendemain'), findsOneWidget);
      await tester.ensureVisible(find.text('Ajouter une date'));
      await tester.tap(find.text('Ajouter une date'));
      await tester.pumpAndSettle();
      expect(find.text('13/11/2026'), findsOneWidget);
      session.clear();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
