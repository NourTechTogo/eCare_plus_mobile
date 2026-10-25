import 'dart:async';
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
    await tester.tap(find.byTooltip('Actions de la notification'));
    await tester.pumpAndSettle();
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
      expect(find.byTooltip('Actualiser'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Left deletes after acknowledgement and undo restores the notification',
    (tester) async {
      final completion = Completer<void>();
      var deleted = false;
      final methods = <String>[];
      final session = await signedInSession(
        handler: (r) async {
          if (r.method == 'DELETE') {
            methods.add('DELETE');
            await completion.future;
            deleted = true;
            return jsonResponse('', 204);
          }
          if (r.url.path.endsWith('/restauration')) {
            methods.add('RESTORE');
            deleted = false;
            return jsonResponse('', 204);
          }
          return jsonResponse(
            deleted
                ? '{"content":[]}'
                : '{"content":[{"id":"n","titre":"Notification privée","message":"Votre suivi"}]}',
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
      await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Notification privée'), findsOneWidget);
      completion.complete();
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(find.text('Notification privée'), findsNothing);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Notification privée'), findsOneWidget);
      expect(methods, ['DELETE', 'RESTORE']);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Right archives and tapping marks read independently', (
    tester,
  ) async {
    var archived = false, read = false;
    final actions = <String>[];
    final session = await signedInSession(
      handler: (r) async {
        if (r.method == 'POST') {
          actions.add(r.url.path.split('/').last);
          if (r.url.path.endsWith('/lecture')) read = true;
          if (r.url.path.endsWith('/archivage')) archived = true;
          if (r.url.path.endsWith('/desarchivage')) archived = false;
          return jsonResponse('', 204);
        }
        final inArchive = r.url.queryParameters['archivees'] == 'true';
        return jsonResponse(
          inArchive != archived
              ? '{"content":[]}'
              : '{"content":[{"id":"n","titre":"Mon rappel","message":"Votre suivi","dateLecture":${read ? '"2026-10-25T10:00:00Z"' : 'null'}}]}',
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
    await tester.tap(find.text('Mon rappel'));
    await tester.pumpAndSettle();
    expect(actions, ['lecture']);
    expect(find.text('Lu'), findsOneWidget);
    expect(find.text('Fermer'), findsNothing);
    await tester.drag(find.byType(Dismissible), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(actions, ['lecture', 'archivage']);
    expect(find.text('Mon rappel'), findsNothing);
    await tester.tap(find.text('Archivées'));
    await tester.pumpAndSettle();
    expect(find.text('Mon rappel'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Failed acknowledgement leaves notification unread without opening detail',
    (tester) async {
      final session = await signedInSession(
        handler: (r) async {
          if (r.method == 'POST') {
            return jsonResponse('{"detail":"Lecture refusée"}', 503);
          }
          if (r.url.path.endsWith('/alertes')) {
            return jsonResponse('{"content":[]}', 200);
          }
          return jsonResponse(
            '{"content":[{"id":"n","titre":"À lire","message":"Contenu complet"}]}',
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
      await tester.tap(find.text('À lire'));
      await tester.pumpAndSettle();
      expect(find.text('Lecture refusée'), findsOneWidget);
      expect(find.text('Fermer'), findsNothing);
      expect(find.text('Lu'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Compact inbox supports 320px, large text and search keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final session = await signedInSession(
      handler: (r) async => jsonResponse(
        r.url.path.endsWith('/alertes')
            ? '{"content":[]}'
            : '{"content":[{"id":"n","titre":"Un rappel avec un titre très long à consulter","message":"Le texte complet reste accessible dans le détail."}]}',
        200,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: MaterialApp(
          builder: (c, w) => MediaQuery(
            data: MediaQuery.of(
              c,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: w!,
          ),
          home: const NotificationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'rappel');
    await tester.pumpAndSettle();
    expect(find.byType(Dismissible), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
