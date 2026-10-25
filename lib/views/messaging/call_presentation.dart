import 'package:flutter/material.dart';
import '../../data/doctor_catalog.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import 'call_screen_connection.dart';

/// Full-screen media with a compact dock, following the supplied call reference.
class CallPresentation extends StatelessWidget {
  final CareDoctor doctor;
  final bool video;
  final CallScreenConnection? connection;
  final bool muted, speaker, camera, front;
  final VoidCallback? onMicrophone,
      onSpeaker,
      onCamera,
      onFlip,
      onVideo,
      onMessages;
  const CallPresentation({
    super.key,
    required this.doctor,
    required this.video,
    this.connection,
    this.muted = false,
    this.speaker = false,
    this.camera = true,
    this.front = true,
    this.onMicrophone,
    this.onSpeaker,
    this.onCamera,
    this.onFlip,
    this.onVideo,
    this.onMessages,
  });

  Widget avatar(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.primaryLighter,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: .8), width: 4),
    ),
    alignment: Alignment.center,
    child: Text(
      doctor.name
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .take(2)
          .map((s) => s[0])
          .join()
          .toUpperCase(),
      style: AppDecor.t(size * .29, w: FontWeight.w700, c: AppColors.primary),
    ),
  );

  Widget round(
    String tooltip,
    IconData icon,
    VoidCallback? action, {
    bool selected = false,
    bool end = false,
    bool dark = false,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: action,
    style: IconButton.styleFrom(
      fixedSize: const Size(46, 46),
      padding: const EdgeInsets.all(11),
      backgroundColor: end
          ? const Color(0xFFE64F62)
          : selected
          ? AppColors.primary
          : Colors.white.withValues(alpha: dark ? .94 : 1),
      foregroundColor: end || selected ? Colors.white : AppColors.primaryDeep,
      disabledBackgroundColor: Colors.white.withValues(alpha: dark ? .3 : .65),
      disabledForegroundColor: dark ? Colors.white54 : AppColors.textHint,
      shape: const CircleBorder(),
    ),
    icon: Icon(icon, size: 23),
  );

  @override
  Widget build(BuildContext context) {
    final noticePainter = TextPainter(
      text: TextSpan(
        text: 'Les appels ne remplacent pas les services d’urgence.',
        style: AppDecor.t(9, h: 1.4),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: MediaQuery.sizeOf(context).width - 32);
    final previewBottom =
        noticePainter.height + 120 + MediaQuery.paddingOf(context).bottom;
    final s = connection;
    final hasCall = s == null || s.hasCall;
    final isMuted = s?.muted ?? muted;
    final isSpeaker = s?.speaker ?? speaker;
    final isCamera = s?.camera ?? camera;
    final color = video ? Colors.white : AppColors.primaryDeep;
    final messages = s != null ? s.onMessages : onMessages;
    final end = s != null ? s.onEnd : () => Navigator.maybePop(context);
    final header = Row(
      children: [
        round(
          'Retour',
          Icons.arrow_back_rounded,
          s != null && s.hasCall ? messages : () => Navigator.maybePop(context),
          dark: video,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            video ? 'Appel vidéo' : 'Appel audio',
            style: AppDecor.t(16, w: FontWeight.w600, c: color),
          ),
        ),
        if (!hasCall)
          round(
            'Messages',
            Icons.chat_bubble_outline_rounded,
            messages,
            dark: video,
          ),
        if (s != null)
          PopupMenuButton<String>(
            tooltip: 'Options de l’appel',
            icon: Icon(Icons.more_vert_rounded, color: color),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: (value) {
              switch (value) {
                case 'history':
                  s.onHistory?.call();
                case 'refresh':
                  s.onRefresh?.call();
                case 'notes':
                  s.onNotes?.call();
              }
            },
            itemBuilder: (_) => [
              if (s.onHistory != null)
                const PopupMenuItem(
                  value: 'history',
                  child: ListTile(
                    leading: Icon(Icons.history_rounded),
                    title: Text('Historique'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (s.onRefresh != null)
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('Actualiser'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (s.onNotes != null)
                const PopupMenuItem(
                  value: 'notes',
                  child: ListTile(
                    leading: Icon(Icons.note_outlined),
                    title: Text('Notes liées'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
      ],
    );
    final identity = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          doctor.name,
          textAlign: TextAlign.center,
          style: AppDecor.t(
            video ? 20 : 24,
            w: FontWeight.w600,
            c: color,
            h: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          doctor.specialty,
          textAlign: TextAlign.center,
          style: AppDecor.t(
            12,
            c: video ? Colors.white70 : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s?.status ?? 'Aperçu de l’interface · Aucun appel lancé',
          textAlign: TextAlign.center,
          style: AppDecor.t(
            12,
            c: video ? Colors.white : AppColors.primary,
            w: FontWeight.w600,
          ),
        ),
      ],
    );
    final actions = s == null
        ? const SizedBox.shrink()
        : Theme(
            data: Theme.of(context).copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: video ? Colors.white : AppColors.primary,
                  foregroundColor: video ? AppColors.primaryDeep : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: color),
              ),
            ),
            child: s.actions,
          );
    final dock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCall)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: video ? const Color(0x66102132) : const Color(0xFFE1EBF2),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                round(
                  'Micro',
                  isMuted ? Icons.mic_off_outlined : Icons.mic_none_rounded,
                  s != null ? s.onMicrophone : onMicrophone,
                  selected: isMuted,
                  dark: video,
                ),
                round(
                  'Haut-parleur',
                  Icons.volume_up_outlined,
                  s != null ? s.onSpeaker : onSpeaker,
                  selected: isSpeaker,
                  dark: video,
                ),
                round(
                  video ? 'Caméra' : 'Passer en vidéo',
                  video && !isCamera
                      ? Icons.videocam_off_outlined
                      : Icons.videocam_outlined,
                  s != null
                      ? (video ? s.onCamera : s.onVideo)
                      : (video ? onCamera : onVideo),
                  selected: video && !isCamera,
                  dark: video,
                ),
                round(
                  'Messages',
                  Icons.chat_bubble_outline_rounded,
                  messages,
                  dark: video,
                ),
                round(
                  'Terminer l’appel',
                  Icons.call_end_rounded,
                  end,
                  end: true,
                  dark: video,
                ),
              ],
            ),
          ),
        if (!hasCall)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: actions,
          ),
        const SizedBox(height: 12),
        Text(
          'Les appels ne remplacent pas les services d’urgence.',
          textAlign: TextAlign.center,
          style: AppDecor.t(
            9,
            c: video ? Colors.white70 : AppColors.textMuted,
            h: 1.4,
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: video
          ? const Color(0xFF12344C)
          : AppColors.scaffoldBackground,
      body: LayoutBuilder(
        builder: (context, bounds) => Stack(
          fit: StackFit.expand,
          children: [
            if (video)
              Positioned.fill(
                child: Container(
                  key: const Key('doctor-video-background'),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF174B60), Color(0xFF0B2035)],
                    ),
                  ),
                  child:
                      s?.remoteVideo ??
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            avatar(100),
                            const SizedBox(height: 18),
                            Text(
                              'En attente de la vidéo',
                              style: AppDecor.t(12, c: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            if (video && s?.remoteVideo != null)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x88000000),
                          Colors.transparent,
                          Color(0x99000000),
                        ],
                        stops: [0, .5, 1],
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    header,
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, area) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: area.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: video
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: [
                                SizedBox(height: video ? 22 : 28),
                                if (!video) ...[
                                  avatar(100),
                                  const SizedBox(height: 22),
                                ],
                                identity,
                                if (hasCall) ...[
                                  const SizedBox(height: 16),
                                  actions,
                                ],
                                if (video)
                                  SizedBox(
                                    height:
                                        180 +
                                        (MediaQuery.textScalerOf(
                                                  context,
                                                ).scale(12) >
                                                18
                                            ? 36
                                            : 0),
                                  ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    dock,
                  ],
                ),
              ),
            ),
            if (video)
              Positioned(
                right: 20 + MediaQuery.paddingOf(context).right,
                bottom: previewBottom,
                child: Container(
                  key: const Key('local-video-preview'),
                  width: bounds.maxWidth < 350 ? 86 : 110,
                  height: bounds.maxHeight < 550 ? 100 : 148,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF36546A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white54, width: 1.5),
                    boxShadow: AppDecor.shadow(.15),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      s?.localVideo ??
                          Center(
                            child: Icon(
                              isCamera
                                  ? Icons.person_outline_rounded
                                  : Icons.videocam_off_outlined,
                              color: Colors.white70,
                              size: 30,
                            ),
                          ),
                      if (s == null)
                        Positioned(
                          left: 4,
                          right: 4,
                          bottom: 6,
                          child: Column(
                            children: [
                              Text(
                                isCamera ? 'Votre caméra' : 'Caméra désactivée',
                                textAlign: TextAlign.center,
                                style: AppDecor.t(9, c: Colors.white),
                              ),
                              Text(
                                front ? 'Avant' : 'Arrière',
                                style: AppDecor.t(9, c: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton(
                          tooltip: 'Changer de caméra',
                          onPressed: s == null ? onFlip : null,
                          icon: const Icon(
                            Icons.cameraswitch_outlined,
                            size: 19,
                          ),
                          color: Colors.white,
                          disabledColor: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
