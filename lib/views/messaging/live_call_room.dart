import 'dart:async';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../services/api_session.dart';
import '../../services/server_calls.dart';
import '../../services/call_media_room.dart';

class LiveCallView {
  final CallMediaRoom? room;
  final bool connected, busy;
  final String? error;
  final VoidCallback join;
  final Future<void> Function(bool camera) toggle;
  const LiveCallView({
    required this.room,
    required this.connected,
    required this.busy,
    required this.error,
    required this.join,
    required this.toggle,
  });
}

class LiveCallRoom extends StatefulWidget {
  final String callId, type;
  final CallMediaRoom Function()? roomFactory;
  final Widget Function(LiveCallView state)? builder;
  const LiveCallRoom({
    super.key,
    required this.callId,
    required this.type,
    this.roomFactory,
    this.builder,
  });
  @override
  State<LiveCallRoom> createState() => _LiveCallRoomState();
}

class _LiveCallRoomState extends State<LiveCallRoom> {
  CallMediaRoom? room;
  String? error;
  bool busy = false, connected = false;
  bool established = false;
  late ApiSession api;
  late int generation;
  @override
  void initState() {
    super.initState();
    api = context.read<ApiSession>();
    generation = api.generation;
    api.addListener(sessionChanged);
  }

  void sessionChanged() {
    if (api.generation != generation) {
      unawaited(room?.close() ?? Future<void>.value());
    }
  }

  void changed() {
    final current = room;
    if (current == null) return;
    if (current.connectionState == ConnectionState.connected) {
      established = true;
    }
    if (established &&
        current.connectionState == ConnectionState.disconnected) {
      current.removeListener(changed);
      room = null;
      established = false;
      unawaited(Future<void>.microtask(current.close));
      if (mounted) {
        setState(() {
          connected = false;
          busy = false;
          error =
              'Média déconnecté. Vous pouvez rejoindre à nouveau si l’appel est toujours actif.';
        });
      }
      return;
    }
    if (mounted) {
      setState(
        () => connected = current.connectionState == ConnectionState.connected,
      );
    }
  }

  Future<void> join() async {
    if (busy || room != null) return;
    setState(() {
      busy = true;
      error = null;
    });
    final current = widget.roomFactory?.call() ?? LiveKitMediaRoom();
    room = current;
    current.addListener(changed);
    try {
      final grant = await ServerCalls(api).connection(widget.callId);
      if (!mounted || api.generation != generation) return;
      await current.connect(grant['url'] as String, grant['jeton'] as String);
      if (!mounted || api.generation != generation) {
        await current.close();
        return;
      }
      await current.setMicrophoneEnabled(true);
      if (!mounted || api.generation != generation) {
        await current.close();
        return;
      }
      if (widget.type == 'VIDEO') {
        try {
          await current.setCameraEnabled(true);
        } catch (_) {
          if (mounted) {
            setState(
              () => error =
                  'Caméra indisponible : l’appel continue en audio. Vous pouvez réessayer.',
            );
          }
        }
        if (!mounted || api.generation != generation) {
          await current.close();
          return;
        }
      }
      changed();
    } catch (e) {
      current.removeListener(changed);
      await current.close();
      room = null;
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> toggle(bool camera) async {
    try {
      final p = room;
      if (p == null) return;
      if (camera) {
        await p.setCameraEnabled(!p.cameraEnabled);
      } else {
        await p.setMicrophoneEnabled(!p.microphoneEnabled);
      }
      changed();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  void dispose() {
    api.removeListener(sessionChanged);
    final current = room;
    current?.removeListener(changed);
    if (current != null) {
      unawaited(current.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(
        LiveCallView(
          room: room,
          connected: connected,
          busy: busy,
          error: error,
          join: join,
          toggle: toggle,
        ),
      );
    }
    final videos = room?.videos ?? <VideoTrack>[];
    return Column(
      children: [
        if (error != null) Text(error!),
        for (final video in videos)
          SizedBox(height: 220, child: VideoTrackRenderer(video)),
        if (!connected)
          FilledButton(
            onPressed: busy ? null : join,
            child: Text(
              widget.type == 'VIDEO'
                  ? 'Rejoindre avec le micro et la caméra'
                  : 'Rejoindre avec le microphone',
            ),
          ),
        if (connected) ...[
          Text(
            room!.remoteCount == 0
                ? 'Média connecté, attente de l’interlocuteur.'
                : 'Média connecté avec votre interlocuteur.',
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => toggle(false),
                child: Text(
                  room!.microphoneEnabled
                      ? 'Couper le micro'
                      : 'Activer le micro',
                ),
              ),
              if (widget.type == 'VIDEO')
                TextButton(
                  onPressed: () => toggle(true),
                  child: Text(
                    room!.cameraEnabled
                        ? 'Couper la caméra'
                        : 'Activer la caméra',
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
