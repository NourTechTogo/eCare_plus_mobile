import 'dart:async';
import 'dart:convert';
import 'package:ecare_plus_mobile/models/doctor_message.dart';
import 'package:ecare_plus_mobile/services/chat_media_service.dart';
import 'package:ecare_plus_mobile/services/server_voice_service.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/messaging/server_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';

class Microphone extends ChatMediaService {
  bool allowed = true, cancelled = false, disposed = false;
  Completer<bool>? permission;
  Completer<void>? pauseGate;
  int stops = 0;
  final players = <TestPlayer>[];
  @override
  Future<bool> startRecording() async =>
      permission == null ? allowed : permission!.future;
  @override
  Future<DoctorMessage?> stopRecording() async {
    stops++;
    return DoctorMessage(
      text: 'Message vocal',
      kind: DoctorMessageKind.voice,
      duration: const Duration(seconds: 3),
      mimeType: 'audio/wav',
      bytes: Uint8List.fromList([82, 73, 70, 70]),
    );
  }

  @override
  Future<void> cancelRecording() async {
    cancelled = true;
  }

  @override
  VoicePlayback createPlayback() {
    final p = TestPlayer();
    players.add(p);
    return p;
  }

  @override
  Future<void> pausePlayback() async {
    await pauseGate?.future;
    for (final p in players) {
      await p.pause();
    }
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class TestPlayer extends VoicePlayback {
  DoctorMessage? played;
  Duration? seeked;
  bool paused = false;
  @override
  Future<void> play(DoctorMessage message) async {
    played = message;
    paused = false;
  }

  @override
  Future<void> pause() async {
    paused = true;
  }

  @override
  Future<void> seek(Duration position) async {
    seeked = position;
  }
}

void main() {
  for (final width in [604.0, 320.0]) {
    testWidgets(
      'Incoming voice is visible and physically playable at ${width.toInt()}x628',
      (tester) async {
        tester.view.physicalSize = Size(width, 628);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        var privateGets = 0;
        String? authorization;
        final session = await signedInSession(
          handler: (request) async {
            if (request.url.path.endsWith(
              '/pieces-jointes/incoming-voice/contenu',
            )) {
              privateGets++;
              authorization = request.headers['authorization'];
              return jsonResponse('RIFF', 200);
            }
            if (request.method == 'POST') return jsonResponse('{}', 200);
            return jsonResponse(
              jsonEncode({
                'content': [
                  for (var i = 0; i < 12; i++)
                    {
                      'id': 'm-$i',
                      'expediteurId': i.isEven ? 'doctor-a' : 'patient-a',
                      'contenu':
                          'Message du suivi pour remplir la conversation et vérifier le défilement $i.',
                      'envoyeLe':
                          '2026-10-26T10:${i.toString().padLeft(2, '0')}:00Z',
                    },
                  {
                    'id': 'voice-message',
                    'expediteurId': 'doctor-a',
                    'contenu': 'Pièce jointe',
                    'envoyeLe': '2026-10-26T10:15:00Z',
                    'piecesJointes': [
                      {
                        'id': 'incoming-voice',
                        'typeMime': 'audio/wav',
                        'dureeMs': 3200,
                        'nomOriginal': 'message-vocal.wav',
                      },
                    ],
                  },
                ],
                'totalPages': 1,
              }),
              200,
            );
          },
        );
        final media = Microphone();
        await tester.pumpWidget(
          ChangeNotifierProvider<ApiSession>(
            create: (_) => session,
            child: MaterialApp(
              home: ServerChatPage(
                conversationId: 'conversation-real',
                doctorName: 'Docteur',
                mediaService: media,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final play = find.byTooltip('Écouter le vocal');
        expect(play, findsOneWidget);
        expect(play.hitTestable(), findsOneWidget);
        final playBounds = tester.getRect(play);
        final listBounds = tester.getRect(find.byType(ListView));
        expect(playBounds.top, greaterThanOrEqualTo(listBounds.top));
        expect(playBounds.bottom, lessThanOrEqualTo(listBounds.bottom));
        expect(find.text('Pièce jointe'), findsNothing);
        expect(find.text('0:03'), findsOneWidget);
        expect(privateGets, 0);
        await tester.tap(play);
        await tester.pumpAndSettle();
        expect(privateGets, 1);
        expect(authorization, 'Bearer test-token');
        expect(
          media.players.single.played?.bytes,
          orderedEquals([82, 73, 70, 70]),
        );
        expect(media.players.single.played?.mimeType, 'audio/wav');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'Device permission cancellation returns promptly and prevents late native start',
    (tester) async {
      const channel = MethodChannel('com.llfbandit.record/messages');
      final permission = Completer<bool>();
      var asked = false, starts = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'hasPermission') {
          asked = true;
          return permission.future;
        }
        if (call.method == 'start') starts++;
        if (call.method == 'isRecording') return false;
        return null;
      });
      final media = ChatMediaService(voiceWav: true);
      final pending = media.startRecording();
      await tester.pump();
      expect(asked, true);
      await media.cancelRecording();
      permission.complete(true);
      await tester.pump();
      expect(await pending, false);
      expect(starts, 0);
      await media.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );

  testWidgets('Empty connected composer offers actual voice recording', (
    tester,
  ) async {
    final session = await signedInSession();
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: const MaterialApp(
          home: ServerChatPage(conversationId: 'c', doctorName: 'Docteur'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Message vocal'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Bonjour');
    await tester.pump();
    expect(find.byTooltip('Envoyer'), findsOneWidget);
    expect(find.byTooltip('Message vocal'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Permission dialog remains usable and actual background stops to draft',
    (tester) async {
      final session = await signedInSession();
      final media = Microphone()..permission = Completer<bool>();
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: MaterialApp(
            home: ServerChatPage(
              conversationId: 'c',
              doctorName: 'Docteur',
              mediaService: media,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Message vocal'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      media.permission!.complete(true);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Arrêter le vocal'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(media.stops, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Arrêter le vocal'), findsNothing);
      expect(find.byTooltip('Écouter le vocal'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Stop creates a playable draft and only explicit send uploads it',
    (tester) async {
      var uploads = 0, sends = 0;
      String? uploadedBody, authorization;
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/pieces-jointes')) {
            uploads++;
            authorization = r.headers['authorization'];
            uploadedBody = r.body;
            return jsonResponse('{"id":"piece-voice"}', 201);
          }
          if (r.method == 'POST' && r.url.path.endsWith('/messages')) {
            sends++;
            final body = jsonDecode(r.body) as Map;
            expect(body['contenu'], '');
            expect(body['piecesJointes'], ['piece-voice']);
            return jsonResponse('{}', 201);
          }
          return jsonResponse('{"content":[],"totalPages":1}', 200);
        },
      );
      final media = Microphone();
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>.value(
          value: session,
          child: MaterialApp(
            home: ServerChatPage(
              conversationId: 'c',
              doctorName: 'Docteur',
              mediaService: media,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Message vocal'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('0:02'), findsOneWidget);
      await tester.tap(find.byTooltip('Arrêter le vocal'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Écouter le vocal'), findsOneWidget);
      expect(uploads, 0);
      await tester.tap(find.byTooltip('Écouter le vocal'));
      await tester.pumpAndSettle();
      expect(
        media.players.single.played?.bytes,
        orderedEquals([82, 73, 70, 70]),
      );
      await tester.drag(find.byType(Slider), const Offset(30, 0));
      await tester.pump();
      expect(media.players.single.seeked, greaterThan(Duration.zero));
      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();
      expect(uploads, 1);
      expect(sends, 1);
      expect(authorization, 'Bearer test-token');
      expect(uploadedBody!.toLowerCase(), contains('content-type: audio/wav'));
      expect(find.byTooltip('Message vocal'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );

  testWidgets('Maximum recording stops to draft without transmitting', (
    tester,
  ) async {
    final session = await signedInSession();
    final media = Microphone();
    final voice = ServerVoiceService(
      api: session,
      conversationId: 'c',
      media: media,
    );
    await voice.start();
    await tester.pump(const Duration(seconds: 120));
    await tester.pump();
    expect(media.stops, 1);
    expect(voice.recording, false);
    expect(voice.draft, isNotNull);
    expect(voice.sending, false);
    voice.dispose();
    session.dispose();
  });

  testWidgets(
    'Active-call conversation blocks microphone and keeps return action',
    (tester) async {
      final session = await signedInSession();
      final media = Microphone();
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: MaterialApp(
            home: ServerChatPage(
              conversationId: 'c',
              doctorName: 'Docteur',
              returnToCall: true,
              mediaService: media,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Message vocal'));
      await tester.pump();
      expect(
        find.text('Terminez l’appel avant d’enregistrer un vocal.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Arrêter le vocal'), findsNothing);
      expect(find.byTooltip('Revenir à l’appel'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('Discarded draft is never transmitted', () async {
    var transfers = 0;
    final session = await signedInSession(
      handler: (_) async {
        transfers++;
        return jsonResponse('{}', 200);
      },
    );
    final voice = ServerVoiceService(
      api: session,
      conversationId: 'c',
      media: Microphone(),
    );
    addTearDown(voice.dispose);
    await voice.start();
    await voice.stop();
    await voice.cancel();
    expect(voice.draft, isNull);
    expect(await voice.send(), false);
    expect(transfers, 0);
  });

  test('WAV cannot be uploaded as a medical document', () async {
    var transfers = 0;
    final session = await signedInSession(
      handler: (_) async {
        transfers++;
        return jsonResponse('{}', 201);
      },
    );
    await expectLater(
      session.upload(
        '/mobile/me/documents',
        bytes: Uint8List.fromList([1]),
        fileName: 'secret.wav',
        fields: {},
      ),
      throwsA(isA<ApiException>()),
    );
    expect(transfers, 0);
  });

  test('Permission denied leaves no recording or draft', () async {
    final session = await signedInSession();
    final media = Microphone()..allowed = false;
    final voice = ServerVoiceService(
      api: session,
      conversationId: 'c',
      media: media,
    );
    addTearDown(voice.dispose);
    await voice.start();
    expect(voice.active, false);
    expect(voice.draft, isNull);
    expect(voice.error, contains('microphone'));
  });

  for (final action in ['cancel', 'suspend', 'logout', 'dispose']) {
    test('Pending permission cannot start recording after $action', () async {
      final session = await signedInSession();
      final media = Microphone()..permission = Completer<bool>();
      final voice = ServerVoiceService(
        api: session,
        conversationId: 'c',
        media: media,
      );
      final pending = voice.start();
      await Future<void>.delayed(Duration.zero);
      switch (action) {
        case 'cancel':
          await voice.cancel();
        case 'suspend':
          await voice.suspend();
        case 'logout':
          session.clear();
        case 'dispose':
          voice.dispose();
      }
      media.permission!.complete(true);
      await pending;
      expect(voice.recording, false);
      expect(voice.draft, isNull);
      expect(media.cancelled, true);
      if (action != 'dispose') voice.dispose();
    });
  }

  for (final failure in ['upload', 'message']) {
    test('Failed $failure keeps draft and reuses retry keys', () async {
      final uploadKeys = <String>[], messageKeys = <String>[];
      var fail = true;
      final session = await signedInSession(
        handler: (r) async {
          if (r.url.path.endsWith('/pieces-jointes')) {
            uploadKeys.add(
              RegExp(
                r'name="sourceRef"\r\n\r\n([^\r]+)',
              ).firstMatch(r.body)!.group(1)!,
            );
            if (fail && failure == 'upload') {
              fail = false;
              return jsonResponse('{"detail":"Hors ligne"}', 503);
            }
            return jsonResponse('{"id":"piece-v"}', 201);
          }
          messageKeys.add((jsonDecode(r.body) as Map)['sourceRef'] as String);
          if (fail && failure == 'message') {
            fail = false;
            return jsonResponse('{"detail":"Hors ligne"}', 503);
          }
          return jsonResponse('{}', 201);
        },
      );
      final voice = ServerVoiceService(
        api: session,
        conversationId: 'c',
        media: Microphone(),
      );
      addTearDown(voice.dispose);
      await voice.start();
      await voice.stop();
      final draft = voice.draft;
      expect(await voice.send(), false);
      expect(voice.draft, same(draft));
      expect(await voice.send(), true);
      expect(voice.draft, isNull);
      expect(uploadKeys.toSet(), hasLength(1));
      expect(messageKeys.toSet(), hasLength(1));
      expect(uploadKeys, hasLength(failure == 'upload' ? 2 : 1));
      expect(messageKeys, hasLength(failure == 'message' ? 2 : 1));
    });
  }

  test(
    'Private playback ignores stale download when another player starts',
    () async {
      final response = Completer<Uint8List>();
      final session = await signedInSession(
        handler: (r) async {
          expect(r.headers['authorization'], 'Bearer test-token');
          expect(
            r.url.path,
            endsWith('/conversations/c/pieces-jointes/secret/contenu'),
          );
          return jsonResponse(utf8.decode(await response.future), 200);
        },
      );
      final media = Microphone();
      final voice = ServerVoiceService(
        api: session,
        conversationId: 'c',
        media: media,
      );
      addTearDown(voice.dispose);
      final first = media.createPlayback() as TestPlayer;
      final second = media.createPlayback() as TestPlayer;
      final pending = voice.play(first, pieceId: 'secret');
      await Future<void>.delayed(Duration.zero);
      final local = DoctorMessage(
        text: 'Vocal',
        bytes: Uint8List.fromList([1]),
      );
      await voice.play(second, local: local);
      response.complete(Uint8List.fromList([82, 73, 70, 70]));
      await pending;
      expect(first.played, isNull);
      expect(second.played, same(local));
      await voice.suspend();
      expect(second.paused, true);
    },
  );

  for (final action in ['replace session', 'dispose']) {
    test('Send paused before upload cannot transmit after $action', () async {
      var transfers = 0;
      final session = await signedInSession(
        handler: (r) async {
          transfers++;
          return jsonResponse(
            r.url.path.endsWith('/pieces-jointes') ? '{"id":"piece"}' : '{}',
            201,
          );
        },
      );
      final media = Microphone();
      final voice = ServerVoiceService(
        api: session,
        conversationId: 'c',
        media: media,
      );
      await voice.start();
      await voice.stop();
      media.pauseGate = Completer<void>();
      final pending = voice.send();
      await Future<void>.delayed(Duration.zero);
      if (action == 'replace session') {
        await session.login('autre@example.com', 'Password123!');
      } else {
        voice.dispose();
      }
      media.pauseGate!.complete();
      expect(await pending, false);
      expect(transfers, 0);
      if (action != 'dispose') voice.dispose();
    });
  }
}
