import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PennyWiseTheme {
  // Brand Color Palette Mapping - Matched to new mockups
  static const Color primaryGreen = Color(0xFF006D37); // Deep Brand Green
  static const Color primaryContainerGreen = Color(0xFF2ECC71); // Vibrant Active Green
  static const Color onPrimaryContainerGreen = Color(0xFF00210C); // Dark text on active green

  static const Color secondaryBlue = Color(0xFF5CB8FD); // Chart Blue
  static const Color tertiaryCoral = Color(0xFFFF9687); // Chart Coral/Expense Red

  // Light Mode Surfaces
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white cards
  static const Color onSurfaceColor = Color(0xFF191C1D); // Near black text
  static const Color onSurfaceVariantColor = Color(0xFF5A635E); // Grey subtitle text

  // Dark Mode Surfaces (Charcoal Aesthetic)
  static const Color darkBackgroundColor = Color(0xFF121212); // Deep background
  static const Color darkSurfaceColor = Color(0xFF1E1E1E); // Elevated cards
  static const Color darkSurfaceContainerHigh = Color(0xFF2C2C2C); // Inputs/Chips
  static const Color darkOnSurfaceColor = Color(0xFFE1E3E4); // Off-white text
  static const Color darkOnSurfaceVariantColor = Color(0xFFA0AAB2); // Light grey subtitle

  // Shape Configuration
  static final BorderRadius roundedMd = BorderRadius.circular(16.0);
  static final BorderRadius roundedLg = BorderRadius.circular(24.0); // Softened from 32
  static final BorderRadius roundedXl = BorderRadius.circular(40.0);

  // Shared Text Theme (Google Fonts)
  static TextTheme _buildTextTheme(Color textColor, Color variantColor) {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: textColor),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: textColor),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: variantColor),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: textColor),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: variantColor),
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        primaryContainer: primaryContainerGreen,
        onPrimaryContainer: onPrimaryContainerGreen,
        secondary: secondaryBlue,
        tertiary: tertiaryCoral,
        surface: surfaceColor,
        surfaceContainerHighest: Color(0xFFE8ECE9),
        onSurface: onSurfaceColor,
        onSurfaceVariant: onSurfaceVariantColor,
        error: Color(0xFFB4271D),
        errorContainer: Color(0xFFFFDAD6),
      ),
      textTheme: _buildTextTheme(onSurfaceColor, onSurfaceVariantColor),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: roundedLg),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8ECE9), thickness: 1),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryContainerGreen,
        onPrimary: Color(0xFF00210C),
        primaryContainer: primaryGreen, // Inverted for dark mode pop
        onPrimaryContainer: Colors.white,
        secondary: secondaryBlue,
        tertiary: tertiaryCoral,
        surface: darkSurfaceColor,
        surfaceContainerHighest: darkSurfaceContainerHigh,
        onSurface: darkOnSurfaceColor,
        onSurfaceVariant: darkOnSurfaceVariantColor,
        error: Color(0xFFFFB4AB),
        errorContainer: Color(0xFF93000A),
      ),
      textTheme: _buildTextTheme(darkOnSurfaceColor, darkOnSurfaceVariantColor),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: roundedLg),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceColor,
      ),
      dividerTheme: const DividerThemeData(color: darkSurfaceContainerHigh, thickness: 1),
    );
  }
}