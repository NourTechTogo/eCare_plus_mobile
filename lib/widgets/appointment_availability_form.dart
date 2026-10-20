import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/doctor_catalog.dart';
import '../models/care_data.dart';
import '../utils/app_colors.dart';
import '../utils/app_decor.dart';
import 'care_page.dart';

/// Local presentation data only. Replace with the doctor's published slots
/// when the scheduling API is connected; never infer real availability here.
class AppointmentAvailabilityForm extends StatefulWidget {
  final String doctor;
  final ValueChanged<CareAppointment> onSaved;
  const AppointmentAvailabilityForm({
    super.key,
    required this.doctor,
    required this.onSaved,
  });

  @override
  State<AppointmentAvailabilityForm> createState() =>
      _AppointmentAvailabilityFormState();
}

class _AppointmentAvailabilityFormState
    extends State<AppointmentAvailabilityForm> {
  final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late CareDoctor _doctor;
  late DateTime _month;
  DateTime? _day;
  DateTime? _slot;
  String? _error;
  static const _weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _months = [
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

  @override
  void initState() {
    super.initState();
    _doctor = doctorCatalog.firstWhere(
      (d) => d.name == widget.doctor,
      orElse: () => doctorCatalog.first,
    );
    _selectDoctor(_doctor);
  }

  List<DateTime> _slotsFor(DateTime day) {
    final second = _doctor.name == doctorCatalog.last.name;
    final workingDays = second ? [2, 3, 5, 6] : [1, 2, 4, 5];
    if (!workingDays.contains(day.weekday) ||
        day.isBefore(_today) ||
        day.isAfter(_today.add(const Duration(days: 21)))) {
      return [];
    }
    final times = second
        ? [(10, 0), (10, 30), (15, 0), (15, 30)]
        : [(9, 0), (9, 30), (10, 30), (14, 0), (14, 30)];
    return times
        .map((t) => DateTime(day.year, day.month, day.day, t.$1, t.$2))
        .where((date) => date.isAfter(DateTime.now()))
        .toList();
  }

  bool _taken(DateTime slot) => context.read<CareData>().appointments.any(
    (a) => a.doctor == _doctor.name && a.date == slot,
  );
  bool _availableDay(DateTime day) =>
      _slotsFor(day).any((slot) => !_taken(slot));

  void _selectDoctor(CareDoctor doctor) {
    _doctor = doctor;
    _slot = null;
    _error = null;
    _day = null;
    // Initially highlight the next available day in the demonstration schedule.
    for (var i = 1; i <= 21; i++) {
      final date = DateTime(_today.year, _today.month, _today.day + i);
      if (_availableDay(date)) {
        _day = date;
        break;
      }
    }
    final day = _day ?? _today;
    _month = DateTime(day.year, day.month);
  }

  Widget _heading(String number, String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.primaryLighter,
          child: Text(
            number,
            style: AppDecor.t(12, c: AppColors.primary, w: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(title, style: AppDecor.t(15, w: FontWeight.w700)),
        ),
      ],
    ),
  );

  void _save() {
    final slot = _slot;
    if (slot == null || !_slotsFor(slot).contains(slot) || _taken(slot)) {
      setState(() {
        _slot = null;
        _error = 'Sélectionnez un créneau encore disponible.';
      });
      return;
    }
    widget.onSaved(CareAppointment(doctor: _doctor.name, date: slot));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CareData>();
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final offset = _month.weekday - 1;
    final lastDay = DateTime(_today.year, _today.month, _today.day + 21);
    final canPrevious = _month.isAfter(DateTime(_today.year, _today.month));
    final canNext = _month.isBefore(DateTime(lastDay.year, lastDay.month));
    final slots = _day == null ? <DateTime>[] : _slotsFor(_day!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planifier une consultation',
          style: AppDecor.t(21, w: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez parmi les créneaux proposés par votre médecin.',
          style: AppDecor.t(13, c: AppColors.textMuted, h: 1.5),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLighter,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disponibilités de démonstration',
                style: AppDecor.t(12, c: AppColors.primary, w: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Cet aperçu ne réserve pas de consultation réelle.',
                style: AppDecor.t(11, c: AppColors.textMuted),
              ),
            ],
          ),
        ),
        _heading('1', 'Votre médecin'),
        for (final doctor in doctorCatalog)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              selected: _doctor == doctor,
              child: Material(
                color: _doctor == doctor
                    ? AppColors.primaryLighter
                    : AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  key: ValueKey('doctor-${doctor.name}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _selectDoctor(doctor)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage(doctor.imageAsset),
                          radius: 23,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor.name,
                                style: AppDecor.t(13, w: FontWeight.w700),
                              ),
                              Text(
                                doctor.specialty,
                                style: AppDecor.t(11, c: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _doctor == doctor
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _doctor == doctor
                              ? AppColors.primary
                              : AppColors.textHint,
                          size: 21,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        _heading('2', 'Un jour disponible'),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_months[_month.month - 1]} ${_month.year}',
                style: AppDecor.t(15, w: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Mois précédent',
              onPressed: canPrevious
                  ? () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Mois suivant',
              onPressed: canNext
                  ? () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final name in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: AppDecor.t(11, c: AppColors.textMuted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: ((offset + daysInMonth + 6) ~/ 7) * 7,
          itemBuilder: (context, index) {
            final number = index - offset + 1;
            if (number < 1 || number > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(_month.year, _month.month, number);
            final available = _availableDay(day);
            final selected = DateUtils.isSameDay(day, _day);
            return Semantics(
              label: careDate(day),
              selected: selected,
              enabled: available,
              child: TextButton(
                key: ValueKey('day-${day.toIso8601String()}'),
                onPressed: available
                    ? () => setState(() {
                        _day = day;
                        _slot = null;
                        _error = null;
                      })
                    : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  backgroundColor: selected
                      ? AppColors.primary
                      : available
                      ? AppColors.primaryLighter
                      : Colors.transparent,
                  foregroundColor: selected ? Colors.white : AppColors.primary,
                  disabledForegroundColor: AppColors.textHint.withValues(
                    alpha: .55,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('$number', style: const TextStyle(fontSize: 13)),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Les jours grisés ne sont pas disponibles.',
          style: AppDecor.t(11, c: AppColors.textMuted),
        ),
        _heading('3', 'Votre créneau · 30 min'),
        if (_day != null)
          Text(careDate(_day!), style: AppDecor.t(13, c: AppColors.textMuted)),
        const SizedBox(height: 10),
        if (slots.isEmpty)
          Text(
            'Aucun créneau disponible. Consultez un autre jour ou un autre médecin.',
            style: AppDecor.t(13, c: AppColors.textMuted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                ChoiceChip(
                  key: ValueKey('slot-${careTime(slot)}'),
                  label: Text(careTime(slot)),
                  selected: _slot == slot,
                  showCheckmark: true,
                  selectedColor: AppColors.primaryLighter,
                  onSelected: _taken(slot)
                      ? null
                      : (_) => setState(() {
                          _slot = slot;
                          _error = null;
                        }),
                ),
            ],
          ),
        if (_slot != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre consultation',
                  style: AppDecor.t(13, w: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(_doctor.name, style: AppDecor.t(13)),
                Text(
                  '${careDate(_slot!)} · ${careTime(_slot!)} – ${careTime(_slot!.add(const Duration(minutes: 30)))}',
                  style: AppDecor.t(12, c: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: AppDecor.t(12, c: AppColors.required)),
          ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _slot == null ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.event_available_outlined, size: 19),
            label: const Text(
              'Ajouter ce créneau à mon agenda',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
