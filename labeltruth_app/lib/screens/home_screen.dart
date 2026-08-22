import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';
import '../widgets/sample_product_sheet.dart';
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
            icon: const Icon(Icons.science_outlined, color: AppColors.accent),
            tooltip: "Test Benchmarks",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SampleProductSheet(),
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
          ? _buildLoadingOverlay(scanState.loadingMessage ?? "Auditing Product...")
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
                    _buildHeroBanner(context),
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
                          "Recent Food Audits",
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

                    // FSSAI Compliance Educational Guide
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
            "Querying FSSAI regulations & Open Food Facts...",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
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
                  "AI VISION AUDIT",
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "FSSAI Sec 23 Enforcer",
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
            "Expose Misleading\nFood Packaging Claims",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Cross-examine marketing slogans with real back-panel ingredients & Indian FSSAI standards.",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFD1FAE5),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CaptureScreen()),
                  );
                },
                icon: const Icon(Icons.flip_camera_ios_rounded, size: 16),
                label: const Text("Dual-Pack Scan"),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.accent),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 16, color: AppColors.accent),
                label: const Text("Scan Barcode"),
              ),
            ],
          ),
        ],
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
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Scan Barcode",
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "Live Registry",
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
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SampleProductSheet(),
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
                      color: AppColors.warningAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.science_outlined, color: AppColors.warningAmber, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Benchmarks",
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "FSSAI Tests",
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.textMutedDark, size: 36),
            const SizedBox(height: 8),
            Text(
              "No scans yet",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              "Scan a food package or barcode to see the Truth Score & FSSAI violations here.",
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMutedDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: scans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = scans[index];
          final scoreColor = AppColors.getScoreColor(item.truthScore);

          return InkWell(
            onTap: () async {
              final scanNotifier = ref.read(scanProvider.notifier);
              final res = await scanNotifier.loadScanById(item.id);
              if (res != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResultScreen(result: res)),
                );
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 230,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: scoreColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          "${item.truthScore} / 100",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                      ),
                      Icon(
                        item.truthScore >= 80 ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: scoreColor,
                        size: 16,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.brandName,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textMutedDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "${item.violationsCount} Violations",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.violationsCount > 0 ? AppColors.criticalRed : AppColors.truthGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.verdict,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComplianceGuideSection() {
    final guides = [
      {
        "title": "Rule A: Zero Sugar Trap",
        "desc": "Brands hide maltodextrin (GI 110) and invert syrups under 'No Added Sugar'.",
        "icon": Icons.water_drop_outlined,
      },
      {
        "title": "Rule B: 100% Atta Inversion",
        "desc": "Maida listed before whole wheat violates mandatory ingredient hierarchy.",
        "icon": Icons.grain_outlined,
      },
      {
        "title": "Rule D: Palm Oil Masking",
        "desc": "FSSAI Section 2.2.2.5 requires explicit declaration of vegetable fat sources.",
        "icon": Icons.oil_barrel_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Know Your Consumer Rights (FSSAI)",
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 10),
        ...guides.map((g) => Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(g["icon"] as IconData, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g["title"] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g["desc"] as String,
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
            )),
      ],
    );
  }
}
