import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../../services/server_calls.dart';
import '../../data/doctor_catalog.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import 'package:livekit_client/livekit_client.dart'
    show VideoTrackRenderer, VideoViewFit, AudioManager;
import 'doctor_call_page.dart';
import 'call_screen_connection.dart';
import '../../widgets/target_notes.dart';
import 'live_call_room.dart';
import 'server_chat_page.dart';

class ServerCallsPage extends StatefulWidget {
  final String conversationId, name;
  final CareDoctor? doctor;
  final String? initialType;
  const ServerCallsPage({
    super.key,
    required this.conversationId,
    required this.name,
    this.doctor,
    this.initialType,
  });
  @override
  State<ServerCallsPage> createState() => _ServerCallsPageState();
}

class _ServerCallsPageState extends State<ServerCallsPage>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> calls = [];
  String? error, loadError, source, typeSource, mediaStopped;
  bool speaker = false, initialAttempted = false;
  late String selectedType = widget.initialType ?? 'AUDIO';
  bool busy = false, loading = false;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(load);
    start();
  }

  void start() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      start();
      load();
    } else {
      timer?.cancel();
    }
  }

  Future<void> load() async {
    if (loading || !mounted) return;
    loading = true;
    try {
      final rows = await ServerCalls(
        context.read<ApiSession>(),
      ).history(widget.conversationId);
      if (mounted) {
        setState(() {
          calls = rows;
          loadError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loadError = e.toString());
    } finally {
      loading = false;
    }
    if (mounted &&
        !initialAttempted &&
        widget.initialType != null &&
        loadError == null) {
      initialAttempted = true;
      if (!calls.any(activeServerCall)) await create(widget.initialType!);
    }
  }

  Future<void> create(String type) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      selectedType = type;
    });
    if (typeSource != type) {
      typeSource = type;
      source = 'call-${DateTime.now().microsecondsSinceEpoch}';
    }
    try {
      await ServerCalls(
        context.read<ApiSession>(),
      ).create(widget.conversationId, type, source!);
      typeSource = null;
      source = null;
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> action(Map<String, dynamic> call, String action) async {
    if (busy) return;
    setState(() {
      busy = true;
      if (action == 'fin') mediaStopped = '${call['id']}';
    });
    try {
      await ServerCalls(
        context.read<ApiSession>(),
      ).action('${call['id']}', action);
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String statusLabel(Map<String, dynamic>? call) {
    if (call == null) return 'Prêt à appeler';
    return switch (call['statut']) {
      'PREPARATION' => 'Préparation de l’appel',
      'EN_ATTENTE' =>
        call['destinataireId'] == context.read<ApiSession>().userId
            ? 'Appel entrant'
            : 'Appel en cours…',
      'ACCEPTE' => 'Appel accepté',
      _ => 'Appel terminé',
    };
  }

  Future<void> history() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        minChildSize: .3,
        maxChildSize: .9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Historique des appels',
              style: AppDecor.t(20, w: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (calls.isEmpty)
              Text(
                'Aucun appel pour cette conversation.',
                style: AppDecor.t(14, c: AppColors.textMuted),
              ),
            for (final c in calls)
              ListTile(
                leading: Icon(
                  c['type'] == 'VIDEO'
                      ? Icons.videocam_outlined
                      : Icons.call_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  '${c['type'] == 'VIDEO' ? 'Vidéo' : 'Audio'} · ${c['statut']}',
                  style: AppDecor.t(13, w: FontWeight.w600),
                ),
                subtitle: Text(
                  '${c['dateCreation']}${c['dureeSecondes'] == null ? '' : ' · ${c['dureeSecondes']} s'}',
                  style: AppDecor.t(11, c: AppColors.textMuted),
                ),
                trailing: IconButton(
                  tooltip: 'Notes liées',
                  onPressed: () =>
                      showTargetNotes(context, 'APPEL', '${c['id']}'),
                  icon: const Icon(Icons.note_outlined),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool showingMessages = false;
  Future<void> openMessages() async {
    if (showingMessages) return;
    showingMessages = true;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ServerChatPage(
            conversationId: widget.conversationId,
            doctorName: widget.name,
            doctor: widget.doctor,
            returnToCall: true,
          ),
        ),
      );
    } finally {
      showingMessages = false;
    }
  }

  Widget screen(Map<String, dynamic>? call, [LiveCallView? media]) {
    final incoming =
        call?['statut'] == 'EN_ATTENTE' &&
        call?['destinataireId'] == context.read<ApiSession>().userId;
    final video =
        call?['type'] == 'VIDEO' || (call == null && selectedType == 'VIDEO');
    final connected = media?.connected ?? false;
    const foreground = AppColors.primary;
    final problem = error ?? loadError ?? media?.error;
    final state = CallScreenConnection(
      hasCall: call != null,
      status: mediaStopped == call?['id'] && call != null
          ? 'Média local arrêté'
          : connected
          ? 'Connecté à l’appel'
          : statusLabel(call),
      muted: !(media?.room?.microphoneEnabled ?? false),
      camera: media?.room?.cameraEnabled ?? false,
      speaker: speaker,
      remoteVideo: media?.room?.videos.isNotEmpty == true
          ? VideoTrackRenderer(
              media!.room!.videos.first,
              fit: VideoViewFit.cover,
            )
          : null,
      localVideo: media?.room?.localVideo != null
          ? VideoTrackRenderer(
              media!.room!.localVideo!,
              fit: VideoViewFit.cover,
            )
          : null,
      onMicrophone: connected ? () => media!.toggle(false) : null,
      onCamera: connected ? () => media!.toggle(true) : null,
      onSpeaker: connected
          ? () async {
              try {
                await AudioManager.instance.setSpeakerOutputPreferred(!speaker);
                if (mounted) setState(() => speaker = !speaker);
              } catch (e) {
                if (mounted) setState(() => error = e.toString());
              }
            }
          : null,
      onVideo: call == null && !busy
          ? () => setState(() => selectedType = 'VIDEO')
          : null,
      onEnd: busy
          ? null
          : call == null
          ? () => Navigator.maybePop(context)
          : () => action(call, 'fin'),
      onMessages: openMessages,
      onHistory: history,
      onRefresh: load,
      onNotes: call == null
          ? null
          : () => showTargetNotes(context, 'APPEL', '${call['id']}'),
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (problem != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                problem,
                textAlign: TextAlign.center,
                style: AppDecor.t(12, c: Theme.of(context).colorScheme.error),
              ),
            ),
          if (call == null)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : () => create('AUDIO'),
                  icon: const Icon(Icons.call_outlined, size: 20),
                  label: const Text('Appel audio'),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : () => create('VIDEO'),
                  icon: const Icon(Icons.videocam_outlined, size: 20),
                  label: const Text('Appel vidéo'),
                ),
              ],
            ),
          if (incoming)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: busy ? null : () => action(call!, 'acceptation'),
                  child: const Text('Accepter'),
                ),
                TextButton(
                  onPressed: busy ? null : () => action(call!, 'refus'),
                  child: Text('Refuser', style: TextStyle(color: foreground)),
                ),
              ],
            ),
          if (media != null && !connected)
            FilledButton(
              onPressed: media.busy ? null : media.join,
              child: Text(
                video
                    ? 'Rejoindre avec le micro et la caméra'
                    : 'Rejoindre avec le microphone',
              ),
            ),
          if (mediaStopped == call?['id'] && call != null)
            Text(
              'Média local arrêté. La fermeture serveur reste à confirmer.',
              textAlign: TextAlign.center,
              style: AppDecor.t(11, c: foreground),
            ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
    return PopScope(
      canPop: call == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) openMessages();
      },
      child: DoctorCallPage(
        doctor: widget.doctor ?? CareDoctor.fromServer({'nom': widget.name}),
        video: video,
        connection: state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = calls.where(activeServerCall).toList();
    final call = active.isEmpty ? null : active.first;
    if (call?['statut'] == 'ACCEPTE' && mediaStopped != call?['id']) {
      return LiveCallRoom(
        key: ValueKey(call!['id']),
        callId: '${call['id']}',
        type: '${call['type']}',
        builder: (state) => screen(call, state),
      );
    }
    return screen(call);
  }
}
