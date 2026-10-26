import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/doctor_message.dart';
import 'api_session.dart';
import 'chat_media_service.dart';

/// Un brouillon reste local jusqu'à l'action explicite « Envoyer ».
class ServerVoiceService extends ChangeNotifier {
  final ApiSession api;
  final String conversationId;
  final ChatMediaService media;
  ServerVoiceService({
    required this.api,
    required this.conversationId,
    ChatMediaService? media,
  }) : media = media ?? ChatMediaService(voiceWav: true),
       _session = api.generation {
    api.addListener(_sessionChanged);
  }
  final int _session;
  bool _disposed = false;
  int _epoch = 0, _playEpoch = 0;
  bool starting = false, recording = false, stopping = false, sending = false;
  Duration elapsed = Duration.zero;
  DoctorMessage? draft;
  String? error, _pieceId, _uploadSource, _messageSource;
  Timer? _timer;
  bool get active => starting || recording || stopping;
  bool get _valid => !_disposed && api.generation == _session;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _sessionChanged() {
    if (api.generation == _session) return;
    _epoch++;
    _playEpoch++;
    _timer?.cancel();
    starting = recording = stopping = false;
    draft = null;
    _pieceId = _uploadSource = _messageSource = null;
    unawaited(media.cancelRecording().catchError((Object _) {}));
    unawaited(media.dispose().catchError((Object _) {}));
    _notify();
  }

  Future<void> start() async {
    if (!_valid || active || sending || draft != null) return;
    final epoch = ++_epoch;
    starting = true;
    error = null;
    _notify();
    try {
      await pausePlayback();
      if (!_valid || epoch != _epoch) return;
      final allowed = await media.startRecording();
      if (!_valid || epoch != _epoch) {
        await media.cancelRecording();
        return;
      }
      if (!allowed) {
        error = 'Autorisez le microphone pour enregistrer un message vocal.';
        return;
      }
      recording = true;
      elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed += const Duration(seconds: 1);
        _notify();
        // Marge pour la fermeture du fichier avant la limite serveur de 120 s.
        if (elapsed >= const Duration(seconds: 119)) unawaited(stop());
      });
    } catch (_) {
      if (_valid && epoch == _epoch) {
        error = 'Enregistrement impossible. Vérifiez le microphone.';
      }
    } finally {
      if (_valid && epoch == _epoch) {
        starting = false;
        _notify();
      }
    }
  }

  Future<void> stop() async {
    if (!recording || stopping) return;
    final epoch = _epoch;
    recording = false;
    stopping = true;
    _timer?.cancel();
    _notify();
    try {
      final result = await media.stopRecording();
      if (!_valid || epoch != _epoch) return;
      if (result == null ||
          result.bytes == null ||
          result.bytes!.isEmpty ||
          result.duration < const Duration(milliseconds: 250)) {
        error = 'Message trop court. Enregistrez au moins une seconde.';
      } else if (result.bytes!.length > 5 * 1024 * 1024) {
        error = '5 Mo maximum par message vocal.';
      } else {
        draft = result;
        _uploadSource = const Uuid().v4();
        _messageSource = const Uuid().v4();
        _pieceId = null;
      }
    } catch (_) {
      if (_valid && epoch == _epoch) {
        error = 'Impossible de conserver cet enregistrement. Réessayez.';
      }
    } finally {
      if (_valid && epoch == _epoch) {
        stopping = false;
        _notify();
      }
    }
  }

  Future<void> cancel() async {
    if (sending) return;
    _epoch++;
    _timer?.cancel();
    starting = recording = stopping = false;
    draft = null;
    _pieceId = _uploadSource = _messageSource = null;
    await pausePlayback();
    try {
      await media.cancelRecording();
    } catch (_) {}
    _notify();
  }

  Future<void> suspend() async {
    await pausePlayback();
    if (starting) {
      await cancel();
    } else if (recording) {
      await stop();
    }
  }

  Future<bool> send() async {
    final message = draft;
    if (!_valid || message == null || sending || active) return false;
    final epoch = _epoch;
    final uploadSource = _uploadSource;
    final messageSource = _messageSource;
    var pieceId = _pieceId;
    sending = true;
    error = null;
    _notify();
    try {
      await pausePlayback();
      if (!_valid || epoch != _epoch) return false;
      if (pieceId == null) {
        final piece = await api.upload(
          '/mobile/conversations/$conversationId/pieces-jointes',
          bytes: message.bytes!,
          fileName: 'message-vocal.wav',
          fields: {'sourceRef': uploadSource!},
        );
        if (!_valid || epoch != _epoch) return false;
        pieceId = '${piece['id']}';
        _pieceId = pieceId;
      }
      if (!_valid || epoch != _epoch) return false;
      await api.request(
        'POST',
        '/mobile/conversations/$conversationId/messages',
        body: {
          'contenu': '',
          'sourceRef': messageSource,
          'piecesJointes': [pieceId],
        },
      );
      if (!_valid || epoch != _epoch) return false;
      draft = null;
      _pieceId = _uploadSource = _messageSource = null;
      return true;
    } catch (e) {
      if (_valid && epoch == _epoch) {
        error = e is ApiException ? e.message : 'Envoi impossible. Réessayez.';
      }
      return false;
    } finally {
      if (!_disposed) {
        sending = false;
        _notify();
      }
    }
  }

  Future<void> pausePlayback() async {
    _playEpoch++;
    await media.pausePlayback();
  }

  Future<void> play(
    VoicePlayback player, {
    DoctorMessage? local,
    String? pieceId,
    Duration duration = Duration.zero,
  }) async {
    if (!_valid || active) return;
    final epoch = ++_playEpoch;
    await media.pausePlayback();
    if (!_valid || epoch != _playEpoch) return;
    final message =
        local ??
        DoctorMessage(
          text: 'Message vocal',
          kind: DoctorMessageKind.voice,
          bytes: await api.bytes(
            '/mobile/conversations/$conversationId/pieces-jointes/$pieceId/contenu',
          ),
          mimeType: 'audio/wav',
          duration: duration,
        );
    if (!_valid || epoch != _playEpoch) return;
    await player.play(message);
    if (!_valid || epoch != _playEpoch) await player.pause();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _playEpoch++;
    _timer?.cancel();
    api.removeListener(_sessionChanged);
    unawaited(media.dispose().catchError((Object _) {}));
    draft = null;
    super.dispose();
  }
}
