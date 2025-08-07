import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors ---
  static const Color primaryColor = Color(0xFFFACC15); // Yellow
  static const Color secondaryColor = Color(0xFF4CAF50); // Green
  static const Color accentColor = Color(0xFF333333); // Dark Grey for text
  static const Color backgroundColor = Color(0xFFFEFCE8); // Light Yellow
  static const Color surfaceColor = Color(0xFFFFFFFF); // White

  // --- Text Theme ---
  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.bold, color: accentColor),
    headlineMedium: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w600, color: accentColor),
    titleLarge: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600, color: accentColor),
    bodyLarge: GoogleFonts.poppins(
        fontSize: 16, color: accentColor, height: 1.5),
    bodyMedium: GoogleFonts.poppins(fontSize: 14, color: accentColor),
    labelLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
  );

  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: Colors.redAccent,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: accentColor,
      onBackground: accentColor,
    ),
    textTheme: _textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _textTheme.titleLarge?.copyWith(color: accentColor),
      iconTheme: const IconThemeData(color: accentColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryColor, width: 2.0),
      ),
      labelStyle: _textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
      hintStyle: _textTheme.bodyMedium?.copyWith(color: Colors.grey.shade400),
    ),
  );
}