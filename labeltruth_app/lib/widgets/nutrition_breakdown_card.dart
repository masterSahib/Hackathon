import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/scan_result.dart';

class NutritionBreakdownCard extends StatelessWidget {
  final NutritionPer100g nutrition;

  const NutritionBreakdownCard({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Nutritional Facts (per 100g)",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${nutrition.energyKcal.round()} kcal",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNutrientRow(
            label: "Total Sugars",
            value: "${nutrition.totalSugarG}g",
            subtext: "Added: ${nutrition.addedSugarG}g",
            isWarning: nutrition.addedSugarG > 10.0 || nutrition.totalSugarG > 15.0,
            progress: (nutrition.totalSugarG / 50.0).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 8),
          _buildNutrientRow(
            label: "Total Fats",
            value: "${nutrition.totalFatG}g",
            subtext: "Saturated: ${nutrition.saturatedFatG}g",
            isWarning: nutrition.saturatedFatG > 6.0,
            progress: (nutrition.totalFatG / 40.0).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 8),
          _buildNutrientRow(
            label: "Protein",
            value: "${nutrition.proteinG}g",
            subtext: "${((nutrition.proteinG * 4 / (nutrition.energyKcal > 0 ? nutrition.energyKcal : 400)) * 100).toStringAsFixed(1)}% energy",
            isPositive: nutrition.proteinG >= 10.0,
            progress: (nutrition.proteinG / 30.0).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 8),
          _buildNutrientRow(
            label: "Sodium",
            value: "${nutrition.sodiumMg.round()}mg",
            subtext: nutrition.sodiumMg > 400 ? "High Sodium" : "Moderate",
            isWarning: nutrition.sodiumMg > 400.0,
            progress: (nutrition.sodiumMg / 1000.0).clamp(0.0, 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow({
    required String label,
    required String value,
    required String subtext,
    bool isWarning = false,
    bool isPositive = false,
    required double progress,
  }) {
    final barColor = isWarning
        ? AppColors.criticalRed
        : (isPositive ? AppColors.truthGreen : AppColors.accent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryDark,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isWarning ? AppColors.criticalRed : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "($subtext)",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
