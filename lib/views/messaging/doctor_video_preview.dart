import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/doctor_catalog.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import 'doctor_chat_page.dart';

class DoctorVideoPreview extends StatefulWidget {
  final CareDoctor doctor;
  const DoctorVideoPreview({super.key, required this.doctor});

  @override
  State<DoctorVideoPreview> createState() => _DoctorVideoPreviewState();
}

class _DoctorVideoPreviewState extends State<DoctorVideoPreview> {
  bool _muted = false;
  bool _speaker = false;
  bool _camera = true;
  bool _frontCamera = true;

  Widget _control(
    String tooltip,
    IconData icon,
    VoidCallback action, {
    bool selected = false,
    bool endCall = false,
    bool message = false,
  }) => Semantics(
    selected: selected,
    child: IconButton.filled(
      tooltip: tooltip,
      onPressed: action,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        maximumSize: const Size(52, 52),
        padding: const EdgeInsets.all(12),
        shape: const CircleBorder(),
        backgroundColor: endCall
            ? const Color(0xFFE05155)
            : selected || message
            ? AppColors.primary
            : Colors.white,
        foregroundColor: endCall || selected || message
            ? Colors.white
            : const Color(0xFF293B4D),
      ),
      icon: Icon(icon, size: 23),
    ),
  );

  Widget _localCamera(double height) => Container(
    width: 142,
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF243747),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .7), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .24),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (_camera)
          Image.asset(
            'lib/data/Profile.png',
            fit: BoxFit.cover,
            semanticLabel: 'Portrait patient de démonstration',
          )
        else
          const Center(
            child: Icon(
              Icons.videocam_off_outlined,
              color: Colors.white70,
              size: 32,
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC101E2D)],
            ),
          ),
        ),
        if (height > 130)
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _camera ? 'Votre caméra' : 'Caméra désactivée',
                  textAlign: TextAlign.center,
                  style: AppDecor.t(11, c: Colors.white, w: FontWeight.w600),
                ),
                if (_camera)
                  Text(
                    _frontCamera ? 'Avant' : 'Arrière',
                    style: AppDecor.t(9, c: Colors.white70),
                  ),
              ],
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF152A3C),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              widget.doctor.imageAsset,
              key: const Key('doctor-video-background'),
              fit: BoxFit.cover,
              // The existing doctor portraits place the subject left of center.
              alignment: const Alignment(-.44, -1),
              semanticLabel:
                  'Portrait de démonstration de ${widget.doctor.name}',
              errorBuilder: (_, _, _) => ColoredBox(
                color: const Color(0xFF152A3C),
                child: Center(
                  child: Icon(
                    widget.doctor.icon,
                    size: 90,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xBB0A1725),
                    Color(0x000A1725),
                    Color(0xDD0A1725),
                  ],
                  stops: [0, .45, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Retour',
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .18),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Appel vidéo',
                          textAlign: TextAlign.center,
                          style: AppDecor.t(
                            14,
                            c: Colors.white,
                            w: FontWeight.w600,
                            h: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        tooltip: 'Changer de caméra',
                        onPressed: _camera
                            ? () => setState(() => _frontCamera = !_frontCamera)
                            : null,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .18),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white38,
                          minimumSize: const Size(48, 48),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(
                          Icons.flip_camera_ios_outlined,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctor.name,
                          style: AppDecor.t(
                            17,
                            c: Colors.white,
                            w: FontWeight.w700,
                            h: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.doctor.specialty,
                          style: AppDecor.t(11, c: Colors.white70, h: 1.25),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '00:00 · Aperçu',
                        style: AppDecor.t(
                          11,
                          c: Colors.white,
                          w: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 12),
                          child: _localCamera(
                            ((constraints.maxHeight - 32) * .78).clamp(
                              0.0,
                              220.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _control(
                        'Micro',
                        _muted
                            ? Icons.mic_off_outlined
                            : Icons.mic_none_rounded,
                        () => setState(() => _muted = !_muted),
                        selected: _muted,
                      ),
                      _control(
                        'Haut-parleur',
                        _speaker
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_outlined,
                        () => setState(() => _speaker = !_speaker),
                        selected: _speaker,
                      ),
                      _control(
                        'Caméra',
                        _camera
                            ? Icons.videocam_outlined
                            : Icons.videocam_off_outlined,
                        () => setState(() => _camera = !_camera),
                        selected: !_camera,
                      ),
                      _control(
                        'Messages',
                        Icons.chat_bubble_outline_rounded,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DoctorChatPage(doctor: widget.doctor),
                          ),
                        ),
                        message: true,
                      ),
                      _control(
                        'Terminer l’appel',
                        Icons.close_rounded,
                        () => Navigator.pop(context),
                        endCall: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Aperçu de l’interface · Aucun appel lancé',
                    textAlign: TextAlign.center,
                    style: AppDecor.t(10, c: Colors.white70, h: 1.25),
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
