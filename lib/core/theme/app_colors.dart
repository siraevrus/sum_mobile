import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2C5CCF);
  static const Color success = Color(0xFF38A169);  
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFD69E2E);
  static const Color info = Color(0xFF3182CE);
  
  static const Color background = Color(0xFFF7FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  
  // Градиенты
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1E4B9C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
