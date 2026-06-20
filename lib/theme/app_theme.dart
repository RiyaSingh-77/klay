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

      // GoogleFonts.xTextTheme() takes Flutter's default TextTheme and
      // swaps every style's fontFamily — this is what makes Text widgets
      // across the WHOLE app use the new fonts without touching each one.
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

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}