import 'package:flutter/material.dart';

class AppColors {
  // Paleta Industrial/Profesional basada en tu Figma
  static const Color primary = Color(0xFF0F172A);      // Azul petróleo profundo
  static const Color accent = Color(0xFFF59E0B);       // Ámbar construcción (Principal)
  static const Color background = Color(0xFFF1F5F9);   // Fondo gris muy claro
  static const Color surface = Colors.white; 
  static const Color actionButton = Color(0xFFF59E0B); // El ámbar de tu diseño
          // Fondo de tarjetas y paneles
  
  static const Color textPrimary = Color(0xFF0F172A);  // Texto principal (Azul oscuro)
  static const Color textSecondary = Color(0xFF64748B);// Texto secundario (Gris)
  static const Color border = Color(0xFFE2E8F0);       // Bordes sutiles

  // Estados semánticos
  static const Color success = Color(0xFF10B981);      // Verde
  static const Color warning = Color(0xFFF59E0B);      // Ámbar
  static const Color error = Color(0xFFEF4444);        // Rojo
  static const Color info = Color(0xFF3B82F6);         // Azul
  
  // Fondos claros para estados (Útiles para Chips/Badges)
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color infoBg = Color(0xFFDBEAFE);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,

      // Esto hace que toda la app use una tipografía mucho más moderna por defecto
    textTheme: Typography.material2021().englishLike.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: 'Roboto', // Flutter usa Roboto, pero el material2021 mejora el espaciado
    ),
      
      // Esquema de colores para componentes Material 3
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      
      // AppBar profesional
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // Botones con estilo moderno
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // Inputs de formularios limpios
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      
      // Tarjetas modernas sin sombras excesivas
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      
      // Chips para estados
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}