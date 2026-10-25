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
  DateTime? _day;
  DateTime? _slot;
  String? _error;
  late int _step;
  bool _doctorChosen = false;
  static const _weekdays = [
    'lun.',
    'mar.',
    'mer.',
    'jeu.',
    'ven.',
    'sam.',
    'dim.',
  ];
  static const _months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  @override
  void initState() {
    super.initState();
    _step = widget.doctor.isNotEmpty ? 1 : 0;
    _doctor = doctorCatalog.firstWhere(
      (d) => d.name == widget.doctor,
      orElse: () => doctorCatalog.first,
    );
    if (widget.doctor.isNotEmpty) _selectDoctor(_doctor);
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

  List<DateTime> get _availableDays => [
    for (var i = 0; i <= 21; i++)
      DateTime(_today.year, _today.month, _today.day + i),
  ].where(_availableDay).toList();

  void _selectDoctor(CareDoctor doctor) {
    _doctor = doctor;
    _doctorChosen = true;
    _slot = null;
    _error = null;
    _day = null;
  }

  void _selectDay(DateTime day) => setState(() {
    _day = day;
    _slot = null;
    _error = null;
  });

  void _selectSlot(DateTime slot) => setState(() {
    _slot = slot;
    _error = null;
  });

  void _advance() {
    if (_step == 0 && !_doctorChosen) return;
    if (_step == 1 && _day == null) return;
    if (_step == 2) {
      if (_slot == null) return;
      _save();
      return;
    }
    setState(() {
      _step++;
      _error = null;
    });
  }

  void _goBack() => setState(() {
    if (_step > (widget.doctor.isNotEmpty ? 1 : 0)) _step--;
    _error = null;
  });

  Widget _stepProgress() {
    final stepNumber = _step + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: index < stepNumber
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Étape $stepNumber sur 3',
          style: AppDecor.t(11, c: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _doctorCard(CareDoctor doctor) => Semantics(
    selected: _doctorChosen && _doctor == doctor,
    button: true,
    child: Material(
      color: _doctorChosen && _doctor == doctor
          ? AppColors.primaryLighter
          : AppColors.scaffoldBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('doctor-${doctor.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          _selectDoctor(doctor);
          _error = null;
        }),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(doctor.imageAsset),
                radius: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      doctor.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppDecor.t(12, w: FontWeight.w700),
                    ),
                    Text(
                      doctor.specialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppDecor.t(10, c: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (_doctorChosen && _doctor == doctor) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _dayCard(DateTime day) {
    final selected = DateUtils.isSameDay(day, _day);
    return SizedBox(
      width: 76,
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('day-${day.toIso8601String()}'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectDay(day),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _weekdays[day.weekday - 1],
                  style: AppDecor.t(
                    11,
                    c: selected ? Colors.white : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.day}',
                  style: AppDecor.t(
                    18,
                    w: FontWeight.w700,
                    c: selected ? Colors.white : AppColors.primaryDeep,
                  ),
                ),
                Text(
                  _months[day.month - 1],
                  style: AppDecor.t(
                    10,
                    c: selected ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
    final availableDays = _availableDays;
    final slots = _day == null
        ? <DateTime>[]
        : _slotsFor(_day!).where((slot) => !_taken(slot)).toList();
    final firstStep = widget.doctor.isNotEmpty ? 1 : 0;
    final canContinue = switch (_step) {
      0 => _doctorChosen,
      1 => _day != null,
      _ => _slot != null,
    };
    final stepTitle = switch (_step) {
      0 => 'Choisissez un médecin',
      1 => 'Choisissez un jour',
      _ => 'Choisissez un horaire',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planifier une consultation',
          style: AppDecor.t(20, w: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _stepProgress(),
        const SizedBox(height: 18),
        Text(stepTitle, style: AppDecor.t(17, w: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          _step == 0
              ? 'Exemples pour votre agenda personnel ; ce choix ne crée aucune affectation médicale.'
              : '${_doctor.name} · ${_doctor.specialty}',
          style: AppDecor.t(12, c: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        if (_step == 0)
          Column(
            children: [
              for (final doctor in doctorCatalog) ...[
                _doctorCard(doctor),
                const SizedBox(height: 8),
              ],
            ],
          ),
        if (_step == 1) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _step = 0),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Modifier le médecin'),
            ),
          ),
          if (availableDays.isEmpty)
            Text(
              'Aucun jour disponible pour ce médecin dans les trois prochaines semaines.',
              style: AppDecor.t(13, c: AppColors.textMuted, h: 1.5),
            )
          else ...[
            Text(
              'Jours disponibles',
              style: AppDecor.t(13, w: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final day in availableDays)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _dayCard(day),
                    ),
                ],
              ),
            ),
          ],
        ],
        if (_step == 2) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.edit_calendar_outlined, size: 17),
              label: Text(_day == null ? 'Choisir un jour' : careDate(_day!)),
            ),
          ),
          Text(
            'Horaires disponibles · séances de 30 min',
            style: AppDecor.t(13, w: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            Text(
              'Aucun horaire disponible ce jour-là. Revenez à la liste des jours.',
              style: AppDecor.t(13, c: AppColors.textMuted, h: 1.5),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final slot in slots)
                  SizedBox(
                    width: 94,
                    height: 52,
                    child: Material(
                      color: _slot == slot
                          ? AppColors.primary
                          : AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        key: ValueKey('slot-${careTime(slot)}'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _selectSlot(slot),
                        child: Center(
                          child: Text(
                            careTime(slot),
                            style: AppDecor.t(
                              14,
                              w: FontWeight.w700,
                              c: _slot == slot
                                  ? Colors.white
                                  : AppColors.primaryDeep,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          Text(
            'Les créneaux affichés sont indicatifs et ne réservent pas de consultation réelle.',
            style: AppDecor.t(11, c: AppColors.textMuted, h: 1.45),
          ),
        ],
        if (_slot != null && _step == 2) ...[
          const SizedBox(height: 18),
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
                  'Récapitulatif',
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
        Row(
          children: [
            if (_step > firstStep)
              Expanded(
                child: OutlinedButton(
                  onPressed: _goBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Précédent'),
                ),
              )
            else
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Annuler'),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: canContinue ? _advance : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_step == 2 ? 'Ajouter' : 'Suivant'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
