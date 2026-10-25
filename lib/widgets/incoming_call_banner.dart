import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_session.dart';
import '../services/server_calls.dart';
import '../views/messaging/server_calls_page.dart';

class IncomingCallBanner extends StatefulWidget {
  const IncomingCallBanner({super.key});
  @override
  State<IncomingCallBanner> createState() => _IncomingCallBannerState();
}

class _IncomingCallBannerState extends State<IncomingCallBanner>
    with WidgetsBindingObserver {
  Timer? timer;
  bool loading = false;
  List<Map<String, dynamic>> incoming = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    start();
    Future.microtask(load);
  }

  void start() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => load());
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
    try {
      final conversations =
          await api.request('GET', '/mobile/conversations') as List;
      final rows = <Map<String, dynamic>>[];
      for (final raw in conversations) {
        final conversation = Map<String, dynamic>.from(raw as Map);
        final calls = await ServerCalls(api).history('${conversation['id']}');
        for (final c in calls) {
          if (c['statut'] == 'EN_ATTENTE' && c['destinataireId'] == api.userId) {
            rows.add({'conversation': conversation, 'call': c});
          }
        }
      }
      if (mounted) setState(() => incoming = rows);
    } catch (_) {
      if (mounted) setState(() => incoming = []);
    } finally {
      loading = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final row in incoming)
        MaterialBanner(
          content: Text(
            'Appel entrant de ${row['conversation']['professionnelNom']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ServerCallsPage(
                    conversationId: '${row['conversation']['id']}',
                    name: '${row['conversation']['professionnelNom']}',
                  ),
                ),
              ),
              child: const Text('Ouvrir'),
            ),
          ],
        ),
    ],
  );
}
