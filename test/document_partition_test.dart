import 'dart:io';
import 'package:ecare_plus_mobile/services/document_library.dart';
import 'package:ecare_plus_mobile/services/document_storage_io.dart';
import 'package:ecare_plus_mobile/models/medical_document.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Patient directories are isolated and logout locks previous library without deleting files',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ecare-patient-documents-',
      );
      addTearDown(() => root.delete(recursive: true));
      final a = DocumentLibrary(
        patientId: 'patient-a',
        storage: LocalDocumentStorage(directory: root, patientId: 'patient-a'),
      );
      final b = DocumentLibrary(
        patientId: 'patient-b',
        storage: LocalDocumentStorage(directory: root, patientId: 'patient-b'),
      );
      final source = File('${root.path}/resultat.pdf');
      await source.writeAsBytes([37, 80, 68, 70]);
      final item = await a.importFile(
        XFile(source.path),
        title: 'Compte A',
        category: DocumentCategory.results,
        conditions: {},
        date: DateTime(2026),
      );
      await b.load();
      expect(b.documents, isEmpty);
      expect(await a.read(item), [37, 80, 68, 70]);
      a.lockSession();
      expect(a.documents, isEmpty);
      expect(() => a.read(item), throwsA(isA<DocumentException>()));
      final restored = DocumentLibrary(
        patientId: 'patient-a',
        storage: LocalDocumentStorage(directory: root, patientId: 'patient-a'),
      );
      await restored.load();
      expect(restored.documents.single.title, 'Compte A');
      expect(
        await File(
          '${root.path}/patients/patient-a/${item.storageName}',
        ).exists(),
        isTrue,
      );
    },
  );
}
