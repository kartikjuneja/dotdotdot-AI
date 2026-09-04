import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class DotDotDotApp extends ConsumerWidget {
  const DotDotDotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final catalog = ref.watch(modelCatalogProvider);

    return db.when(
      loading: () => const _BootSplash(message: 'Opening local database…'),
      error: (e, _) => _BootSplash(
        message: 'Could not open database.\n$e',
        isError: true,
      ),
      data: (_) => catalog.when(
        loading: () => const _BootSplash(message: 'Loading model catalog…'),
        error: (e, _) => _BootSplash(
          message: 'Could not load model catalog.\n$e',
          isError: true,
        ),
        data: (_) {
          final router = ref.watch(goRouterProvider);
          return MaterialApp.router(
            title: 'DotDotDot',
            debugShowCheckedModeBanner: false,
            theme: buildDotTheme(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildDotTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isError) const CircularProgressIndicator(),
                if (!isError) const SizedBox(height: 20),
                Text(
                  'DotDotDot',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isError ? DotColors.danger : DotColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
