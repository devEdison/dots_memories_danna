import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores principales de la paleta de 15 años de Danna (Rose Gold & Champagne)
  static const Color primaryRose = Color(0xFFC75D76);
  static const Color primaryDarkRose = Color(0xFF96354B);
  static const Color softBlush = Color(0xFFFFF0F3);
  static const Color palePink = Color(0xFFFAF2F5);
  static const Color champagneGold = Color(0xFFD4AF37);
  static const Color warmGold = Color(0xFFE5C378);
  static const Color deepPlum = Color(0xFF28141E);
  static const Color charcoal = Color(0xFF33292E);
  static const Color mutedText = Color(0xFF75626A);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF0DFE4);

  // Gradientes
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF7F9),
      Color(0xFFFBE4EB),
      Color(0xFFF7D5E0),
    ],
  );

  static const LinearGradient roseGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD47A8E),
      Color(0xFFC75D76),
      Color(0xFFB54862),
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFDF79),
      Color(0xFFD4AF37),
      Color(0xFF9E7C1B),
    ],
  );

  static const LinearGradient folderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xCC28141E),
    ],
  );

  static ThemeData get themeData {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRose,
        primary: primaryRose,
        secondary: champagneGold,
        surface: cardBg,
        surfaceContainerHighest: softBlush,
        onPrimary: Colors.white,
        onSurface: charcoal,
      ),
      scaffoldBackgroundColor: palePink,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: deepPlum,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: deepPlum,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: deepPlum,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: deepPlum,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          color: charcoal,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          color: mutedText,
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRose,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryRose.withAlpha(90),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRose,
          side: const BorderSide(color: primaryRose, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryRose, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          color: mutedText.withAlpha(160),
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shadowColor: primaryRose.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
    );
  }
}
