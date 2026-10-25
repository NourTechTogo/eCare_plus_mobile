import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_session.dart';
import '../utils/app_colors.dart';
import '../utils/app_decor.dart';
import 'care_page.dart';
import 'care_components.dart';

Future<void> showTargetNotes(BuildContext context, String type, String id) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      useSafeArea: true,
      builder: (_) => TargetNotes(type: type, id: id),
    );

class TargetNotes extends StatefulWidget {
  final String type, id;
  const TargetNotes({super.key, required this.type, required this.id});
  @override
  State<TargetNotes> createState() => _TargetNotesState();
}

class _TargetNotesState extends State<TargetNotes> {
  final text = TextEditingController();
  List<Map<String, dynamic>> notes = [];
  String visibility = 'PRIVEE';
  String? error;
  Map<String, dynamic>? editing;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final rows = await context.read<ApiSession>().all(
        '/notes?typeCible=${widget.type}&cibleId=${widget.id}',
      );
      if (mounted) setState(() => notes = rows);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> save() async {
    if (busy || text.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await context.read<ApiSession>().request(
        editing == null ? 'POST' : 'PATCH',
        editing == null ? '/notes' : '/notes/${editing!['id']}',
        body: {
          'contenu': text.text.trim(),
          'visibilite': visibility,
          if (editing == null) ...{
            'typeCible': widget.type,
            'cibleId': widget.id,
          } else
            'version': editing!['version'],
        },
      );
      if (mounted) {
        text.clear();
        setState(() {
          editing = null;
          error = null;
        });
        await load();
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove(Map<String, dynamic> note) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await context.read<ApiSession>().request(
        'DELETE',
        '/notes/${note['id']}',
      );
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            .8,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Notes liées',
              style: AppDecor.t(
                21,
                w: FontWeight.w700,
                c: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Une précision pour mieux suivre votre santé.',
              style: AppDecor.t(12, c: AppColors.textMuted, h: 1.6),
            ),
            if (error != null) CareNotice(error!, error: true),
            const SizedBox(height: 18),
            for (final n in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('${n['contenu']}', style: AppDecor.t(14, h: 1.6)),
                      const SizedBox(height: 10),
                      Text(
                        n['visibilite'] == 'PRIVEE' ? 'Privée' : 'Partagée',
                        style: AppDecor.t(11, c: AppColors.primary),
                      ),
                      if (n['auteurId'] == context.read<ApiSession>().userId)
                        Wrap(
                          alignment: WrapAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Modifier',
                              onPressed: busy
                                  ? null
                                  : () {
                                      setState(() {
                                        editing = n;
                                        visibility = '${n['visibilite']}';
                                        text.text = '${n['contenu']}';
                                      });
                                    },
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: busy ? null : () => remove(n),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            if (notes.isEmpty)
              const CareNotice(
                'Aucune note pour le moment. Ajoutez une précision ci-dessous.',
              ),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    editing == null ? 'Ajouter une note' : 'Modifier ma note',
                    style: AppDecor.t(15, w: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: text,
                    maxLength: 5000,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Votre note',
                      alignLabelWithHint: true,
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: visibility,
                    itemHeight: null,
                    isDense: false,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Visibilité',
                      filled: true,
                      fillColor: AppColors.scaffoldBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PRIVEE',
                        child: Text('Privée, visible de moi seul', maxLines: 2),
                      ),
                      DropdownMenuItem(
                        value: 'PARTAGEE',
                        child: Text(
                          'Partagée avec mon interlocuteur habilité',
                          maxLines: 2,
                        ),
                      ),
                    ],
                    onChanged: busy
                        ? null
                        : (v) => setState(() => visibility = v!),
                  ),
                  const SizedBox(height: 20),
                  CareAction(
                    label: editing == null ? 'Ajouter' : 'Enregistrer',
                    busy: busy,
                    icon: Icons.check_rounded,
                    onPressed: save,
                  ),
                  if (editing != null)
                    TextButton(
                      onPressed: () {
                        setState(() => editing = null);
                        text.clear();
                      },
                      child: const Text('Annuler la modification'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
