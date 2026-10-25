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
  List<Map<String, dynamic>> notifications = [], alerts = [];
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
    try {
      final results = await Future.wait([
        api.all('/compte/notifications'),
        api.all('/mobile/me/alertes'),
      ]);
      if (mounted && generation == api.generation) {
        setState(() {
          notifications = results[0];
          alerts = results[1];
          error = null;
        });
      }
    } catch (e) {
      if (mounted && generation == api.generation) {
        setState(() => error = e.toString());
      }
    } finally {
      loading = false;
    }
  }

  Future<void> mark(Map<String, dynamic> n) async {
    try {
      await context.read<ApiSession>().request(
        'POST',
        '/compte/notifications/${n['id']}/lecture',
      );
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> open(Map<String, dynamic> n) async {
    try {
      await mark(n);
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

  @override
  Widget build(BuildContext context) {
    final query = normalize(search.text.trim());
    final items =
        [
              for (final alert in alerts) {...alert, '_alert': true},
              ...notifications,
            ]
            .where(
              (item) =>
                  (category == null || itemCategory(item) == category) &&
                  normalize(
                    '${item['titre']} ${item['description'] ?? item['message'] ?? ''} ${itemCategory(item)}',
                  ).contains(query),
            )
            .toList();
    return CarePage(
      title: 'Mes notifications',
      subtitle: 'Vos rappels et informations, réunis au même endroit.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: search,
            style: AppDecor.t(13),
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher une notification',
              hintStyle: AppDecor.t(13, c: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      onPressed: () => setState(search.clear),
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: category ?? 'Toutes',
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Catégorie',
              prefixIcon: const Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            items: [
              for (final label in [
                'Toutes',
                'Médicaments',
                'Rendez-vous',
                'Mesures',
                'Alertes',
                'Messages',
                'Appels',
                'Informations',
              ])
                DropdownMenuItem(
                  value: label,
                  child: Text(label, style: AppDecor.t(13)),
                ),
            ],
            onChanged: (value) =>
                setState(() => category = value == 'Toutes' ? null : value),
          ),
          const SizedBox(height: 8),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${items.length} notification${items.length > 1 ? 's' : ''}',
                  style: AppDecor.t(12, c: AppColors.textMuted),
                ),
              ),
              TextButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualiser'),
              ),
            ],
          ),
          if (items.isEmpty && error == null)
            CareEmpty(
              icon: Icons.notifications_none_rounded,
              title: query.isEmpty ? 'Aucune notification' : 'Aucun résultat',
              description: query.isEmpty
                  ? 'Vos prochains rappels et informations apparaîtront ici.'
                  : 'Essayez un autre mot ou choisissez une autre catégorie.',
            ),
          for (final item in items) ...[
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLighter,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          categoryIcon(itemCategory(item)),
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          itemCategory(item),
                          style: AppDecor.t(
                            12,
                            w: FontWeight.w600,
                            c: AppColors.primary,
                          ),
                        ),
                      ),
                      if (item['_alert'] != true && item['dateLecture'] == null)
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item['titre'] ?? 'Alerte'}',
                    style: AppDecor.t(14, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item['description'] ?? item['message'] ?? ''}',
                    style: AppDecor.t(13, c: AppColors.textMuted, h: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateLabel(item),
                    style: AppDecor.t(11, c: AppColors.textMuted),
                  ),
                  if (item['_alert'] == true)
                    TextButton.icon(
                      onPressed: () =>
                          showTargetNotes(context, 'ALERTE', '${item['id']}'),
                      icon: const Icon(Icons.note_outlined, size: 18),
                      label: const Text('Notes liées'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => open(item),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: const Text('Ouvrir'),
                        ),
                        if (item['dateLecture'] != null)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Lu'),
                          )
                        else
                          TextButton(
                            onPressed: () => mark(item),
                            child: const Text('Marquer lu'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Text(
            'Les seuils d’alerte de démonstration sont indicatifs. Cette application ne traite pas les urgences.',
            style: AppDecor.t(10, c: AppColors.textMuted, h: 1.6),
          ),
        ],
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
