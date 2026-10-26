import 'dart:js_interop';

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(JSString url);

Future<void> deleteTemporaryRecording(String path) async {
  if (Uri.tryParse(path)?.scheme == 'blob') _revokeObjectUrl(path.toJS);
}
