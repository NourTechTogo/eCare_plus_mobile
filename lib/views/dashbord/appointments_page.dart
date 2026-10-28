import '../../widgets/care_month_calendar.dart';
import '../../widgets/care_date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/personal_appointment.dart';
import '../../services/api_session.dart';
import '../../services/personal_agenda_api.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/appointment_availability_form.dart';
import '../../widgets/care_page.dart';
import '../../widgets/care_components.dart';

class AppointmentsPage extends StatefulWidget {
  final bool showBack, active;
  final String initialDoctor;
  final String? initialAppointmentId;
  const AppointmentsPage({
    super.key,
    this.showBack = true,
    this.active = true,
    this.initialDoctor = '',
    this.initialAppointmentId,
  });
  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with WidgetsBindingObserver {
  PersonalAgendaApi? _api;
  List<PersonalAppointment> _rows = [];
  Map<String, String> _reminders = {};
  final Map<String, AgendaCancellation> _pending = {};
  bool _loading = false, _writing = false, _cancelled = false, _opened = false;
  int _loadVersion = 0;
  DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());
  late DateTime _month = DateTime(_selectedDay.year, _selectedDay.month);
  bool _selectionInitialized = false;
  void _selectDay(DateTime day) {
    setState(() {
      _selectionInitialized = true;
      _selectedDay = DateUtils.dateOnly(day);
      _month = DateTime(day.year, day.month);
    });
  }

  void _changeMonth(DateTime month) {
    final last = DateUtils.getDaysInMonth(month.year, month.month);
    _selectDay(
      DateTime(
        month.year,
        month.month,
        _selectedDay.day > last ? last : _selectedDay.day,
      ),
    );
  }

