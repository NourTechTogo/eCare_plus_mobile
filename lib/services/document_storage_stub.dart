import 'dart:typed_data';
import '../models/medical_document.dart';
import 'document_storage.dart';

DocumentStorage createDocumentStorage({String? patientId}) =>
    _UnavailableStorage();

class _UnavailableStorage implements DocumentStorage {
  Never _unavailable() => throw const DocumentException(
    'Le carnet de documents est disponible dans l’application mobile.',
  );
  @override
  Future<Map<String, dynamic>> loadIndex() async => _unavailable();
  @override
  Future<void> saveIndex(Map<String, dynamic> index) async => _unavailable();
  @override
  Future<void> write(String name, Uint8List bytes) async => _unavailable();
  @override
  Future<Uint8List> read(String name) async => _unavailable();
  @override
  Future<String> path(String name) async => _unavailable();
  @override
  Future<void> delete(String name) async => _unavailable();
}
