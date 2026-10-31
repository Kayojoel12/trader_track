import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0B0F14);
  static const surface = Color(0xFF141A22);
  static const border = Color(0xFF232C38);
  static const text = Color(0xFFE8EDF3);
  static const muted = Color(0xFF9AA7B5);
  static const gain = Color(0xFF2ECC8F);
  static const loss = Color(0xFFFF5C6C);
  static const accent = Color(0xFF5B8CFF);
  static const warn = Color(0xFFFFB020);
}

class AppTheme {
  static ThemeData get dark => _build(
        const ColorScheme.dark(
          primary: AppColors.accent,
          onPrimary: AppColors.bg,
          surface: AppColors.surface,
          error: AppColors.loss,
        ),
        AppColors.bg,
        AppColors.border,
      );

  static ThemeData get light => _build(
        const ColorScheme.light(
          primary: Color(0xFF3A66E0),
          surface: Colors.white,
          error: Color(0xFFD93A4C),
        ),
        const Color(0xFFF6F8FB),
        const Color(0xFFDDE3EA),
      );

  static ThemeData _build(ColorScheme scheme, Color bg, Color border) {
    final base = ThemeData(
        colorScheme: scheme, scaffoldBackgroundColor: bg, useMaterial3: true);
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
