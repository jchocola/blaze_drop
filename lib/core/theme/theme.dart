import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// BlazeDrop "Cyber-Utility" color tokens (source: `.ai_skill/DESIGN.md`).
abstract final class AppColors {
  // Surfaces.
  static const Color deepCharcoal = Color(0xFF0D0D0D);
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFBAC9CC);

  // Primary (Electric Cyan).
  static const Color primary = Color(0xFFC3F5FF);
  static const Color primaryContainer = Color(0xFF00E5FF);
  static const Color onPrimary = Color(0xFF00363D);
  static const Color onPrimaryContainer = Color(0xFF00626E);
  static const Color inversePrimary = Color(0xFF006875);

  // Secondary (Vibrant Orange).
  static const Color secondary = Color(0xFFFFB693);
  static const Color secondaryContainer = Color(0xFFFE6B00);
  static const Color onSecondary = Color(0xFF561F00);

  // Tertiary (Neon Green).
  static const Color tertiary = Color(0xFFBAFFA2);
  static const Color tertiaryContainer = Color(0xFF2CF100);
  static const Color onTertiary = Color(0xFF053900);

  // Error.
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Outline.
  static const Color outline = Color(0xFF849396);
  static const Color outlineVariant = Color(0xFF3B494C);
}

/// Typography scale (DESIGN.md) mapped to Flutter [TextStyle]s.
abstract final class AppTextStyles {
  static const String displayFont = 'Inter';
  static const String monoFont = 'SpaceGrotesk';

  static const TextStyle displayLg = TextStyle(
    fontFamily: displayFont,
    fontSize: 72,
    height: 1.0,
    fontWeight: FontWeight.w900,
    letterSpacing: -2.88,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: displayFont,
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.64,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: displayFont,
    fontSize: 24,
    height: 1.33,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: displayFont,
    fontSize: 18,
    height: 1.56,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: displayFont,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: displayFont,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelCaps = TextStyle(
    fontFamily: monoFont,
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static const TextStyle codeSm = TextStyle(
    fontFamily: monoFont,
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w400,
  );
}

/// The BlazeDrop dark "command deck" theme.
///
/// Sharp corners (0px), luminance-and-stroke elevation, neon accents.
abstract final class AppTheme {
  static const BorderRadius sharp = BorderRadius.zero;

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primaryContainer,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondaryContainer,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondary,
      tertiary: AppColors.tertiaryContainer,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiary,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      inverseSurface: AppColors.onSurface,
      onInverseSurface: AppColors.surfaceContainerLowest,
      inversePrimary: AppColors.inversePrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.displayFont,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTextStyles.displayLg,
        headlineLarge: AppTextStyles.headlineLg,
        headlineMedium: AppTextStyles.headlineMd,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        bodySmall: AppTextStyles.bodySm,
        labelLarge: const TextStyle(
          fontFamily: AppTextStyles.monoFont,
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
        labelMedium: AppTextStyles.labelCaps,
        labelSmall: AppTextStyles.labelCaps.copyWith(fontSize: 11),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.sharp,
          side: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.sharp,
          side: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        titleTextStyle: AppTextStyles.headlineMd,
        contentTextStyle: AppTextStyles.bodyMd,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMd,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.cardPadding,
          vertical: AppConstants.cardPadding,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppTheme.sharp,
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppTheme.sharp,
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppTheme.sharp,
          borderSide: BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: AppTheme.sharp),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.monoFont,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerHigh,
          foregroundColor: AppColors.primaryContainer,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: AppTheme.sharp),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.monoFont,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
          side: const BorderSide(color: AppColors.primaryContainer, width: 2),
          shape: const RoundedRectangleBorder(borderRadius: AppTheme.sharp),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.monoFont,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.monoFont,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(
          AppColors.outlineVariant,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryContainer,
        linearTrackColor: AppColors.surfaceContainerHighest,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: AppTextStyles.bodyMd,
        actionTextColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.sharp,
          side: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        labelStyle: AppTextStyles.labelCaps.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.sharp),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor: AppColors.primaryContainer,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryContainer,
        selectionColor: Color(0x4D00E5FF),
        selectionHandleColor: AppColors.primaryContainer,
      ),
    );
  }
}
