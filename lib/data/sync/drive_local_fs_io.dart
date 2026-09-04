import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> ensureLocalMirrorDir(String relativeDir) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, relativeDir));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

Future<void> writeLocalMirrorBytes({
  required String relativeDir,
  required String fileName,
  required Uint8List bytes,
}) async {
  await ensureLocalMirrorDir(relativeDir);
  final docs = await getApplicationDocumentsDirectory();
  final file = File(p.join(docs.path, relativeDir, fileName));
  await file.writeAsBytes(bytes, flush: true);
}

Future<Uint8List?> readLocalMirrorBytes({
  required String relativeDir,
  required String fileName,
}) async {
  final docs = await getApplicationDocumentsDirectory();
  final file = File(p.join(docs.path, relativeDir, fileName));
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<String> localMirrorPath({
  required String relativeDir,
  required String fileName,
}) async {
  final docs = await getApplicationDocumentsDirectory();
  return p.join(docs.path, relativeDir, fileName);
}
