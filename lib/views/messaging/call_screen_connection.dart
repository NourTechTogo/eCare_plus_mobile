import 'package:flutter/material.dart';

/// Server state supplied to the existing audio/video presentation.
class CallScreenConnection {
  final String status;
  final Widget actions;
  final Widget? remoteVideo, localVideo;
  final bool muted, speaker, camera, hasCall;
  final VoidCallback? onMicrophone,
      onSpeaker,
      onCamera,
      onVideo,
      onEnd,
      onMessages;
  const CallScreenConnection({
    required this.status,
    required this.actions,
    this.remoteVideo,
    this.localVideo,
    this.hasCall = true,
    this.muted = true,
    this.speaker = false,
    this.camera = false,
    this.onMicrophone,
    this.onSpeaker,
    this.onCamera,
    this.onVideo,
    this.onEnd,
    this.onMessages,
  });
}
