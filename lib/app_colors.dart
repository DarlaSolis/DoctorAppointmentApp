import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF89CFF0);
  static const Color primaryPurple = Color(0xFFC8A2C8);
  static const Color accentBlue = Color(0xFFB6D0E2);
  static const Color accentPurple = Color(0xFFD8BFD8);
  static const Color background = Color(0xFFF8F9FF);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF89CFF0), Color(0xFFC8A2C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF89CFF0), Color(0xFFA7C7E7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8F9FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppShadows {
  static const BoxShadow softShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 10,
    offset: Offset(0, 4),
    spreadRadius: 1,
  );

  static const BoxShadow mediumShadow = BoxShadow(
    color: Colors.black26,
    blurRadius: 15,
    offset: Offset(0, 6),
    spreadRadius: 1,
  );
}
