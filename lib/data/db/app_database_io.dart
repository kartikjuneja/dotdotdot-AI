import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

/// IO (mobile/desktop) Sembast opener under application documents.
Future<Database> openPlatformDatabase({String dbName = 'dotdotdot.db'}) async {
  final dir = await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);
  final dbPath = p.join(dir.path, dbName);
  return databaseFactoryIo.openDatabase(dbPath);
}

/// Exposes documents directory for media/cache helpers.
Future<Directory> appDocumentsDirectory() => getApplicationDocumentsDirectory();
