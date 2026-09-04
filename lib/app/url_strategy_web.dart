import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Hash URLs (`/#/settings`) so static hosts like GitHub Pages work
/// without server-side rewrite rules.
void configureUrlStrategy() {
  setUrlStrategy(const HashUrlStrategy());
}
