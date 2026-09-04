import 'package:dotdotdot_ai/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('buildDotTheme MaterialApp loads', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDotTheme(),
        home: const Scaffold(
          body: Text('DotDotDot'),
        ),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('DotDotDot'), findsOneWidget);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.colorScheme.primary, DotColors.ink);
    expect(materialApp.theme?.scaffoldBackgroundColor, DotColors.paper);
  });
}
