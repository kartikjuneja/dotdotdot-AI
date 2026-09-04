import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveMediaBytes({
  required List<int> bytes,
  required String fileName,
  String? mimeType,
}) async {
  final docs = await getApplicationDocumentsDirectory();
  final mediaDir = Directory(p.join(docs.path, 'media'));
  if (!await mediaDir.exists()) {
    await mediaDir.create(recursive: true);
  }
  final file = File(p.join(mediaDir.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

bool localFileExists(String path) {
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

Uint8List? readLocalFileBytes(String path) {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytesSync();
  } catch (_) {
    return null;
  }
}
