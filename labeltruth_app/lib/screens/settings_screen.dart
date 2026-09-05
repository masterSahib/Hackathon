import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/api_endpoints.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _badgeController;
  late TextEditingController _jurisdictionController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _urlController = TextEditingController(text: settings.backendUrl);
    _badgeController = TextEditingController(text: settings.badgeNumber);
    _jurisdictionController = TextEditingController(text: settings.jurisdiction);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _badgeController.dispose();
    _jurisdictionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final allergens = [
      "Peanuts",
      "Gluten / Wheat",
      "Dairy / Milk",
      "Soy",
      "Tree Nuts",
      "Sulphites (INS 223)",
      "Eggs",
      "Fish / Shellfish"
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Officer Credentials & Settings",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Role-Based Access Control (RBAC) Section
            Text(
              "User Role & Enforcement Mode",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Configure whether the application runs in official Regulatory Officer or Citizen Advocate mode:",
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: settings.isOfficerMode ? AppColors.accent.withOpacity(0.5) : AppColors.surfaceLightDark,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: settings.isOfficerMode ? AppColors.accent.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          settings.isOfficerMode ? Icons.shield_rounded : Icons.person_rounded,
                          color: settings.isOfficerMode ? AppColors.accent : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.isOfficerMode ? "Legal Metrology Officer (Inspector)" : "Consumer Advocate (Citizen)",
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
                            ),
                            Text(
                              settings.isOfficerMode
                                  ? "Authorized to issue statutory LMPC Rule 6/7 inspection dockets"
                                  : "Standard consumer compliance auditor & dietary advisor",
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.isOfficerMode,
                        activeColor: AppColors.accent,
                        onChanged: (val) => settingsNotifier.updateOfficerMode(val),
                      ),
                    ],
                  ),
                  if (settings.isOfficerMode) ...[
                    const Divider(color: AppColors.surfaceLightDark, height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Officer Badge / ID", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMutedDark)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _badgeController,
                                style: GoogleFonts.inter(fontSize: 12),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: AppColors.surfaceLightDark,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                                onSubmitted: (val) => settingsNotifier.updateBadgeNumber(val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Jurisdiction Zone", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMutedDark)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _jurisdictionController,
                                style: GoogleFonts.inter(fontSize: 12),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: AppColors.surfaceLightDark,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                                onSubmitted: (val) => settingsNotifier.updateJurisdiction(val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Dietary Health Flags
            Text(
              "Personal Health & Ingestion Alerts",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "LabelTruth will immediately trigger warnings if an audited package contains selected items:",
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: "Avoid Palm Oil / Palmolein",
                    subtitle: "Flag products with refined palm oil or undeclared vegetable fats",
                    value: settings.avoidPalmOil,
                    onChanged: (val) => settingsNotifier.updateAvoidPalmOil(val),
                    icon: Icons.oil_barrel_outlined,
                  ),
                  const Divider(color: AppColors.surfaceLightDark, height: 1),
                  _buildSwitchTile(
                    title: "Diabetic / Glycemic Mode",
                    subtitle: "Flag hidden sugars (maltodextrin, invert syrup, high GI fillers)",
                    value: settings.diabeticMode,
                    onChanged: (val) => settingsNotifier.updateDiabeticMode(val),
                    icon: Icons.bloodtype_outlined,
                  ),
                  const Divider(color: AppColors.surfaceLightDark, height: 1),
                  _buildSwitchTile(
                    title: "Low Sodium Watch",
                    subtitle: "Flag products exceeding FSSAI HFSS cap (400mg sodium/100g)",
                    value: settings.lowSodium,
                    onChanged: (val) => settingsNotifier.updateLowSodium(val),
                    icon: Icons.grain_outlined,
                  ),
                  const Divider(color: AppColors.surfaceLightDark, height: 1),
                  _buildSwitchTile(
                    title: "Strict Vegan Verification",
                    subtitle: "Verify non-vegetarian animal derivatives, gelatins, shellac, and dairy",
                    value: settings.vegan,
                    onChanged: (val) => settingsNotifier.updateVegan(val),
                    icon: Icons.eco_outlined,
                  ),
                  const Divider(color: AppColors.surfaceLightDark, height: 1),
                  _buildSwitchTile(
                    title: "Avoid Artificial Sweeteners",
                    subtitle: "Flag Sucralose (INS 955), Aspartame (INS 951), Ace-K (INS 950)",
                    value: settings.avoidArtificialSweeteners,
                    onChanged: (val) => settingsNotifier.updateAvoidArtificialSweeteners(val),
                    icon: Icons.no_food_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Allergen Watchlist
            Text(
              "Allergen Sensitivity Watchlist",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Select allergens to receive prominent highlight alerts during scans:",
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allergens.map((allergen) {
                  final isSelected = settings.allergies.contains(allergen);
                  return FilterChip(
                    label: Text(allergen),
                    selected: isSelected,
                    onSelected: (_) => settingsNotifier.toggleAllergy(allergen),
                    backgroundColor: AppColors.surfaceLightDark,
                    selectedColor: AppColors.accent.withOpacity(0.2),
                    checkmarkColor: AppColors.accent,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.accent : AppColors.textSecondaryDark,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : Colors.transparent,
                        width: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // 4. API Backend Configuration
            Text(
              "Backend API Configuration",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Connect to local development backend or cloud deployment URL:",
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _urlController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Backend Base URL",
                      labelStyle: GoogleFonts.inter(color: AppColors.textMutedDark),
                      hintText: "http://10.0.2.2:8000 or https://your-render-url.onrender.com",
                      hintStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark),
                      prefixIcon: const Icon(Icons.cloud_outlined, color: AppColors.accent),
                      filled: true,
                      fillColor: AppColors.surfaceLightDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await settingsNotifier.updateBackendUrl(_urlController.text.trim());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.accent,
                              content: Text("Backend URL saved successfully!"),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLightDark,
                        foregroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        "Save API Configuration",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
      secondary: Icon(icon, color: value ? AppColors.accent : AppColors.textMutedDark, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondaryDark),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
