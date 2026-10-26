import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;
import '../../data/doctor_catalog.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/page_header.dart';
import '../../widgets/chat_menu_entry.dart';
import 'doctor_contact_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import 'package:file_selector/file_selector.dart';
import '../../services/private_files.dart';
import '../../widgets/target_notes.dart';
import 'server_calls_page.dart';
import '../../services/chat_media_service.dart';
import '../../services/server_voice_service.dart';
import '../../widgets/server_voice_bubble.dart';

class ServerChatPage extends StatefulWidget {
  final String conversationId, doctorName;
  final CareDoctor? doctor;
  final bool returnToCall;
  final ChatMediaService? mediaService;
  const ServerChatPage({
    super.key,
    required this.conversationId,
    required this.doctorName,
    this.doctor,
    this.returnToCall = false,
    this.mediaService,
  });
  @override
  State<ServerChatPage> createState() => _ServerChatPageState();
}

class _ServerChatPageState extends State<ServerChatPage>
    with WidgetsBindingObserver {
  final text = TextEditingController();
  final search = TextEditingController();
  final scroll = ScrollController();
  bool searching = false, showEmojis = false;
  late final ServerVoiceService voice;
  void voiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> openContact() async {
    await voice.suspend();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DoctorContactPage(doctor: doctor),
      ),
    );
  }

  CareDoctor get doctor =>
      widget.doctor ?? CareDoctor.fromServer({'nom': widget.doctorName});

  Future<void> openCalls([String? type]) async {
    if (voice.active) {
      await voice.cancel();
    } else {
      await voice.pausePlayback();
    }
    if (!mounted) return;
    if (widget.returnToCall) {
      Navigator.pop(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ServerCallsPage(
          conversationId: widget.conversationId,
          name: widget.doctorName,
          doctor: doctor,
          initialType: type,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> messages = [];
  Timer? timer;
  String? error;
  bool sending = false, loading = false;
  final List<Map<String, dynamic>> attachments = [];
  Future<void> attach({bool camera = false}) async {
    if (sending ||
        voice.active ||
        voice.draft != null ||
        attachments.length >= 5) {
      return;
    }
    try {
      final file = camera
          ? await ImagePicker().pickImage(source: ImageSource.camera)
          : await openFile(
              acceptedTypeGroups: [
                const XTypeGroup(
                  label: 'PDF ou image',
                  extensions: ['pdf', 'jpg', 'jpeg', 'png'],
                ),
              ],
            );
      if (file == null || !mounted) return;
      if (await file.length() > 5 * 1024 * 1024) {
        if (mounted) setState(() => error = '5 Mo maximum par fichier.');
        return;
      }
      if (mounted) {
        setState(
          () => attachments.add({
            'file': file,
            'source': 'piece-${DateTime.now().microsecondsSinceEpoch}',
          }),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> download(Map<String, dynamic> piece) async {
    try {
      await savePrivateFile(
        context.read<ApiSession>(),
        '/mobile/conversations/${widget.conversationId}/pieces-jointes/${piece['id']}/contenu',
        '${piece['nomOriginal']}',
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    voice = ServerVoiceService(
      api: context.read<ApiSession>(),
      conversationId: widget.conversationId,
      media: widget.mediaService,
    );
    voice.addListener(voiceChanged);
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
      // Une boîte de permission rend temporairement l'écran inactif.
      // Un passage réel en arrière-plan annule toujours la demande en attente.
      if (s != AppLifecycleState.inactive || !voice.starting) {
        unawaited(voice.suspend());
      }
    }
  }

  Future<void> load() async {
    if (loading || !mounted) return;
    loading = true;
    final api = context.read<ApiSession>();
    final generation = api.generation;
    try {
      final rows = await api.all(
        '/mobile/conversations/${widget.conversationId}/messages',
      );
      if (!mounted || generation != api.generation) return;
      rows.sort((a, b) {
        final c = '${a['envoyeLe']}'.compareTo('${b['envoyeLe']}');
        return c != 0 ? c : '${a['id']}'.compareTo('${b['id']}');
      });
      final followLatest =
          messages.isEmpty ||
          !scroll.hasClients ||
          scroll.position.extentAfter < 80;
      setState(() {
        messages = rows;
        error = null;
      });
      if (followLatest && !searching) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && scroll.hasClients) {
            scroll.jumpTo(scroll.position.maxScrollExtent);
          }
        });
      }
      await api.request(
        'POST',
        '/mobile/conversations/${widget.conversationId}/lecture',
      );
    } catch (e) {
      if (mounted && generation == api.generation) {
        setState(() => error = e.toString());
      }
    } finally {
      loading = false;
    }
  }

  String? submissionFingerprint, submissionSource;
  Future<void> send() async {
    if (voice.draft != null) {
      if (await voice.send()) await load();
      return;
    }
    if (voice.active || voice.sending) return;
    final draft = text.text.trim();
    if ((draft.isEmpty && attachments.isEmpty) || sending) return;
    if (draft.length > 2000) {
      setState(() => error = 'Maximum 2000 caractères.');
      return;
    }
    setState(() => sending = true);
    try {
      final api = context.read<ApiSession>();
      for (final attachment in attachments) {
        if (attachment['id'] != null) continue;
        final file = attachment['file'] as XFile;
        final piece = await api.upload(
          '/mobile/conversations/${widget.conversationId}/pieces-jointes',
          bytes: await file.readAsBytes(),
          fileName: file.name,
          fields: {'sourceRef': attachment['source'] as String},
        );
        attachment['id'] = piece['id'];
      }
      final fingerprint = jsonEncode([
        draft,
        attachments.map((p) => p['id']).toList(),
      ]);
      if (submissionFingerprint != fingerprint) {
        submissionFingerprint = fingerprint;
        submissionSource = const Uuid().v4();
      }
      await api.request(
        'POST',
        '/mobile/conversations/${widget.conversationId}/messages',
        body: {
          'contenu': draft,
          'sourceRef': submissionSource,
          if (attachments.isNotEmpty)
            'piecesJointes': attachments.map((p) => p['id']).toList(),
        },
      );
      if (!mounted) return;
      submissionFingerprint = null;
      submissionSource = null;
      if (text.text.trim() == draft) text.clear();
      setState(() => attachments.clear());
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    voice.removeListener(voiceChanged);
    voice.dispose();
    WidgetsBinding.instance.removeObserver(this);
    text.dispose();
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  Widget composerIcon(String tooltip, IconData icon, VoidCallback action) =>
      IconButton(
        tooltip: tooltip,
        onPressed: sending || voice.active || voice.draft != null
            ? null
            : action,
        constraints: const BoxConstraints.tightFor(width: 44, height: 48),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 24, color: AppColors.textMuted),
      );

  Widget bubble(Map<String, dynamic> message, String? userId) {
    final mine = message['expediteurId'] == userId;
    final color = mine ? AppColors.textDark : Colors.white;
    final date = DateTime.tryParse('${message['envoyeLe']}')?.toLocal();
    final time = date == null
        ? ''
        : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Tooltip(
      message: 'Appui long : notes liées',
      child: GestureDetector(
        onLongPress: () =>
            showTargetNotes(context, 'MESSAGE', '${message['id']}'),
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.sizeOf(context).width * .78)
                  .clamp(0, 440)
                  .toDouble(),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 7),
              decoration: BoxDecoration(
                color: mine ? Colors.white : const Color(0xFF228FA9),
                border: Border.all(
                  color: mine ? const Color(0xFFE0E8EE) : Colors.transparent,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ('${message['contenu'] ?? ''}'.isNotEmpty &&
                      !(message['contenu'] == 'Pièce jointe' &&
                          (message['piecesJointes'] as List? ?? [])
                              .isNotEmpty &&
                          (message['piecesJointes'] as List).every(
                            (p) => p['typeMime'] == 'audio/wav',
                          )))
                    Text(
                      '${message['contenu']}',
                      style: AppDecor.t(13, c: color, h: 1.45),
                    ),
                  for (final raw in (message['piecesJointes'] as List? ?? []))
                    if (raw['typeMime'] == 'audio/wav')
                      ServerVoiceBubble(
                        key: ValueKey(raw['id']),
                        voice: voice,
                        pieceId: '${raw['id']}',
                        duration: Duration(
                          milliseconds: (raw['dureeMs'] as num?)?.toInt() ?? 0,
                        ),
                        color: color,
                      )
                    else
                      TextButton.icon(
                        onPressed: () =>
                            download(Map<String, dynamic>.from(raw as Map)),
                        style: TextButton.styleFrom(foregroundColor: color),
                        icon: const Icon(Icons.insert_drive_file_outlined),
                        label: Text(
                          '${raw['nomOriginal']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          time,
                          style: AppDecor.t(
                            10,
                            c: color.withValues(alpha: .75),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (mine)
                        Icon(
                          message['luLe'] == null
                              ? Icons.check
                              : Icons.done_all,
                          size: 14,
                          color: color,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = context.watch<ApiSession>().userId;
    final filtered = messages
        .where(
          (m) => '${m['contenu'] ?? ''}'.toLowerCase().contains(
            search.text.toLowerCase(),
          ),
        )
        .toList();
    return PopScope(
      canPop: !showEmojis,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && showEmojis) setState(() => showEmojis = false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF4F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          foregroundColor: AppColors.primaryDeep,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 64,
          leading: PageBackButton(
            color: AppColors.primaryDeep,
            backgroundColor: Colors.white,
          ),
          titleSpacing: 0,
          title: InkWell(
            onTap: openContact,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLighter,
                  child: Text(
                    widget.doctorName
                        .trim()
                        .split(RegExp(r'\s+'))
                        .where((s) => s.isNotEmpty)
                        .take(2)
                        .map((s) => s[0])
                        .join()
                        .toUpperCase(),
                    style: AppDecor.t(
                      11,
                      c: AppColors.primary,
                      w: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.doctorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (widget.returnToCall)
              IconButton(
                tooltip: 'Revenir à l’appel',
                onPressed: openCalls,
                icon: const Icon(Icons.call_outlined),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Appeler',
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.call_outlined),
                onSelected: openCalls,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'AUDIO',
                    child: ChatMenuEntry(
                      icon: Icons.call_outlined,
                      title: 'Appel audio',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'VIDEO',
                    child: ChatMenuEntry(
                      icon: Icons.videocam_outlined,
                      title: 'Appel vidéo',
                    ),
                  ),
                ],
              ),
            PopupMenuButton<String>(
              tooltip: 'Options de la conversation',
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              onSelected: (value) {
                if (value == 'search') setState(() => searching = true);
                if (value == 'contact') {
                  unawaited(openContact());
                }
                if (value == 'calls') openCalls();
                if (value == 'info') {
                  showDialog<void>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('À propos de la messagerie'),
                      content: const Text(
                        'Cette messagerie ne traite pas les urgences. En cas d’urgence, contactez les services d’urgence locaux.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'info',
                  child: ChatMenuEntry(
                    icon: Icons.info_outline_rounded,
                    title: 'À propos de la messagerie',
                  ),
                ),
                PopupMenuItem(
                  value: 'contact',
                  child: ChatMenuEntry(
                    icon: Icons.person_outline_rounded,
                    title: 'Afficher le contact',
                  ),
                ),
                PopupMenuItem(
                  value: 'search',
                  child: ChatMenuEntry(
                    icon: Icons.search_rounded,
                    title: 'Rechercher',
                  ),
                ),
                PopupMenuItem(
                  value: 'calls',
                  child: ChatMenuEntry(
                    icon: Icons.history_rounded,
                    title: 'Historique des appels',
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (widget.returnToCall)
                Material(
                  color: AppColors.primary,
                  child: InkWell(
                    onTap: openCalls,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.call_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Revenir à l’appel',
                              style: AppDecor.t(
                                12,
                                c: Colors.white,
                                w: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (searching)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher dans la conversation',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Fermer la recherche',
                        onPressed: () => setState(() {
                          searching = false;
                          search.clear();
                        }),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (voice.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  child: Text(
                    voice.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            searching
                                ? 'Aucun message trouvé'
                                : 'Commencez votre conversation',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.all(18),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final current = DateTime.tryParse(
                            '${filtered[i]['envoyeLe']}',
                          )?.toLocal();
                          final previous = i == 0
                              ? null
                              : DateTime.tryParse(
                                  '${filtered[i - 1]['envoyeLe']}',
                                )?.toLocal();
                          final newDay =
                              current != null &&
                              (previous == null ||
                                  current.year != previous.year ||
                                  current.month != previous.month ||
                                  current.day != previous.day);
                          return Column(
                            children: [
                              if (newDay)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 18,
                                  ),
                                  child: Text(
                                    '${current.day.toString().padLeft(2, '0')}/${current.month.toString().padLeft(2, '0')}/${current.year}',
                                    style: AppDecor.t(
                                      10,
                                      c: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              bubble(filtered[i], id),
                            ],
                          );
                        },
                      ),
              ),
              if (attachments.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final a in attachments)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(
                                (a['file'] as XFile).name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            onDeleted: sending
                                ? null
                                : () => setState(() => attachments.remove(a)),
                          ),
                        ),
                    ],
                  ),
                ),
              if (voice.active || voice.draft != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Annuler le vocal',
                        onPressed: voice.sending ? null : voice.cancel,
                        icon: const Icon(Icons.delete_outline),
                      ),
                      if (voice.draft != null)
                        Expanded(
                          child: ServerVoiceBubble(
                            key: ValueKey(voice.draft),
                            voice: voice,
                            draft: voice.draft,
                            duration: voice.draft!.duration,
                            color: AppColors.primaryDeep,
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            voice.starting
                                ? 'Autorisation du microphone…'
                                : voice.stopping
                                ? 'Préparation du vocal…'
                                : 'Enregistrement ${voiceTime(voice.elapsed)} · 2 min max.',
                          ),
                        ),
                      if (voice.recording)
                        IconButton(
                          tooltip: 'Arrêter le vocal',
                          onPressed: voice.stop,
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.red,
                          ),
                        )
                      else if (voice.draft != null)
                        TextButton(
                          onPressed: voice.sending ? null : send,
                          child: Text(voice.sending ? 'Envoi…' : 'Envoyer'),
                        ),
                    ],
                  ),
                ),
              if (!voice.active && voice.draft == null)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              composerIcon(
                                showEmojis
                                    ? 'Afficher le clavier'
                                    : 'Choisir un emoji',
                                showEmojis
                                    ? Icons.keyboard_outlined
                                    : Icons.emoji_emotions_outlined,
                                () {
                                  FocusScope.of(context).unfocus();
                                  setState(() => showEmojis = !showEmojis);
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: text,
                                  minLines: 1,
                                  maxLines:
                                      MediaQuery.viewInsetsOf(context).bottom >
                                          0
                                      ? 2
                                      : 4,
                                  onChanged: (_) => setState(() {}),
                                  onTap: () {
                                    if (showEmojis) {
                                      setState(() => showEmojis = false);
                                    }
                                  },
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Message',
                                    hintMaxLines: 1,
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 12,
                                    ),
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                              ),
                              composerIcon(
                                'Joindre un PDF ou une image',
                                Icons.attach_file_rounded,
                                () => attach(),
                              ),
                              composerIcon(
                                'Prendre une photo',
                                Icons.camera_alt_outlined,
                                () => attach(camera: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: text.text.trim().isEmpty && attachments.isEmpty
                            ? 'Message vocal'
                            : 'Envoyer',
                        onPressed: sending
                            ? null
                            : text.text.trim().isEmpty && attachments.isEmpty
                            ? () {
                                if (widget.returnToCall) {
                                  setState(
                                    () => error =
                                        'Terminez l’appel avant d’enregistrer un vocal.',
                                  );
                                } else {
                                  unawaited(voice.start());
                                }
                              }
                            : send,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(52, 52),
                          shape: const CircleBorder(),
                          backgroundColor: const Color(0xFF228FA9),
                          foregroundColor: Colors.white,
                        ),
                        icon: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                text.text.trim().isEmpty && attachments.isEmpty
                                    ? Icons.mic_rounded
                                    : Icons.send_rounded,
                              ),
                      ),
                    ],
                  ),
                ),
              if (showEmojis)
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * .3,
                  child: EmojiPicker(
                    textEditingController: text,
                    onEmojiSelected: (_, _) => setState(() {}),
                    config: Config(
                      height: MediaQuery.sizeOf(context).height * .3,
                      locale: const Locale('fr'),
                      emojiViewConfig: const EmojiViewConfig(
                        columns: 8,
                        emojiSizeMax: 28,
                        backgroundColor: Color(0xFFF3F7FB),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
