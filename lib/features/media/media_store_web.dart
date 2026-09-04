import 'dart:convert';
import 'dart:typed_data';

Future<String> saveMediaBytes({
  required List<int> bytes,
  required String fileName,
  String? mimeType,
}) async {
  final mime = mimeType ?? 'application/octet-stream';
  final b64 = base64Encode(bytes);
  return 'data:$mime;base64,$b64';
}

bool localFileExists(String path) => path.startsWith('data:');

Uint8List? readLocalFileBytes(String path) {
  if (!path.startsWith('data:')) return null;
  final comma = path.indexOf(',');
  if (comma < 0) return null;
  try {
    return Uint8List.fromList(base64Decode(path.substring(comma + 1)));
  } catch (_) {
    return null;
  }
}
