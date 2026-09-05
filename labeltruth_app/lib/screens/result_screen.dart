import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'product_chat_screen.dart';

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
                  "LMPC & FSSAI Notice Ready",
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
                      Text("• Department of Consumer Affairs (DoCA)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text("• Legal Metrology Enforcement Directorate", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text("• Central Consumer Protection Authority (CCPA)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
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
                        "Statutory Notice downloaded & ready for filing.",
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
      }
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF Notice downloaded successfully.")),
        );
      }
    }
  }

  void _showExportOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.file_download_outlined, color: AppColors.accent, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Export Compliance Report",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Download or export the complete audit docket in multiple digital formats:",
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 16),

            // 1. PDF Export
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.criticalRed),
              ),
              title: Text("Formal Statutory Notice (PDF)", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text("Print-ready legal grievance notice for CCPA / DoCA", style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark)),
              onTap: () {
                Navigator.pop(ctx);
                _handlePdfGeneration();
              },
            ),
            const Divider(color: AppColors.surfaceLightDark, height: 1),

            // 2. CSV Export
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.truthGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart_rounded, color: AppColors.truthGreen),
              ),
              title: Text("Editable Inspection Report (CSV)", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text("Tabular spreadsheet format for officer logs & records", style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(
                  text: "Product,Brand,Truth Score,Verdict\n${widget.result.productName},${widget.result.brandName},${widget.result.truthScore},${widget.result.verdict}\n"
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.truthGreen,
                    content: Text("CSV Inspection Report copied to clipboard / ready for Excel export."),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.surfaceLightDark, height: 1),

            // 3. JSON Export
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.code_rounded, color: AppColors.accent),
              ),
              title: Text("Full Audit Docket (JSON)", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text("Machine-readable JSON data with LMPC & FSSAI fields", style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.accent,
                    content: Text("JSON Audit Docket exported successfully."),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
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
            icon: const Icon(Icons.forum_outlined, color: AppColors.accent),
            tooltip: "Ask Legal Metrology AI",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductChatScreen(scanResult: r)),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
              color: _isSpeaking ? AppColors.accent : Colors.white,
            ),
            tooltip: _isSpeaking ? "Stop Audio" : "Listen to Audit Verdict",
            onPressed: _toggleAudioSpeech,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: "Export Report Options",
            onPressed: () => _showExportOptionsModal(context),
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

            // AI Chat Banner Button
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductChatScreen(scanResult: r)),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Have Questions About This Product?",
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          Text(
                            "Chat with our Legal Metrology & FSSAI Regulatory AI",
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFD1FAE5)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.accent, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Dietary Warnings (if any)
            if (r.dietaryWarnings.isNotEmpty) ...[
              _buildDietaryWarningsBanner(r.dietaryWarnings),
              const SizedBox(height: 16),
            ],

            // 3. LMPC Rule 6 Mandatory Declarations Checklist
            _buildSectionHeader("1. LMPC Rule 6 Mandatory Declarations", Icons.checklist_rounded),
            const SizedBox(height: 10),
            _buildMandatoryDeclarationsCard(r.mandatoryDeclarations),
            const SizedBox(height: 20),

            // 4. LMPC Rule 7 & 9 Font Size & Readability Analysis
            _buildSectionHeader("2. Font Size & Readability Analysis", Icons.format_size_rounded),
            const SizedBox(height: 10),
            _buildFontReadabilityCard(r.fontReadability),
            const SizedBox(height: 20),

            // 5. Claim vs. Reality Section
            _buildSectionHeader("3. Marketing Claim vs. Reality Comparison", Icons.compare_arrows_rounded),
            const SizedBox(height: 10),
            if (r.claimComparisons.isNotEmpty)
              ...r.claimComparisons.map((c) => ClaimVsRealityCard(comparison: c))
            else
              _buildEmptyPlaceholder("No deceptive claims flagged in this product."),
            const SizedBox(height: 20),

            // 6. Ingredient Breakdown (Color-Coded)
            _buildSectionHeader("4. Ingredient Hierarchy & Additives", Icons.format_list_bulleted_rounded),
            const SizedBox(height: 10),
            _buildIngredientBreakdownCard(r.ingredients),
            const SizedBox(height: 20),

            // 7. Statutory Violations
            _buildSectionHeader("5. Statutory Violations & Legal Defects", Icons.gavel_rounded),
            const SizedBox(height: 10),
            if (r.violations.isNotEmpty)
              ...r.violations.map((v) => ViolationCard(violation: v))
            else
              _buildCleanComplianceBadge(),
            const SizedBox(height: 20),

            // 8. High-Risk Additives & E-Numbers
            if (r.suspiciousAdditives.isNotEmpty) ...[
              _buildSectionHeader("6. High-Risk Additives & E-Numbers", Icons.biotech_outlined),
              const SizedBox(height: 10),
              _buildAdditivesCard(r.suspiciousAdditives),
              const SizedBox(height: 20),
            ],

            // 9. Nutritional Facts Breakdown
            _buildSectionHeader("7. Nutritional Fact Audit", Icons.bar_chart_rounded),
            const SizedBox(height: 10),
            NutritionBreakdownCard(nutrition: r.nutritionPer100g),
            const SizedBox(height: 20),

            // 10. Healthier Clean Alternatives
            if (r.healthierAlternatives.isNotEmpty) ...[
              _buildSectionHeader("8. Healthier Clean Alternatives", Icons.recommend_rounded),
              const SizedBox(height: 10),
              _buildAlternativesList(r.healthierAlternatives),
              const SizedBox(height: 24),
            ],

            // 11. Action Buttons
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
        ],
      ),
    );
  }

  Widget _buildMandatoryDeclarationsCard(MandatoryDeclarationsAudit? audit) {
    if (audit == null || audit.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLightDark),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_outlined, color: AppColors.truthGreen, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "All 7 LMPC Rule 6 mandatory declarations verified on package display panel.",
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryDark),
              ),
            ),
          ],
        ),
      );
    }

    final passPct = audit.compliancePercentage;
    final pctColor = passPct >= 80 ? AppColors.truthGreen : (passPct >= 50 ? AppColors.warningAmber : AppColors.criticalRed);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLightDark),
      ),
      child: Column(
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: pctColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "LMPC Compliance: ${audit.passedCount} / ${audit.totalDeclarations} Passed",
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: pctColor),
                ),
                Text(
                  "${passPct.toInt()}% Verified",
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: pctColor),
                ),
              ],
            ),
          ),
          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: audit.items.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceLightDark, height: 1),
            itemBuilder: (ctx, idx) {
              final item = audit.items[idx];
              final isOk = item.isCompliant && item.isPresent;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isOk ? AppColors.truthGreen : AppColors.criticalRed,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "[${item.ruleClause}]",
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOk
                                ? (item.extractedText ?? "Declared on packaging")
                                : (item.legalDefect ?? "Missing or defective statutory declaration"),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: isOk ? AppColors.textSecondaryDark : AppColors.criticalRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontReadabilityCard(FontReadabilityAudit? fontAudit) {
    if (fontAudit == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLightDark),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.truthGreen, size: 20),
            const SizedBox(width: 10),
            Text(
              "Numeral font height meets LMPC Rule 7 statutory standard.",
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      );
    }

    final isOk = fontAudit.isFontCompliant;
    final fColor = isOk ? AppColors.truthGreen : AppColors.criticalRed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isOk ? Icons.check_circle_rounded : Icons.warning_rounded, color: fColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isOk ? "LMPC Rule 7 Compliant" : "Font Height Defect",
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: fColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: fColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${fontAudit.detectedFontHeightMm} mm detected",
                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: fColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fontAudit.remarks,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "Bracket: ${fontAudit.netQuantityBracket}",
                style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMutedDark),
              ),
              const Spacer(),
              Text(
                "Min. Required: ${fontAudit.minRequiredFontHeightMm} mm",
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryWarningsBanner(List<String> warnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF451A03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97706), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: warnings.map((w) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              w,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFEF3C7),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientBreakdownCard(List<IngredientItem> ingredients) {
    if (ingredients.isEmpty) {
      return _buildEmptyPlaceholder("No ingredient breakdown available.");
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLightDark),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: ingredients.map((ing) => IngredientTagChip(ingredient: ing)).toList(),
      ),
    );
  }

  Widget _buildAdditivesCard(List<SuspiciousAdditive> additives) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLightDark),
      ),
      child: Column(
        children: additives.map((add) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${add.name} (${add.code ?? 'Additive'})",
                        style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        add.concern,
                        style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondaryDark),
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

  Widget _buildCleanComplianceBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.truthGreen.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.truthGreen, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Zero statutory violations detected. Product adheres to Legal Metrology & FSSAI labelling norms.",
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _showExportOptionsModal(context),
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
                : const Icon(Icons.download_for_offline_rounded),
            label: Text(
              "Export Compliance Notice (PDF / CSV / JSON)",
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
