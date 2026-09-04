import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

/// Web Sembast opener via IndexedDB (`databaseFactoryWeb`).
Future<Database> openPlatformDatabase({String dbName = 'dotdotdot.db'}) {
  return databaseFactoryWeb.openDatabase(dbName);
}
