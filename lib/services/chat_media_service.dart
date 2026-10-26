import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/doctor_message.dart';
import 'chat_audio_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMediaException implements Exception {
  final String message;
  const ChatMediaException(this.message);
}

/// Device media only. This service does not transmit anything to a doctor.
class ChatMediaService {
  final String? doctorName;
  final bool voiceWav;
  ChatMediaService({this.doctorName, this.voiceWav = false});
  bool _disposed = false;
  int _recordEpoch = 0;
  Future<bool>? _starting;
  bool _permissionPending = false;
  String? _recordPath;
  static const pendingPhotoKey = 'chat.pendingPhotoDoctor';
  AudioRecorder? _recorder;
  final _players = <VoicePlayback>{};
  final _clock = Stopwatch();
  Stream<double>? _levels;
  static const maxBytes = 20 * 1024 * 1024;

  Future<DoctorMessage?> pickPhoto({required bool camera}) async {
    final trackRecovery =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        doctorName != null;
    final prefs = trackRecovery ? await SharedPreferences.getInstance() : null;
    if (prefs != null) await prefs.setString(pendingPhotoKey, doctorName!);
    try {
      final image = await ImagePicker().pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null) return null;
      return DoctorMessage(
        text: image.name,
        kind: DoctorMessageKind.attachment,
        bytes: await _read(image),
        filePath: kIsWeb ? null : image.path,
        isImage: true,
      );
    } finally {
      if (prefs != null) await prefs.remove(pendingPhotoKey);
    }
  }

  /// The image picker shares one recovery queue across profile and chat.
  static Future<(String, DoctorMessage)?> recoverPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final prefs = await SharedPreferences.getInstance();
    final doctor = prefs.getString(pendingPhotoKey);
    if (doctor == null) return null;
    try {
      final result = await ImagePicker().retrieveLostData();
      if (result.files == null || result.files!.isEmpty) return null;
      final image = result.files!.first;
      final bytes = await ChatMediaService()._read(image);
      return (
        doctor,
        DoctorMessage(
          text: image.name,
          kind: DoctorMessageKind.attachment,
          bytes: bytes,
          filePath: image.path,
          isImage: true,
        ),
      );
    } catch (_) {
      return null;
    } finally {
      await prefs.remove(pendingPhotoKey);
    }
  }

  Future<DoctorMessage?> pickDocument() async {
    final file = await openFile();
    if (file == null) return null;
    return DoctorMessage(
      text: file.name,
      kind: DoctorMessageKind.attachment,
      bytes: await _read(file),
      filePath: kIsWeb ? null : file.path,
    );
  }

  Future<Uint8List> _read(XFile file) async {
    if (await file.length() > maxBytes) {
      throw const ChatMediaException(
        'Choisissez un fichier de moins de 20 Mo.',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw const ChatMediaException('Ce fichier est vide.');
    return bytes;
  }

  Stream<double> get recordingLevels {
    final recorder = _recorder;
    if (recorder == null) return const Stream<double>.empty();
    return _levels ??= recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .map((amplitude) => amplitude.current);
  }

  Future<bool> startRecording() {
    final task = _startRecording(++_recordEpoch);
    _starting = task;
    return task;
  }

  Future<bool> _startRecording(int epoch) async {
    if (_disposed) return false;
    final recorder = _recorder ??= AudioRecorder();
    _permissionPending = true;
    bool allowed;
    try {
      allowed = await recorder.hasPermission();
    } finally {
      _permissionPending = false;
    }
    if (!allowed) return false;
    if (_disposed || epoch != _recordEpoch) return false;
    final wav = voiceWav || kIsWeb;
    final path = kIsWeb
        ? ''
        : '${(await getTemporaryDirectory()).path}/ecare-vocal-${DateTime.now().microsecondsSinceEpoch}.${wav ? 'wav' : 'm4a'}';
    if (_disposed || epoch != _recordEpoch) return false;
    _recordPath = path;
    await recorder.start(
      RecordConfig(
        encoder: wav ? AudioEncoder.wav : AudioEncoder.aacLc,
        numChannels: 1,
        sampleRate: voiceWav ? 16000 : 44100,
        bitRate: 64000,
      ),
      path: path,
    );
    if (_disposed || epoch != _recordEpoch) {
      final discarded = await recorder.stop();
      await deleteTemporaryRecording(discarded ?? path);
      return false;
    }
    _clock
      ..reset()
      ..start();
    return true;
  }

  Future<DoctorMessage?> stopRecording() async {
    _clock.stop();
    final duration = _clock.elapsed;
    final path = await _recorder?.stop();
    if (path == null) return null;
    try {
      final bytes = await _read(XFile(path));
      return DoctorMessage(
        text: 'Message vocal',
        kind: DoctorMessageKind.voice,
        bytes: bytes,
        mimeType: voiceWav || kIsWeb ? 'audio/wav' : 'audio/mp4',
        duration: duration,
      );
    } finally {
      await deleteTemporaryRecording(path);
      _recordPath = null;
    }
  }

  Future<void> cancelRecording() async {
    _recordEpoch++;
    _clock.stop();
    // Le plugin sérialise ses appels : ne pas bloquer la navigation derrière
    // une boîte de permission. Le démarrage vérifie l'époque à son retour.
    if (_permissionPending) return;
    final path = await _recorder?.stop() ?? _recordPath;
    _recordPath = null;
    if (path != null) await deleteTemporaryRecording(path);
  }

  VoicePlayback createPlayback() {
    late final VoicePlayback player;
    player = VoicePlayback(
      onDisposed: () => _players.remove(player),
      beforePlay: () async {
        for (final other in _players.toList()) {
          if (other != player) await other.pause();
        }
      },
    );
    _players.add(player);
    return player;
  }

  Future<void> pausePlayback() async {
    for (final player in _players.toList()) {
      await player.pause();
    }
  }

  Future<void> openDocument(DoctorMessage message) async {
    if (message.filePath == null) {
      throw const ChatMediaException(
        'L’ouverture des documents est disponible sur le téléphone.',
      );
    }
    final result = await OpenFilex.open(message.filePath!);
    if (result.type != ResultType.done) {
      throw const ChatMediaException(
        'Aucune application disponible pour ouvrir ce fichier.',
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _recordEpoch++;
    for (final player in _players.toList()) {
      await player.dispose();
    }
    try {
      await _starting;
    } catch (_) {}
    final recorder = _recorder;
    if (recorder != null) {
      if (await recorder.isRecording()) {
        final path = await recorder.stop();
        if (path != null) await deleteTemporaryRecording(path);
      }
      await recorder.dispose();
    }
  }
}

class VoicePlayback {
  final VoidCallback? onDisposed;
  final Future<void> Function()? beforePlay;
  VoicePlayback({this.onDisposed, this.beforePlay});
  bool _disposed = false;
  AudioPlayer? _player;
  final _positions = StreamController<Duration>.broadcast();
  final _states = StreamController<bool>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _loaded = false;
  int _epoch = 0;
  Stream<Duration> get positions => _positions.stream;
  Stream<bool> get states => _states.stream;

  Future<void> play(DoctorMessage message) async {
    if (_disposed) return;
    final epoch = ++_epoch;
    await beforePlay?.call();
    if (_disposed || epoch != _epoch) return;
    if (message.bytes == null) {
      throw const ChatMediaException('Ce vocal est indisponible.');
    }
    if (_player == null) {
      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.stop);
      if (_disposed || epoch != _epoch) return;
      _subscriptions.add(_player!.onPositionChanged.listen(_positions.add));
      _subscriptions.add(
        _player!.onPlayerStateChanged.listen(
          (state) => _states.add(state == PlayerState.playing),
        ),
      );
    }
    if (_loaded) {
      if (_player!.state == PlayerState.completed) {
        await _player!.seek(Duration.zero);
      }
      await _player!.resume();
      if (_disposed || epoch != _epoch) await _player?.pause();
    } else {
      await _player!.play(
        BytesSource(message.bytes!, mimeType: message.mimeType ?? 'audio/wav'),
      );
      _loaded = true;
      if (_disposed || epoch != _epoch) await _player?.pause();
    }
  }

  Future<void> pause() async {
    _epoch++;
    await _player?.pause();
  }

  Future<void> seek(Duration position) async {
    if (!_disposed) await _player?.seek(position);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _epoch++;
    onDisposed?.call();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player?.dispose();
    await _positions.close();
    await _states.close();
  }
}
