import 'dart:typed_data';

Future<String> saveMediaBytes({
  required List<int> bytes,
  required String fileName,
  String? mimeType,
}) {
  throw UnsupportedError('Media store unavailable on this platform');
}

bool localFileExists(String path) => false;

Uint8List? readLocalFileBytes(String path) => null;
