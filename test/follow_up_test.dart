import 'package:ecare_plus_mobile/services/api_session.dart';
import 'support/care_fixture.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/measurement/follow_up_page.dart';
import 'package:ecare_plus_mobile/widgets/measurement_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> openFollowUp(WidgetTester tester, CareData data) async {
  final session = await careSession(data);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiSession>(lazy: false, create: (_) => session),
        ChangeNotifierProvider<CareData>.value(value: data),
      ],
      child: const MaterialApp(home: FollowUpPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Chart supports all finite positive scales', (tester) async {
    final now = DateTime.now();
    for (final value in [1.7e308, 1e308, 1e-323]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeasurementChart(
              points: [MeasurementPoint(now, value)],
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Infinity'), findsNothing);
    }
  });

  testWidgets('Follow up fits narrow screens with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: CareData(),
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const FollowUpPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Period filter changes the actual displayed measurements', (
    tester,
  ) async {
    final data = CareData();
    data.addReading(98, date: DateTime.now());
    data.addReading(
      115,
      date: DateTime.now().subtract(const Duration(days: 15)),
    );
    await openFollowUp(tester, data);
    expect(find.text('1 mesure sur la période'), findsOneWidget);
    expect(find.byKey(const ValueKey('measurement-chart')), findsOneWidget);
    await tester.tap(find.text('30 jours'));
    await tester.pumpAndSettle();
    expect(find.text('2 mesures sur la période'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Corner plus adds blood pressure to its graph', (tester) async {
    final data = CareData();
    await openFollowUp(tester, data);
    await tester.tap(find.text('Tension artérielle'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter une mesure'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '120');
    await tester.enterText(find.byType(TextFormField).at(1), '80');
    await tester.ensureVisible(find.text('Enregistrer la mesure'));
    await tester.tap(find.text('Enregistrer la mesure'));
    await tester.pumpAndSettle();
    expect(data.bloodPressureReadings.single.systolic, 120);
    expect(data.bloodPressureReadings.single.diastolic, 80);
    expect(find.text('Systolique'), findsWidgets);
    expect(find.text('Diastolique'), findsWidgets);
    expect(find.text('1 mesure sur la période'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
