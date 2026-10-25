import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/care_date_time_picker.dart';
import 'package:provider/provider.dart';
import '../../models/care_data.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';
import '../../widgets/page_header.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/measurement_chart.dart';

enum FollowUpMode { combined, glucose, bloodPressure }

class FollowUpPage extends StatefulWidget {
  final FollowUpMode mode;
  const FollowUpPage({super.key, this.mode = FollowUpMode.combined});
  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> {
  bool _selectedPressure = false;
  @override
  void initState() {
    super.initState();
    final data = context.read<CareData>();
    Future.microtask(data.refresh);
  }

  bool get _pressure => switch (widget.mode) {
    FollowUpMode.combined => _selectedPressure,
    FollowUpMode.glucose => false,
    FollowUpMode.bloodPressure => true,
  };
  int _period = 0;

  DateTime _start(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (_period < 2) {
      return today.subtract(Duration(days: _period == 0 ? 6 : 29));
    }
    final month = DateTime(now.year, now.month - (_period == 2 ? 3 : 6), 1);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, math.min(now.day, lastDay));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<CareData>();
    final now = DateTime.now();
    final start = _start(now);
    final points =
        (_pressure
                ? data.bloodPressureReadings.map(
                    (reading) => MeasurementPoint(
                      reading.date,
                      reading.systolic,
                      reading.diastolic,
                    ),
                  )
                : data.readings.map(
                    (reading) => MeasurementPoint(reading.date, reading.value),
                  ))
            .where(
              (point) =>
                  !point.date.isBefore(start) && !point.date.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                if (data.syncError != null) Text(data.syncError!),
                PageHeader(
                  title: switch (widget.mode) {
                    FollowUpMode.combined => 'Mon suivi',
                    FollowUpMode.glucose => 'Mon suivi glycémie',
                    FollowUpMode.bloodPressure => 'Mon suivi tension',
                  },
                  subtitle: switch (widget.mode) {
                    FollowUpMode.combined =>
                      'Vos constantes et leur évolution, au même endroit.',
                    FollowUpMode.glucose =>
                      'Votre glycémie et son évolution, au même endroit.',
                    FollowUpMode.bloodPressure =>
                      'Votre tension artérielle et son évolution, au même endroit.',
                  },
                ),
                if (widget.mode == FollowUpMode.combined)
                  for (final m in data.measurements.where(
                    (m) => ![
                      'GLYCEMIE',
                      'TENSION_ARTERIELLE',
                    ].contains(m['typeMesure']),
                  ))
                    Card(
                      child: ListTile(
                        title: Text(
                          "${m['typeMesure']} : ${m['valeurPrincipale']} ${m['unite']}",
                        ),
                        subtitle: Text("${m['dateMesure']}"),
                      ),
                    ),
                const SizedBox(height: 26),
                if (widget.mode == FollowUpMode.combined) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _tab('Glycémie', false),
                        _tab('Tension artérielle', true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              ['7 jours', '30 jours', '3 mois', '6 mois'][i],
                            ),
                            selected: _period == i,
                            selectedColor: AppColors.primary,
                            labelStyle: AppDecor.t(
                              12,
                              w: FontWeight.w600,
                              c: _period == i
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _period = i),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pressure
                                      ? 'Évolution de la tension'
                                      : 'Évolution de la glycémie',
                                  style: AppDecor.t(16, w: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${points.length} ${points.length == 1 ? 'mesure' : 'mesures'} sur la période',
                                  style: AppDecor.t(11, c: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Ajouter une mesure',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _addMeasurement,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      MeasurementChart(
                        key: const ValueKey('measurement-chart'),
                        points: points,
                        start: start,
                        end: now,
                        pressure: _pressure,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Répartition des mesures',
                        style: AppDecor.t(
                          17,
                          w: FontWeight.w700,
                          c: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Par moment de la journée',
                        style: AppDecor.t(11, c: AppColors.textMuted),
                      ),
                      const SizedBox(height: 18),
                      MeasurementDistribution(
                        dates: points.map((point) => point.date).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'lib/data/Icon_bon a savoir.png',
                        width: 48,
                        height: 54,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bon à savoir',
                              style: AppDecor.t(
                                14,
                                w: FontWeight.w700,
                                c: const Color(0xFF315D85),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Le bouton + permet d’ajouter une constante avec sa date. Les courbes suivent les mesures de la période choisie.',
                              style: AppDecor.t(
                                12,
                                c: const Color(0xFF315D85),
                                h: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (points.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Historique de la période',
                    style: AppDecor.t(16, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  for (final point in points.reversed) ...[
                    CareCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${careDate(point.date)} · ${careTime(point.date)}',
                            style: AppDecor.t(11, c: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pressure
                                ? '${point.primary} / ${point.secondary} mmHg'
                                : '${point.primary} mg/dL',
                            style: AppDecor.t(
                              15,
                              w: FontWeight.w700,
                              c: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                const SizedBox(height: 10),
                Text(
                  'Mesures conservées pendant cette session.',
                  textAlign: TextAlign.center,
                  style: AppDecor.t(10, c: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool pressure) => Expanded(
    child: Material(
      color: _pressure == pressure ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => setState(() => _selectedPressure = pressure),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppDecor.t(
              13,
              w: FontWeight.w700,
              c: _pressure == pressure ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _addMeasurement() =>
      showMeasurementSheet(context, pressure: _pressure);
}

/// Shared entry point for the follow-up page and the central navigation action.
Future<void> showMeasurementSheet(
  BuildContext context, {
  bool? pressure,
}) async {
  final result = await showDialog<_MeasurementInput>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppColors.scaffoldBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(dialogContext).height * .88,
        ),
        child: _MeasurementForm(pressure: pressure),
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Constante enregistrée')));
}

class _MeasurementInput {
  final double primary;
  final double? secondary;
  final DateTime date;
  const _MeasurementInput(this.primary, this.secondary, this.date);
}

class _MeasurementForm extends StatefulWidget {
  final bool? pressure;
  const _MeasurementForm({this.pressure});
  @override
  State<_MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<_MeasurementForm> {
  late String _type = widget.pressure == true
      ? 'TENSION_ARTERIELLE'
      : 'GLYCEMIE';
  bool get _pressure => _type == 'TENSION_ARTERIELLE';
  bool _busy = false;
  final String _sourceRef = 'manual-${DateTime.now().microsecondsSinceEpoch}';
  static const types = {
    'GLYCEMIE': 'Glycémie',
    'TENSION_ARTERIELLE': 'Tension artérielle',
    'POIDS': 'Poids',
    'FREQUENCE_CARDIAQUE': 'Fréquence cardiaque',
    'TEMPERATURE': 'Température',
    'SPO2': 'Saturation en oxygène',
  };
  String get unit => {
    'GLYCEMIE': 'mg/dL',
    'TENSION_ARTERIELLE': 'mmHg',
    'POIDS': 'kg',
    'FREQUENCE_CARDIAQUE': 'bpm',
    'TEMPERATURE': '°C',
    'SPO2': '%',
  }[_type]!;
  final _form = GlobalKey<FormState>();
  final _primary = TextEditingController();
  final _secondary = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;
  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
  Widget _field(TextEditingController controller, String label, String unit) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        validator: (value) {
          final number = _parse(value ?? '');
          return number == null || !number.isFinite || number <= 0
              ? 'Saisissez une valeur positive en $unit'
              : null;
        },
      );
  Future<void> save() async {
    if (!_form.currentState!.validate()) return;
    if (_date.isAfter(DateTime.now())) {
      setState(
        () => _error = 'La date de la mesure ne peut pas être dans le futur.',
      );
      return;
    }
    if (_pressure && _parse(_primary.text)! <= _parse(_secondary.text)!) {
      setState(
        () => _error = 'La systolique doit être supérieure à la diastolique.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<CareData>().submitMeasurement(
        _type,
        _parse(_primary.text)!,
        unit,
        secondary: _pressure ? _parse(_secondary.text) : null,
        date: _date,
        sourceRef: _sourceRef,
      );
      if (!mounted) return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(
      context,
      _MeasurementInput(
        _parse(_primary.text)!,
        _pressure ? _parse(_secondary.text)! : null,
        _date,
      ),
    );
  }

  IconData iconFor(String type) => switch (type) {
    'GLYCEMIE' => Icons.water_drop_outlined,
    'TENSION_ARTERIELLE' => Icons.monitor_heart_outlined,
    'POIDS' => Icons.monitor_weight_outlined,
    'FREQUENCE_CARDIAQUE' => Icons.favorite_border_rounded,
    'TEMPERATURE' => Icons.thermostat_rounded,
    _ => Icons.air_rounded,
  };
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, layout) => Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pressure == null
                            ? 'Ajouter une constante'
                            : _pressure
                            ? 'Nouvelle tension artérielle'
                            : 'Nouvelle glycémie',
                        style: AppDecor.t(
                          20,
                          w: FontWeight.w700,
                          c: AppColors.primaryDeep,
                          h: 1.3,
                        ),
                      ),
                      if (layout.maxHeight > 460) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Renseignez votre mesure et le moment de la prise.',
                          style: AppDecor.t(12, c: AppColors.textMuted, h: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.pressure == null) ...[
                    Text(
                      'Quelle constante souhaitez-vous ajouter ?',
                      style: AppDecor.t(13, w: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, c) {
                        if (c.maxWidth < 330) {
                          return DropdownButtonFormField<String>(
                            initialValue: _type,
                            isExpanded: true,
                            itemHeight: null,
                            decoration: InputDecoration(
                              labelText: 'Type de constante',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                            items: [
                              for (final type in types.keys)
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    types[type]!,
                                    style: AppDecor.t(13, w: FontWeight.w600),
                                    softWrap: true,
                                  ),
                                ),
                            ],
                            onChanged: _busy
                                ? null
                                : (type) {
                                    if (type == null || type == _type) {
                                      return;
                                    }
                                    setState(() {
                                      _type = type;
                                      _primary.clear();
                                      _secondary.clear();
                                      _error = null;
                                      _form.currentState?.reset();
                                    });
                                  },
                          );
                        }
                        final single =
                            MediaQuery.textScalerOf(context).scale(14) > 20;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final type in types.keys)
                              SizedBox(
                                width: single
                                    ? c.maxWidth
                                    : (c.maxWidth - 10) / 2,
                                child: Semantics(
                                  button: true,
                                  selected: _type == type,
                                  child: Material(
                                    color: _type == type
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: _busy || _type == type
                                          ? null
                                          : () => setState(() {
                                              _type = type;
                                              _primary.clear();
                                              _secondary.clear();
                                              _error = null;
                                              _form.currentState?.reset();
                                            }),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minHeight: 60,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _type == type
                                                ? AppColors.primary
                                                : AppColors.border,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              iconFor(type),
                                              size: 19,
                                              color: _type == type
                                                  ? Colors.white
                                                  : AppColors.primary,
                                            ),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Text(
                                                types[type]!,
                                                style: AppDecor.t(
                                                  12,
                                                  w: FontWeight.w600,
                                                  c: _type == type
                                                      ? Colors.white
                                                      : AppColors.textMuted,
                                                  h: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                  ],
                  Text(
                    'Valeur mesurée',
                    style: AppDecor.t(
                      13,
                      w: FontWeight.w600,
                      c: AppColors.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _primary,
                    _pressure ? 'Systolique' : types[_type]!,
                    unit,
                  ),
                  if (_pressure) ...[
                    const SizedBox(height: 14),
                    _field(_secondary, 'Diastolique', 'mmHg'),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Date et heure',
                    style: AppDecor.t(
                      13,
                      w: FontWeight.w600,
                      c: AppColors.primaryDeep,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(careDate(_date)),
                    trailing: const Icon(Icons.edit_outlined, size: 18),
                    onTap: () async {
                      final date = await showCareDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null && mounted) {
                        setState(
                          () => _date = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            _date.hour,
                            _date.minute,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(careTime(_date)),
                    trailing: const Icon(Icons.edit_outlined, size: 18),
                    onTap: () async {
                      final time = await showCareTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_date),
                      );
                      if (time != null && mounted) {
                        setState(
                          () => _date = DateTime(
                            _date.year,
                            _date.month,
                            _date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    },
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: AppDecor.t(12, c: AppColors.required, h: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: GradientButton(
              text: 'Enregistrer la mesure',
              isLoading: _busy,
              onPressed: save,
            ),
          ),
        ],
      ),
    ),
  );
}
