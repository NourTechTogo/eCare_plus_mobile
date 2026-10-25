import 'package:flutter/material.dart';
import '../../data/doctor_catalog.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/page_header.dart';
import 'call_screen_connection.dart';

/// Shared eCare+ layout: bounded media, readable identity and reachable controls.
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
  Widget control(
    String label,
    String tooltip,
    IconData icon,
    bool selected,
    VoidCallback? action,
  ) => SizedBox(
    width: 76,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: action,
          isSelected: selected,
          style: IconButton.styleFrom(
            minimumSize: const Size(50, 50),
            backgroundColor: selected
                ? AppColors.primary
                : AppColors.primaryLighter,
            foregroundColor: selected ? Colors.white : AppColors.primary,
            disabledBackgroundColor: AppColors.scaffoldBackground,
            disabledForegroundColor: AppColors.textHint,
            shape: const CircleBorder(),
          ),
          icon: Icon(icon, size: 23),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppDecor.t(11, c: AppColors.textMuted, h: 1.3),
        ),
      ],
    ),
  );
  Widget avatar(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.primaryLighter,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 5),
      boxShadow: AppDecor.shadow(.07),
    ),
    child: Center(
      child: Text(
        doctor.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .take(2)
            .map((s) => s[0])
            .join()
            .toUpperCase(),
        style: AppDecor.t(size * .3, w: FontWeight.w700, c: AppColors.primary),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = connection;
    final isMuted = state?.muted ?? muted,
        isSpeaker = state?.speaker ?? speaker,
        isCamera = state?.camera ?? camera;
    final controls = Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == null || state.hasCall)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 12,
              children: [
                control(
                  isMuted ? 'Micro coupé' : 'Micro',
                  'Micro',
                  isMuted ? Icons.mic_off_outlined : Icons.mic_none_rounded,
                  isMuted,
                  state != null ? state.onMicrophone : onMicrophone,
                ),
                control(
                  'Haut-parleur',
                  'Haut-parleur',
                  Icons.volume_up_outlined,
                  isSpeaker,
                  state != null ? state.onSpeaker : onSpeaker,
                ),
                control(
                  video ? (isCamera ? 'Caméra' : 'Caméra coupée') : 'Vidéo',
                  video ? 'Caméra' : 'Passer en vidéo',
                  video
                      ? (isCamera
                            ? Icons.videocam_outlined
                            : Icons.videocam_off_outlined)
                      : Icons.videocam_outlined,
                  video && !isCamera,
                  state != null
                      ? (video ? state.onCamera : state.onVideo)
                      : (video ? onCamera : onVideo),
                ),
              ],
            ),
          const SizedBox(height: 18),
          if (state == null || state.hasCall)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  tooltip: 'Terminer l’appel',
                  onPressed: state != null
                      ? state.onEnd
                      : () => Navigator.maybePop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFD94E61),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(64, 64),
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.call_end_rounded, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  state == null ? 'Fermer l’aperçu' : 'Terminer l’appel',
                  style: AppDecor.t(11, c: AppColors.textMuted),
                ),
              ],
            )
          else
            Text(
              'Choisissez un appel audio ou vidéo pour commencer.',
              textAlign: TextAlign.center,
              style: AppDecor.t(12, c: AppColors.textMuted, h: 1.5),
            ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: LayoutBuilder(
              builder: (context, c) {
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const PageBackButton(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            video ? 'Appel vidéo' : 'Appel audio',
                            style: AppDecor.t(
                              18,
                              w: FontWeight.w700,
                              c: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Messages',
                          onPressed: state != null
                              ? state.onMessages
                              : onMessages,
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (video)
                      Container(
                        key: const Key('doctor-video-background'),
                        height: MediaQuery.textScalerOf(context).scale(14) > 20
                            ? 260
                            : (c.maxHeight * .27).clamp(170, 240).toDouble(),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFF102E4B),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (state?.remoteVideo != null)
                              state!.remoteVideo!
                            else
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    avatar(76),
                                    const SizedBox(height: 14),
                                    Text(
                                      'La vidéo apparaîtra ici',
                                      style: AppDecor.t(12, c: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                width: 82,
                                height: 108,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF29445D),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white54),
                                ),
                                child:
                                    state?.localVideo ??
                                    Center(
                                      child: Icon(
                                        isCamera
                                            ? Icons.person_outline_rounded
                                            : Icons.videocam_off_outlined,
                                        color: Colors.white70,
                                        size: 30,
                                      ),
                                    ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: IconButton.filledTonal(
                                tooltip: 'Changer de caméra',
                                onPressed: state == null ? onFlip : null,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: .15,
                                  ),
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white38,
                                ),
                                icon: const Icon(
                                  Icons.cameraswitch_outlined,
                                  size: 21,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: avatar(c.maxHeight < 650 ? 68 : 100),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      doctor.name,
                      textAlign: TextAlign.center,
                      style: AppDecor.t(
                        22,
                        w: FontWeight.w700,
                        c: AppColors.primaryDeep,
                        h: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      textAlign: TextAlign.center,
                      style: AppDecor.t(12, c: AppColors.textMuted, h: 1.4),
                    ),
                    if (video && state == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        isCamera ? 'Votre caméra' : 'Caméra désactivée',
                        textAlign: TextAlign.center,
                        style: AppDecor.t(11, c: AppColors.textMuted),
                      ),
                      Text(
                        front ? 'Avant' : 'Arrière',
                        textAlign: TextAlign.center,
                        style: AppDecor.t(10, c: AppColors.textMuted),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLighter,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          state?.status ??
                              'Aperçu de l’interface · Aucun appel lancé',
                          textAlign: TextAlign.center,
                          style: AppDecor.t(
                            12,
                            w: FontWeight.w600,
                            c: AppColors.primary,
                            h: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (state != null) ...[
                      const SizedBox(height: 12),
                      Theme(
                        data: Theme.of(context).copyWith(
                          filledButtonTheme: FilledButtonThemeData(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                        child: state.actions,
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                );
                final footer = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    controls,
                    const SizedBox(height: 10),
                    Text(
                      'Les appels ne remplacent pas les services d’urgence.',
                      textAlign: TextAlign.center,
                      style: AppDecor.t(10, c: AppColors.textMuted, h: 1.4),
                    ),
                  ],
                );
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: largeText || c.maxHeight < 480
                      ? SingleChildScrollView(
                          child: Column(children: [content, footer]),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(child: content),
                            ),
                            footer,
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
