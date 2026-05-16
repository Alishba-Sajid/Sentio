import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primary = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFF22D3EE);
  static const Color surface = Color(0xFFF4F6FB);
  static const Color surfaceDark = Color(0xFFE8ECF4);
  static const Color background = Color(0xFFF7F9FF);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B21B6), Color(0xFF0EA5E9)],
  );

  static const LinearGradient scaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9FBFF), Color(0xFFE8EEFF)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFEDF2FF)],
  );

  static const double radiusLg = 22;
  static const double radiusMd = 16;

  static BoxDecoration premiumCardDecoration({Color? borderColor}) {
    return BoxDecoration(
      gradient: surfaceGradient,
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(
        color: borderColor ?? const Color(0xFFDEE7FF),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF23374D).withValues(alpha: 0.08),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration premiumBackgroundDecoration() {
    return const BoxDecoration(gradient: scaffoldGradient);
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: textPrimary,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: surfaceDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: surfaceDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}
