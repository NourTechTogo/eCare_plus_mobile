import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import '../../services/api_session.dart';
import '../../services/document_library.dart';
import '../../models/medical_document.dart';
import '../../widgets/care_page.dart';

class LocalArchivePage extends StatefulWidget {
  const LocalArchivePage({super.key});
  @override
  State<LocalArchivePage> createState() => _LocalArchivePageState();
}

class _LocalArchivePageState extends State<LocalArchivePage> {
  late DocumentLibrary local, remote;
  late ApiSession api;
  late int generation;
  String? error;
  bool busy = false;
  final Map<String, XFile> files = {};
  @override
  void initState() {
    super.initState();
    api = context.read<ApiSession>();
    generation = api.generation;
    local = DocumentLibrary(patientId: api.userId);
    remote = context.read<DocumentLibrary>();
    api.addListener(changed);
    Future.microtask(load);
  }

  void changed() {
    if (api.generation != generation) local.lockSession();
  }

  Future<void> load() async {
    try {
      await local.load();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is DocumentException ? e.message : e.toString(),
        );
      }
    }
  }

  Future<void> transmit(MedicalDocument item) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final file = files[item.id] ??= XFile.fromData(
        await local.read(item),
        name: item.fileName,
        path: item.fileName,
      );
      await remote.importFile(
        file,
        title: item.title,
        category: item.category,
        conditions: {},
        date: item.date,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Copie transmise au carnet serveur. Original local conservé.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is DocumentException ? e.message : e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    api.removeListener(changed);
    local.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarePage(
    title: 'Archives locales',
    subtitle: 'Aucun fichier ne sera transféré automatiquement',
    child: Column(
      children: [
        const Text(
          'Ces fichiers restent sur cet appareil. Transmettez seulement ceux que vous souhaitez rendre accessibles au médecin de votre dossier. Les anciens fichiers non attribués à un compte restent dans leur répertoire historique.',
        ),
        if (error != null) Text(error!),
        if (!local.loaded)
          TextButton(
            onPressed: load,
            child: const Text('Charger les archives'),
          ),
        for (final item in local.documents)
          Card(
            child: ListTile(
              title: Text(item.title),
              subtitle: Text(item.fileName),
              trailing: TextButton(
                onPressed: busy ? null : () => transmit(item),
                child: const Text('Transmettre'),
              ),
            ),
          ),
        if (local.loaded && local.documents.isEmpty)
          const Text('Aucun document local pour ce compte.'),
      ],
    ),
  );
}
