import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';
import '../providers/settings_provider.dart';
import 'capture_screen.dart';
import 'barcode_scan_screen.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentNavIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBarcodeSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final scanNotifier = ref.read(scanProvider.notifier);
    final res = await scanNotifier.lookupBarcode(query);
    if (res != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: res)),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceCardDark,
            content: Text("Barcode '$query' not found in registry. Try dual-camera snap."),
            action: SnackBarAction(
              label: "Dual Snap",
              textColor: AppColors.accent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CaptureScreen()),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Label",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  TextSpan(
                    text: "Truth",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Officer Mode Pill Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: settings.isOfficerMode ? AppColors.accent.withOpacity(0.18) : Colors.grey.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: settings.isOfficerMode ? AppColors.accent : Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  settings.isOfficerMode ? Icons.shield_rounded : Icons.person_rounded,
                  size: 13,
                  color: settings.isOfficerMode ? AppColors.accent : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  settings.isOfficerMode ? "OFFICER" : "CITIZEN",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: settings.isOfficerMode ? AppColors.accent : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.accent),
            tooltip: "Scan Barcode",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: scanState.isLoading
          ? _buildLoadingOverlay(scanState.loadingMessage ?? "Auditing Packaging...")
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(scanProvider.notifier).loadRecentScans();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Scanner Banner
                    _buildHeroBanner(context, settings.isOfficerMode),
                    const SizedBox(height: 16),

                    // Enforcement Monitoring Dashboard Summary
                    _buildEnforcementDashboardSummary(scanState.recentScans),
                    const SizedBox(height: 18),

                    // Search / Barcode Bar
                    _buildSearchBar(),
                    const SizedBox(height: 20),

                    // Quick Actions Row (Dual-Cam, Barcode Scanner, Benchmarks)
                    _buildQuickActionCards(context),
                    const SizedBox(height: 24),

                    // Recent Scans Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Inspection Audits",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HistoryScreen()),
                            );
                          },
                          child: Text(
                            "View All",
                            style: GoogleFonts.inter(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Recent Scans Carousel / List
                    _buildRecentScansList(scanState.recentScans),
                    const SizedBox(height: 24),

                    // FSSAI & LMPC Compliance Educational Guide
                    _buildComplianceGuideSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaptureScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.flip_camera_ios_rounded), label: "Dual Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: "Barcode"),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "History"),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CaptureScreen()),
          );
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
        label: Text(
          "Audit Packaging",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 18),
          Text(
            msg,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Auditing LMPC Rule 6 declarations & FSSAI standards...",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isOfficer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOfficer ? "OFFICER ENFORCEMENT" : "AI PACKAGING AUDITOR",
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "LMPC Rules 2011 & FSSAI Enforcer",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isOfficer
                ? "Automated Packaging\nCompliance Enforcement"
                : "Expose Misleading\nFood Packaging Claims",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOfficer
                ? "Verify mandatory LMPC declarations, font area thresholds & issue statutory violation notices."
                : "Cross-examine marketing slogans with real back-panel ingredients & Indian FSSAI standards.",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFD1FAE5),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CaptureScreen()),
                    );
                  },
                  icon: const Icon(Icons.flip_camera_ios_rounded, size: 16),
                  label: const Text(
                    "Dual-Pack Scan",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 16, color: AppColors.accent),
                  label: const Text(
                    "Scan Barcode",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnforcementDashboardSummary(List<RecentScanItem> scans) {
    final total = scans.length;
    final verified = scans.where((s) => s.verdict == "Verified").length;
    final violations = scans.where((s) => s.verdict != "Verified").length;
    final rate = total > 0 ? ((verified / total) * 100).toInt() : 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLightDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Enforcement Dashboard Overview",
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
              ),
              Text(
                "Live Metrics",
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricTile("Total Audited", "$total", AppColors.textPrimaryDark, Icons.inventory_2_outlined),
              const SizedBox(width: 8),
              _buildMetricTile("Compliance Rate", "$rate%", AppColors.truthGreen, Icons.check_circle_outline),
              const SizedBox(width: 8),
              _buildMetricTile("Defects / Notices", "$violations", AppColors.criticalRed, Icons.gavel_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLightDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textMutedDark),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(color: AppColors.textPrimaryDark, fontSize: 13),
        decoration: InputDecoration(
          hintText: "Enter Indian Barcode (e.g. 8901030882101)...",
          prefixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
              );
            },
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textSecondaryDark),
            onPressed: _handleBarcodeSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (_) => _handleBarcodeSearch(),
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CaptureScreen()),
              );
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flip_camera_ios_rounded, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dual-Pack Snap",
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "Front + Back Panel",
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMutedDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
              );
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.truthGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: AppColors.truthGreen, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Barcode Scanner",
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "Instant Registry DB",
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMutedDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScansList(List<RecentScanItem> scans) {
    if (scans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLightDark),
        ),
        child: Column(
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 36, color: AppColors.textMutedDark),
            const SizedBox(height: 8),
            Text(
              "No audits yet",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              "Scan packaging with dual camera or barcode to start.",
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scans.take(4).length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = scans[index];
        final scoreColor = AppColors.getScoreColor(item.truthScore);

        return InkWell(
          onTap: () async {
            final scanNotifier = ref.read(scanProvider.notifier);
            final fullResult = await scanNotifier.loadScanById(item.id);
            if (fullResult != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ResultScreen(result: fullResult)),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLightDark),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scoreColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      "${item.truthScore}",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.brandName,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.verdict,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComplianceGuideSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLightDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                "Legal Metrology & FSSAI Standards Enforced",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGuideBullet("LMPC Rule 6", "Mandatory Net Quantity, USP, MRP, Dates & Grievance Contact"),
          _buildGuideBullet("LMPC Rule 7 & 9", "Principal Display Panel font size & numeral area ratio check"),
          _buildGuideBullet("FSSAI Sec 23", "Atta grain hierarchy & Zero Sugar maltodextrin verification"),
          _buildGuideBullet("FSSAI HFSS", "Caps high sodium (>400mg) and saturated fats (>6g/100g)"),
        ],
      ),
    );
  }

  Widget _buildGuideBullet(String rule, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$rule: ",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondaryDark,
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
}
