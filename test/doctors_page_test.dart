import 'dart:convert';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/dashbord/doctors_page.dart';
import 'package:ecare_plus_mobile/views/messaging/server_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Assigned doctors only, server UUID opens chat at text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Map<String, dynamic>? opened;
        final session = await signedInSession(
          handler: (r) async {
            if (r.url.path.endsWith('/professionnels')) {
              return jsonResponse(
                '[{"id":"doctor-uuid","nom":"Médecin","prenoms":"Affecté","specialite":"Suivi"}]',
                200,
              );
            }
            if (r.method == 'POST' && r.url.path.endsWith('/conversations')) {
              opened = jsonDecode(r.body) as Map<String, dynamic>;
              return jsonResponse('{"id":"conversation-uuid"}', 201);
            }
            return jsonResponse('{"content":[],"totalPages":1}', 200);
          },
        );
        await tester.pumpWidget(
          ChangeNotifierProvider<ApiSession>(
            create: (_) => session,
            child: MaterialApp(
              builder: (c, w) => MediaQuery(
                data: MediaQuery.of(
                  c,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: w!,
              ),
              home: const DoctorsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Affecté Médecin'), findsOneWidget);
        expect(find.textContaining('Lawson'), findsNothing);
        await tester.ensureVisible(find.byTooltip('Écrire un message'));
        await tester.tap(find.byTooltip('Écrire un message'));
        await tester.pumpAndSettle();
        expect(opened, {'professionnelId': 'doctor-uuid'});
        expect(find.byType(ServerChatPage), findsOneWidget);
        expect(find.byIcon(Icons.videocam), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('No assigned doctor does not invent a directory', (tester) async {
    final session = await signedInSession(
      handler: (r) async => jsonResponse('[]', 200),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: const MaterialApp(home: DoctorsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun professionnel affecté'), findsOneWidget);
  });
  testWidgets(
    'Chat preserves draft after rejected send and never fabricates reply',
    (tester) async {
      var fail = true;
      final session = await signedInSession(
        handler: (r) async =>
            r.method == 'POST' && r.url.path.endsWith('/messages')
            ? jsonResponse('{"detail":"Envoi refusé"}', fail ? 503 : 201)
            : jsonResponse('{"content":[],"totalPages":1}', 200),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: const MaterialApp(
            home: ServerChatPage(
              conversationId: 'real-id',
              doctorName: 'Docteur',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Bonjour');
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
      expect(find.text('Envoi refusé'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Bonjour',
      );
      fail = false;
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.textContaining('Bonjour docteur'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
