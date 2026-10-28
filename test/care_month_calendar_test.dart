import 'dart:ui' show SemanticsAction;
import 'package:ecare_plus_mobile/widgets/care_month_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Calendar shows French month, Monday grid, selected day and real event counts',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        DateTime? chosen;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CareMonthCalendar(
                month: DateTime(2026, 11),
                selectedDay: DateTime(2026, 11, 12),
                counts: const {'2026-11-12': 2},
                onDaySelected: (d) => chosen = d,
                onMonthChanged: (_) {},
                onToday: () {},
                onPickDate: () {},
              ),
            ),
          ),
        );
        expect(find.text('Novembre 2026'), findsOneWidget);
        final monday = tester.getTopLeft(
          find.byKey(const ValueKey('calendar-weekday-0')),
        );
        final sunday = tester.getTopLeft(
          find.byKey(const ValueKey('calendar-weekday-6')),
        );
        expect(monday.dx, lessThan(sunday.dx));
        expect(monday.dy, sunday.dy);
        final day = find.byKey(const ValueKey('calendar-day-2026-11-12'));
        expect(
          tester.widget<Semantics>(day).properties.label,
          contains('2 rendez-vous'),
        );
        expect(tester.widget<Semantics>(day).properties.selected, true);
        expect(
          tester
              .getSemantics(day)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          true,
        );
        await tester.tap(find.byKey(const ValueKey('calendar-day-2026-11-13')));
        expect(chosen, DateTime(2026, 11, 13));
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'Month navigation crosses December correctly and respects supported year bounds',
    (tester) async {
      DateTime? month;
      Widget calendar(DateTime m) => MaterialApp(
        home: Scaffold(
          body: CareMonthCalendar(
            month: m,
            selectedDay: m,
            counts: const {},
            onDaySelected: (_) {},
            onMonthChanged: (d) => month = d,
            onToday: () {},
            onPickDate: () {},
          ),
        ),
      );
      await tester.pumpWidget(calendar(DateTime(2026, 12)));
      await tester.tap(find.byTooltip('Mois suivant'));
      expect(month, DateTime(2027, 1));
      await tester.pumpWidget(calendar(DateTime(1, 1)));
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(calendar(DateTime(9999, 12)));
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'Calendar fits a 320px phone with enlarged text without clipping controls',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: CareMonthCalendar(
                month: DateTime(2026, 11),
                selectedDay: DateTime(2026, 11, 12),
                counts: const {'2026-11-12': 2},
                onDaySelected: (_) {},
                onMonthChanged: (_) {},
                onToday: () {},
                onPickDate: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byTooltip('Mois suivant'));
      expect(
        tester.getRect(find.byTooltip('Mois suivant')).right,
        lessThanOrEqualTo(320),
      );
    },
  );
}
