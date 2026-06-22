import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// AppTheme is the single source of truth for colors and typography.
// Using GoogleFonts instead of the default Material font gives the app a
// consistent, intentional look across Android/iOS/Web instead of falling
// back to each platform's system font (Roboto on Android, San Francisco
// on iOS) — that inconsistency is exactly what GoogleFonts solves.
class AppTheme {
  static const Color primary = Color(0xFFC8553D);     // terracotta
  static const Color background = Color(0xFFFAF3E8);  // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2B2420);

  // Generic Material grays (Colors.black54, black45, black38, black26)
  // were scattered across widgets/screens for secondary text and faint
  // icons. Those are neutral grays with a cool/blue undertone, which
  // visibly clashes against the warm cream background and terracotta
  // accent everywhere else in the app — most noticeable on long screens
  // like Author Profile or Library where a lot of muted text is visible
  // at once. textMuted/textFaint replace them with warm-toned grays
  // derived from textDark, so secondary content recedes without fighting
  // the rest of the palette.
  static const Color textMuted = Color(0xFF8A7E73);  // secondary text (was black54/black45)
  static const Color textFaint = Color(0xFFC2B7AB);  // disabled/faint icons (was black38/black26/black12)

  // A dedicated delete/destructive color instead of stock Colors.red —
  // same purpose (clearly reads as "destructive"), but warmed slightly
  // toward the terracotta family so it reads as part of this app's
  // palette rather than a generic Material red dropped in unchanged.
  static const Color error = Color(0xFFC44536);

  static ThemeData get lightTheme {
    // Three-tier type system, Poppins for headings (bold, distinctive), Inter for body
    // text (highly readable at small sizes), Roboto for buttons (neutral,
    // works well in all-caps UI labels).
    final headingStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: textDark,
    );
    final bodyStyle = GoogleFonts.inter(color: textDark);
    final buttonStyle = GoogleFonts.roboto(fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),

      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: headingStyle.copyWith(fontSize: 32),
        headlineMedium: headingStyle.copyWith(fontSize: 24),
        headlineSmall: headingStyle.copyWith(fontSize: 20),
        titleLarge: headingStyle.copyWith(fontSize: 18),
        bodyLarge: bodyStyle.copyWith(fontSize: 16),
        bodyMedium: bodyStyle.copyWith(fontSize: 14),
        labelLarge: buttonStyle.copyWith(fontSize: 14, letterSpacing: 0.5),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textDark,
        elevation: 0,
        titleTextStyle: headingStyle.copyWith(fontSize: 20),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: buttonStyle.copyWith(fontSize: 15),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: buttonStyle.copyWith(fontSize: 15),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        indicatorColor: primary,
        labelStyle: buttonStyle.copyWith(fontSize: 13, letterSpacing: 0.5),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}