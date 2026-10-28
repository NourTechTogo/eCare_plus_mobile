import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../../services/consultation_reports_api.dart';
import '../../services/document_export_cleanup.dart';
import '../../services/document_library.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';
import 'consultation_report_detail.dart';

class ConsultationReportsPage extends StatefulWidget {
  final Future<bool> Function(Uint8List, String)? savePdf;
  const ConsultationReportsPage({super.key, this.savePdf});
  @override
  State<ConsultationReportsPage> createState() =>
      _ConsultationReportsPageState();
}

class _ConsultationReportsPageState extends State<ConsultationReportsPage> {
  ConsultationReportsApi? _api;
  late ApiSession _session;
  final _zone = TextEditingController(text: 'Africa/Lome');
  late DateTimeRange _period;
  ReportRequest? _request;
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic>? _selected;
  final _copied = <String>{};
  int _page = 0, _totalPages = 0, _listVersion = 0;
  bool _busy = false, _loading = true;
  String? _error, _information;
  bool get _alive => mounted && _api?.valid == true;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _period = DateTimeRange(
      start: DateTime(now.year, now.month, now.day - 29),
      end: today,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api != null) return;
    _session = context.read<ApiSession>();
    _api = ConsultationReportsApi(_session);
    _session.addListener(_sessionChanged);
    Future.microtask(() => _loadRows(reset: true));
  }

  void _sessionChanged() {
    if (!_api!.valid && mounted) {
      setState(() {
        _reports = [];
        _selected = null;
        _copied.clear();
        _information = null;
        _error = null;
        _listVersion++;
      });
    }
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    _api?.dispose();
    _zone.dispose();
    super.dispose();
  }

  Future<void> _loadRows({bool reset = false}) async {
    if (!_alive) return;
    final version = ++_listVersion;
    final page = reset ? 0 : _page + 1;
    setState(() => _loading = true);
    try {
      final result = await _api!.list(page: page);
      if (!_alive || version != _listVersion) return;
      final rows = reportRows(result['content']);
      setState(() {
        _reports = reset
            ? rows
            : [
                ..._reports,
                ...rows.where(
                  (r) => !_reports.any((old) => old['id'] == r['id']),
                ),
              ];
        _page = page;
        _totalPages = (result['totalPages'] as num).toInt();
        _error = null;
      });
    } catch (e) {
      if (_alive && version == _listVersion) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (_alive && version == _listVersion) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_alive || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _information = null;
    });
    try {
      await action();
    } catch (e) {
      if (_alive) setState(() => _error = e.toString());
    } finally {
      if (_alive) setState(() => _busy = false);
    }
  }

  Future<void> _choosePeriod() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _period,
      helpText: 'Période du rapport (90 jours maximum)',
      saveText: 'Choisir',
      cancelText: 'Annuler',
    );
    if (result != null && _alive) {
      setState(() {
        _period = result;
        _request = null;
      });
    }
  }

  Future<void> _generate() => _run(() async {
    _request ??= ReportRequest(
      from: _period.start,
      to: _period.end,
      zone: _zone.text,
    );
    final result = await _api!.generate(_request!);
    if (!_alive) return;
    setState(() {
      _selected = result;
      _request = null;
    });
    await _loadRows(reset: true);
  });
  Future<void> _read(String id) => _run(() async {
    final result = await _api!.read(id);
    if (_alive) setState(() => _selected = result);
  });
  Future<bool> _save(Uint8List bytes, String name) async {
    final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final exportName = ios
        ? 'ecare-export-${DateTime.now().microsecondsSinceEpoch}-$name'
        : name;
    try {
      final target = await FilePicker.platform.saveFile(
        dialogTitle: 'Télécharger le rapport PDF',
        fileName: exportName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (kIsWeb) {
        return true; // Browser starts a download and intentionally returns no destination.
      }
      if (target == null) return false;
      if (!_alive) return false;
      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        await XFile.fromData(bytes).saveTo(target);
      }
      return true;
    } finally {
      if (ios) await deleteIosExportStaging(exportName);
    }
  }

  Future<void> _download() => _run(() async {
    final id = _selected!['id'] as String;
    final bytes = await _api!.pdf(id);
    if (!_alive) return;
    final saved = await (widget.savePdf ?? _save)(
      bytes,
      ConsultationReportsApi.filename(id),
    );
    if (_alive && saved) {
      setState(
        () => _information = kIsWeb
            ? 'Téléchargement demandé au navigateur.'
            : 'PDF enregistré.',
      );
    }
  });
  Future<void> _deposit() async {
    final report = _selected;
    if (report == null || _busy || !_alive) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Déposer une copie ?'),
        content: const SingleChildScrollView(
          child: Text(
            'Cette copie du PDF sera ajoutée à votre carnet de documents. Elle sera accessible aux professionnels autorisés à votre dossier, selon vos affectations et votre consentement. Le rapport personnel original reste privé. Aucun rendez-vous n’est réservé.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Déposer la copie'),
          ),
        ],
      ),
    );
    if (confirmed != true || !_alive) return;
    await _run(() async {
      await _api!.depositCopy(report);
      if (!mounted || !_api!.valid) return;
      setState(() {
        _copied.add(report['id'] as String);
        _information = 'Copie déposée dans votre carnet de documents.';
      });
      final library = context.read<DocumentLibrary?>();
      if (library != null) {
        try {
          await library.reload();
        } catch (_) {
          if (_alive) {
            setState(
              () => _information =
                  'Copie déposée. Actualisez le carnet pour la retrouver.',
            );
          }
        }
      }
    });
  }

  Widget _feedback() => Column(
    children: [
      if (_error != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Semantics(
            liveRegion: true,
            child: Text(_error!, style: AppDecor.t(13, c: Colors.red.shade800)),
          ),
        ),
      if (_information != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _information!,
              style: AppDecor.t(13, c: AppColors.primary),
            ),
          ),
        ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: LinearProgressIndicator(),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    if (_api?.valid != true) {
      return const CarePage(
        title: 'Mes rapports',
        subtitle: null,
        child: CareEmpty(
          icon: Icons.lock_outline,
          title: 'Accès au suivi interrompu',
          description:
              'Reconnectez-vous et vérifiez votre consentement pour consulter vos rapports.',
        ),
      );
    }
    if (_selected != null) {
      return CarePage(
        title: 'Mon rapport',
        subtitle: 'Votre synthèse enregistrée pour préparer une consultation.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _selected = null;
                      _error = null;
                      _information = null;
                    }),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour aux rapports'),
            ),
            const SizedBox(height: 14),
            _feedback(),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _download,
                    icon: const Icon(Icons.download_outlined),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Télécharger le PDF',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy || _copied.contains(_selected!['id'])
                        ? null
                        : _deposit,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _copied.contains(_selected!['id'])
                            ? 'Copie déposée dans mon carnet'
                            : 'Déposer une copie dans mon carnet',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Le téléchargement ne transmet pas ce rapport à un professionnel.',
                    style: AppDecor.t(12, c: AppColors.textMuted, h: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ConsultationReportDetail(
              key: ValueKey(_selected!['id']),
              report: _selected!,
            ),
          ],
        ),
      );
    }
    return CarePage(
      title: 'Mes rapports',
      subtitle:
          'Préparez votre consultation à partir de vos données enregistrées.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _feedback(),
          CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Préparer ma consultation',
                  style: AppDecor.t(
                    17,
                    w: FontWeight.w700,
                    c: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez une période de 1 à 90 jours. La synthèse conserve les données présentes lors de sa génération.',
                  style: AppDecor.t(12, c: AppColors.textMuted, h: 1.6),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _choosePeriod,
                  icon: const Icon(Icons.date_range_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      '${careDate(_period.start)} au ${careDate(_period.end)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _zone,
                  enabled: !_busy,
                  autocorrect: false,
                  onChanged: (_) => _request = null,
                  decoration: const InputDecoration(
                    labelText: 'Fuseau du rapport',
                    hintText: 'Africa/Lome',
                    helperText: 'Nom IANA, par exemple UTC ou Africa/Lome.',
                    helperMaxLines: 3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _busy || _loading ? null : _generate,
                  icon: const Icon(Icons.description_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Générer la synthèse',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(
                'Rapports enregistrés',
                style: AppDecor.t(17, w: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: _busy || _loading
                    ? null
                    : () => _loadRows(reset: true),
                icon: const Icon(Icons.refresh, size: 19),
                label: const Text('Actualiser'),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && _reports.isEmpty && _error == null)
            const CareEmpty(
              icon: Icons.description_outlined,
              title: 'Aucun rapport enregistré',
              description:
                  'Votre première synthèse apparaîtra ici après sa génération.',
            ),
          for (final report in _reports)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Du ${reportDate(report['du'])} au ${reportDate(report['au'])}',
                      style: AppDecor.t(14, w: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${report['fuseau']} · ${reportDate(report['genereLe'])}',
                      style: AppDecor.t(12, c: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _read(report['id'] as String),
                      child: const Text('Consulter le rapport'),
                    ),
                  ],
                ),
              ),
            ),
          if (_page + 1 < _totalPages)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: _loading || _busy ? null : () => _loadRows(),
                child: const Text('Charger les rapports suivants'),
              ),
            ),
        ],
      ),
    );
  }
}
