import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/messaging/server_calls_page.dart';
import 'package:ecare_plus_mobile/views/messaging/server_chat_page.dart';
import 'package:ecare_plus_mobile/views/messaging/live_call_room.dart';
import 'support/api_fixture.dart';

void main() {
  testWidgets('Messages preserves the call media owner until explicit hangup', (
    tester,
  ) async {
    var endRequests = 0;
    final api = await signedInSession(
      handler: (r) async {
        if (r.url.path.endsWith('/fin')) endRequests++;
        if (r.url.path.endsWith('/appels')) {
          return jsonResponse(
            '{"content":[{"id":"call-a","type":"AUDIO","statut":"ACCEPTE","initiateurId":"patient-a","destinataireId":"doctor-a"}]}',
            200,
          );
        }
        return jsonResponse('{"content":[],"totalPages":1}', 200);
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => api,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ServerCallsPage(
                      conversationId: 'c',
                      name: 'Médecin référent',
                    ),
                  ),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    final owner = tester.state(find.byType(LiveCallRoom));
    await tester.tap(find.byTooltip('Messages'));
    await tester.pumpAndSettle();
    expect(find.byType(ServerChatPage), findsOneWidget);
    expect(find.byType(LiveCallRoom, skipOffstage: false), findsOneWidget);
    expect(
      tester.state(find.byType(LiveCallRoom, skipOffstage: false)),
      same(owner),
    );
    expect(endRequests, 0);
    await tester.tap(find.text('Revenir à l’appel'));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(LiveCallRoom)), same(owner));
    expect(endRequests, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ServerChatPage), findsOneWidget);
    expect(
      tester.state(find.byType(LiveCallRoom, skipOffstage: false)),
      same(owner),
    );
    expect(endRequests, 0);
    await tester.tap(find.text('Revenir à l’appel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Terminer l’appel'));
    await tester.pumpAndSettle();
    expect(endRequests, 1);
    expect(find.byType(LiveCallRoom, skipOffstage: false), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
