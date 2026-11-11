import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta Verde Salvia y Rosado para los 15 Años de Danna
  static const Color sageGreen = Color(0xFF6E8B74);
  static const Color sageDark = Color(0xFF4B6651);
  static const Color sageDeep = Color(0xFF334A38);
  static const Color sageLight = Color(0xFFEDF3EE);
  static const Color sageSoft = Color(0xFFDFE9E0);
  static const Color sageBorder = Color(0xFFCCDACC);

  static const Color blushPink = Color(0xFFE598A8);
  static const Color dustyPink = Color(0xFFCF7B8D);
  static const Color deepRose = Color(0xFFB3576C);
  static const Color palePink = Color(0xFFFDF2F4);
  static const Color softPinkBg = Color(0xFFFCEDF0);
  static const Color pinkBorder = Color(0xFFF5D6DE);

  static const Color warmGold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF8EDC2);
  static const Color goldDeep = Color(0xFFA88225);
  static const Color goldBorder = Color(0xFFE4CF82);
  static const Color goldGlow = Color(0x40D4AF37);
  static const Color charcoal = Color(0xFF263328);
  static const Color mutedText = Color(0xFF5D7061);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF7FBF8);
  static const Color borderLight = Color(0xFFE4ECE5);

  // Gradientes armónicos Verde Salvia, Rosado & Dorado para 15 Años
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF6FAF6), // Blanco Salvia
      Color(0xFFEFF5F0), // Salvia Suave
      Color(0xFFFDF1F4), // Toque Rosado
      Color(0xFFFCF9ED), // Toque Dorado suave
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5E4A8),
      Color(0xFFD4AF37),
      Color(0xFFA88225),
    ],
  );

  static const LinearGradient sageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7E9B84),
      Color(0xFF6E8B74),
      Color(0xFF4B6651),
    ],
  );

  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0AAB8),
      Color(0xFFE598A8),
      Color(0xFFCF7B8D),
    ],
  );

  static const LinearGradient sagePinkBlend = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF6E8B74),
      Color(0xFFE598A8),
    ],
  );

  static const LinearGradient royalQuinceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4B6651), // Salvia
      Color(0xFFB3576C), // Rosado
      Color(0xFFB59332), // Dorado
    ],
  );

  static ThemeData get themeData {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sageGreen,
        primary: sageGreen,
        secondary: blushPink,
        surface: cardBg,
        surfaceContainerHighest: sageLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: charcoal,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7FAF7),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: sageDeep,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: sageDeep,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: sageDeep,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: sageDeep,
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
          backgroundColor: sageGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: sageGreen.withAlpha(90),
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
          foregroundColor: sageGreen,
          side: const BorderSide(color: sageGreen, width: 1.5),
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
          borderSide: const BorderSide(color: sageBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sageBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sageGreen, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          color: mutedText.withAlpha(160),
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shadowColor: sageGreen.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
    );
  }
}
