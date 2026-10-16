import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecare_plus_mobile/views/legal/privacy_policy_page.dart';
import 'package:ecare_plus_mobile/views/legal/terms_of_use_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Legal documents remain readable from start to end on phones', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.runAsync(() async {
      final fonts = FontLoader('Poppins');
      for (final weight in ['Regular', 'SemiBold', 'Bold']) {
        fonts.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
      }
      await fonts.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await render.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File('artifacts/legal-$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }

    for (final narrow in [false, true]) {
      tester.view.physicalSize = narrow
          ? const Size(320, 740)
          : const Size(390, 844);
      tester.platformDispatcher.textScaleFactorTestValue = narrow ? 1.5 : 1;
      for (final privacy in [true, false]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: 'Poppins'),
              home: privacy
                  ? const PrivacyPolicyPage()
                  : const TermsOfUsePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final name =
            '${privacy ? 'privacy' : 'terms'}-${narrow ? 'small' : 'phone'}';
        await capture('$name-start');
        await tester.ensureVisible(
          find.text(privacy ? 'Données utilisées' : 'Objet de l’application'),
        );
        await tester.pumpAndSettle();
        await capture('$name-body');
        await tester.ensureVisible(
          find.text(
            privacy
                ? 'Éditeur, évolution et références de la politique'
                : 'Identification de l’éditeur et version du document',
          ),
        );
        await tester.pumpAndSettle();
        await capture('$name-end');
        expect(tester.takeException(), isNull);
      }
    }
  });
}
