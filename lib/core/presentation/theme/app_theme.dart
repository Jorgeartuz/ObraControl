import 'package:flutter/material.dart';

class AppColors {
  // Paleta Industrial/Profesional
  static const Color primary = Color(0xFF1E293B); // Azul petróleo profundo
  static const Color accent = Color(0xFFF59E0B); // Ámbar construcción
  static const Color background = Color(0xFFF1F5F9); // Gris muy claro (fondo)
  static const Color surface = Colors.white; // Fondo de tarjetas
  static const Color textPrimary = Color(0xFF0F172A); // Texto principal
  static const Color textSecondary = Color(0xFF64748B); // Texto secundario
  static const Color border = Color(0xFFE2E8F0); // Bordes sutiles

  // Estados semánticos
  static const Color success = Color(0xFF10B981); // Verde
  static const Color warning = Color(0xFFF59E0B); // Ámbar
  static const Color error = Color(0xFFEF4444); // Rojo
  static const Color info = Color(0xFF3B82F6); // Azul
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // AppBar profesional
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),

      // Botones con estilo moderno
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Inputs de formularios limpios
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),

      // Tarjetas modernas sin sombras excesivas
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
