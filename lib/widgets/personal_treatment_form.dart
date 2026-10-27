import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/api_session.dart';
import '../services/care_api.dart';
import 'care_page.dart';
import 'care_components.dart';

/// Records the patient's own declaration; never edits a professional prescription.
class PersonalTreatmentForm extends StatefulWidget {
  const PersonalTreatmentForm({super.key});
  @override
  State<PersonalTreatmentForm> createState() => _PersonalTreatmentFormState();
}

class _PersonalTreatmentFormState extends State<PersonalTreatmentForm> {
  final form = GlobalKey<FormState>();
  final fields = {
    'treatment-name': TextEditingController(),
    'medicine-name': TextEditingController(),
    'medicine-dose': TextEditingController(),
    'medicine-dose-unit': TextEditingController(),
    'medicine-form': TextEditingController(),
    'intake-quantity': TextEditingController(text: '1'),
    'intake-unit': TextEditingController(),
  };
  DateTime start = DateUtils.dateOnly(DateTime.now());
  DateTime? end;
  TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);
  String? error;
  bool busy = false;
  Map<String, dynamic>? pending;
  late final ApiSession _openingSession;
  late final int _openingGeneration;
  bool _expired = false;

  bool get _sessionCurrent =>
      !_expired &&
      _openingSession.authenticated &&
      _openingSession.generation == _openingGeneration;

  @override
  void initState() {
    super.initState();
    _openingSession = context.read<ApiSession>();
    _openingGeneration = _openingSession.generation;
    _openingSession.addListener(_sessionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!identical(context.watch<ApiSession>(), _openingSession) ||
        !_sessionCurrent) {
      _clearExpiredForm();
    }
  }

  void _clearExpiredForm() {
    _expired = true;
    pending = null;
    error = null;
    busy = false;
    end = null;
    start = DateUtils.dateOnly(DateTime.now());
    time = const TimeOfDay(hour: 8, minute: 0);
    for (final controller in fields.values) {
      controller.clear();
    }
  }

  void _sessionChanged() {
    if (!_sessionCurrent && !_expired && mounted) {
      setState(_clearExpiredForm);
    }
  }

  @override
  void dispose() {
    _openingSession.removeListener(_sessionChanged);
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> selectDate(bool isEnd) async {
    if (!_sessionCurrent) return;
    final selected = await showDatePicker(
      context: context,
      initialDate: isEnd ? end ?? start : start,
      firstDate: isEnd ? start : DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted || !_sessionCurrent) return;
    setState(() {
      if (isEnd) {
        end = selected;
      } else {
        start = selected;
        if (end != null && end!.isBefore(start)) end = null;
      }
    });
  }

  Future<void> save() async {
    if (!_sessionCurrent || busy || !form.currentState!.validate()) return;
    final payload = pending ??= {
      'libelle': fields['treatment-name']!.text.trim(),
      'dateDebut': civilDate(start),
      'dateFin': end == null ? null : civilDate(end!),
      'medicament': {
        'nomCommercial': fields['medicine-name']!.text.trim(),
        'dosage': fields['medicine-dose']!.text.trim(),
        'uniteDosage': fields['medicine-dose-unit']!.text.trim(),
        'forme': fields['medicine-form']!.text.trim(),
      },
      'prise': {
        'quantite': double.parse(
          fields['intake-quantity']!.text.replaceAll(',', '.'),
        ),
        'unite': fields['intake-unit']!.text.trim(),
        'heurePrevue':
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'fuseau': 'UTC',
        'joursSemaine': [1, 2, 3, 4, 5, 6, 7],
      },
      'sourceRef': const Uuid().v4(),
    };
    final api = _openingSession;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await api.request('POST', '/mobile/me/traitements', body: payload);
      if (mounted && _sessionCurrent) Navigator.pop(context, true);
    } catch (e) {
      if (mounted && _sessionCurrent) {
        setState(() {
          error = e.toString();
          // A definitive validation refusal permits correction and a new operation.
          if (e is ApiException &&
              (e.status == 400 || e.status == 422 || e.status == 403)) {
            pending = null;
          }
        });
      }
    } finally {
      if (mounted && _sessionCurrent) setState(() => busy = false);
    }
  }

  Widget input(String key, String label, {bool quantity = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: Key(key),
      controller: fields[key],
      enabled: !busy && pending == null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: quantity
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Obligatoire';
        if (quantity) {
          final n = double.tryParse(v.replaceAll(',', '.'));
          if (n == null || !n.isFinite || n <= 0) {
            return 'Saisissez une quantité positive';
          }
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => !_sessionCurrent
      ? const CarePage(
          title: 'Session expirée',
          subtitle: null,
          child: Text(
            'Rouvrez le formulaire depuis votre session actuelle. Les données de cette déclaration ont été effacées.',
          ),
        )
      : CarePage(
          title: 'Déclarer un traitement',
          subtitle: 'Déclaration personnelle, sans prescription médicale.',
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Recopiez votre traitement existant et ses horaires. Cette déclaration ne remplace pas les consignes de votre professionnel.',
                ),
                const SizedBox(height: 18),
                input('treatment-name', 'Nom du traitement'),
                input('medicine-name', 'Nom du médicament'),
                input('medicine-dose', 'Dosage indiqué'),
                input('medicine-dose-unit', 'Unité du dosage'),
                input('medicine-form', 'Forme (comprimé, solution…)'),
                input('intake-quantity', 'Quantité par prise', quantity: true),
                input('intake-unit', 'Unité de prise'),
                TextButton(
                  onPressed: busy || pending != null
                      ? null
                      : () => selectDate(false),
                  child: Text('Début : ${civilDate(start)}'),
                ),
                TextButton(
                  onPressed: busy || pending != null
                      ? null
                      : () => selectDate(true),
                  child: Text(
                    end == null
                        ? 'Ajouter une date de fin (facultatif)'
                        : 'Fin : ${civilDate(end!)}',
                  ),
                ),
                if (end != null)
                  TextButton(
                    onPressed: busy || pending != null
                        ? null
                        : () => setState(() => end = null),
                    child: const Text('Sans date de fin'),
                  ),
                const Text(
                  'Une prise chaque jour, du lundi au dimanche. Horaire en UTC : vérifiez le décalage avec votre heure locale.',
                ),
                TextButton(
                  onPressed: busy || pending != null
                      ? null
                      : () async {
                          if (!_sessionCurrent) return;
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );
                          if (selected != null && mounted && _sessionCurrent) {
                            setState(() => time = selected);
                          }
                        },
                  child: Text(
                    'Heure UTC : ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                if (error != null) Text(error!),
                if (pending != null && !busy)
                  const Text(
                    'Transmission non confirmée. Réessayez cette même déclaration avant de la modifier.',
                  ),
                const SizedBox(height: 18),
                CareAction(
                  label: 'Enregistrer ma déclaration',
                  icon: Icons.save_outlined,
                  onPressed: busy ? null : save,
                ),
              ],
            ),
          ),
        );
}
