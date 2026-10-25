import 'support/care_fixture.dart';
import 'package:ecare_plus_mobile/main.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/dashbord/home_page.dart';
import 'package:ecare_plus_mobile/widgets/measurement_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, CareData data, String route) async {
    final session = await careSession(data);
    await tester.pumpWidget(ECarePlusApp(initialData: data, session: session));
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byType(HomePage)),
    ).pushReplacementNamed(route);
    await tester.pumpAndSettle();
  }

  for (final pressure in [false, true]) {
    final route = pressure ? '/follow-up/blood-pressure' : '/follow-up/glucose';
    testWidgets(
      '${pressure ? 'Blood pressure' : 'Glucose'} route isolates charts, entry and history',
      (tester) async {
        final data = CareData();
        data.addReading(99);
        data.addReading(
          108,
          date: DateTime.now().subtract(const Duration(days: 15)),
        );
        data.addBloodPressure(123, 81);
        await open(tester, data, route);
        expect(
          find.text(pressure ? 'Mon suivi tension' : 'Mon suivi glycémie'),
          findsOneWidget,
        );
        expect(
          find.text(pressure ? 'Glycémie' : 'Tension artérielle'),
          findsNothing,
        );
        var chart = tester.widget<MeasurementChart>(
          find.byType(MeasurementChart),
        );
        expect(chart.pressure, pressure);
        expect(chart.points.single.primary, pressure ? 123 : 99);
        await tester.tap(find.text('30 jours'));
        await tester.pumpAndSettle();
        chart = tester.widget<MeasurementChart>(find.byType(MeasurementChart));
        expect(chart.points.length, pressure ? 1 : 2);
        await tester.tap(find.byTooltip('Ajouter une mesure'));
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNWidgets(pressure ? 2 : 1));
        await tester.enterText(
          find.byType(TextFormField).first,
          pressure ? '126' : '102',
        );
        if (pressure) {
          await tester.enterText(find.byType(TextFormField).last, '82');
        }
        await tester.ensureVisible(find.text('Enregistrer la mesure'));
        await tester.tap(find.text('Enregistrer la mesure'));
        await tester.pumpAndSettle();
        expect(data.readings.length, pressure ? 2 : 3);
        expect(data.bloodPressureReadings.length, pressure ? 2 : 1);
        final reading = pressure ? '126.0 / 82.0 mmHg' : '102.0 mg/dL';
        await tester.scrollUntilVisible(
          find.text(reading),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(reading), findsOneWidget);
        expect(
          find.text(pressure ? '99.0 mg/dL' : '123.0 / 81.0 mmHg'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets(
      '${pressure ? 'Blood pressure' : 'Glucose'} variant fits small screens and large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await open(tester, CareData(), route);
        expect(
          find.text(pressure ? 'Mon suivi tension' : 'Mon suivi glycémie'),
          findsOneWidget,
        );
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
      },
    );
  }
}
