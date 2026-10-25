import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/messaging/live_call_room.dart';
import 'package:ecare_plus_mobile/services/call_media_room.dart';
import 'support/api_fixture.dart';

class FakeMediaRoom extends CallMediaRoom {
  lk.ConnectionState state = lk.ConnectionState.disconnected;
  @override
  lk.ConnectionState get connectionState => state;
  @override
  Future<void> connect(String url, String token) async {
    state = lk.ConnectionState.connected;
    notifyListeners();
  }

  void loseConnection() {
    state = lk.ConnectionState.disconnected;
    notifyListeners();
  }

  @override
  int get remoteCount => 0;
  @override
  List<lk.VideoTrack> get videos => [];
  @override
  bool microphoneEnabled = false;
  @override
  bool cameraEnabled = false;
  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    microphoneEnabled = enabled;
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    cameraEnabled = enabled;
  }

  bool closed = false;
  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    state = lk.ConnectionState.disconnected;
    dispose();
  }
}

void main() {
  testWidgets('Video join publishes camera after explicit user action', (
    tester,
  ) async {
    final api = await signedInSession(
      handler: (_) async =>
          jsonResponse('{"url":"wss://test.invalid","jeton":"grant"}', 200),
    );
    final room = FakeMediaRoom();
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => api,
        child: MaterialApp(
          home: Scaffold(
            body: LiveCallRoom(
              callId: 'video',
              type: 'VIDEO',
              roomFactory: () => room,
            ),
          ),
        ),
      ),
    );
    expect(room.cameraEnabled, isFalse);
    await tester.tap(find.textContaining('Rejoindre avec le'));
    await tester.pumpAndSettle();
    expect(room.microphoneEnabled, isTrue);
    expect(room.cameraEnabled, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'terminal media disconnection can reconnect with a fresh grant and room',
    (tester) async {
      var grants = 0;
      final rooms = <FakeMediaRoom>[];
      final api = await signedInSession(
        handler: (r) async {
          grants++;
          return jsonResponse(
            '{"url":"wss://test.invalid","jeton":"test-grant","expireLe":"2099-01-01T00:00:00Z"}',
            200,
          );
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => api,
          child: MaterialApp(
            home: Scaffold(
              body: LiveCallRoom(
                callId: 'call',
                type: 'AUDIO',
                roomFactory: () {
                  final room = FakeMediaRoom();
                  rooms.add(room);
                  return room;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Rejoindre avec le microphone'));
      await tester.pumpAndSettle();
      expect(grants, 1);
      expect(find.textContaining('Média connecté'), findsOneWidget);
      rooms.first.loseConnection();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rejoindre avec le microphone'));
      await tester.pumpAndSettle();
      expect(grants, 2);
      expect(rooms.length, 2);
      expect(find.textContaining('Média connecté'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
