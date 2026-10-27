import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../../services/care_api.dart';
import '../../models/care_data.dart';
import '../../widgets/care_page.dart';
import '../../widgets/care_components.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/personal_treatment_form.dart';

class TreatmentsPage extends StatefulWidget {
  const TreatmentsPage({super.key});
  @override
  State<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends State<TreatmentsPage> {
  Map<String, dynamic>? planning, observance;
  String? error;
  bool busy = false, loading = true;
  DateTime day = DateTime.now();
  final Map<String, Map<String, dynamic>> pending = {};
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    final api = context.read<ApiSession>(),
        generation = context.read<ApiSession>().generation;
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        CareApi(api).planning(day, day),
        CareApi(api).observance(day.subtract(const Duration(days: 29)), day),
      ]);
      if (!mounted || api.generation != generation) return;
      setState(() {
        planning = results[0];
        observance = results[1];
        error = null;
      });
    } catch (e) {
      if (mounted && api.generation == generation) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> respond(Map<String, dynamic> row, String action) async {
    if (busy) return;
    final key = '${row['id']}:$action';
    var operation = pending[key];
    if (operation == null) {
      DateTime? report;
      if (action == 'REPORTER') {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 7)),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time == null) return;
        report = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
      operation = {
        'source': 'prise-${DateTime.now().microsecondsSinceEpoch}',
        'date': DateTime.now(),
        'report': report,
      };
      pending[key] = operation;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      await CareApi(context.read<ApiSession>()).reply(
        row,
        action,
        sourceRef: operation['source'] as String,
        dateAction: operation['date'] as DateTime,
        reporteeAu: operation['report'] as DateTime?,
      );
      pending.remove(key);
      await load();
    } catch (e) {
      if (e is ApiException && e.status == 409) {
        pending.remove(key);
        await load();
      }
      if (mounted &&
          e is ApiException &&
          (e.status == null || e.status == 503)) {
        final queue = context.read<CareData?>()?.syncQueue;
        queue?.enqueueDirectReply(
          operation['source'] as String,
          '${row['id']}',
          {
            'action': action,
            'version': row['version'],
            'sourceRef': operation['source'],
            'dateAction': (operation['date'] as DateTime)
                .toUtc()
                .toIso8601String(),
            if (operation['report'] != null)
              'reporteeAu': (operation['report'] as DateTime)
                  .toUtc()
                  .toIso8601String(),
          },
        );
        setState(
          () => error =
              'Réponse non confirmée.${queue == null ? ' Réessayez ici.' : ' Elle attend dans Paramètres > Synchronisation, avant de fermer l’application.'}',
        );
      } else if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CarePage(
    title: 'Mes traitements',
    subtitle: 'Chaque prise, un pas pour votre santé.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CareSummary(
          icon: Icons.medication_outlined,
          title: 'Mon suivi au quotidien',
          description:
              'Retrouvez vos traitements et confirmez vos prises au fil de la journée.',
          footer: observance == null
              ? null
              : Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Observance sur 30 jours : ${observance!['taux'] == null ? 'non calculable' : '${(observance!['taux'] as num).toStringAsFixed(0)} %'} (${observance!['prisesConfirmees']}/${observance!['prisesPrevues']})',
                    style: AppDecor.t(12, c: Colors.white, h: 1.6),
                  ),
                ),
        ),
        const SizedBox(height: 22),
        CareAction(
          label: 'Déclarer un traitement',
          icon: Icons.add,
          onPressed: busy || loading
              ? null
              : () async {
                  final saved = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => const PersonalTreatmentForm(),
                    ),
                  );
                  if (saved == true && mounted) await load();
                },
        ),
        const SizedBox(height: 14),
        CareCard(
          child: Row(
            children: [
              IconButton(
                tooltip: 'Jour précédent',
                onPressed: busy || loading
                    ? null
                    : () {
                        day = day.subtract(const Duration(days: 1));
                        load();
                      },
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Mon programme',
                      style: AppDecor.t(11, c: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      civilDate(day),
                      textAlign: TextAlign.center,
                      style: AppDecor.t(
                        15,
                        w: FontWeight.w700,
                        c: AppColors.primaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Jour suivant',
                onPressed: busy || loading
                    ? null
                    : () {
                        day = day.add(const Duration(days: 1));
                        load();
                      },
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
              ),
            ],
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LinearProgressIndicator(),
          ),
        if (error != null) CareNotice(error!, error: true),
        CareSection(
          title: 'Prises de la journée',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (planning != null &&
                  (planning!['occurrences'] as List? ?? []).isEmpty)
                const CareEmpty(
                  icon: Icons.event_available_outlined,
                  title: 'Aucune prise prévue pour ce jour.',
                  description:
                      'Vos prises apparaîtront ici selon votre prescription.',
                ),
              for (final raw in planning?['occurrences'] as List? ?? [])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _occurrence(Map<String, dynamic>.from(raw as Map)),
                ),
            ],
          ),
        ),
        if ((planning?['traitements'] as List? ?? []).isNotEmpty)
          CareSection(
            title: 'Traitements enregistrés',
            child: Column(
              children: [
                for (final raw in planning!['traitements'] as List)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CareDetail(
                      icon: Icons.medication_outlined,
                      title:
                          '${raw['libelle']}${raw['declarationPersonnelle'] == true ? ' · Déclaration personnelle' : ''}',
                      detail:
                          '${raw['consignes'] ?? (raw['declarationPersonnelle'] == true ? 'Traitement déclaré par vous. Cette déclaration ne constitue pas une prescription médicale.' : 'Suivez les consignes de votre médecin.')}${(raw['prises'] as List? ?? []).any((p) => p['configurationRequise'] == true) ? '\nHoraires à préciser.' : ''}',
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        CareAction(
          label: 'Actualiser',
          icon: Icons.refresh_rounded,
          onPressed: busy || loading ? null : load,
        ),
      ],
    ),
  );
  Widget _occurrence(Map<String, dynamic> row) {
    final date = DateTime.parse(
      '${row['reporteeAu'] ?? row['prevueLe']}',
    ).toLocal();
    final actionable =
        row['annulee'] != true &&
        (row['statut'] == 'ATTENTE' || row['statut'] == 'REPORTEE');
    const labels = {
      'ATTENTE': 'À prendre',
      'REPORTEE': 'Reportée',
      'PRISE': 'Prise confirmée',
      'OUBLIEE': 'Ignorée',
    };
    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row['medicament']}',
                      style: AppDecor.t(16, w: FontWeight.w700, h: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${row['dosage'] ?? ''} ${row['uniteDosage'] ?? ''}',
                      style: AppDecor.t(12, c: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(careTime(date)),
                backgroundColor: AppColors.primaryLighter,
                side: BorderSide.none,
              ),
              Chip(
                label: Text(
                  row['annulee'] == true
                      ? 'Annulée'
                      : labels[row['statut']] ?? '${row['statut']}',
                ),
                backgroundColor: AppColors.scaffoldBackground,
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${row['quantite']} ${row['unite']} · ${row['fuseau']}',
            style: AppDecor.t(12, c: AppColors.textMuted, h: 1.5),
          ),
          if (actionable) ...[
            const SizedBox(height: 18),
            CareAction(
              label: 'Pris',
              icon: Icons.check_rounded,
              onPressed: busy ? null : () => respond(row, 'PRIS'),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                TextButton(
                  onPressed: busy ? null : () => respond(row, 'REPORTER'),
                  child: const Text('Reporter'),
                ),
                TextButton(
                  onPressed: busy ? null : () => respond(row, 'IGNORER'),
                  child: const Text('Ignorer'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
