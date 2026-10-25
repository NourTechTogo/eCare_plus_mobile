import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecare_plus_mobile/models/medical_document.dart';
import 'package:ecare_plus_mobile/services/document_library.dart';
import 'package:ecare_plus_mobile/services/document_storage_io.dart';
import 'package:ecare_plus_mobile/views/dashbord/documents_page.dart';
import 'package:file_selector/file_selector.dart';

class DeviceDocuments extends DocumentLibrary {
  DeviceDocuments(LocalDocumentStorage storage) : super(storage: storage);
  XFile? selectedFile;
  int opens = 0, downloads = 0;
  final imported = Completer<void>();
  @override
  Future<MedicalDocument> importFile(
    XFile file, {
    required String title,
    required DocumentCategory category,
    required Set<MedicalCondition> conditions,
    required DateTime date,
  }) async {
    final item = await super.importFile(
      file,
      title: title,
      category: category,
      conditions: conditions,
      date: date,
    );
    if (!imported.isCompleted) imported.complete();
    return item;
  }

  @override
  Future<XFile?> pickFile() async => selectedFile;
  @override
  Future<void> open(MedicalDocument item) async {
    opens++;
  }

  @override
  Future<bool> export(MedicalDocument item) async {
    downloads++;
    return true;
  }
}

void main() {
  late Directory directory;
  late DeviceDocuments library;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ecare-doc-ui-');
    library = DeviceDocuments(LocalDocumentStorage(directory: directory));
    await library.load();
    await library.setConditions(MedicalCondition.values.toSet());
    final file = File('${directory.path}/bilan.pdf');
    await file.writeAsBytes([37, 80, 68, 70]);
    library.selectedFile = XFile(file.path);
  });
  tearDown(() async {
    library.dispose();
    await directory.delete(recursive: true);
  });
  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: DocumentsPage(library: library)));
    await tester.pumpAndSettle();
  }

  Future<void> openFilters(WidgetTester tester) async {
    await tester.ensureVisible(find.byTooltip('Filtres'));
    await tester.tap(find.byTooltip('Filtres'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Full document title and file name remain accessible from information menu',
    (tester) async {
      const title =
          'Bilan de suivi annuel et compte rendu de consultation spécialisée';
      await tester.runAsync(
        () => library.importFile(
          library.selectedFile!,
          title: title,
          category: DocumentCategory.results,
          conditions: {},
          date: DateTime(2026, 10, 14),
        ),
      );
      await start(tester);
      await tester.ensureVisible(find.byTooltip('Actions pour $title'));
      await tester.tap(find.byTooltip('Actions pour $title'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Informations'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SelectableText, title), findsOneWidget);
      expect(find.widgetWithText(SelectableText, 'bilan.pdf'), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(library.opens, 0);
      expect(library.documents.single.title, title);
    },
  );

  testWidgets(
    'Search and filters combine, cancelled drafts do not apply, reset preserves search',
    (tester) async {
      await tester.runAsync(() async {
        for (final category in [
          DocumentCategory.prescription,
          DocumentCategory.results,
        ]) {
          await library.importFile(
            library.selectedFile!,
            title: category == DocumentCategory.prescription
                ? 'Ordonnance annuelle'
                : 'Bilan annuel',
            category: category,
            conditions: {MedicalCondition.diabetes},
            date: DateTime(2026, 10, 14),
          );
        }
      });
      await start(tester);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('2 documents trouvés'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'annuel');
      await tester.pumpAndSettle();
      await openFilters(tester);
      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<DocumentCategory>,
          'Type de document',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ordonnances').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fermer les filtres'));
      await tester.pumpAndSettle();
      expect(find.text('2 documents trouvés'), findsOneWidget);
      await openFilters(tester);
      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<DocumentCategory>,
          'Type de document',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ordonnances').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Afficher les résultats'));
      await tester.pumpAndSettle();
      expect(find.text('1 document trouvé'), findsOneWidget);
      expect(find.text('Type : Ordonnances'), findsOneWidget);
      expect(find.text('Bilan annuel'), findsNothing);
      await tester.ensureVisible(find.text('Réinitialiser les filtres'));
      await tester.tap(find.text('Réinitialiser les filtres'));
      await tester.pumpAndSettle();
      expect(find.text('2 documents trouvés'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'annuel',
      );
    },
  );

  testWidgets(
    'Import, search, pathology filters, open and download are functional',
    (tester) async {
      await start(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Ajouter un document'));
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du document'),
        'Bilan partagé',
      );
      await tester.tap(find.text('Diabète').last);
      await tester.tap(find.text('Hypertension').last);
      await tester.ensureVisible(find.text('Enregistrer le document'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Enregistrer le document'));
        await library.imported.future;
      });
      await tester.pumpAndSettle();
      expect(
        library.documents.single.conditions,
        MedicalCondition.values.toSet(),
      );
      await tester.ensureVisible(find.text('Bilan partagé'));
      await tester.tap(find.text('Bilan partagé'));
      await tester.pumpAndSettle();
      expect(library.opens, 1);
      await tester.tap(find.byTooltip('Actions pour Bilan partagé'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();
      expect(library.downloads, 1);
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'introuvable');
      await tester.pumpAndSettle();
      expect(find.text('Aucun document trouvé'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await openFilters(tester);
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Suivi médical'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Général').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Afficher les résultats'));
      await tester.pumpAndSettle();
      expect(find.text('Bilan partagé'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Single pathology filters and notebook fit narrow screens with large text',
    (tester) async {
      await tester.runAsync(
        () => library.setConditions({MedicalCondition.diabetes}),
      );
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: DocumentsPage(library: library),
        ),
      );
      await tester.pumpAndSettle();
      await openFilters(tester);
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Suivi médical'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hypertension'), findsNothing);
      expect(find.text('Diabète'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
