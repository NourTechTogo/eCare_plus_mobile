import 'package:ecare_plus_mobile/data/doctor_catalog.dart';
import 'package:ecare_plus_mobile/views/messaging/doctor_call_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/views/messaging/doctor_chat_page.dart';

void main() {
  testWidgets(
    'Video messages open the conversation and ending returns to the previous page',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareData(),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => DoctorCallPage(
                        doctor: doctorCatalog.first,
                        video: true,
                      ),
                    ),
                  ),
                  child: const Text('Ouvrir la vidéo'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir la vidéo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Messages'));
      await tester.pumpAndSettle();
      expect(find.byType(DoctorChatPage), findsOneWidget);
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Terminer l’appel'));
      await tester.pumpAndSettle();
      expect(find.text('Ouvrir la vidéo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Video uses a bounded frame with all five controls visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: DoctorCallPage(doctor: doctorCatalog.first, video: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const Key('doctor-video-background'))),
      isNot(const Rect.fromLTWH(0, 0, 360, 780)),
    );
    for (final tooltip in [
      'Micro',
      'Haut-parleur',
      'Caméra',
      'Messages',
      'Terminer l’appel',
    ]) {
      expect(find.byTooltip(tooltip).hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('Video preview offers camera switching and camera disabling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: DoctorCallPage(doctor: doctorCatalog.first, video: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Votre caméra'), findsOneWidget);
    await tester.tap(find.byTooltip('Changer de caméra'));
    await tester.pump();
    expect(find.text('Arrière'), findsOneWidget);
    await tester.tap(find.byTooltip('Caméra'));
    await tester.pumpAndSettle();
    expect(find.text('Caméra désactivée'), findsOneWidget);
    expect(find.byTooltip('Changer de caméra').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Video preview stays usable on a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: DoctorCallPage(doctor: doctorCatalog.first, video: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Terminer l’appel'));
    expect(find.byTooltip('Terminer l’appel').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Audio call preview offers a transition to video', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: DoctorCallPage(doctor: doctorCatalog.first, video: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Aperçu de l’interface · Aucun appel lancé'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Micro'));
    await tester.pump();
    expect(find.byIcon(Icons.mic_off_outlined), findsOneWidget);
    await tester.tap(find.byTooltip('Haut-parleur'));
    await tester.pump();
    await tester.tap(find.byTooltip('Passer en vidéo'));
    await tester.pumpAndSettle();
    expect(find.text('Appel vidéo'), findsOneWidget);
    expect(find.text('Votre caméra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Audio controls remain reachable with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: DoctorCallPage(doctor: doctorCatalog.first, video: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Terminer l’appel'));
    expect(find.byTooltip('Terminer l’appel').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
