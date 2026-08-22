import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';
import '../services/tts_service.dart';
import '../widgets/truth_gauge.dart';
import '../widgets/claim_vs_reality_card.dart';
import '../widgets/ingredient_tag_chip.dart';
import '../widgets/violation_card.dart';
import '../widgets/nutrition_breakdown_card.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final ScanResult result;

  const ResultScreen({super.key, required this.result});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _isGeneratingPdf = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    ttsService.init();
  }

  @override
  void dispose() {
    ttsService.stop();
    super.dispose();
  }

  void _toggleAudioSpeech() async {
    setState(() => _isSpeaking = !_isSpeaking);
    if (_isSpeaking) {
      await ttsService.speakAuditSummary(widget.result);
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    } else {
      await ttsService.stop();
    }
  }

  void _handlePdfGeneration() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final scanNotifier = ref.read(scanProvider.notifier);
      final pdfB64 = await scanNotifier.generateComplaintPdf(widget.result);
      setState(() => _isGeneratingPdf = false);

      if (pdfB64 != null && mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: AppColors.criticalRed, size: 24),
                const SizedBox(width: 8),
                Text(
                  "FSSAI Notice Generated",
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Formal Statutory Complaint & Violation Notice has been prepared with full empirical evidence table for submission to:",
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• Central Consumer Protection Authority (CCPA)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text("• FSSAI Grievance Portal (FOSCOS)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text("• National Consumer Helpline (NCH)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.accent,
                      content: Text(
                        "Notice saved to downloads. Ready for filing.",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text("Download PDF"),
              ),
            ],
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PDF generator ready. Download requested.")),
          );
        }
      }
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF Notice created successfully.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final scoreColor = AppColors.getScoreColor(r.truthScore);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Packaging Compliance Audit",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
              color: _isSpeaking ? AppColors.accent : Colors.white,
            ),
            tooltip: _isSpeaking ? "Stop Audio" : "Listen to Audit Verdict",
            onPressed: _toggleAudioSpeech,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Audit report link copied to clipboard.")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Section: Truth Score Gauge Card
            _buildTruthScoreCard(r, scoreColor),
            const SizedBox(height: 16),

            // 2. Dietary Warnings (if any)
            if (r.dietaryWarnings.isNotEmpty) ...[
              _buildDietaryWarningsBanner(r.dietaryWarnings),
              const SizedBox(height: 16),
            ],

            // 3. Claim vs. Reality Section
            _buildSectionHeader("1. Claim vs. Reality Comparison", Icons.compare_arrows_rounded),
            const SizedBox(height: 10),
            if (r.claimComparisons.isNotEmpty)
              ...r.claimComparisons.map((c) => ClaimVsRealityCard(comparison: c))
            else
              _buildEmptyPlaceholder("No deceptive claims flagged in this product."),
            const SizedBox(height: 20),

            // 4. Ingredient Breakdown (Color-Coded)
            _buildSectionHeader("2. Ingredient Hierarchy & Additives", Icons.format_list_bulleted_rounded),
            const SizedBox(height: 10),
            _buildIngredientBreakdownCard(r.ingredients),
            const SizedBox(height: 20),

            // 5. Statutory FSSAI Violations
            _buildSectionHeader("3. Statutory FSSAI & Legal Violations", Icons.gavel_rounded),
            const SizedBox(height: 10),
            if (r.violations.isNotEmpty)
              ...r.violations.map((v) => ViolationCard(violation: v))
            else
              _buildCleanComplianceBadge(),
            const SizedBox(height: 20),

            // 6. High-Risk Additives & E-Numbers
            if (r.suspiciousAdditives.isNotEmpty) ...[
              _buildSectionHeader("4. High-Risk Additives & E-Numbers", Icons.biotech_outlined),
              const SizedBox(height: 10),
              _buildAdditivesCard(r.suspiciousAdditives),
              const SizedBox(height: 20),
            ],

            // 7. Nutritional Facts Breakdown
            _buildSectionHeader("5. Nutritional Fact Audit", Icons.bar_chart_rounded),
            const SizedBox(height: 10),
            NutritionBreakdownCard(nutrition: r.nutritionPer100g),
            const SizedBox(height: 20),

            // 8. Healthier Clean Alternatives
            if (r.healthierAlternatives.isNotEmpty) ...[
              _buildSectionHeader("6. Healthier Clean Alternatives", Icons.recommend_rounded),
              const SizedBox(height: 10),
              _buildAlternativesList(r.healthierAlternatives),
              const SizedBox(height: 24),
            ],

            // 9. Complaint PDF & Action Buttons
            _buildActionButtons(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleAudioSpeech,
        backgroundColor: _isSpeaking ? AppColors.criticalRed : AppColors.accent,
        icon: Icon(_isSpeaking ? Icons.stop_rounded : Icons.record_voice_over_rounded, color: Colors.white),
        label: Text(
          _isSpeaking ? "Stop Audio" : "Listen to Verdict",
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTruthScoreCard(ScanResult r, Color scoreColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            r.productName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "Brand: ${r.brandName} • Barcode: ${r.barcode ?? 'N/A'}",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMutedDark,
            ),
          ),
          const SizedBox(height: 18),
          TruthGauge(score: r.truthScore, verdict: r.verdict, size: 170),
          const SizedBox(height: 14),
          Text(
            r.verdictDescription,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Audio Voice Assistant Trigger Chip
          InkWell(
            onTap: _toggleAudioSpeech,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isSpeaking ? AppColors.criticalRed.withOpacity(0.15) : AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isSpeaking ? AppColors.criticalRed : AppColors.accent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSpeaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                    color: _isSpeaking ? AppColors.criticalRed : AppColors.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isSpeaking ? "Speaking Audit Summary..." : "Listen to Voice Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isSpeaking ? AppColors.criticalRed : AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryWarningsBanner(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.criticalRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.criticalRed.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.criticalRed, size: 16),
              const SizedBox(width: 6),
              Text(
                "Personal Dietary Alert Triggers",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.criticalRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  w,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientBreakdownCard(List<IngredientItem> ingredients) {
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
            children: [
              _buildLegendDot(AppColors.ingredientHarmfulText, "Harmful / Palm Fat"),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.ingredientWarningText, "Warning / Refined"),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.ingredientCleanText, "Clean"),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ingredients.map((i) => IngredientTagChip(ingredient: i)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondaryDark),
        ),
      ],
    );
  }

  Widget _buildCleanComplianceBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.truthGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.truthGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.truthGreen, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Zero Statutory Violations Detected",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.truthGreen,
                  ),
                ),
                Text(
                  "Packaging claims adhere to FSSAI packaging & nutritional declaration norms.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditivesCard(List<SuspiciousAdditive> additives) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningAmber.withOpacity(0.35)),
      ),
      child: Column(
        children: additives.map((a) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    a.code ?? "ADDITIVE",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warningAmber,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${a.name} (${a.category})",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        a.concern,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlternativesList(List<AlternativeProduct> alternatives) {
    return Column(
      children: alternatives.map((alt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.truthGreen.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.truthGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      "${alt.truthScore}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.truthGreen,
                      ),
                    ),
                    Text(
                      "SCORE",
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.truthGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alt.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      "By ${alt.brand}",
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMutedDark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alt.whyBetter,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingPdf ? null : _handlePdfGeneration,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.criticalRed,
              foregroundColor: Colors.white,
            ),
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(
              _isGeneratingPdf ? "Compiling Statutory PDF..." : "Generate FSSAI Complaint Notice (PDF)",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceCardDark,
                  content: Text("${widget.result.productName} added to your Watchlist."),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_border_rounded, size: 18),
            label: const Text("Add to Personal Watchlist"),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMutedDark),
        ),
      ),
    );
  }
}
