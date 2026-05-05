import 'package:flutter/material.dart';

class AppTheme {
  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1E40AF);
  static const Color green = Color(0xFF10B981);
  static const Color bg = Color(0xFFF9FAFB);
  static const Color textDark = Color(0xFF111827);
  static const Color textMid = Color(0xFF374151);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color red = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);

  // Cores dos medicamentos por índice
  static const List<Color> medColors = [
    Color(0xFF2563EB), // azul
    Color(0xFF14B8A6), // teal
    Color(0xFFEAB308), // amarelo
    Color(0xFF9333EA), // roxo
    Color(0xFFEC4899), // rosa
  ];

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: bg,
        primaryColor: blue,
        colorScheme: const ColorScheme.light(primary: blue, secondary: green),
      );
}
