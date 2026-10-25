import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/notification/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';

void main() {
  testWidgets('Server notification marked read only after acknowledgement', (
    tester,
  ) async {
    var read = false;
    var loads = 0;
    final session = await signedInSession(
      handler: (r) async {
        if (r.method == 'POST') {
          expect(r.url.path, endsWith('/notifications/n-uuid/lecture'));
          read = true;
          return jsonResponse('', 204);
        }
        if (r.url.path.endsWith('/alertes')) {
          return jsonResponse('{"content":[],"totalPages":1}', 200);
        }
        loads++;
        return jsonResponse(
          '{"content":[{"id":"n-uuid","titre":"Résultat","message":"Dossier mis à jour","dateEnvoi":"2026-10-24T10:00:00Z","dateLecture":${read ? '"2026-10-24T10:01:00Z"' : 'null'}}],"totalPages":1}',
          200,
        );
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: const MaterialApp(home: NotificationsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Résultat'), findsOneWidget);
    await tester.ensureVisible(find.text('Marquer lu'));
    await tester.tap(find.text('Marquer lu'));
    await tester.pumpAndSettle();
    expect(read, isTrue);
    expect(find.text('Lu'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(loads, greaterThanOrEqualTo(3));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Network errors display retry instead of local invented notifications',
    (tester) async {
      final session = await signedInSession(
        handler: (r) async =>
            jsonResponse('{"detail":"Service indisponible"}', 503),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Service indisponible'), findsOneWidget);
      expect(find.text('Actualiser'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
