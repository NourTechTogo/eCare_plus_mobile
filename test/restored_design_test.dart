import 'dart:convert';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/dashbord/doctors_page.dart';
import 'package:ecare_plus_mobile/views/messaging/doctor_call_page.dart';
import 'package:ecare_plus_mobile/views/messaging/server_calls_page.dart';
import 'package:ecare_plus_mobile/views/messaging/server_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';

void main() {
  testWidgets('Unchanged server draft retries with the same message source', (
    tester,
  ) async {
    final sent = <Map<String, dynamic>>[];
    final session = await signedInSession(
      handler: (request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/messages')) {
          sent.add(jsonDecode(request.body) as Map<String, dynamic>);
          return jsonResponse('{"detail":"Réponse perdue"}', 503);
        }
        return jsonResponse('{"content":[]}', 200);
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: const MaterialApp(
          home: ServerChatPage(conversationId: 'c', doctorName: 'Médecin'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Essai');
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.pumpAndSettle();
    }
    expect(sent, hasLength(2));
    expect(sent.first['sourceRef'], isNotNull);
    expect(sent.last['sourceRef'], sent.first['sourceRef']);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final type in ['AUDIO', 'VIDEO']) {
    testWidgets(
      'Connected $type screen stays usable on small portrait phone with large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final session = await signedInSession(
          handler: (_) async => jsonResponse(
            '{"content":[{"id":"call","type":"$type","statut":"ACCEPTE","initiateurId":"doctor","destinataireId":"patient-a"}]}',
            200,
          ),
        );
        await tester.pumpWidget(
          ChangeNotifierProvider<ApiSession>(
            create: (_) => session,
            child: const MaterialApp(
              home: ServerCallsPage(
                conversationId: 'c',
                name: 'Médecin du suivi',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Terminer l’appel'));
        expect(
          find.byTooltip('Terminer l’appel').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('Original directory search filters assigned server doctors', (
    tester,
  ) async {
    final session = await signedInSession(
      handler: (_) async => jsonResponse(
        '[{"id":"d1","nom":"Alpha","prenoms":"Anne","specialite":"Cardiologie"},'
        '{"id":"d2","nom":"Beta","prenoms":"Ben","specialite":"Diabétologie"}]',
        200,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: const MaterialApp(home: DoctorsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Filtres'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un médecin'),
      'Alpha',
    );
    await tester.pumpAndSettle();
    expect(find.text('Anne Alpha'), findsOneWidget);
    expect(find.text('Ben Beta'), findsNothing);
    expect(find.text('Message'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Reference conversation keeps composer and call actions', (
    tester,
  ) async {
    final session = await signedInSession();
    await tester.pumpWidget(
      ChangeNotifierProvider<ApiSession>(
        create: (_) => session,
        child: const MaterialApp(
          home: ServerChatPage(conversationId: 'c', doctorName: 'Médecin'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
      const Color(0xFFF8FAFC),
    );
    expect(find.byTooltip('Appeler'), findsOneWidget);
    expect(find.byTooltip('Choisir un emoji'), findsOneWidget);
    expect(find.byTooltip('Joindre un PDF ou une image'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Calls use original screen and keep real provider failure visible',
    (tester) async {
      final session = await signedInSession(
        handler: (r) async => r.method == 'POST'
            ? jsonResponse('{"detail":"Service non configuré"}', 503)
            : jsonResponse('{"content":[]}', 200),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ApiSession>(
          create: (_) => session,
          child: const MaterialApp(
            home: ServerCallsPage(conversationId: 'c', name: 'Médecin'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DoctorCallPage), findsOneWidget);
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Appel audio'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Appel audio'));
      await tester.pumpAndSettle();
      expect(find.text('Service non configuré'), findsOneWidget);
      expect(find.textContaining('Aperçu'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
