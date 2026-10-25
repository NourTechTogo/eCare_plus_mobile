import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../../widgets/care_page.dart';
import '../../widgets/care_components.dart';
import '../../utils/app_colors.dart';
import '../../widgets/target_notes.dart';

class MeasureNotesPage extends StatefulWidget {
  const MeasureNotesPage({super.key});
  @override
  State<MeasureNotesPage> createState() => _MeasureNotesPageState();
}

class _MeasureNotesPageState extends State<MeasureNotesPage> {
  List<Map<String, dynamic>> measures = [];
  String? error;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final rows = await context.read<ApiSession>().all('/mobile/me/mesures');
      if (mounted) setState(() => measures = rows);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => CarePage(
    title: 'Notes sur mes mesures',
    subtitle: 'Retrouvez le contexte de votre suivi.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CareSummary(
          icon: Icons.edit_note_rounded,
          title: 'Votre carnet de notes',
          description:
              'Ajoutez une précision à une mesure ou retrouvez les échanges avec votre professionnel.',
        ),
        if (error != null) CareNotice(error!, error: true),
        CareSection(
          title: 'Mes mesures',
          subtitle: 'Ouvrez une mesure pour consulter ses notes.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (measures.isEmpty && error == null)
                const CareEmpty(
                  icon: Icons.notes_rounded,
                  title: 'Aucune mesure pour le moment',
                  description:
                      'Vos mesures enregistrées et leurs notes apparaîtront ici.',
                ),
              for (final m in measures)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CareDetail(
                    icon: Icons.monitor_heart_outlined,
                    title: measureLabel('${m['typeMesure']}'),
                    detail:
                        '${m['valeurPrincipale'] ?? '—'}${m['valeurSecondaire'] == null ? '' : ' / ${m['valeurSecondaire']}'} ${m['unite'] ?? ''} · ${measureDate('${m['dateMesure']}')}',
                    action: OutlinedButton.icon(
                      onPressed: () =>
                          showTargetNotes(context, 'MESURE', '${m['id']}'),
                      icon: const Icon(Icons.note_outlined, size: 18),
                      label: const Text('Ouvrir les notes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CareAction(
          label: 'Actualiser',
          icon: Icons.refresh_rounded,
          onPressed: load,
        ),
      ],
    ),
  );
  String measureLabel(String type) =>
      const {
        'GLYCEMIE': 'Glycémie',
        'PRESSION_ARTERIELLE': 'Tension artérielle',
        'TENSION_ARTERIELLE': 'Tension artérielle',
        'POIDS': 'Poids',
        'TEMPERATURE': 'Température',
        'FREQUENCE_CARDIAQUE': 'Fréquence cardiaque',
        'SATURATION_OXYGENE': 'Saturation en oxygène',
        'SPO2': 'Saturation en oxygène',
      }[type] ??
      'Mesure de santé';
  String measureDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    return date == null
        ? 'Date non renseignée'
        : '${careDate(date)} à ${careTime(date)}';
  }
}
