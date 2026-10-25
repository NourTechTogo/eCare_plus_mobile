import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/messaging/server_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';

void main() {
  for (final scale in [1.0, 1.3, 1.5]) {
    testWidgets(
      'Connected text conversation fits keyboard and text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final session = await signedInSession();
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
              home: const ServerChatPage(
                conversationId: 'conversation-uuid',
                doctorName: 'Docteur affecté',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'Un message suffisamment long pour occuper plusieurs lignes et vérifier le clavier.',
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Envoyer').hitTestable(), findsOneWidget);
        expect(
          find.textContaining('ne traite pas les urgences'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'Incoming messages load from server, poll and mark actual UUID conversation read',
    (tester) async {
      var loads = 0, reads = 0;
      final session = await signedInSession(
        handler: (r) async {
          expect(r.url.path, contains('/conversations/conversation-uuid/'));
          if (r.method == 'POST') {
            reads++;
            return jsonResponse('', 204);
          }
          loads++;
          return jsonResponse(
            '{"content":[{"id":"m-uuid","expediteurId":"doctor-uuid","contenu":"Message reçu du professionnel","envoyeLe":"2026-10-24T10:00:00Z","luLe":null}],"totalPages":1}',
            200,
          );
        },
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: const MaterialApp(
            home: ServerChatPage(
              conversationId: 'conversation-uuid',
              doctorName: 'Docteur',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Message reçu du professionnel'), findsOneWidget);
      expect(reads, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(reads, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
      expect(loads, 2);
    },
  );
  testWidgets(
    'Connected chat keeps original controls without fabricated replies',
    (tester) async {
      final session = await signedInSession();
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: const MaterialApp(
            home: ServerChatPage(
              conversationId: 'uuid',
              doctorName: 'Référent',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Appeler', 'Prendre une photo']) {
        expect(find.byTooltip(label), findsOneWidget);
      }
      expect(find.text('Exemple de message'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
