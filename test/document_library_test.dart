import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_selector/file_selector.dart';
import 'package:ecare_plus_mobile/models/medical_document.dart';
import 'package:ecare_plus_mobile/services/document_library.dart';
import 'package:ecare_plus_mobile/services/document_storage_io.dart';
import 'package:ecare_plus_mobile/services/document_export_cleanup_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late DocumentLibrary library;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ecare-documents-test-');
    library = DocumentLibrary(
      storage: LocalDocumentStorage(directory: directory),
    );
    await library.load();
  });
  tearDown(() async {
    library.dispose();
    await directory.delete(recursive: true);
  });
  test('iOS staging cleanup removes only its own unique export file', () async {
    final original = File('${directory.path}/ordonnance.pdf');
    final staging = File('${directory.path}/ecare-export-123-ordonnance.pdf');
    await original.writeAsString('original');
    await staging.writeAsString('staging');
    await deleteIosExportStaging(
      'ecare-export-123-ordonnance.pdf',
      directory: directory,
    );
    expect(await staging.exists(), false);
    expect(await original.readAsString(), 'original');
    await expectLater(
      deleteIosExportStaging('../ordonnance.pdf', directory: directory),
      throwsFormatException,
    );
  });
  test(
    'Imports a durable copy, restores profile and matches both pathologies once',
    () async {
      final source = File('${directory.path}/source.pdf');
      await source.writeAsBytes([37, 80, 68, 70, 45, 49]);
      await library.setConditions({
        MedicalCondition.diabetes,
        MedicalCondition.hypertension,
      });
      final item = await library.importFile(
        XFile(source.path),
        title: 'Bilan commun',
        category: DocumentCategory.results,
        conditions: MedicalCondition.values.toSet(),
        date: DateTime(2026, 10, 14),
      );
      await source.delete();
      final restored = DocumentLibrary(
        storage: LocalDocumentStorage(directory: directory),
      );
      await restored.load();
      expect(restored.conditions, MedicalCondition.values.toSet());
      expect(restored.documents.length, 1);
      expect(
        restored.filtered(condition: MedicalCondition.diabetes).single.id,
        item.id,
      );
      expect(
        restored.filtered(condition: MedicalCondition.hypertension).single.id,
        item.id,
      );
      expect(
        await restored.read(item),
        Uint8List.fromList([37, 80, 68, 70, 45, 49]),
      );
      await restored.remove(item);
      final again = DocumentLibrary(
        storage: LocalDocumentStorage(directory: directory),
      );
      await again.load();
      expect(again.documents, isEmpty);
      restored.dispose();
      again.dispose();
    },
  );
  test('Rejects empty and unsupported files without adding a record', () async {
    await expectLater(
      library.importFile(
        XFile.fromData(Uint8List(0), path: 'empty.pdf'),
        title: 'Vide',
        category: DocumentCategory.other,
        conditions: {},
        date: DateTime.now(),
      ),
      throwsA(isA<DocumentException>()),
    );
    await expectLater(
      library.importFile(
        XFile.fromData(Uint8List.fromList([1]), path: 'bad.exe'),
        title: 'Invalide',
        category: DocumentCategory.other,
        conditions: {},
        date: DateTime.now(),
      ),
      throwsA(isA<DocumentException>()),
    );
    expect(library.documents, isEmpty);
  });
}
