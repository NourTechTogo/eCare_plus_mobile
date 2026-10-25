import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/care_data.dart';
import '../../widgets/care_page.dart';
import '../../widgets/care_components.dart';

class PendingSyncPage extends StatefulWidget {
  const PendingSyncPage({super.key});
  @override
  State<PendingSyncPage> createState() => _PendingSyncPageState();
}

class _PendingSyncPageState extends State<PendingSyncPage> {
  String? error;
  bool busy = false;
  Future<void> retry() async {
    setState(() => busy = true);
    try {
      final data = context.read<CareData>();
      await data.syncQueue?.flush();
      await data.refresh();
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<CareData>().syncQueue;
    final operations = queue?.pending ?? <Map<String, dynamic>>[];
    return CarePage(
      title: 'Synchronisation',
      subtitle: 'Gardez votre suivi à jour, en toute simplicité.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareSummary(
            icon: Icons.sync_rounded,
            title: operations.isEmpty
                ? 'Tout est à jour'
                : '${operations.length} envoi(s) à terminer',
            description: operations.isEmpty
                ? 'Aucune opération ne reste en attente dans cette session.'
                : 'Vos réponses attendent la confirmation du serveur.',
          ),
          if (error != null) CareNotice(error!, error: true),
          CareSection(
            title: 'État des transmissions',
            child: operations.isEmpty
                ? const CareEmpty(
                    icon: Icons.cloud_done_outlined,
                    title: 'Vous êtes à jour',
                    description:
                        'Vos prochaines opérations en attente apparaîtront ici.',
                  )
                : Column(
                    children: [
                      for (final operation in operations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CareDetail(
                            icon: Icons.cloud_upload_outlined,
                            title: operation['typeOperation'] == 'REPONSE_PRISE'
                                ? 'Réponse à une prise'
                                : 'Opération de suivi',
                            detail:
                                '${queue?.results[operation['identifiantLocal']]?['statut'] ?? 'En attente de transmission'}\n${queue?.results[operation['identifiantLocal']]?['message'] ?? 'Votre réponse est conservée dans cette session.'}',
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          CareAction(
            label: 'Réessayer la transmission',
            icon: Icons.sync_rounded,
            busy: busy,
            onPressed: retry,
          ),
          const CareNotice(
            'Gardez l’application ouverte et restez connecté jusqu’à la confirmation. Les opérations en attente sont conservées uniquement pendant cette session.',
          ),
        ],
      ),
    );
  }
}
