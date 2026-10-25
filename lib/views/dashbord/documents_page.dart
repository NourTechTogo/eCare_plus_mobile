import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medical_document.dart';
import '../../services/document_library.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';
import '../../widgets/document_import_sheet.dart';
import '../../widgets/document_filter_sheet.dart';

class DocumentsPage extends StatefulWidget {
  final DocumentLibrary? library;
  const DocumentsPage({super.key, this.library});
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  late final DocumentLibrary _library =
      widget.library ??
      context.read<DocumentLibrary?>() ??
      DocumentLibrary.instance;
  final _search = TextEditingController();
  DocumentCategory? _category;
  MedicalCondition? _condition;
  bool _general = false, _oldest = false, _working = false;
  String? _error;
  bool _importSheetOpen = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      if (_library.remote) {
        await _library.reload();
      } else {
        await _library.load();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is DocumentException
              ? e.message
              : 'Impossible de charger votre carnet. Réessayez.',
        );
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } catch (e) {
      _notice(
        e is DocumentException
            ? e.message
            : 'Impossible de terminer cette opération. Réessayez.',
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _add() => _action(() async {
    final file = await _library.pickFile();
    if (file == null || !mounted) return;
    if (await file.length() > DocumentLibrary.maxBytes) {
      throw const DocumentException('Le fichier doit faire moins de 5 Mo.');
    }
    if (!mounted) return;
    setState(() => _importSheetOpen = true);
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.scaffoldBackground,
      builder: (_) => DocumentImportSheet(library: _library, file: file),
    );
    if (mounted) setState(() => _importSheetOpen = false);
    if (added == true) _notice('Document ajouté à votre carnet.');
  });
  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<DocumentFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => DocumentFilterSheet(
        initial: DocumentFilters(
          category: _category,
          condition: _library.conditions.contains(_condition)
              ? _condition
              : null,
          general: _general,
        ),
        conditions: _library.conditions,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _category = result.category;
      _condition = result.condition;
      _general = result.general;
    });
  }

  Future<void> _menu(MedicalDocument item, String action) async {
    if (action == 'details') {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Informations du document'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nom du document',
                style: AppDecor.t(12, c: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              SelectableText(
                item.title,
                style: AppDecor.t(15, w: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              Text(
                'Nom du fichier',
                style: AppDecor.t(12, c: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              SelectableText(item.fileName, style: AppDecor.t(13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      return;
    }
    await _action(() async {
      if (action == 'open') await _library.open(item);
      if (action == 'download') {
        if (await _library.export(item)) {
          _notice('Document enregistré à l’emplacement choisi.');
        }
      }
      if (action == 'delete') {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Retirer ce document ?'),
            content: Text(
              '« ${item.title} » sera supprimé de ce carnet. Le fichier d’origine restera intact.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Retirer'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _library.remove(item);
          _notice('Document retiré du carnet.');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _library,
    builder: (context, _) {
      final docs = _library.filtered(
        category: _category,
        condition: _library.conditions.contains(_condition) ? _condition : null,
        general: _general,
        query: _search.text,
        oldestFirst: _oldest,
      );
      return CarePage(
        title: 'Mes documents',
        subtitle: 'Votre carnet de santé, à portée de main.',
        floatingActionButton: FloatingActionButton(
          onPressed: _working ? null : _add,
          tooltip: 'Ajouter un document',
          backgroundColor: AppColors.primaryDeep,
          foregroundColor: Colors.white,
          child: _working && !_importSheetOpen
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              CareEmpty(
                icon: Icons.folder_off_outlined,
                title: 'Carnet indisponible',
                description: _error!,
                action: TextButton(
                  onPressed: _load,
                  child: const Text('Réessayer'),
                ),
              )
            else if (!_library.loaded)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nom du document ou mot-clé…',
                  labelText: 'Rechercher un document',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_search.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Effacer la recherche',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_search.clear),
                        ),
                      IconButton(
                        tooltip: 'Filtres',
                        onPressed: _working ? null : _openFilters,
                        icon: const Icon(Icons.tune_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor:
                              _category != null ||
                                  _general ||
                                  _library.conditions.contains(_condition)
                              ? AppColors.primaryLighter
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              if (_category != null ||
                  _general ||
                  _library.conditions.contains(_condition)) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_category != null)
                      InputChip(
                        label: Text('Type : ${_category!.label}'),
                        backgroundColor: AppColors.primaryLighter,
                        onDeleted: () => setState(() => _category = null),
                        deleteButtonTooltipMessage: 'Retirer le filtre de type',
                      ),
                    if (_general || _library.conditions.contains(_condition))
                      InputChip(
                        label: Text(
                          'Suivi : ${_general ? 'Général' : _condition!.label}',
                        ),
                        backgroundColor: AppColors.primaryLighter,
                        onDeleted: () => setState(() {
                          _condition = null;
                          _general = false;
                        }),
                        deleteButtonTooltipMessage:
                            'Retirer le filtre de suivi',
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _category = null;
                    _condition = null;
                    _general = false;
                  }),
                  child: const Text('Réinitialiser les filtres'),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '${docs.length} document${docs.length > 1 ? 's trouvés' : ' trouvé'}',
                    style: AppDecor.t(
                      20,
                      w: FontWeight.w700,
                      c: AppColors.primaryDeep,
                    ),
                  ),
                  PopupMenuButton<bool>(
                    tooltip: 'Trier les documents',
                    initialValue: _oldest,
                    onSelected: (value) => setState(() => _oldest = value),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: false,
                        child: Text('Plus récents'),
                      ),
                      const PopupMenuItem(
                        value: true,
                        child: Text('Plus anciens'),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _oldest ? 'Plus anciens' : 'Plus récents',
                            style: AppDecor.t(12, c: AppColors.textMuted),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                CareEmpty(
                  icon: Icons.folder_copy_outlined,
                  title: _library.documents.isEmpty
                      ? 'Votre carnet commence ici'
                      : 'Aucun document trouvé',
                  description: _library.documents.isEmpty
                      ? 'Ajoutez vos ordonnances, résultats et comptes rendus pour les retrouver facilement.'
                      : 'Essayez une autre recherche ou modifiez vos filtres.',
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: .6),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < docs.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                        _DocumentRow(
                          item: docs[i],
                          enabled: !_working,
                          onOpen: () => _menu(docs[i], 'open'),
                          onAction: (action) => _menu(docs[i], action),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      );
    },
  );
}

class _DocumentRow extends StatelessWidget {
  final MedicalDocument item;
  final bool enabled;
  final VoidCallback onOpen;
  final ValueChanged<String> onAction;
  const _DocumentRow({
    required this.item,
    required this.enabled,
    required this.onOpen,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) {
    final isPdf = item.extension == 'pdf';
    final color = isPdf ? const Color(0xFFD35A65) : AppColors.primary;
    final date =
        '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}';
    final size = item.size < 1024 * 1024
        ? '${(item.size / 1024).ceil()} Ko'
        : '${(item.size / (1024 * 1024)).toStringAsFixed(1)} Mo';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 4, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPdf
                  ? Icons.picture_as_pdf_outlined
                  : ['jpg', 'jpeg', 'png'].contains(item.extension)
                  ? Icons.image_outlined
                  : Icons.description_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: enabled ? onOpen : null,
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppDecor.t(
                      15,
                      w: FontWeight.w700,
                      c: AppColors.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date · ${item.extension.toUpperCase()} · $size',
                    style: AppDecor.t(11, c: AppColors.textMuted),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _tag(item.category.label, AppColors.primary),
                      _tag(
                        item.followUp,
                        item.conditions.contains(MedicalCondition.diabetes)
                            ? const Color(0xFF17766F)
                            : AppColors.primaryDeep,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            enabled: enabled,
            tooltip: 'Actions pour ${item.title}',
            onSelected: onAction,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'open', child: Text('Ouvrir')),
              const PopupMenuItem(
                value: 'details',
                child: Text('Informations'),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Text('Télécharger'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Retirer du carnet'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(text, style: AppDecor.t(10, c: color)),
  );
}
