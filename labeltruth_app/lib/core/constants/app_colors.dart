import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF0F172A);      // Deep Slate Navy
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color accent = Color(0xFF10B981);       // Truth Green
  static const Color accentGradientStart = Color(0xFF059669);
  static const Color accentGradientEnd = Color(0xFF10B981);

  // Truth Score Tier Colors
  static const Color truthGreen = Color(0xFF10B981);    // 80-100 Verified
  static const Color warningAmber = Color(0xFFF59E0B);  // 50-79 Misleading
  static const Color criticalRed = Color(0xFFEF4444);   // 0-49 Violates Standards

  // Backgrounds & Surfaces
  static const Color backgroundDark = Color(0xFF0B0F17);
  static const Color surfaceDark = Color(0xFF131B2A);
  static const Color surfaceCardDark = Color(0xFF1E293B);
  static const Color surfaceLightDark = Color(0xFF334155);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Ingredient Category Colors
  static const Color ingredientCleanBg = Color(0x1A10B981);
  static const Color ingredientCleanText = Color(0xFF10B981);
  static const Color ingredientCleanBorder = Color(0x3310B981);

  static const Color ingredientWarningBg = Color(0x1AF59E0B);
  static const Color ingredientWarningText = Color(0xFFF59E0B);
  static const Color ingredientWarningBorder = Color(0x33F59E0B);

  static const Color ingredientHarmfulBg = Color(0x1AEF4444);
  static const Color ingredientHarmfulText = Color(0xFFEF4444);
  static const Color ingredientHarmfulBorder = Color(0x33EF4444);

  // Helper method for dynamic truth color
  static Color getScoreColor(int score) {
    if (score >= 80) return truthGreen;
    if (score >= 50) return warningAmber;
    return criticalRed;
  }

  static String getVerdictTitle(int score) {
    if (score >= 80) return "Verified Clean";
    if (score >= 50) return "Misleading Claims";
    return "Violates Standards";
  }
}
