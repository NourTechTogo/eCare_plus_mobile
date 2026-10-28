import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_decor.dart';

const careCalendarMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];
const _weekdays = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];
String calendarDayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
String calendarDateLabel(DateTime day) =>
    '${_weekdays[day.weekday - 1]} ${day.day} ${careCalendarMonths[day.month - 1]} ${day.year}';
String _capital(String value) =>
    '${value[0].toUpperCase()}${value.substring(1)}';

/// Controlled civil-date calendar. Counts come exclusively from authorized API rows.
class CareMonthCalendar extends StatelessWidget {
  final DateTime month, selectedDay;
  final Map<String, int> counts;
  final ValueChanged<DateTime> onDaySelected, onMonthChanged;
  final VoidCallback onToday, onPickDate;
  const CareMonthCalendar({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.counts,
    required this.onDaySelected,
    required this.onMonthChanged,
    required this.onToday,
    required this.onPickDate,
  });
  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = first.weekday - 1;
    final weeks = (offset + days + 6) ~/ 7;
    final today = DateUtils.dateOnly(DateTime.now());
    final count = counts.entries
        .where(
          (e) => e.key.startsWith(
            '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-',
          ),
        )
        .fold<int>(0, (sum, e) => sum + e.value);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecor.shadow(.035),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onPickDate,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Tooltip(
                      message: 'Choisir une date',
                      child: Text(
                        '${_capital(careCalendarMonths[month.month - 1])} ${month.year}',
                        style: AppDecor.t(
                          19,
                          c: AppColors.primaryDeep,
                          w: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mois précédent',
                onPressed: month.year > 1 || month.month > 1
                    ? () =>
                          onMonthChanged(DateTime(month.year, month.month - 1))
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.primary,
              ),
              IconButton(
                tooltip: 'Mois suivant',
                onPressed: month.year < 9999 || month.month < 12
                    ? () =>
                          onMonthChanged(DateTime(month.year, month.month + 1))
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: onToday,
                icon: const Icon(Icons.today_outlined, size: 16),
                label: Text(
                  'Aujourd’hui',
                  style: AppDecor.t(
                    11,
                    c: AppColors.primary,
                    w: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count rendez-vous ce mois',
                style: AppDecor.t(10, c: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 280 || scale > 1.3;
              return Column(
                children: [
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              narrow
                                  ? const [
                                      'L',
                                      'M',
                                      'M',
                                      'J',
                                      'V',
                                      'S',
                                      'D',
                                    ][col]
                                  : const [
                                      'LUN',
                                      'MAR',
                                      'MER',
                                      'JEU',
                                      'VEN',
                                      'SAM',
                                      'DIM',
                                    ][col],
                              key: ValueKey('calendar-weekday-$col'),
                              textAlign: TextAlign.center,
                              style: AppDecor.t(
                                9,
                                c: AppColors.textMuted,
                                w: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (var row = 0; row < weeks; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final day = DateTime(
                                  month.year,
                                  month.month,
                                  1 + row * 7 + col - offset,
                                );
                                final allowed =
                                    day.year >= 1 && day.year <= 9999;
                                if (!allowed) return const SizedBox(height: 48);
                                final active = DateUtils.isSameDay(
                                  day,
                                  selectedDay,
                                );
                                final isToday = DateUtils.isSameDay(day, today);
                                final inMonth =
                                    day.month == month.month &&
                                    day.year == month.year;
                                final events = counts[calendarDayKey(day)] ?? 0;
                                final color = active
                                    ? Colors.white
                                    : inMonth
                                    ? AppColors.textDark
                                    : AppColors.textHint;
                                return Semantics(
                                  key: ValueKey(
                                    'calendar-day-${calendarDayKey(day)}',
                                  ),
                                  button: true,
                                  onTap: () => onDaySelected(day),
                                  selected: active,
                                  label:
                                      '${calendarDateLabel(day)}, $events rendez-vous${isToday ? ', aujourd’hui' : ''}',
                                  child: ExcludeSemantics(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 2,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                          onTap: () => onDaySelected(day),
                                          child: Ink(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              gradient: active
                                                  ? AppDecor.buttonGradient
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                              border: isToday && !active
                                                  ? Border.all(
                                                      color: AppColors.primary,
                                                    )
                                                  : null,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height: 32,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      '${day.day}',
                                                      style: AppDecor.t(
                                                        14,
                                                        c: color,
                                                        w: active || isToday
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  height: 4,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      for (
                                                        var i = 0;
                                                        i <
                                                            (events > 3
                                                                ? 3
                                                                : events);
                                                        i++
                                                      )
                                                        Container(
                                                          width: 3,
                                                          height: 3,
                                                          margin:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 1,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: active
                                                                ? Colors.white
                                                                : AppColors
                                                                      .primaryBright,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBright,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Jour avec rendez-vous',
                  style: AppDecor.t(10, c: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
