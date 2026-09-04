import 'package:sembast/sembast.dart';

import 'app_database_stub.dart'
    if (dart.library.io) 'app_database_io.dart'
    if (dart.library.html) 'app_database_web.dart';

/// Factory that opens the app Sembast database for the current platform.
Future<Database> createAppDatabase({String dbName = 'dotdotdot.db'}) {
  return openPlatformDatabase(dbName: dbName);
}
