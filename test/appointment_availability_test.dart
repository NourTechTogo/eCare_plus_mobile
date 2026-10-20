import 'package:ecare_plus_mobile/data/doctor_catalog.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/dashbord/appointments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Changing doctor clears the selected slot on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CareData(),
        child: MaterialApp(
          home: AppointmentsPage(initialDoctor: doctorCatalog.first.name),
        ),
      ),
    );
    final slot = find.byKey(const ValueKey('slot-09:00'));
    await tester.ensureVisible(slot);
    await tester.tap(slot);
    await tester.pumpAndSettle();
    expect(find.text('Votre consultation'), findsOneWidget);
    final doctor = find.byKey(ValueKey('doctor-${doctorCatalog.last.name}'));
    await tester.ensureVisible(doctor);
    await tester.tap(doctor);
    await tester.pumpAndSettle();
    expect(find.text('Votre consultation'), findsNothing);
    expect(find.byKey(const ValueKey('slot-09:00')), findsNothing);
    expect(find.byKey(const ValueKey('slot-10:00')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((widget) => widget is FilledButton),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Only a listed doctor slot can be added and cannot be reused', (
    tester,
  ) async {
    final data = CareData();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: data,
        child: MaterialApp(
          home: AppointmentsPage(initialDoctor: doctorCatalog.first.name),
        ),
      ),
    );
    expect(find.text('Disponibilités de démonstration'), findsOneWidget);
    expect(find.text('Choisir une date'), findsNothing);
    expect(find.text('Choisir une heure'), findsNothing);
    final slot = find.byKey(const ValueKey('slot-09:00'));
    await tester.ensureVisible(slot);
    await tester.tap(slot);
    await tester.pumpAndSettle();
    final save = find.text('Ajouter ce créneau à mon agenda');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(data.appointments, hasLength(1));
    expect(data.appointments.single.doctor, doctorCatalog.first.name);
    expect(data.appointments.single.date.hour, 9);
    expect(data.appointments.single.date.isAfter(DateTime.now()), isTrue);
    await tester.ensureVisible(find.text('Ajouter un rendez-vous'));
    await tester.tap(find.text('Ajouter un rendez-vous'));
    await tester.pumpAndSettle();
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('slot-09:00')),
    );
    expect(chip.onSelected, isNull);
    expect(tester.takeException(), isNull);
  });
}
