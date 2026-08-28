import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    surfaces: AppSurfaceTokens.light,
    primary: const Color(0xFF245E73),
    onPrimary: const Color(0xFFFFFFFF),
    foreground: const Color(0xFF1B1D1F),
    colors: AppSemanticColors.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    surfaces: AppSurfaceTokens.dark,
    primary: const Color(0xFF79CBE3),
    onPrimary: const Color(0xFF062630),
    foreground: const Color(0xFFF4F6F7),
    colors: AppSemanticColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppSurfaceTokens surfaces,
    required Color primary,
    required Color onPrimary,
    required Color foreground,
    required AppSemanticColors colors,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      surface: surfaces.surface,
      onSurface: foreground,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaces.canvas,
      canvasColor: surfaces.canvas,
      cardColor: surfaces.surface,
      extensions: const <ThemeExtension<dynamic>>[AppMotionTokens.standard()],
    );
    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        colors,
        const AppMotionTokens.standard(),
        surfaces,
      ],
      cardTheme: CardThemeData(
        color: surfaces.surface,
        shadowColor: surfaces.shadow,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.section,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaces.surface,
        elevation: AppElevation.none,
        shadowColor: surfaces.shadow,
        surfaceTintColor: Colors.transparent,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          base.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaces.surface,
        elevation: AppElevation.none,
        useIndicator: true,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        minWidth: AppSizes.navigationRail,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaces.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.extraLarge),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? surfaces.surfaceRaised
            : const Color(0xFF1B1D1F),
        contentTextStyle: TextStyle(
          color: brightness == Brightness.dark
              ? foreground
              : const Color(0xFFFFFFFF),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontSize: 40,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontSize: 32,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          height: 30 / 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      focusColor: brightness == Brightness.light
          ? const Color(0xFF006B86)
          : const Color(0xFF79D4F2),
    );
  }
}
