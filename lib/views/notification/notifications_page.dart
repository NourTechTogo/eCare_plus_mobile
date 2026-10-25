import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../../widgets/care_page.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/target_notes.dart';
import '../messaging/server_chat_page.dart';
import '../messaging/server_calls_page.dart';
import '../dashbord/treatments_page.dart';
import '../../services/server_calls.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  Timer? timer;
  final search = TextEditingController();
  String? category;
  int inboxTab = 0;
  bool searching = false;
  List<Map<String, dynamic>> notifications = [];
  String? error;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(load);
    start();
  }

  void start() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (ModalRoute.of(context)?.isCurrent == true) load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      start();
      load();
    } else {
      timer?.cancel();
    }
  }

  Future<void> load() async {
    if (loading || !mounted) return;
    loading = true;
    final api = context.read<ApiSession>();
    final generation = api.generation;
    final archiveView = inboxTab == 2;
    try {
      final rows = await api.all(
        '/compte/notifications${archiveView ? '?archivees=true' : ''}',
      );
      if (mounted &&
          generation == api.generation &&
          archiveView == (inboxTab == 2)) {
        setState(() {
          notifications = rows;
          error = null;
        });
      }
    } catch (e) {
      if (mounted && generation == api.generation) {
        setState(() => error = e.toString());
      }
    } finally {
      loading = false;
      if (mounted &&
          generation == api.generation &&
          archiveView != (inboxTab == 2)) {
        unawaited(load());
      }
    }
  }

  Future<bool> changeInbox(
    Map<String, dynamic> item,
    String action, {
    bool offerUndo = true,
  }) async {
    try {
      await context.read<ApiSession>().request(
        action == 'suppression' ? 'DELETE' : 'POST',
        '/compte/notifications/${item['id']}${action == 'suppression' ? '' : '/$action'}',
      );
      if (!mounted) return true;
      if (action == 'suppression' ||
          action == 'archivage' ||
          action == 'desarchivage') {
        setState(() => notifications.removeWhere((n) => n['id'] == item['id']));
      }
      await load();
      if (mounted && offerUndo) {
        final undo = action == 'suppression'
            ? 'restauration'
            : action == 'archivage'
            ? 'desarchivage'
            : 'archivage';
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'suppression'
                  ? 'Notification supprimée'
                  : action == 'archivage'
                  ? 'Notification archivée'
                  : 'Notification désarchivée',
            ),
            action: SnackBarAction(
              label: 'Annuler',
              onPressed: () => changeInbox(item, undo, offerUndo: false),
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    }
  }

  Future<bool> mark(Map<String, dynamic> n) async {
    try {
      await context.read<ApiSession>().request(
        'POST',
        '/compte/notifications/${n['id']}/lecture',
      );
      await load();
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    }
  }

  Future<void> open(Map<String, dynamic> n, {bool alreadyRead = false}) async {
    try {
      if (!alreadyRead &&
          n['_alert'] != true &&
          n['dateLecture'] == null &&
          !await mark(n)) {
        return;
      }
      if (!mounted) return;
      if (n['typeRessource'] == 'TRAITEMENT') {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const TreatmentsPage()),
        );
        return;
      }
      if (n['typeRessource'] == 'ALERTE') {
        await showTargetNotes(context, 'ALERTE', '${n['ressourceId']}');
        return;
      }
      final api = context.read<ApiSession>();
      final conversations =
          await api.request('GET', '/mobile/conversations') as List;
      for (final c in conversations) {
        bool matches =
            n['typeRessource'] == 'CONVERSATION' && c['id'] == n['ressourceId'];
        if (n['typeRessource'] == 'APPEL') {
          final calls = await ServerCalls(api).history('${c['id']}');
          matches = calls.any((call) => call['id'] == n['ressourceId']);
        }
        if (matches && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => n['typeRessource'] == 'APPEL'
                  ? ServerCallsPage(
                      conversationId: '${c['id']}',
                      name: '${c['professionnelNom']}',
                    )
                  : ServerChatPage(
                      conversationId: '${c['id']}',
                      doctorName: '${c['professionnelNom']}',
                    ),
            ),
          );
          return;
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String itemCategory(Map<String, dynamic> item) => item['_alert'] == true
      ? 'Alertes'
      : switch (item['typeRessource']) {
          'ALERTE' => 'Alertes',
          'CONVERSATION' => 'Messages',
          'APPEL' => 'Appels',
          'TRAITEMENT' => 'Médicaments',
          'MESURE' => 'Mesures',
          'RENDEZ_VOUS' => 'Rendez-vous',
          _ => 'Informations',
        };
  IconData categoryIcon(String label) => switch (label) {
    'Alertes' => Icons.warning_amber_rounded,
    'Messages' => Icons.chat_bubble_outline_rounded,
    'Appels' => Icons.call_outlined,
    'Médicaments' => Icons.medication_outlined,
    'Mesures' => Icons.monitor_heart_outlined,
    'Rendez-vous' => Icons.calendar_month_outlined,
    _ => Icons.notifications_none_rounded,
  };
  String normalize(String value) {
    const replacements = {
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'à': 'a',
      'â': 'a',
      'ù': 'u',
      'û': 'u',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ç': 'c',
    };
    var text = value.toLowerCase();
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text;
  }

  bool unread(Map<String, dynamic> item) =>
      item['_alert'] != true && item['dateLecture'] == null;

  DateTime? itemDate(Map<String, dynamic> item) => DateTime.tryParse(
    '${item['dateEnvoi'] ?? item['dateCreation']}',
  )?.toLocal();

  String shortDate(Map<String, dynamic> item) {
    final date = itemDate(item);
    if (date == null) return '';
    final now = DateTime.now();
    return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day
        ? careTime(date)
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> detail(Map<String, dynamic> item) async {
    if (unread(item) && !await mark(item)) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              itemCategory(item),
              style: AppDecor.t(12, c: AppColors.primary, w: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '${item['titre'] ?? 'Alerte'}',
              style: AppDecor.t(20, w: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              '${item['description'] ?? item['message'] ?? ''}',
              style: AppDecor.t(14, h: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              dateLabel(item),
              style: AppDecor.t(11, c: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (item['_alert'] == true ||
                    const [
                      'TRAITEMENT',
                      'ALERTE',
                      'CONVERSATION',
                      'APPEL',
                    ].contains(item['typeRessource']))
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      if (item['_alert'] == true) {
                        showTargetNotes(context, 'ALERTE', '${item['id']}');
                      } else {
                        open(item, alreadyRead: true);
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(
                      item['_alert'] == true ? 'Notes liées' : 'Ouvrir',
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget notificationRow(Map<String, dynamic> item) {
    final isUnread = unread(item);
    final content = Material(
      color: isUnread ? Colors.white : const Color(0xFFF2F4F7),
      child: InkWell(
        onTap: isUnread ? () => mark(item) : null,
        onLongPress: () => detail(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isUnread
                      ? AppColors.primaryLighter
                      : const Color(0xFFE4E8ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  categoryIcon(itemCategory(item)),
                  size: 21,
                  color: isUnread ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['titre'] ?? 'Alerte'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppDecor.t(
                        13,
                        w: isUnread ? FontWeight.w700 : FontWeight.w500,
                        c: isUnread ? AppColors.textDark : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item['description'] ?? item['message'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppDecor.t(11, c: AppColors.textMuted, h: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    shortDate(item),
                    style: AppDecor.t(10, c: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  if (isUnread)
                    Semantics(
                      label: 'Non lue',
                      child: Icon(
                        Icons.circle,
                        color: AppColors.primary,
                        size: 8,
                      ),
                    )
                  else if (item['_alert'] != true)
                    Text('Lu', style: AppDecor.t(9, c: AppColors.textMuted)),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'Actions de la notification',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onSelected: (value) {
                  if (value == 'read') mark(item);
                  if (value == 'detail') detail(item);
                  if (value == 'archive') {
                    changeInbox(
                      item,
                      inboxTab == 2 ? 'desarchivage' : 'archivage',
                    );
                  }
                  if (value == 'delete') changeInbox(item, 'suppression');
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Text('Voir le détail'),
                  ),
                  if (isUnread)
                    const PopupMenuItem(
                      value: 'read',
                      child: Text('Marquer lu'),
                    ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(inboxTab == 2 ? 'Désarchiver' : 'Archiver'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return Dismissible(
      key: ValueKey('notification-${item['id']}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        await changeInbox(
          item,
          direction == DismissDirection.endToStart
              ? 'suppression'
              : inboxTab == 2
              ? 'desarchivage'
              : 'archivage',
        );
        return false;
      },
      background: Container(
        color: AppColors.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: const Color(0xFFE45B64),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = normalize(search.text.trim());
    final items =
        [...notifications]
            .where(
              (item) =>
                  (inboxTab != 1 || unread(item)) &&
                  (category == null || itemCategory(item) == category) &&
                  normalize(
                    '${item['titre']} ${item['description'] ?? item['message'] ?? ''} ${itemCategory(item)}',
                  ).contains(query),
            )
            .toList()
          ..sort(
            (a, b) => (itemDate(b) ?? DateTime(1970)).compareTo(
              itemDate(a) ?? DateTime(1970),
            ),
          );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Retour',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Mes notifications',
                          style: AppDecor.t(
                            20,
                            w: FontWeight.w700,
                            c: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Rechercher',
                        onPressed: () => setState(() {
                          searching = !searching;
                          if (!searching) search.clear();
                        }),
                        icon: Icon(
                          searching
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (searching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      controller: search,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: AppDecor.t(13),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une notification',
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF4F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                if (!(searching && MediaQuery.viewInsetsOf(context).bottom > 0))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F5FA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          for (final entry in [
                            (0, 'Toutes'),
                            (1, 'Non lues'),
                            (2, 'Archivées'),
                          ])
                            Expanded(
                              child: Semantics(
                                selected: inboxTab == entry.$1,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() => inboxTab = entry.$1);
                                    load();
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: inboxTab == entry.$1
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    foregroundColor: inboxTab == entry.$1
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    entry.$2,
                                    style: AppDecor.t(
                                      12,
                                      w: FontWeight.w600,
                                      c: inboxTab == entry.$1
                                          ? Colors.white
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (!(searching && MediaQuery.viewInsetsOf(context).bottom > 0))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: PopupMenuButton<String>(
                            tooltip: 'Filtrer par catégorie',
                            onSelected: (label) => setState(
                              () => category = label == 'Toutes les catégories'
                                  ? null
                                  : label,
                            ),
                            itemBuilder: (_) => [
                              for (final label in [
                                'Toutes les catégories',
                                'Médicaments',
                                'Rendez-vous',
                                'Mesures',
                                'Alertes',
                                'Messages',
                                'Appels',
                                'Informations',
                              ])
                                PopupMenuItem(value: label, child: Text(label)),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      category ?? 'Toutes les catégories',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppDecor.t(
                                        11,
                                        c: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${items.length}',
                          style: AppDecor.t(11, c: AppColors.textMuted),
                        ),
                        IconButton(
                          tooltip: 'Actualiser',
                          onPressed: load,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: items.isEmpty
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: CareEmpty(
                            icon: Icons.notifications_none_rounded,
                            title: query.isEmpty
                                ? 'Aucune notification'
                                : 'Aucun résultat',
                            description: query.isEmpty
                                ? 'Vos prochains rappels et informations apparaîtront ici.'
                                : 'Essayez un autre mot ou une autre catégorie.',
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: load,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                            itemCount: items.length + 1,
                            itemBuilder: (_, i) => i == items.length
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      20,
                                      16,
                                      8,
                                    ),
                                    child: Text(
                                      'Les seuils d’alerte de démonstration sont indicatifs. Cette application ne traite pas les urgences.',
                                      style: AppDecor.t(
                                        10,
                                        c: AppColors.textMuted,
                                        h: 1.5,
                                      ),
                                    ),
                                  )
                                : notificationRow(items[i]),
                            separatorBuilder: (_, _) => const Padding(
                              padding: EdgeInsets.only(left: 66, right: 16),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFEBF0F5),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String dateLabel(Map<String, dynamic> item) {
    final date = DateTime.tryParse(
      '${item['dateEnvoi'] ?? item['dateCreation']}',
    )?.toLocal();
    return date == null ? '' : '${careDate(date)} à ${careTime(date)}';
  }
}
