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

class ServerChatPage extends StatefulWidget {
  final String conversationId, doctorName;
  final CareDoctor? doctor;
  const ServerChatPage({
    super.key,
    required this.conversationId,
    required this.doctorName,
    this.doctor,
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
  CareDoctor get doctor =>
      widget.doctor ?? CareDoctor.fromServer({'nom': widget.doctorName});

  void openCalls([String? type]) => Navigator.push(
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

  List<Map<String, dynamic>> messages = [];
  Timer? timer;
  String? error;
  bool sending = false, loading = false;
  final List<Map<String, dynamic>> attachments = [];
  Future<void> attach({bool camera = false}) async {
    if (sending || attachments.length >= 5) return;
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
      final rows = await api.all(
        '/mobile/conversations/${widget.conversationId}/messages',
      );
      if (!mounted || generation != api.generation) return;
      rows.sort((a, b) {
        final c = '${a['envoyeLe']}'.compareTo('${b['envoyeLe']}');
        return c != 0 ? c : '${a['id']}'.compareTo('${b['id']}');
      });
      setState(() {
        messages = rows;
        error = null;
      });
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
    WidgetsBinding.instance.removeObserver(this);
    text.dispose();
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  Widget composerIcon(String tooltip, IconData icon, VoidCallback action) =>
      IconButton(
        tooltip: tooltip,
        onPressed: sending ? null : action,
        constraints: const BoxConstraints.tightFor(width: 44, height: 48),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 24, color: AppColors.textMuted),
      );

  Widget bubble(Map<String, dynamic> message, String? userId) {
    final mine = message['expediteurId'] == userId;
    final color = mine ? Colors.white : AppColors.textDark;
    final date = DateTime.tryParse('${message['envoyeLe']}')?.toLocal();
    final time = date == null
        ? ''
        : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if ('${message['contenu'] ?? ''}'.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${message['contenu']}',
                    style: AppDecor.t(14, c: color, h: 1.5),
                  ),
                ),
              for (final raw in (message['piecesJointes'] as List? ?? []))
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
                      style: AppDecor.t(10, c: color.withValues(alpha: .75)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  if (mine)
                    Icon(
                      message['luLe'] == null ? Icons.check : Icons.done_all,
                      size: 14,
                      color: color,
                    ),
                  IconButton(
                    tooltip: 'Notes liées',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        showTargetNotes(context, 'MESSAGE', '${message['id']}'),
                    icon: Icon(Icons.note_outlined, size: 17, color: color),
                  ),
                ],
              ),
            ],
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leadingWidth: 64,
          leading: PageBackButton(
            color: Colors.white,
            backgroundColor: Colors.white.withAlpha(45),
          ),
          titleSpacing: 0,
          title: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DoctorContactPage(doctor: doctor),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage(doctor.imageAsset),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.doctorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
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
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => DoctorContactPage(doctor: doctor),
                    ),
                  );
                }
                if (value == 'calls') openCalls();
              },
              itemBuilder: (_) => const [
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Text(
                  'Cette messagerie ne traite pas les urgences. En cas d’urgence, contactez les services d’urgence locaux.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                        itemBuilder: (_, i) => bubble(filtered[i], id),
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
                          color: const Color(0xFFF0F4F8),
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
                                    MediaQuery.viewInsetsOf(context).bottom > 0
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
                      tooltip: 'Envoyer',
                      onPressed: sending ? null : send,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        shape: const CircleBorder(),
                        backgroundColor: AppColors.primary,
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
                          : const Icon(Icons.send_rounded),
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
