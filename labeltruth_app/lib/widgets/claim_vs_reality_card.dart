import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/scan_result.dart';

class ClaimVsRealityCard extends StatelessWidget {
  final ClaimComparison comparison;

  const ClaimVsRealityCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final isViolation = comparison.status == 'violation';
    final isMisleading = comparison.status == 'misleading';
    final statusColor = isViolation
        ? AppColors.criticalRed
        : (isMisleading ? AppColors.warningAmber : AppColors.truthGreen);

    final statusIcon = isViolation
        ? Icons.cancel_outlined
        : (isMisleading ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded);

    final statusLabel = isViolation
        ? "DECEPTIVE CLAIM"
        : (isMisleading ? "MISLEADING" : "VERIFIED TRUE");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Claim Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📢 ", style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Front-of-Pack Claim:",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "\"${comparison.frontClaim}\"",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.surfaceLightDark, height: 1),
                ),

                // Reality Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isViolation ? "❌ " : (isMisleading ? "⚠️ " : "✅ "),
                      style: const TextStyle(fontSize: 14),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Audit / Lab Reality:",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comparison.realityFinding,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isViolation ? const Color(0xFFFCA5A5) : AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (comparison.explanation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      comparison.explanation,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondaryDark,
                        height: 1.4,
                      ),
                    ),
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
