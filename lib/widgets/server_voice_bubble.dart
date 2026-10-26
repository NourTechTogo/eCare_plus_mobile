import 'dart:async';
import 'package:flutter/material.dart';
import '../models/doctor_message.dart';
import '../services/chat_media_service.dart';
import '../services/server_voice_service.dart';

String voiceTime(Duration duration) =>
    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

class ServerVoiceBubble extends StatefulWidget {
  final ServerVoiceService voice;
  final String? pieceId;
  final DoctorMessage? draft;
  final Duration duration;
  final Color color;
  const ServerVoiceBubble({
    super.key,
    required this.voice,
    this.pieceId,
    this.draft,
    required this.duration,
    required this.color,
  });
  @override
  State<ServerVoiceBubble> createState() => _ServerVoiceBubbleState();
}

class _ServerVoiceBubbleState extends State<ServerVoiceBubble> {
  late final VoicePlayback player;
  StreamSubscription<Duration>? positions;
  StreamSubscription<bool>? states;
  bool playing = false, busy = false;
  Duration position = Duration.zero;
  int epoch = 0;
  @override
  void initState() {
    super.initState();
    player = widget.voice.media.createPlayback();
    positions = player.positions.listen((p) {
      if (mounted) setState(() => position = p);
    });
    states = player.states.listen((p) {
      if (mounted) setState(() => playing = p);
    });
  }

  Future<void> toggle() async {
    if (busy) return;
    final token = ++epoch;
    setState(() => busy = true);
    try {
      if (playing) {
        await player.pause();
      } else {
        await widget.voice.play(
          player,
          local: widget.draft,
          pieceId: widget.pieceId,
          duration: widget.duration,
        );
      }
    } catch (_) {
      if (mounted && token == epoch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture impossible. Réessayez.')),
        );
      }
    } finally {
      if (mounted && token == epoch) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    epoch++;
    unawaited(positions?.cancel());
    unawaited(states?.cancel());
    unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.duration.inMilliseconds.toDouble().clamp(
      1.0,
      double.infinity,
    );
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          IconButton(
            tooltip: playing ? 'Pause du vocal' : 'Écouter le vocal',
            onPressed: busy ? null : toggle,
            color: widget.color,
            icon: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.color,
                    ),
                  )
                : Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message vocal',
                  style: TextStyle(fontSize: 12, color: widget.color),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                  ),
                  child: Slider(
                    semanticFormatterCallback: (v) =>
                        voiceTime(Duration(milliseconds: v.round())),
                    activeColor: widget.color,
                    inactiveColor: widget.color.withValues(alpha: .25),
                    min: 0,
                    max: max,
                    value: position.inMilliseconds.toDouble().clamp(0, max),
                    onChanged: busy
                        ? null
                        : (v) async {
                            await player.seek(
                              Duration(milliseconds: v.round()),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
          Text(
            voiceTime(
              playing || position > Duration.zero ? position : widget.duration,
            ),
            style: TextStyle(fontSize: 11, color: widget.color),
          ),
        ],
      ),
    );
  }
}
