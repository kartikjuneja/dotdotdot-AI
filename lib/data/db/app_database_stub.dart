import 'package:sembast/sembast.dart';

/// Opens the platform-specific Sembast database.
///
/// Implemented by conditional imports in [createAppDatabase].
Future<Database> openPlatformDatabase({String dbName = 'dotdotdot.db'}) {
  throw UnsupportedError(
    'No Sembast database implementation for this platform.',
  );
}
