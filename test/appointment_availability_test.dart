import 'package:ecare_plus_mobile/data/doctor_catalog.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/dashbord/appointments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Finder keyPrefix(String prefix) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key as ValueKey<String>).value.startsWith(prefix),
);
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> chooseDay(WidgetTester tester) async {
  await tapVisible(tester, keyPrefix('day-').first);
  await tapVisible(tester, find.text('Suivant'));
}

void main() {
  testWidgets(
    'Changing local example doctor clears the previously selected day',
    (tester) async {
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
      await tester.pumpAndSettle();
      await tapVisible(tester, keyPrefix('day-').first);
      await tapVisible(tester, find.text('Modifier le médecin'));
      await tapVisible(
        tester,
        find.byKey(ValueKey('doctor-${doctorCatalog.last.name}')),
      );
      await tapVisible(tester, find.text('Suivant'));
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Suivant'))
            .onPressed,
        isNull,
      );
      expect(find.text('Jours disponibles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Local agenda requires day and time then removes occupied slot', (
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
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    await chooseDay(tester);
    expect(
      find.textContaining('ne réservent pas de consultation réelle'),
      findsOneWidget,
    );
    final slot = keyPrefix('slot-').first;
    final time = (tester.widget(slot).key as ValueKey<String>).value;
    await tapVisible(tester, slot);
    await tapVisible(tester, find.text('Ajouter'));
    expect(data.appointments, hasLength(1));
    expect(data.appointments.single.doctor, doctorCatalog.first.name);
    await tapVisible(tester, find.byTooltip('Ajouter un rendez-vous'));
    await chooseDay(tester);
    expect(find.byKey(ValueKey(time)), findsNothing);
  });
}
