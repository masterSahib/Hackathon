import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/scan_result.dart';

class IngredientTagChip extends StatelessWidget {
  final IngredientItem ingredient;

  const IngredientTagChip({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color border;
    IconData icon;

    switch (ingredient.category.toLowerCase()) {
      case 'harmful':
        bg = AppColors.ingredientHarmfulBg;
        textColor = AppColors.ingredientHarmfulText;
        border = AppColors.ingredientHarmfulBorder;
        icon = Icons.dangerous_outlined;
        break;
      case 'warning':
        bg = AppColors.ingredientWarningBg;
        textColor = AppColors.ingredientWarningText;
        border = AppColors.ingredientWarningBorder;
        icon = Icons.warning_amber_rounded;
        break;
      case 'clean':
      default:
        bg = AppColors.ingredientCleanBg;
        textColor = AppColors.ingredientCleanText;
        border = AppColors.ingredientCleanBorder;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    String label = ingredient.name;
    if (ingredient.percentage != null) {
      label += " (${ingredient.percentage}%)";
    }
    if (ingredient.insCode != null) {
      label += " [${ingredient.insCode}]";
    }

    return InkWell(
      onTap: () {
        if (ingredient.flagReason != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceCardDark,
              duration: const Duration(seconds: 4),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ingredient.flagReason!,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
