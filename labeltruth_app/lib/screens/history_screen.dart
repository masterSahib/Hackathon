import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/scan_provider.dart';
import 'result_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = "all"; // all, clean, misleading, violations
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final scans = scanState.recentScans;

    final filtered = scans.where((s) {
      final matchesSearch = _searchController.text.isEmpty ||
          s.productName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          s.brandName.toLowerCase().contains(_searchController.text.toLowerCase());

      if (!matchesSearch) return false;

      if (_filter == "clean") return s.truthScore >= 80;
      if (_filter == "misleading") return s.truthScore >= 50 && s.truthScore < 80;
      if (_filter == "violations") return s.truthScore < 50;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Food Audit History",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    hintText: "Filter by brand or product name...",
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("all", "All Scans (${scans.length})"),
                      const SizedBox(width: 8),
                      _buildFilterChip("violations", "Violations (<50)", color: AppColors.criticalRed),
                      const SizedBox(width: 8),
                      _buildFilterChip("misleading", "Misleading (50-79)", color: AppColors.warningAmber),
                      const SizedBox(width: 8),
                      _buildFilterChip("clean", "Clean (80-100)", color: AppColors.truthGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceLightDark, height: 1),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(scanProvider.notifier).loadRecentScans();
              },
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_toggle_off_rounded, color: AppColors.textMutedDark, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "No audit records found",
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final scoreColor = AppColors.getScoreColor(item.truthScore);
                        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt);

                        return InkWell(
                          onTap: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(color: AppColors.accent),
                              ),
                            );

                            final scanNotifier = ref.read(scanProvider.notifier);
                            final res = await scanNotifier.loadScanById(item.id, productId: item.productId);

                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              if (res != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ResultScreen(result: res)),
                                );
                              } else {
                                final error = ref.read(scanProvider).errorMessage ?? "Unable to load audit report.";
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: AppColors.criticalRed,
                                  ),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCardDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.surfaceLightDark, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: scoreColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: scoreColor.withOpacity(0.4)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${item.truthScore}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: scoreColor,
                                          height: 1.1,
                                        ),
                                      ),
                                      Text(
                                        "SCORE",
                                        style: GoogleFonts.inter(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: scoreColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
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
                                      const SizedBox(height: 2),
                                      Text(
                                        "${item.brandName} • $dateStr",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textMutedDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: scoreColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.verdict,
                                              style: GoogleFonts.poppins(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: scoreColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${item.violationsCount} violations",
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: item.violationsCount > 0
                                                  ? AppColors.criticalRed
                                                  : AppColors.truthGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textMutedDark),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {Color? color}) {
    final isSelected = _filter == filterKey;
    final activeColor = color ?? AppColors.accent;

    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondaryDark,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: AppColors.surfaceCardDark,
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.surfaceLightDark,
      ),
      onSelected: (_) => setState(() => _filter = filterKey),
    );
  }
}
