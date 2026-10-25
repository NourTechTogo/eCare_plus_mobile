import 'package:ecare_plus_mobile/data/doctor_catalog.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/dashbord/appointments_page.dart';
import 'package:ecare_plus_mobile/views/messaging/doctor_contact_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'Local contact preview opens agenda with selected example doctor',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareData(),
          child: MaterialApp(
            home: DoctorContactPage(doctor: doctorCatalog.first),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Prendre rendez-vous'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Prendre rendez-vous'));
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentsPage), findsOneWidget);
      expect(find.text('Jours disponibles'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    },
  );
  testWidgets(
    'Adding to local agenda opens its wizard without fictitious booking',
    (tester) async {
      final data = CareData();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: data,
          child: const MaterialApp(home: AppointmentsPage()),
        ),
      );
      await tester.tap(find.byTooltip('Ajouter un rendez-vous'));
      await tester.pumpAndSettle();
      expect(find.text('Planifier une consultation'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Suivant'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Suivant'))
            .onPressed,
        isNull,
      );
      expect(data.appointments, isEmpty);
    },
  );
}
