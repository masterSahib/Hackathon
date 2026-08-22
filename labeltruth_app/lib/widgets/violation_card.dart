import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/scan_result.dart';

class ViolationCard extends StatelessWidget {
  final ViolationItem violation;

  const ViolationCard({super.key, required this.violation});

  @override
  Widget build(BuildContext context) {
    Color sevColor;
    switch (violation.severity.toLowerCase()) {
      case 'critical':
        sevColor = AppColors.criticalRed;
        break;
      case 'high':
        sevColor = const Color(0xFFEA580C);
        break;
      case 'medium':
      default:
        sevColor = AppColors.warningAmber;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sevColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sevColor.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.gavel_rounded, color: sevColor, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    violation.regulationReference,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sevColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: sevColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    violation.severity.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  violation.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  violation.auditFinding,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                    height: 1.4,
                  ),
                ),
                if (violation.recommendation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("💡 ", style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          violation.recommendation,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
