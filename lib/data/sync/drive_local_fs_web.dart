import 'dart:typed_data';

Future<void> ensureLocalMirrorDir(String relativeDir) async {}

Future<void> writeLocalMirrorBytes({
  required String relativeDir,
  required String fileName,
  required Uint8List bytes,
}) async {
  throw UnsupportedError('Local file mirror is not available on web');
}

Future<Uint8List?> readLocalMirrorBytes({
  required String relativeDir,
  required String fileName,
}) async {
  return null;
}

Future<String> localMirrorPath({
  required String relativeDir,
  required String fileName,
}) async {
  return '$relativeDir/$fileName';
}
