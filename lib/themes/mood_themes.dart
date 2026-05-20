import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All the moods supported in Lunaire.
enum Mood {
  happy,
  sad,
  angry,
  calm,
  romantic,
  anxious,
  defaultMood,
}

extension MoodMeta on Mood {
  String get label {
    switch (this) {
      case Mood.happy:    return 'Happy';
      case Mood.sad:      return 'Sad';
      case Mood.angry:    return 'Angry';
      case Mood.calm:     return 'Calm';
      case Mood.romantic: return 'Romantic';
      case Mood.anxious:  return 'Anxious';
      case Mood.defaultMood: return 'Default';
    }
  }

  String get emoji {
    switch (this) {
      case Mood.happy:    return '😊';
      case Mood.sad:      return '😢';
      case Mood.angry:    return '😡';
      case Mood.calm:     return '😌';
      case Mood.romantic: return '🥰';
      case Mood.anxious:  return '😰';
      case Mood.defaultMood: return '🌙';
    }
  }
}

/// MoodPalette - colors for a single theme.
/// burstCore / burstAccent are high-contrast colors specifically chosen
/// so tap-burst particles stay visible against the theme background.
class MoodPalette {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color moonColor;
  final Color moonGlow;
  final List<Color> skyGradient;
  final Color burstCore;
  final Color burstAccent;

  const MoodPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.moonColor,
    required this.moonGlow,
    required this.skyGradient,
    required this.burstCore,
    required this.burstAccent,
  });
}

