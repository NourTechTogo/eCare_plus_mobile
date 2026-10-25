import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/messaging/server_calls_page.dart';
import 'package:ecare_plus_mobile/views/messaging/live_call_room.dart';
import 'support/api_fixture.dart';

void main() {
  testWidgets('ready audio screen has no hangup or inactive media controls', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = await signedInSession(handler: (r) async =>
      jsonResponse('{"content":[],"totalPages":1}', 200));
    await tester.pumpWidget(ChangeNotifierProvider<ApiSession>(
      create: (_) => api,
      child: MaterialApp(
        builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(
          textScaler: const TextScaler.linear(1.5)), child: w!),
        home: const ServerCallsPage(conversationId: 'c', name: 'Médecin fictif'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Prêt à appeler'), findsOneWidget);
    expect(find.byTooltip('Terminer l’appel'), findsNothing);
    expect(find.byTooltip('Micro'), findsNothing);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Appel audio'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hangup stops local media before slow server acknowledgement', (
    tester,
  ) async {
    final completion = Completer<http.Response>();
    var finished = false;
    final api = await signedInSession(
      handler: (r) async {
        if (r.method == 'POST') {
          return completion.future;
        }
        return jsonResponse(
          '{"content":[{"id":"call","type":"AUDIO","statut":"${finished ? 'TERMINE' : 'ACCEPTE'}","initiateurId":"patient-a","destinataireId":"doctor-a","dateCreation":"2026-10-25T08:00:00Z"}]}',
          200,
        );
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => api,
        child: const MaterialApp(
          home: ServerCallsPage(conversationId: 'c', name: 'Médecin fictif'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LiveCallRoom), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Terminer l’appel'));
    await tester.tap(find.byTooltip('Terminer l’appel'));
    await tester.pump();
    final remaining = find.byType(LiveCallRoom).evaluate().length;
    finished = true;
    completion.complete(jsonResponse('{}', 200));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      remaining,
      0,
      reason:
          'Le média doit être coupé localement sans attendre la réponse réseau.',
    );
  });
}
