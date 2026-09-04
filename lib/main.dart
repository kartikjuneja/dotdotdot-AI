import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/url_strategy_stub.dart'
    if (dart.library.html) 'app/url_strategy_web.dart';

void main() async {
  configureUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DotDotDotApp()));
}