class MoodThemes {
  static MoodPalette palette(Mood mood, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (mood) {
      case Mood.happy:
        return MoodPalette(
          primary: const Color(0xFFFFB347),
          secondary: const Color(0xFFFF8C42),
          background: isDark ? const Color(0xFF2A1810) : const Color(0xFFFFF5E6),
          surface: isDark ? const Color(0xFF3D2817) : const Color(0xFFFFE8C7),
          textPrimary: isDark ? const Color(0xFFFFE8C7) : const Color(0xFF3D2817),
          textSecondary: isDark ? const Color(0xFFFFB347) : const Color(0xFF8B5A2B),
          moonColor: const Color(0xFFFFE066),
          moonGlow: const Color(0xFFFFD700),
          skyGradient: isDark
              ? [const Color(0xFF2A1810), const Color(0xFF5D2E0F)]
              : [const Color(0xFFFFF5E6), const Color(0xFFFFCC80)],
          burstCore: isDark ? const Color(0xFFFFF8C0) : const Color(0xFFFF6B1A),
          burstAccent: isDark ? const Color(0xFFFF6B1A) : const Color(0xFFB8460D),
        );
      case Mood.sad:
        return MoodPalette(
          primary: const Color(0xFF4A6FA5),
          secondary: const Color(0xFF6B8CBC),
          background: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFE8F0FA),
          surface: isDark ? const Color(0xFF1A2A45) : const Color(0xFFD0DFF0),
          textPrimary: isDark ? const Color(0xFFD0DFF0) : const Color(0xFF1A2A45),
          textSecondary: isDark ? const Color(0xFF6B8CBC) : const Color(0xFF4A6FA5),
          moonColor: const Color(0xFFB8C9DD),
          moonGlow: const Color(0xFF8AA7C8),
          skyGradient: isDark
              ? [const Color(0xFF0F1A2E), const Color(0xFF2C4159)]
              : [const Color(0xFFE8F0FA), const Color(0xFFA8C0DC)],
          burstCore: isDark ? const Color(0xFFE0F0FF) : const Color(0xFF1A3A6A),
          burstAccent: isDark ? const Color(0xFF6BB6FF) : const Color(0xFF4A6FA5),
        );
      case Mood.angry:
        return MoodPalette(
          primary: const Color(0xFFB22222),
          secondary: const Color(0xFFDC143C),
          background: isDark ? const Color(0xFF1A0606) : const Color(0xFFFFE8E8),
          surface: isDark ? const Color(0xFF2D0A0A) : const Color(0xFFFFCDD2),
          textPrimary: isDark ? const Color(0xFFFFCDD2) : const Color(0xFF2D0A0A),
          textSecondary: isDark ? const Color(0xFFDC143C) : const Color(0xFFB22222),
          moonColor: const Color(0xFFD63031),
          moonGlow: const Color(0xFFFF4757),
          skyGradient: isDark
              ? [const Color(0xFF1A0606), const Color(0xFF4A0E0E)]
              : [const Color(0xFFFFE8E8), const Color(0xFFFF8A80)],
          burstCore: isDark ? const Color(0xFFFFE066) : const Color(0xFF5A0000),
          burstAccent: isDark ? const Color(0xFFFF8A3D) : const Color(0xFFFF3D3D),
        );
      case Mood.calm:
        return MoodPalette(
          primary: const Color(0xFF9B7EBD),
          secondary: const Color(0xFFC8B6E2),
          background: isDark ? const Color(0xFF1A1525) : const Color(0xFFF3EBFA),
          surface: isDark ? const Color(0xFF2A2238) : const Color(0xFFE0D0F0),
          textPrimary: isDark ? const Color(0xFFE0D0F0) : const Color(0xFF2A2238),
          textSecondary: isDark ? const Color(0xFFC8B6E2) : const Color(0xFF9B7EBD),
          moonColor: const Color(0xFFE8DDF5),
          moonGlow: const Color(0xFFC8B6E2),
          skyGradient: isDark
              ? [const Color(0xFF1A1525), const Color(0xFF3D2E55)]
              : [const Color(0xFFF3EBFA), const Color(0xFFD4BEEF)],
          burstCore: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF5D3A8A),
          burstAccent: isDark ? const Color(0xFFC8B6E2) : const Color(0xFF9B7EBD),
        );
      case Mood.romantic:
        return MoodPalette(
          primary: const Color(0xFFE91E63),
          secondary: const Color(0xFFF8BBD0),
          background: isDark ? const Color(0xFF2A0A1A) : const Color(0xFFFFE4EC),
          surface: isDark ? const Color(0xFF3D1429) : const Color(0xFFFFC1D6),
          textPrimary: isDark ? const Color(0xFFFFC1D6) : const Color(0xFF3D1429),
          textSecondary: isDark ? const Color(0xFFF8BBD0) : const Color(0xFFE91E63),
          moonColor: const Color(0xFFFFD1DC),
          moonGlow: const Color(0xFFFF99AC),
          skyGradient: isDark
              ? [const Color(0xFF2A0A1A), const Color(0xFF5D1F3D)]
              : [const Color(0xFFFFE4EC), const Color(0xFFFFAACB)],
          burstCore: isDark ? const Color(0xFFFFFFFF) : const Color(0xFFA01040),
          burstAccent: isDark ? const Color(0xFFFF4D8A) : const Color(0xFFE91E63),
        );
      case Mood.anxious:
        return MoodPalette(
          primary: const Color(0xFF6C7A89),
          secondary: const Color(0xFF95A5A6),
          background: isDark ? const Color(0xFF1C1C24) : const Color(0xFFECEFF1),
          surface: isDark ? const Color(0xFF2D2D38) : const Color(0xFFCFD8DC),
          textPrimary: isDark ? const Color(0xFFCFD8DC) : const Color(0xFF2D2D38),
          textSecondary: isDark ? const Color(0xFF95A5A6) : const Color(0xFF6C7A89),
          moonColor: const Color(0xFFB0BEC5),
          moonGlow: const Color(0xFF8B9DA5),
          skyGradient: isDark
              ? [const Color(0xFF1C1C24), const Color(0xFF3D3D4D)]
              : [const Color(0xFFECEFF1), const Color(0xFFA8B5BC)],
          burstCore: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF2D2D38),
          burstAccent: isDark ? const Color(0xFFA0AFC0) : const Color(0xFF6C7A89),
        );
      case Mood.defaultMood:
        return MoodPalette(
          primary: const Color(0xFF5C6BC0),
          secondary: const Color(0xFF9FA8DA),
          background: isDark ? const Color(0xFF0A0E1F) : const Color(0xFFEEF0FA),
          surface: isDark ? const Color(0xFF161B33) : const Color(0xFFD6DBF0),
          textPrimary: isDark ? const Color(0xFFE8EAF6) : const Color(0xFF161B33),
          textSecondary: isDark ? const Color(0xFF9FA8DA) : const Color(0xFF5C6BC0),
          moonColor: const Color(0xFFF5F5F0),
          moonGlow: const Color(0xFFE8E8D8),
          skyGradient: isDark
              ? [const Color(0xFF0A0E1F), const Color(0xFF252B4A)]
              : [const Color(0xFFEEF0FA), const Color(0xFFB4BDE0)],
          burstCore: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF161B33),
          burstAccent: isDark ? const Color(0xFF9FA8DA) : const Color(0xFF5C6BC0),
        );
    }
  }

  /// Builds the actual ThemeData from a mood + brightness.
  static ThemeData buildTheme(Mood mood, Brightness brightness) {
    final p = palette(mood, brightness);
    final isDark = brightness == Brightness.dark;

    final textTheme = GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      primaryColor: p.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: Colors.white,
        secondary: p.secondary,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        background: p.background,
        onBackground: p.textPrimary,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: p.textSecondary.withOpacity(0.6)),
      ),
    );
  }
}
