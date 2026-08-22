import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../providers/scan_provider.dart';
import '../screens/result_screen.dart';

class SampleProductSheet extends ConsumerWidget {
  const SampleProductSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final samples = [
      {
        "title": "Digestive '100% Atta' Biscuits",
        "brand": "NutriWhole Foods",
        "claims": "100% Whole Wheat, Zero Sugar Added, High Fibre",
        "ingredients": "Refined Wheat Flour (Maida) 58%, Palm Oil, Invert Sugar Syrup, Maltodextrin, Whole Wheat Flour (Atta) 12%, Caramel Color (INS 150d)",
        "icon": Icons.cookie_outlined,
        "scoreHint": "Score ~42 (Red)",
        "scoreColor": AppColors.criticalRed,
      },
      {
        "title": "Max Protein Power Energy Bar",
        "brand": "FitPower Nutrition",
        "claims": "High Protein Muscle Fuel, Zero Sugar Added, Guilt Free",
        "ingredients": "Liquid Glucose, Invert Sugar Syrup, Soy Protein Crispies 8%, Maltodextrin, Palmolein, Milk Chocolate, Sucralose (INS 955)",
        "icon": Icons.fitness_center_rounded,
        "scoreHint": "Score ~15 (Red)",
        "scoreColor": AppColors.criticalRed,
      },
      {
        "title": "100% Real Alphonso Mango Nectar",
        "brand": "PureOrchard Botanicals",
        "claims": "100% Real Fruit Goodness, No Preservatives, Rich Vitamin C",
        "ingredients": "Water, Mango Pulp 18%, Sugar, INS 330, INS 110 Sunset Yellow, INS 211 Sodium Benzoate",
        "icon": Icons.local_drink_outlined,
        "scoreHint": "Score ~80 (Amber/Green)",
        "scoreColor": AppColors.warningAmber,
      },
      {
        "title": "100% Rolled Oats Sourdough Crackers",
        "brand": "CleanOats Organics",
        "claims": "100% Whole Grain Oats, Cold Pressed Coconut Oil, Zero Refined Sugar",
        "ingredients": "Whole Rolled Oats Flour 72%, Cold Pressed Virgin Coconut Oil 14%, Chia Seeds 6%, Pumpkin Seeds 5%, Rock Salt 2%",
        "icon": Icons.eco_outlined,
        "scoreHint": "Score ~100 (Green)",
        "scoreColor": AppColors.truthGreen,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Benchmark Test Products",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMutedDark, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            "Select a realistic market product to test the compliance rule engine & multimodal audit:",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: samples.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = samples[index];
                return InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    final scanNotifier = ref.read(scanProvider.notifier);
                    final res = await scanNotifier.analyzeDualImages(
                      brandName: s["brand"] as String,
                      productName: s["title"] as String,
                      rawMarketingText: s["claims"] as String,
                      rawIngredientsText: s["ingredients"] as String,
                    );
                    if (res != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(result: res),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s["icon"] as IconData, color: AppColors.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s["title"] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s["claims"] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (s["scoreColor"] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: (s["scoreColor"] as Color).withOpacity(0.4)),
                          ),
                          child: Text(
                            s["scoreHint"] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: s["scoreColor"] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
