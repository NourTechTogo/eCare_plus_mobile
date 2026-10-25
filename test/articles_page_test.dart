import 'package:ecare_plus_mobile/views/dashbord/articles_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ArticlesPage()));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Search and categories combine and empty results can be cleared',
    (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'glycemie');
      await tester.pumpAndSettle();
      expect(find.text('Comprendre sa glycémie'), findsOneWidget);
      await tester.tap(find.text('Hypertension'));
      await tester.pumpAndSettle();
      expect(find.text('Aucun article trouvé'), findsOneWidget);
      await tester.tap(find.text('Réinitialiser la recherche'));
      await tester.pumpAndSettle();
      expect(find.text('À la une'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reading opens a labelled preview and saved articles survive reopening',
    (tester) async {
      await open(tester);
      await tester.ensureVisible(
        find.text('Mieux comprendre sa santé, un article à la fois'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Mieux comprendre sa santé, un article à la fois'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Article'), findsOneWidget);
      await tester.tap(find.byTooltip('Enregistrer cet article').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Retour'));
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await open(tester);
      await tester.tap(find.byTooltip('Mes favoris'));
      await tester.pumpAndSettle();
      expect(
        find.text('Mieux comprendre sa santé, un article à la fois'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Retirer des favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Votre bibliothèque commence ici'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Small screens and large text remain readable', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: const ArticlesPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prendre soin de soi'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('articles-scroll')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
