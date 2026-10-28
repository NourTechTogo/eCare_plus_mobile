import 'package:ecare_plus_mobile/data/doctor_catalog.dart';
import 'package:ecare_plus_mobile/views/messaging/doctor_contact_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecare_plus_mobile/services/doctor_contact_service.dart';
import 'package:ecare_plus_mobile/widgets/doctor_social_links.dart';
import 'package:provider/provider.dart';
import 'package:ecare_plus_mobile/models/care_data.dart';

void main() {
  test('Les liens absents ou invalides ne sont pas ouverts', () async {
    var calls = 0;
    final service = DoctorContactService(
      launcher: (_) async {
        calls++;
        return true;
      },
    );
    for (final value in [
      null,
      '',
      'un lien',
      'javascript:alert(1)',
      'https://',
    ]) {
      expect(await service.open(value), isFalse);
    }
    expect(calls, 0);
  });

  testWidgets('Un contact configuré ouvre son lien et signale un échec', (
    tester,
  ) async {
    Uri? opened;
    final service = DoctorContactService(
      launcher: (uri) async {
        opened = uri;
        return false;
      },
    );
    const doctor = CareDoctor(
      'Dr Test',
      'Généraliste',
      Icons.person,
      Colors.blue,
      '',
      whatsappUrl: 'https://wa.me/33123456789',
      isDemo: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoctorSocialLinks(doctor: doctor, contactService: service),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Ouvrir WhatsApp'));
    await tester.pumpAndSettle();
    expect(opened.toString(), doctor.whatsappUrl);
    expect(
      find.text('Impossible d’ouvrir WhatsApp. Réessayez plus tard.'),
      findsOneWidget,
    );
    final facebookButton = find.descendant(
      of: find.byTooltip('Facebook : contact non renseigné'),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(facebookButton).onPressed, isNull);
  });
  testWidgets('Le parcours et les contacts restent lisibles sur petit écran', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CareData(),
        child: MaterialApp(
          home: DoctorContactPage(doctor: doctorCatalog.first),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('TikTok'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Mon parcours'), 200);
    expect(find.text('Mon parcours'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ajouter à mon agenda'), 200);
    await tester.tap(find.text('Ajouter à mon agenda'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connectez-vous'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
