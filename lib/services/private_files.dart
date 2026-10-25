import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'api_session.dart';

Future<void> savePrivateFile(ApiSession api, String path, String name) async {
  final data = await api.bytes(path);
  final safeName = name.split(RegExp(r'[/\\]')).last;
  final destination = await FilePicker.platform.saveFile(
    dialogTitle: 'Enregistrer le fichier privé',
    fileName: safeName,
    bytes: data,
  );
  if (destination != null &&
      !kIsWeb &&
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    await XFile.fromData(data).saveTo(destination);
  }
}
