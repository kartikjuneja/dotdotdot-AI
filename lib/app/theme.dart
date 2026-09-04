import 'package:flutter/material.dart';

/// DotDotDot visual identity: deep ink navy + warm amber on soft paper.
abstract final class DotColors {
  static const Color ink = Color(0xFF0B1C2C);
  static const Color inkMuted = Color(0xFF1A3248);
  static const Color inkSoft = Color(0xFF2A455C);
  static const Color amber = Color(0xFFE8A317);
  static const Color amberDeep = Color(0xFFC4840A);
  static const Color paper = Color(0xFFF7F4EF);
  static const Color paperElevated = Color(0xFFFFFCF8);
  static const Color paperLine = Color(0xFFE4DDD3);
  static const Color textPrimary = Color(0xFF142433);
  static const Color textSecondary = Color(0xFF5A6B7A);
  static const Color danger = Color(0xFFB42318);
  static const Color success = Color(0xFF1F7A4C);
}

ThemeData buildDotTheme() {
  const seed = DotColors.ink;
  final base = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: DotColors.ink,
    onPrimary: DotColors.paper,
    secondary: DotColors.amber,
    onSecondary: DotColors.ink,
    surface: DotColors.paper,
    onSurface: DotColors.textPrimary,
    error: DotColors.danger,
  );

  // Expressive sizes without Google Fonts — platform fallback stacks.
  const displayFamily = 'Georgia';
  const bodyFamily = 'Segoe UI';

  final textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: displayFamily,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: DotColors.ink,
      height: 1.15,
    ),
    displayMedium: TextStyle(
      fontFamily: displayFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: DotColors.ink,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontFamily: displayFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: DotColors.ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: displayFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: DotColors.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: displayFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: DotColors.ink,
    ),
    titleLarge: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: DotColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: DotColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: DotColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 16,
      height: 1.45,
      color: DotColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      height: 1.45,
      color: DotColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 12,
      height: 1.4,
      color: DotColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: DotColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: DotColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: DotColors.textSecondary,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base.copyWith(
      primaryContainer: DotColors.inkMuted,
      onPrimaryContainer: DotColors.paper,
      secondaryContainer: const Color(0xFFFFE8B8),
      onSecondaryContainer: DotColors.ink,
      outline: DotColors.paperLine,
      surfaceContainerHighest: DotColors.paperElevated,
    ),
    scaffoldBackgroundColor: DotColors.paper,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: DotColors.paper,
      foregroundColor: DotColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: textTheme.titleLarge,
    ),
    dividerTheme: const DividerThemeData(
      color: DotColors.paperLine,
      thickness: 1,
      space: 1,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: DotColors.ink,
      selectedIconTheme: const IconThemeData(color: DotColors.amber),
      unselectedIconTheme: IconThemeData(color: DotColors.paper.withOpacity(0.7)),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: DotColors.amber),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: DotColors.paper.withOpacity(0.7),
      ),
      indicatorColor: DotColors.inkSoft,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: DotColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DotColors.ink,
        foregroundColor: DotColors.paper,
        disabledBackgroundColor: DotColors.inkSoft.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DotColors.amber,
        foregroundColor: DotColors.ink,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DotColors.ink,
        side: const BorderSide(color: DotColors.paperLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DotColors.paperElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DotColors.paperLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DotColors.paperLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DotColors.amber, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: DotColors.paperElevated,
      selectedColor: const Color(0xFFFFE8B8),
      side: const BorderSide(color: DotColors.paperLine),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: DotColors.inkMuted,
      textColor: DotColors.textPrimary,
      selectedColor: DotColors.amber,
      selectedTileColor: DotColors.inkSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: DotColors.amber,
      inactiveTrackColor: DotColors.paperLine,
      thumbColor: DotColors.amberDeep,
      overlayColor: DotColors.amber.withOpacity(0.15),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: DotColors.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: DotColors.paper),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DotColors.amber,
      linearTrackColor: DotColors.paperLine,
    ),
  );
}