  Future<void> _pickCalendarDate() async {
    final day = await showCareDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Choisir une date',
    );
    if (day != null && mounted && (_api?.valid ?? false)) {
      _selectDay(day);
    }
  }

  String? _error, _reminderError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.watch<ApiSession?>();
    if (session != null &&
        session.authenticated &&
        (_api == null || !identical(_api!.session, session) || !_api!.valid) &&
        session.profile?['consentementAccepte'] == true) {
      _api?.removeListener(_scopeChanged);
      _api?.dispose();
      _api = PersonalAgendaApi(session)..addListener(_scopeChanged);
      _rows = [];
      _reminders = {};
      _pending.clear();
      _selectionInitialized = false;
      _selectedDay = DateUtils.dateOnly(DateTime.now());
      _month = DateTime(_selectedDay.year, _selectedDay.month);
      _loadVersion++;
      if (widget.active) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _load();
        });
      }
    }
  }

  void _scopeChanged() {
    if (mounted && !(_api?.valid ?? false)) {
      setState(() {
        _loadVersion++;
        _rows = [];
        _reminders = {};
        _pending.clear();
        _loading = false;
        _writing = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppointmentsPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active && !_writing) {
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _api?.removeListener(_scopeChanged);
    _api?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = _api;
    if (api == null || !api.valid || !mounted) return;
    final request = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
      _reminderError = null;
    });
    try {
      final entries = await api.list();
      if (widget.initialAppointmentId != null) {
        final selected = await api.read(widget.initialAppointmentId!);
        entries.removeWhere((a) => a.id == selected.id);
        entries.add(selected);
      }
      if (!mounted || !api.valid || request != _loadVersion) return;
      entries.sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _rows = entries;
        _loading = false;
        if (!_selectionInitialized) {
          PersonalAppointment? focus;
          if (widget.initialAppointmentId != null) {
            focus = entries.firstWhere(
              (a) => a.id == widget.initialAppointmentId,
            );
          } else {
            final active = entries.where((a) => !a.cancelled).toList();
            final upcoming = active.where(
              (a) => !a.date.toLocal().isBefore(
                DateUtils.dateOnly(DateTime.now()),
              ),
            );
            if (upcoming.isNotEmpty) {
              focus = upcoming.first;
            } else if (active.isNotEmpty) {
              focus = active.last;
            }
          }
          if (focus != null) {
            _selectedDay = DateUtils.dateOnly(focus.date.toLocal());
            _month = DateTime(_selectedDay.year, _selectedDay.month);
          }
          _selectionInitialized = true;
        }
        for (final a in entries.where((a) => a.cancelled)) {
          _pending.remove(a.id);
        }
        if (!_opened && widget.initialAppointmentId != null) {
          _cancelled = entries
              .firstWhere((a) => a.id == widget.initialAppointmentId)
              .cancelled;
        }
      });
      try {
        final reminders = await api.reminders();
        if (mounted && api.valid && request == _loadVersion) {
          setState(() => _reminders = reminders);
        }
      } catch (_) {
        if (mounted && api.valid && request == _loadVersion) {
          setState(() {
            _reminders = {};
            _reminderError =
                'Le statut des rappels est indisponible. Vos dates restent enregistrées.';
          });
        }
      }
      if (mounted && api.valid && !_opened && widget.initialDoctor.isNotEmpty) {
        _opened = true;
        await _edit();
      }
      _opened = true;
    } catch (e) {
      if (mounted && api.valid && request == _loadVersion) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _edit([PersonalAppointment? appointment]) async {
    final api = _api;
    if (api == null || !api.valid || _writing) return;
    setState(() {
      _writing = true;
      _loadVersion++;
    });
    var saved = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * .9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: AppointmentAvailabilityForm(
              api: api,
              appointment: appointment,
              doctor: widget.initialDoctor,
              initialDate: DateTime(
                _selectedDay.year,
                _selectedDay.month,
                _selectedDay.day,
                DateUtils.isSameDay(_selectedDay, DateTime.now())
                    ? DateTime.now().hour
                    : 9,
                DateUtils.isSameDay(_selectedDay, DateTime.now())
                    ? DateTime.now().minute
                    : 0,
              ),
              onSaved: (entry) {
                _selectedDay = DateUtils.dateOnly(entry.date.toLocal());
                _month = DateTime(_selectedDay.year, _selectedDay.month);
                _selectionInitialized = true;
                saved = true;
                Navigator.pop(dialogContext);
              },
            ),
          ),
        ),
      ),
    );
    if (!mounted || !api.valid) return;
    setState(() => _writing = false);
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date enregistrée dans votre agenda personnel.'),
        ),
      );
    }
    await _load();
  }

  Future<void> _cancel(PersonalAppointment appointment) async {
    final api = _api;
    if (api == null || !api.valid || _writing) return;
    var command = _pending[appointment.id];
    if (command == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Annuler cette date ?'),
          content: const Text(
            'Elle restera dans votre historique. Son rappel sera annulé. Cette action ne contacte pas le professionnel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Conserver'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Annuler la date'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted || !api.valid) return;
      command = AgendaCancellation(
        id: appointment.id,
        version: appointment.version,
      );
      _pending[appointment.id] = command;
    }
    setState(() {
      _writing = true;
      _loadVersion++;
    });
    try {
      await api.cancel(command);
      if (!mounted || !api.valid) return;
      _pending.remove(appointment.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Date annulée.')));
    } catch (e) {
      if (!mounted || !api.valid) return;
      final status = e is ApiException ? e.status : null;
      if (status != null && status < 500 && status != 408) {
        _pending.remove(appointment.id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 409
                ? 'Cette date a changé. L’agenda va être actualisé.'
                : _pending.containsKey(appointment.id)
                ? 'Annulation non confirmée. Réessayez la même annulation.'
                : e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted && api.valid) setState(() => _writing = false);
    }
    await _load();
  }

  String _reminderLabel(PersonalAppointment a) {
    if (a.cancelled) return 'Date annulée · Rappel annulé';
    if (a.reminderMinutes == null) return 'Sans rappel';
    return switch (_reminders[a.reminderId]) {
      'PLANIFIE' => 'Rappel planifié dans eCare+',
      'ENVOYE' => 'Rappel publié dans eCare+',
      'LU' => 'Rappel lu dans eCare+',
      'TERMINE' => 'Rappel terminé',
      'ANNULE' => 'Rappel annulé',
      'ECHEC' => 'Rappel en échec',
      _ => 'Statut du rappel indisponible',
    };
  }

  String _status(PersonalAppointment a) => switch (a.status) {
    'CONFIRME' => 'Confirmé',
    'REPORTE' => 'Reporté',
    'REALISE' => 'Réalisé',
    'ANNULE' => 'Annulé',
    _ => 'Planifié',
  };
  Widget _appointmentCard(PersonalAppointment a) => Container(
    key: ValueKey(a.id),
    decoration: a.id == widget.initialAppointmentId
        ? BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(24),
          )
        : null,
    child: CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    careTime(a.date.toLocal()),
                    textAlign: TextAlign.center,
                    style: AppDecor.t(
                      12,
                      c: AppColors.primary,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.motif, style: AppDecor.t(15, w: FontWeight.w600)),
                    if (a.professional != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          a.professional!,
                          style: AppDecor.t(12, c: AppColors.textMuted),
                        ),
                      ),
                    if (a.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          a.location!,
                          style: AppDecor.t(12, c: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: a.cancelled
                  ? const Color(0xFFF2F4F7)
                  : AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _status(a),
              style: AppDecor.t(
                10,
                c: a.cancelled ? AppColors.textMuted : AppColors.primary,
                w: FontWeight.w600,
              ),
            ),
          ),
          if (a.comment != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(a.comment!, style: AppDecor.t(12)),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _reminderLabel(a),
                  style: AppDecor.t(11, c: AppColors.textMuted),
                ),
              ),
            ],
          ),
          if (_pending.containsKey(a.id))
            const CareNotice(
              'Annulation non confirmée. Réessayez sans créer une nouvelle demande.',
              error: true,
            ),
          if (!a.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed:
                        _writing ||
                            _loading ||
                            _error != null ||
                            _pending.containsKey(a.id)
                        ? null
                        : () => _edit(a),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Modifier'),
                  ),
                  TextButton.icon(
                    onPressed: _writing || _loading || _error != null
                        ? null
                        : () => _cancel(a),
                    icon: const Icon(Icons.event_busy_outlined, size: 18),
                    label: Text(
                      _pending.containsKey(a.id)
                          ? 'Réessayer l’annulation'
                          : 'Annuler',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final valid = _api?.valid ?? false;
    final filtered = _rows.where((a) => a.cancelled == _cancelled).toList();
    final entries = filtered
        .where((a) => DateUtils.isSameDay(a.date.toLocal(), _selectedDay))
        .toList();
    final counts = <String, int>{};
    for (final a in filtered) {
      final key = calendarDayKey(a.date.toLocal());
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final label = calendarDateLabel(_selectedDay);
    return CarePage(
      title: 'Mes rendez-vous',
      subtitle: 'Votre suivi, un jour à la fois.',
      showBack: widget.showBack,
      child: !valid
          ? const CareNotice(
              'Connectez-vous avec votre consentement au suivi médical pour retrouver votre agenda personnel.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                CareMonthCalendar(
                  month: _month,
                  selectedDay: _selectedDay,
                  counts: counts,
                  onDaySelected: _selectDay,
                  onMonthChanged: _changeMonth,
                  onToday: () => _selectDay(DateTime.now()),
                  onPickDate: _pickCalendarDate,
                ),
                const SizedBox(height: 16),
                Tooltip(
                  message: 'Ajouter un rendez-vous',
                  child: FilledButton.icon(
                    onPressed: _loading || _writing || _error != null
                        ? null
                        : () => _edit(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Ajouter une date',
                      style: AppDecor.t(
                        13,
                        c: Colors.white,
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('Mes dates'),
                            selected: !_cancelled,
                            onSelected: (_) =>
                                setState(() => _cancelled = false),
                          ),
                          ChoiceChip(
                            label: const Text('Annulées'),
                            selected: _cancelled,
                            onSelected: (_) =>
                                setState(() => _cancelled = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Actualiser',
                      onPressed: _loading || _writing ? null : _load,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                if (_error != null) CareNotice(_error!, error: true),
                if (_reminderError != null)
                  CareNotice(_reminderError!, error: true),
                const SizedBox(height: 20),
                Text(
                  '${label[0].toUpperCase()}${label.substring(1)}',
                  style: AppDecor.t(
                    16,
                    c: AppColors.primaryDeep,
                    w: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${entries.length} rendez-vous${_cancelled ? ' annulé${entries.length > 1 ? 's' : ''}' : ''}',
                  style: AppDecor.t(11, c: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty && !_loading && _error == null)
                  CareEmpty(
                    icon: Icons.event_available_outlined,
                    title: _cancelled
                        ? 'Aucune date annulée ce jour'
                        : 'Une journée sans rendez-vous',
                    description:
                        'Choisissez un autre jour dans le calendrier${_cancelled ? '.' : ' ou ajoutez une date à votre suivi.'}',
                  ),
                for (final a in entries) ...[
                  _appointmentCard(a),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 16),
                Text(
                  'Agenda personnel enregistré sur votre compte. L’ajout d’une date ne réserve pas de consultation.',
                  textAlign: TextAlign.center,
                  style: AppDecor.t(10, c: AppColors.textMuted, h: 1.6),
                ),
              ],
            ),
    );
  }
}

Future<void> openAppointmentsPage(
  BuildContext context, {
  String doctor = '',
}) async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => AppointmentsPage(initialDoctor: doctor),
    ),
  );
}
