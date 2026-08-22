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

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _urlController = TextEditingController(text: settings.backendUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
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
          "Dietary Alerts & Settings",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dietary Health Flags
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
                    subtitle: "Flag food items with sodium exceeding 400mg per 100g",
                    value: settings.lowSodium,
                    onChanged: (val) => settingsNotifier.updateLowSodium(val),
                    icon: Icons.water_outlined,
                  ),
                  const Divider(color: AppColors.surfaceLightDark, height: 1),
                  _buildSwitchTile(
                    title: "Avoid Artificial Sweeteners",
                    subtitle: "Flag Sucralose (INS 955), Aspartame (INS 951), Ace-K (INS 950)",
                    value: settings.avoidArtificialSweeteners,
                    onChanged: (val) => settingsNotifier.updateAvoidArtificialSweeteners(val),
                    icon: Icons.warning_amber_rounded,
                  ),
                  const Divider(color: AppColors.surfaceLightDark, height: 1),
                  _buildSwitchTile(
                    title: "Strict Vegan Verification",
                    subtitle: "Check for gelatin, cochineal dye (INS 120), shellac and animal byproducts",
                    value: settings.vegan,
                    onChanged: (val) => settingsNotifier.updateVegan(val),
                    icon: Icons.eco_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Allergens Checklist
            Text(
              "Specific Allergen Alerts",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
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
                    label: Text(
                      allergen,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.criticalRed,
                    backgroundColor: AppColors.surfaceDark,
                    side: BorderSide(
                      color: isSelected ? AppColors.criticalRed : AppColors.surfaceLightDark,
                    ),
                    onSelected: (_) => settingsNotifier.toggleAllergy(allergen),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Backend API Configuration
            Text(
              "Backend API Connection (FastAPI on Render)",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _urlController,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimaryDark),
                    decoration: InputDecoration(
                      labelText: "API Base URL",
                      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMutedDark),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: AppColors.accent),
                        onPressed: () {
                          settingsNotifier.updateBackendUrl(_urlController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("API Base URL updated.")),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Quick Switch Presets:",
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text("Localhost (Desktop/Web)", style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _urlController.text = ApiEndpoints.localDesktopBaseUrl;
                          settingsNotifier.updateBackendUrl(ApiEndpoints.localDesktopBaseUrl);
                        },
                      ),
                      ActionChip(
                        label: const Text("Android Emulator (10.0.2.2)", style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _urlController.text = ApiEndpoints.androidEmulatorBaseUrl;
                          settingsNotifier.updateBackendUrl(ApiEndpoints.androidEmulatorBaseUrl);
                        },
                      ),
                      ActionChip(
                        label: const Text("Render Cloud API", style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _urlController.text = ApiEndpoints.productionBaseUrl;
                          settingsNotifier.updateBackendUrl(ApiEndpoints.productionBaseUrl);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About & Legal
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user, color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "LabelTruth v1.0.0 (Production Ready)",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Enforcing FSSAI (Packaging & Labelling) Regulations 2020, Claims & Advertisements Regulations 2018, and Consumer Protection Act 2019.",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMutedDark,
                      height: 1.4,
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
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.accent,
      secondary: Icon(icon, color: value ? AppColors.accent : AppColors.textMutedDark, size: 20),
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
        style: GoogleFonts.inter(
          fontSize: 11,
          color: AppColors.textSecondaryDark,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    );
  }
}
