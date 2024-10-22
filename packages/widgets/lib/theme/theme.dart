import 'package:flutter/material.dart';
import 'package:widgets/theme/color_theme.dart';
import 'package:widgets/theme/spacing_theme.dart';
import 'package:widgets/theme/text_theme.dart';

class TokeruTheme {
  static final spacing = () {
    return TokeruSpacingExtension(
      none: 0,
      smallX: 4,
      small: 8,
      medium: 16,
      large: 24,
    );
  }();

  static final color = () {
    return TokeruColorsExtension(
      primary: Colors.cyan.shade500,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.grey.shade900,
      onSurfaceSubtle: Colors.grey.shade600,
      outline: Colors.grey.shade300,
      outlineSubtle: Colors.grey.shade200,
      outlineStrong: Colors.grey.shade400,
      link: Colors.blue.shade800,
      skeleton: Colors.grey.shade300,
    );
  }();

  static final light = () {
    final defaultTheme = ThemeData.light();

    final colorExt = color;

    return defaultTheme.copyWith(
      dividerColor: colorExt.outline,
      extensions: [
        colorExt,
        spacing,
        const TokeruTextThemeExtension(
          displayLarge: TextStyle(fontSize: 57),
          displayMedium: TextStyle(fontSize: 45),
          displaySmall: TextStyle(fontSize: 36),
          headlineLarge: TextStyle(fontSize: 32),
          headlineMedium: TextStyle(fontSize: 28),
          headlineSmall: TextStyle(fontSize: 24),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          labelMidium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }();

  static final dark = () {
    final defaultTheme = ThemeData.dark();

    final colorExt = color;

    return defaultTheme.copyWith(
      extensions: [
        colorExt,
        spacing,
        const TokeruTextThemeExtension(
          displayLarge: TextStyle(fontSize: 57),
          displayMedium: TextStyle(fontSize: 45),
          displaySmall: TextStyle(fontSize: 36),
          headlineLarge: TextStyle(fontSize: 32),
          headlineMedium: TextStyle(fontSize: 28),
          headlineSmall: TextStyle(fontSize: 24),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          labelMidium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }();
}

extension TokeruThemeExtension on BuildContext {
  TokeruTextThemeExtension get tokeruTextTheme {
    return Theme.of(this).extension<TokeruTextThemeExtension>()!;
  }

  TokeruColorsExtension get tokeruColors {
    return Theme.of(this).extension<TokeruColorsExtension>()!;
  }

  TokeruSpacingExtension get tokeruSpacing {
    return Theme.of(this).extension<TokeruSpacingExtension>()!;
  }
}
