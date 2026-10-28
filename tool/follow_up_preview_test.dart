import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/utils/app_colors.dart';
import 'package:ecare_plus_mobile/views/measurement/follow_up_page.dart';
import 'package:ecare_plus_mobile/views/notification/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Example measurements belong to the preview only.
void main() {
  testWidgets('Render both follow-up charts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final font = FontLoader('Poppins');
      for (final weight in ['Regular', 'SemiBold', 'Bold']) {
        font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
      }
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final data = CareData();
    final now = DateTime.now();
    for (var i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month, now.day - 6 + i, 8 + i * 2);
      data.addReading([112.0, 105.0, 118.0, 98.0, 102.0, 96.0][i], date: date);
      data.addBloodPressure(
        [128.0, 124.0, 130.0, 122.0, 120.0, 125.0][i],
        [84.0, 82.0, 86.0, 80.0, 78.0, 81.0][i],
        date: date,
      );
    }
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ChangeNotifierProvider.value(
          value: data,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
              ),
              textTheme: ThemeData.light().textTheme.apply(
                fontFamily: 'Poppins',
              ),
            ),
            home: const FollowUpPage(),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('lib/data/Icon_bon a savoir.png'),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await render.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts').create(recursive: true);
        await File(
          'artifacts/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }

    await capture('suivi-glycemie-exemple');
    await tester.tap(find.text('Tension artérielle'));
    await tester.pumpAndSettle();
    await capture('suivi-tension-exemple');
    data.addNotification(
      CareNotification(
        title: 'Rappel de traitement',
        message: 'Retrouvez les horaires indiqués dans votre traitement.',
        date: now,
        category: NotificationCategory.medication,
      ),
    );
    Navigator.of(
      tester.element(find.byType(FollowUpPage)),
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationsPage()));
    await tester.pumpAndSettle();
    await capture('notifications-exemple');
    expect(tester.takeException(), isNull);
  });
}
