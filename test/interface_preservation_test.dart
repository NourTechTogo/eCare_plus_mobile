import 'package:ecare_plus_mobile/models/care_data.dart';
import 'package:ecare_plus_mobile/services/api_session.dart';
import 'package:ecare_plus_mobile/views/dashbord/home_page.dart';
import 'package:ecare_plus_mobile/views/profile/profile_page.dart';
import 'package:ecare_plus_mobile/views/notification/notifications_page.dart';
import 'package:ecare_plus_mobile/views/auth/forgot_password_page.dart';
import 'package:ecare_plus_mobile/widgets/auth_layout.dart';
import 'package:ecare_plus_mobile/widgets/patient_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/api_fixture.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget page) async {
    final session = await signedInSession(
      handler: (r) async {
        if (r.url.path.endsWith('/mobile/me')) {
          return jsonResponse(
            '{"id":"patient-a","nom":"Dupont","prenoms":"Gloria","telephone":"+22890123456","sexe":"FEMININ","pathologie":"diabete_hypertension","consentementAccepte":true}',
            200,
          );
        }
        if (r.url.path.endsWith('/professionnels')) {
          return jsonResponse(
            '[{"id":"doctor-a","nom":"Référent","prenoms":"Médecin","specialite":"Médecine générale"}]',
            200,
          );
        }
        return jsonResponse('{"content":[],"totalPages":1}', 200);
      },
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiSession>(
            lazy: false,
            create: (_) => session,
          ),
          ChangeNotifierProvider<CareData>(create: (_) => CareData()),
        ],
        child: MaterialApp(home: Scaffold(body: page)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Home retains original horizontal assigned-doctor cards', (
    tester,
  ) async {
    await mount(tester, const HomePage());
    expect(find.byKey(const PageStorageKey('doctor-scroll')), findsOneWidget);
    expect(find.text('Médecin Référent'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Profile retains large avatar and two pathology selections', (
    tester,
  ) async {
    await mount(tester, const ProfilePage());
    expect(tester.widget<PatientAvatar>(find.byType(PatientAvatar)).radius, 58);
    expect(find.text('Pathologies suivies'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Diabète'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Hypertension'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Notifications retain search and category filters', (
    tester,
  ) async {
    await mount(tester, const NotificationsPage());
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'Rechercher une notification'),
      findsOneWidget,
    );
    expect(find.text('Toutes'), findsOneWidget);
    await tester.tap(find.byTooltip('Filtrer par catégorie'));
    await tester.pumpAndSettle();
    expect(find.text('Alertes'), findsWidgets);
    await tester.tap(find.text('Alertes').last);
    await tester.pumpAndSettle();
    expect(find.text('Aucune notification'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Password reset retains original authentication layout', (
    tester,
  ) async {
    await mount(tester, const ForgotPasswordPage());
    expect(find.byType(AuthLayout), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
