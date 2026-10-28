import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';

List<Map<String, dynamic>> reportRows(dynamic value) => value is List
    ? value.whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList()
    : [];
String reportValue(dynamic value) =>
    value == null || '$value'.isEmpty ? 'Non renseigné' : '$value';
String reportDate(dynamic value) {
  final date = DateTime.tryParse('$value');
  if (date == null) return reportValue(value);
  return '${careDate(date.toUtc())}${'$value'.contains('T') ? ' à ${date.toUtc().hour.toString().padLeft(2, '0')}:${date.toUtc().minute.toString().padLeft(2, '0')} UTC' : ''}';
}

String reportMeasureName(Map<String, dynamic> row) {
  final name =
      const {
        'GLYCEMIE': 'Glycémie',
        'POIDS': 'Poids',
        'TENSION_ARTERIELLE': 'Tension artérielle',
        'FREQUENCE_CARDIAQUE': 'Fréquence cardiaque',
        'TEMPERATURE': 'Température',
        'SATURATION_OXYGENE': 'Saturation en oxygène',
      }[row['typeMesure']] ??
      reportValue(row['typeMesure']);
  return row['composante'] == 'DIASTOLIQUE' ? '$name · Diastolique' : name;
}

class ConsultationReportDetail extends StatelessWidget {
  final Map<String, dynamic> report;
  const ConsultationReportDetail({super.key, required this.report});
  @override
  Widget build(BuildContext context) {
    final patient = Map<String, dynamic>.from(report['patient'] as Map? ?? {});
    final series = reportRows(report['seriesMesures']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${patient['prenoms'] ?? ''} ${patient['nom'] ?? ''}'.trim(),
                style: AppDecor.t(18, w: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Du ${reportDate(report['du'])} au ${reportDate(report['au'])}',
                style: AppDecor.t(13),
              ),
              const SizedBox(height: 6),
              Text(
                'Fuseau : ${report['fuseau']}\nEnregistré le ${reportDate(report['genereLe'])}',
                style: AppDecor.t(12, c: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  Text(
                    '${report['nombreMesures']} mesures',
                    style: AppDecor.t(
                      14,
                      w: FontWeight.w600,
                      c: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${report['joursSansSaisie']} jours sans saisie',
                    style: AppDecor.t(13, c: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (series.isEmpty)
          const CareCard(
            child: Text('Aucune mesure enregistrée sur cette période.'),
          ),
        for (final serie in series) ...[
          CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reportMeasureName(serie),
                  style: AppDecor.t(
                    16,
                    w: FontWeight.w700,
                    c: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Moyenne : ${serie['moyenne']} ${serie['unite']}',
                      style: AppDecor.t(14, w: FontWeight.w600),
                    ),
                    Text(
                      'Min. ${serie['minimum']} · Max. ${serie['maximum']}',
                      style: AppDecor.t(12, c: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${serie['nombre']} valeurs · ${serie['joursSansSaisie']} jours sans saisie',
                  style: AppDecor.t(12, c: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dernière valeur : ${serie['derniereValeur']} ${serie['unite']}\n${reportDate(serie['derniereLe'])}',
                  style: AppDecor.t(12),
                ),
                const SizedBox(height: 16),
                ReportSeriesChart(serie: serie),
                _ReportRecords(
                  title: 'Valeurs enregistrées',
                  rows: reportRows(serie['points']),
                  describe: (p) =>
                      '${reportDate(p['dateMesure'])}\n${p['valeur']} ${serie['unite']} · ${reportValue(p['contexte'])}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _ReportRecords(
          title: 'Traitements',
          rows: reportRows(report['traitements']),
          describe: (t) {
            final horaires = reportRows(t['horaires'])
                .map(
                  (h) =>
                      '${reportValue(h['medicament'])} ${h['dosage'] ?? ''} ${h['uniteDosage'] ?? ''} · ${h['quantite']} ${h['unite']} à ${h['heurePrevue']} (${h['fuseau']}) · Jours ISO ${h['joursSemaine']} · ${h['actif'] == true ? 'Actif' : 'Inactif'}',
                )
                .join('\n');
            return '${t['libelle']} · ${t['statutCourant']}\n${t['declarationPersonnelle'] == true ? 'Déclaration personnelle' : 'Dossier de soins'} · Du ${reportDate(t['dateDebut'])} au ${reportDate(t['dateFin'])}\n$horaires';
          },
        ),
        _ReportRecords(
          title: 'Réponses aux prises',
          rows: reportRows(report['reponsesPrises']),
          describe: (p) =>
              '${reportValue(p['medicament'])} ${p['dosage'] ?? ''} ${p['uniteDosage'] ?? ''} · ${p['quantite']} ${p['unite']}\n${reportValue(p['forme'])} · ${reportValue(p['voieAdministration'])}\n${reportDate(p['prevueLe'])} · ${p['statut']}\nReport : ${reportDate(p['reporteeAu'])} · Confirmation : ${reportDate(p['dateConfirmation'])}',
        ),
        _ReportRecords(
          title: 'Alertes enregistrées',
          rows: reportRows(report['alertes']),
          describe: (a) {
            final rule = a['regleAppliquee'];
            return '${a['titre']} · ${a['niveauPriorite']}\n${reportDate(a['dateEvenement'])} · ${a['statut']}\n${rule is Map ? 'Règle : ${rule['nom']} · version ${rule['version']} · ${rule['operateur']} ${rule['seuilMin'] ?? ''} ${rule['seuilMax'] ?? ''} ${rule['unite'] ?? ''}' : 'Capture de règle historique indisponible.'}';
          },
        ),
        _ReportRecords(
          title: 'Agenda personnel',
          rows: reportRows(report['rendezVous']),
          describe: (r) =>
              '${r['motif']} · ${r['statut']}\n${reportDate(r['dateHeure'])}\n${reportValue(r['lieu'])} · ${reportValue(r['professionnelNom'])}',
        ),
        const SizedBox(height: 16),
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repères de lecture',
                style: AppDecor.t(15, w: FontWeight.w700),
              ),
              for (final note in (report['avertissements'] as List? ?? []))
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '$note',
                    style: AppDecor.t(12, c: AppColors.textMuted, h: 1.6),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportRecords extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic>) describe;
  const _ReportRecords({
    required this.title,
    required this.rows,
    required this.describe,
  });
  @override
  State<_ReportRecords> createState() => _ReportRecordsState();
}

class _ReportRecordsState extends State<_ReportRecords> {
  int visible = 10;
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.only(bottom: 10),
      title: Text(
        '${widget.title} (${widget.rows.length})',
        style: AppDecor.t(14, w: FontWeight.w600),
      ),
      children: [
        if (widget.rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Aucun élément enregistré sur cette période.'),
          ),
        for (final row in widget.rows.take(visible))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Text(widget.describe(row), style: AppDecor.t(12, h: 1.6)),
          ),
        if (visible < widget.rows.length)
          TextButton(
            onPressed: () => setState(() => visible += 10),
            child: const Text('Afficher les éléments suivants'),
          ),
      ],
    ),
  );
}

class ReportSeriesChart extends StatelessWidget {
  final Map<String, dynamic> serie;
  const ReportSeriesChart({super.key, required this.serie});
  @override
  Widget build(BuildContext context) {
    final points = reportRows(serie['points']);
    if (points.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label:
          'Graphique descriptif de ${reportMeasureName(serie)}, ${points.length} valeurs en ${serie['unite']}. Détails dans les valeurs enregistrées.',
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${serie['maximum']} ${serie['unite']}',
                style: AppDecor.t(10, c: AppColors.textMuted),
              ),
            ],
          ),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _ReportPoints(
                points,
                (serie['minimum'] as num).toDouble(),
                (serie['maximum'] as num).toDouble(),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                '${serie['minimum']} ${serie['unite']}',
                style: AppDecor.t(10, c: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  reportDate(points.first['dateMesure']),
                  style: AppDecor.t(10, c: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reportDate(points.last['dateMesure']),
                  textAlign: TextAlign.right,
                  style: AppDecor.t(10, c: AppColors.textMuted),
                ),
              ),
            ],
          ),
          Text(
            'Points enregistrés, sans interpolation · instants UTC',
            style: AppDecor.t(10, c: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReportPoints extends CustomPainter {
  final List<Map<String, dynamic>> points;
  final double min, max;
  _ReportPoints(this.points, this.min, this.max);
  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(
      8,
      8,
      math.max(1, size.width - 16),
      math.max(1, size.height - 16),
    );
    final axis = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(area.topLeft, area.bottomLeft, axis);
    canvas.drawLine(area.bottomLeft, area.bottomRight, axis);
    final start = DateTime.parse(
      points.first['dateMesure'] as String,
    ).millisecondsSinceEpoch;
    final end = DateTime.parse(
      points.last['dateMesure'] as String,
    ).millisecondsSinceEpoch;
    final paint = Paint()..color = AppColors.primary;
    for (final p in points) {
      final time = DateTime.parse(
        p['dateMesure'] as String,
      ).millisecondsSinceEpoch;
      final value = (p['valeur'] as num).toDouble();
      final x = end == start ? 0.5 : (time - start) / (end - start),
          y = max == min ? 0.5 : (value - min) / (max - min);
      canvas.drawCircle(
        Offset(area.left + area.width * x, area.bottom - area.height * y),
        3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReportPoints old) =>
      old.points != points || old.min != min || old.max != max;
}
