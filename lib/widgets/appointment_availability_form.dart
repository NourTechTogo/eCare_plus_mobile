import 'package:flutter/material.dart';
import '../models/personal_appointment.dart';
import '../services/api_session.dart';
import '../services/personal_agenda_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_decor.dart';
import 'care_components.dart';

/// A personal calendar entry, not a published medical availability or booking.
class AppointmentAvailabilityForm extends StatefulWidget {
  final PersonalAgendaApi api;
  final PersonalAppointment? appointment;
  final String doctor;
  final DateTime? initialDate;
  final ValueChanged<PersonalAppointment> onSaved;
  const AppointmentAvailabilityForm({
    super.key,
    required this.api,
    required this.onSaved,
    this.appointment,
    this.doctor = '',
    this.initialDate,
  });
  @override
  State<AppointmentAvailabilityForm> createState() =>
      _AppointmentAvailabilityFormState();
}

class _AppointmentAvailabilityFormState
    extends State<AppointmentAvailabilityForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _motif, _professional, _location, _comment;
  late DateTime _local;
  bool _dateChanged = false,
      _busy = false,
      _uncertain = false,
      _conflict = false;
  String? _error;
  int? _reminder;
  AgendaCommand? _command;
  bool get _enabled => !_busy && !_uncertain && !_conflict && widget.api.valid;
  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    _motif = TextEditingController(text: a?.motif ?? '');
    _professional = TextEditingController(
      text: a?.professional ?? widget.doctor,
    );
    _location = TextEditingController(text: a?.location ?? '');
    _comment = TextEditingController(text: a?.comment ?? '');
    _local =
        a?.date.toLocal() ??
        widget.initialDate ??
        DateTime.now().add(const Duration(days: 1));
    _reminder = a?.reminderMinutes;
    widget.api.addListener(_scopeChanged);
  }

  void _scopeChanged() {
    if (!mounted) return;
    if (!widget.api.valid) {
      for (final controller in [_motif, _professional, _location, _comment]) {
        controller.clear();
      }
      _command = null;
      _uncertain = false;
      _busy = false;
      _error = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.api.removeListener(_scopeChanged);
    for (final c in [_motif, _professional, _location, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _local,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (day == null || !mounted || !_enabled) return;
    _setDate(day.year, day.month, day.day, _local.hour, _local.minute);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_local),
    );
    if (time == null || !mounted || !_enabled) return;
    _setDate(_local.year, _local.month, _local.day, time.hour, time.minute);
  }

  void _setDate(int y, int m, int d, int h, int minute) {
    final value = DateTime(y, m, d, h, minute);
    if (value.year != y ||
        value.month != m ||
        value.day != d ||
        value.hour != h ||
        value.minute != minute) {
      setState(
        () => _error =
            'Cette heure locale n’existe pas. Choisissez une autre heure.',
      );
      return;
    }
    setState(() {
      _local = value;
      _dateChanged = true;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_busy || !widget.api.valid || _conflict) return;
    if (_command == null) {
      if (!_form.currentState!.validate()) return;
      try {
        _command = AgendaCommand(
          motif: _motif.text,
          date: !_dateChanged && widget.appointment != null
              ? widget.appointment!.date
              : _local,
          id: widget.appointment?.id,
          version: widget.appointment?.version,
          professional: _professional.text,
          location: _location.text,
          comment: _comment.text,
          rappelMinutes: _reminder,
        );
      } on ApiException catch (e) {
        setState(() => _error = e.message);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await widget.api.save(_command!);
      if (!mounted || !widget.api.valid) return;
      widget.onSaved(saved);
    } catch (e) {
      if (!mounted) return;
      final status = e is ApiException ? e.status : null;
      setState(() {
        _conflict = status == 409;
        _uncertain = status == null || status >= 500 || status == 408;
        if (!_uncertain) _command = null;
        _error = _conflict
            ? 'Cette date a changé sur le serveur. Fermez puis actualisez l’agenda avant de la modifier.'
            : _uncertain
            ? 'Réponse non confirmée. Réessayez le même enregistrement pour éviter un doublon.'
            : e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    if (_busy) return;
    if (_uncertain) {
      final abandon = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quitter cet enregistrement ?'),
          content: const Text(
            'Le serveur a peut-être déjà enregistré cette date. Actualisez votre agenda avant de créer une nouvelle entrée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Rester'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
      if (abandon != true || !mounted) return;
    }
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    filled: true,
    fillColor: AppColors.scaffoldBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );
  String? _length(String? value, int limit) =>
      (value?.trim().length ?? 0) > limit
      ? '$limit unités de texte au maximum.'
      : null;
  String _two(int n) => n.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) {
    if (!widget.api.valid) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CareNotice(
            'Session ou consentement modifié. Reconnectez-vous.',
            error: true,
          ),
          TextButton(onPressed: _close, child: const Text('Fermer')),
        ],
      );
    }
    final offset = _local.timeZoneOffset;
    final zone =
        'UTC${offset.isNegative ? '-' : '+'}${_two(offset.inMinutes.abs() ~/ 60)}:${_two(offset.inMinutes.abs() % 60)}';
    return PopScope(
      canPop: !_busy && !_uncertain,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.appointment == null
                  ? 'Ajouter une date'
                  : 'Modifier la date',
              style: AppDecor.t(
                21,
                c: AppColors.primaryDeep,
                w: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre agenda personnel · Une date ajoutée ici ne réserve pas de consultation.',
              style: AppDecor.t(12, c: AppColors.textMuted, h: 1.6),
            ),
            const SizedBox(height: 20),
            if (!widget.api.valid)
              const CareNotice(
                'Session ou consentement modifié. Reconnectez-vous.',
                error: true,
              ),
            TextFormField(
              controller: _motif,
              enabled: _enabled,
              maxLength: 200,
              decoration: _decoration('Motif', Icons.event_note_outlined),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Indiquez le motif.'
                  : _length(v, 200),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _professional,
              enabled: _enabled,
              maxLength: 200,
              decoration: _decoration(
                'Professionnel (facultatif)',
                Icons.person_outline,
              ),
              validator: (v) => _length(v, 200),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _enabled ? _pickDate : null,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    '${_two(_local.day)}/${_two(_local.month)}/${_local.year}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _enabled ? _pickTime : null,
                  icon: const Icon(Icons.schedule),
                  label: Text('${_two(_local.hour)}:${_two(_local.minute)}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Heure de votre appareil · $zone',
              style: AppDecor.t(11, c: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _location,
              enabled: _enabled,
              maxLength: 300,
              decoration: _decoration(
                'Lieu (facultatif)',
                Icons.place_outlined,
              ),
              validator: (v) => _length(v, 300),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _reminder ?? -1,
              isExpanded: true,
              decoration: _decoration(
                'Rappel dans eCare+',
                Icons.notifications_none_rounded,
              ),
              items: [
                const DropdownMenuItem(value: -1, child: Text('Sans rappel')),
                for (final n in {
                  0,
                  15,
                  30,
                  60,
                  1440,
                  ?_reminder,
                }.toList()..sort())
                  DropdownMenuItem(
                    value: n,
                    child: Text(
                      n == 0
                          ? 'À l’heure du rendez-vous'
                          : n == 1440
                          ? 'La veille'
                          : n == 60
                          ? '1 heure avant'
                          : '$n minutes avant',
                    ),
                  ),
              ],
              onChanged: _enabled
                  ? (n) => setState(() => _reminder = n == -1 ? null : n)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Le statut du rappel est suivi sur le serveur. La réception d’une notification externe dépend de sa configuration.',
              style: AppDecor.t(11, c: AppColors.textMuted, h: 1.5),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _comment,
              enabled: _enabled,
              maxLength: 2000,
              minLines: 2,
              maxLines: 4,
              decoration: _decoration(
                'Note (facultative)',
                Icons.notes_rounded,
              ),
              validator: (v) => _length(v, 2000),
            ),
            if (_error != null) CareNotice(_error!, error: true),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_busy || _conflict || !widget.api.valid)
                  ? null
                  : _save,
              icon: Icon(
                _busy ? Icons.hourglass_top_rounded : Icons.check_rounded,
              ),
              label: Text(
                _busy
                    ? 'Enregistrement…'
                    : _uncertain
                    ? 'Réessayer le même enregistrement'
                    : 'Enregistrer',
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _close,
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}
