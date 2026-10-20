import 'package:ecare_plus_mobile/data/doctor_catalog.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/dashbord/appointments_page.dart';
import 'package:ecare_plus_mobile/views/dashbord/doctors_page.dart';
import 'package:ecare_plus_mobile/views/dashbord/home_page.dart';
import 'package:ecare_plus_mobile/views/messaging/doctor_contact_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  for (final entry in <String, Widget>{
    'Planifier': const HomePage(),
    'Ajouter à mon agenda': const DoctorsPage(),
    'Prendre rendez-vous': DoctorContactPage(doctor: doctorCatalog.first),
  }.entries) {
    testWidgets('${entry.key} opens appointments with the selected doctor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareData(),
          child: MaterialApp(home: Scaffold(body: entry.value)),
        ),
      );
      final button = find.text(entry.key).first;
      if (entry.key == 'Planifier') {
        for (
          var attempt = 0;
          attempt < 6 && button.hitTestable().evaluate().isEmpty;
          attempt++
        ) {
          await tester.drag(
            find.byKey(const PageStorageKey('home-scroll')),
            const Offset(0, -180),
          );
          await tester.pumpAndSettle();
        }
        expect(button.hitTestable(), findsOneWidget);
      } else {
        await tester.ensureVisible(button);
      }
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Mes rendez-vous'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Disponibilités de démonstration'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Adding an appointment uses the form inside the appointments page',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareData(),
          child: const MaterialApp(home: AppointmentsPage()),
        ),
      );
      await tester.tap(find.text('Ajouter un rendez-vous'));
      await tester.pumpAndSettle();
      expect(find.text('Mes rendez-vous'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      await tester.ensureVisible(find.text('Ajouter ce créneau à mon agenda'));

      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byWidgetPredicate((widget) => widget is FilledButton),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
