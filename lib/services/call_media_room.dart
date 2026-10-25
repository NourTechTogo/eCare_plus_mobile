import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

/// The widget owns one connection; SDK resources remain behind this boundary.
abstract class CallMediaRoom extends ChangeNotifier {
  ConnectionState get connectionState;
  int get remoteCount;
  List<VideoTrack> get videos;
  VideoTrack? get localVideo => null;
  bool get microphoneEnabled;
  bool get cameraEnabled;
  Future<void> connect(String url, String token);
  Future<void> setMicrophoneEnabled(bool enabled);
  Future<void> setCameraEnabled(bool enabled);
  Future<void> close();
}

class LiveKitMediaRoom extends CallMediaRoom {
  final Room _room = Room(
    roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
  );
  bool _closed = false;
  LiveKitMediaRoom() {
    _room.addListener(_changed);
  }
  void _changed() {
    if (!_closed) notifyListeners();
  }

  @override
  ConnectionState get connectionState => _room.connectionState;
  @override
  int get remoteCount => _room.remoteParticipants.length;
  @override
  List<VideoTrack> get videos => [
    for (final participant in _room.remoteParticipants.values)
      for (final p in participant.videoTrackPublications)
        if (p.track is VideoTrack) p.track as VideoTrack,
  ];
  @override
  bool get microphoneEnabled =>
      _room.localParticipant?.isMicrophoneEnabled() ?? false;
  @override
  bool get cameraEnabled => _room.localParticipant?.isCameraEnabled() ?? false;
  @override
  VideoTrack? get localVideo {
    final tracks = _room.localParticipant?.videoTrackPublications;
    if (tracks == null) return null;
    for (final publication in tracks) {
      if (publication.track is VideoTrack) {
        return publication.track as VideoTrack;
      }
    }
    return null;
  }

  @override
  Future<void> connect(String url, String token) => _room.connect(url, token);
  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _room.localParticipant?.setMicrophoneEnabled(enabled);
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    await _room.localParticipant?.setCameraEnabled(enabled);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _room.removeListener(_changed);
    try {
      await _room.disconnect();
    } finally {
      await _room.dispose();
      super.dispose();
    }
  }
}
