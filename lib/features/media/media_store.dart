import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'media_store_stub.dart'
    if (dart.library.io) 'media_store_io.dart'
    if (dart.library.html) 'media_store_web.dart' as impl;

Future<String> saveMediaBytes({
  required List<int> bytes,
  required String fileName,
  String? mimeType,
}) {
  return impl.saveMediaBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}

Future<String> applicationMediaDirPath() async {
  final docs = await getApplicationDocumentsDirectory();
  return p.join(docs.path, 'media');
}

bool localFileExists(String path) => impl.localFileExists(path);

Uint8List? readLocalFileBytes(String path) => impl.readLocalFileBytes(path);
