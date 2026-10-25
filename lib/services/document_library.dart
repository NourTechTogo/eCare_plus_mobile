import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../models/medical_document.dart';
import 'document_storage.dart';
import 'document_export_cleanup.dart';
import 'api_session.dart';

class DocumentLibrary extends ChangeNotifier {
  static final instance = DocumentLibrary();
  static const extensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const maxBytes = 5 * 1024 * 1024;
  final ApiSession? session;
  bool get remote => session != null;
  final Map<XFile, String> _pendingSources = {};
  final DocumentStorage storage;
  final String? patientId;
  final bool locked;
  bool _closed = false;
  void lockSession() {
    _closed = true;
    _documents = [];
    _conditions = {};
  }

  @override
  void notifyListeners() {
    if (!_closed) super.notifyListeners();
  }

  DocumentLibrary({
    DocumentStorage? storage,
    this.patientId,
    this.locked = false,
    this.session,
  }) : storage = storage ?? createDocumentStorage(patientId: patientId);
  List<MedicalDocument> _documents = [];
  Set<MedicalCondition> _conditions = {};
  Future<void>? _loading;
  bool loaded = false;
  bool _busy = false;
  List<MedicalDocument> get documents =>
      List.unmodifiable(_closed || locked ? <MedicalDocument>[] : _documents);
  Set<MedicalCondition> get conditions =>
      Set.unmodifiable(_closed || locked ? <MedicalCondition>{} : _conditions);
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    if (locked || _closed) {
      throw const DocumentException(
        'Reconnectez-vous pour ouvrir votre carnet.',
      );
    }
    try {
      if (session != null) {
        final rows = await session!.all('/mobile/me/documents');
        if (_closed) return;
        _documents = rows.map(_fromServer).toList();
        loaded = true;
        notifyListeners();
        return;
      }
      final index = await storage.loadIndex();
      if (_closed) return;
      _documents = ((index['documents'] ?? []) as List)
          .map(
            (j) =>
                MedicalDocument.fromJson(Map<String, dynamic>.from(j as Map)),
          )
          .toList();
      _conditions = ((index['conditions'] ?? []) as List)
          .map((c) => MedicalCondition.values.byName(c as String))
          .toSet();
      loaded = true;
      notifyListeners();
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  MedicalDocument _fromServer(Map<String, dynamic> row) => MedicalDocument(
    id: row['id'] as String,
    title: row['titre'] as String,
    fileName: row['nomOriginal'] as String,
    storageName: '${row['id']}.bin',
    size: (row['tailleOctets'] as num).toInt(),
    date: DateTime.parse(row['dateDocument'] as String),
    category: switch (row['typeDocument']) {
      'ORDONNANCE' => DocumentCategory.prescription,
      'RESULTAT_ANALYSE' => DocumentCategory.results,
      'COMPTE_RENDU' => DocumentCategory.report,
      _ => DocumentCategory.other,
    },
    conditions: {},
  );

  Future<void> reload() {
    _loading = null;
    return load();
  }

  Future<void> _persist(
    List<MedicalDocument> docs,
    Set<MedicalCondition> conditions,
  ) => storage.saveIndex({
    'version': 1,
    'conditions': conditions.map((c) => c.name).toList(),
    'documents': docs.map((d) => d.toJson()).toList(),
  });
  Future<T> _change<T>(Future<T> Function() action) async {
    if (locked || _closed) throw const DocumentException('Carnet verrouillé.');
    if (_busy) {
      throw const DocumentException(
        'Une opération est déjà en cours. Réessayez dans un instant.',
      );
    }
    _busy = true;
    try {
      await load();
      if (_closed) throw const DocumentException('Carnet verrouillé.');
      return await action();
    } finally {
      _busy = false;
    }
  }

  Future<void> setConditions(Set<MedicalCondition> conditions) =>
      _change(() async {
        await _persist(_documents, conditions);
        _conditions = Set.of(conditions);
        notifyListeners();
      });
  Future<XFile?> pickFile() => openFile(
    acceptedTypeGroups: [
      const XTypeGroup(
        label: 'Documents médicaux',
        extensions: extensions,
        mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
        uniformTypeIdentifiers: ['com.adobe.pdf', 'public.jpeg', 'public.png'],
      ),
    ],
  );
  Future<MedicalDocument> importFile(
    XFile file, {
    required String title,
    required DocumentCategory category,
    required Set<MedicalCondition> conditions,
    required DateTime date,
  }) => _change(() async {
    final fileName = file.name.split(RegExp(r'[/\\]')).last;
    final ext = fileName.split('.').last.toLowerCase();
    if (!extensions.contains(ext)) {
      throw const DocumentException('Choisissez un PDF ou une image JPG/PNG.');
    }
    if (title.trim().isEmpty) {
      throw const DocumentException('Donnez un nom au document.');
    }
    if (await file.length() > maxBytes) {
      throw const DocumentException('Le fichier doit faire moins de 5 Mo.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw const DocumentException('Ce fichier est vide.');
    if (bytes.length > maxBytes) {
      throw const DocumentException('Le fichier doit faire moins de 5 Mo.');
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    if (session != null) {
      try {
        final source = _pendingSources.putIfAbsent(file, () => 'document-$id');
        final row = await session!.upload(
          '/mobile/me/documents',
          bytes: bytes,
          fileName: fileName,
          fields: {
            'titre': title.trim(),
            'typeDocument': switch (category) {
              DocumentCategory.prescription => 'ORDONNANCE',
              DocumentCategory.results => 'RESULTAT_ANALYSE',
              DocumentCategory.report => 'COMPTE_RENDU',
              DocumentCategory.other => 'AUTRE',
            },
            'dateDocument':
                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            'sourceRef': source,
          },
        );
        if (_closed) throw const DocumentException('Carnet verrouillé.');
        final item = _fromServer(row);
        _documents = [..._documents.where((d) => d.id != item.id), item];
        _pendingSources.remove(file);
        notifyListeners();
        return item;
      } on ApiException catch (e) {
        throw DocumentException(e.message);
      }
    }
    final item = MedicalDocument(
      id: id,
      title: title.trim(),
      fileName: fileName,
      storageName: '$id.$ext',
      size: bytes.length,
      date: date,
      category: category,
      conditions: conditions,
    );
    await storage.write(item.storageName, bytes);
    final next = [..._documents, item];
    try {
      await _persist(next, _conditions);
    } catch (_) {
      await storage.delete(item.storageName);
      rethrow;
    }
    _documents = next;
    notifyListeners();
    return item;
  });
  List<MedicalDocument> filtered({
    DocumentCategory? category,
    MedicalCondition? condition,
    bool general = false,
    String query = '',
    bool oldestFirst = false,
  }) {
    if (_closed || locked) return [];
    final search = query.trim().toLowerCase();
    final result = _documents
        .where(
          (d) =>
              (category == null || d.category == category) &&
              (condition == null || d.conditions.contains(condition)) &&
              (!general || d.conditions.isEmpty) &&
              (search.isEmpty ||
                  '${d.title} ${d.fileName} ${d.category.label} ${d.followUp}'
                      .toLowerCase()
                      .contains(search)),
        )
        .toList();
    result.sort((a, b) {
      final order = a.date.compareTo(b.date);
      return oldestFirst ? order : -order;
    });
    return result;
  }

  Future<Uint8List> read(MedicalDocument item) {
    if (locked || _closed) throw const DocumentException('Carnet verrouillé.');
    if (session != null) {
      return session!.bytes('/mobile/me/documents/${item.id}/contenu');
    }
    return storage.read(item.storageName);
  }

  Future<void> open(MedicalDocument item) async {
    if (locked || _closed) throw const DocumentException('Carnet verrouillé.');
    if (session != null) {
      await export(item);
      return;
    }
    final result = await OpenFilex.open(await storage.path(item.storageName));
    if (result.type != ResultType.done) {
      throw const DocumentException(
        'Aucune application ne peut ouvrir ce document. Vous pouvez le télécharger.',
      );
    }
  }

  Future<bool> export(MedicalDocument item) async {
    final bytes = await read(item);
    final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final exportName = ios
        ? 'ecare-export-${DateTime.now().microsecondsSinceEpoch}-${item.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_')}'
        : item.fileName;
    try {
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Télécharger le document',
        fileName: exportName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [item.extension],
      );
      if (saved == null) return false;
      // Mobile implementations write bytes themselves; desktop returns a destination.
      if (!kIsWeb &&
          defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        await XFile.fromData(bytes).saveTo(saved);
      }
      return true;
    } finally {
      if (ios) await deleteIosExportStaging(exportName);
    }
  }

  Future<void> remove(MedicalDocument item) => _change(() async {
    if (session != null) {
      try {
        await session!.request('DELETE', '/mobile/me/documents/${item.id}');
      } on ApiException catch (e) {
        throw DocumentException(e.message);
      }
      if (_closed) return;
      _documents = _documents.where((d) => d.id != item.id).toList();
      notifyListeners();
      return;
    }
    final next = _documents.where((d) => d.id != item.id).toList();
    await _persist(next, _conditions);
    _documents = next;
    notifyListeners();
    await storage.delete(item.storageName);
  });
}
