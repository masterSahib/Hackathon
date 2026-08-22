import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../providers/scan_provider.dart';
import '../widgets/sample_product_sheet.dart';
import 'barcode_scan_screen.dart';
import 'result_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  Uint8List? _frontBytes;
  Uint8List? _backBytes;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _claimsController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _brandController.dispose();
    _productController.dispose();
    _claimsController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront, ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          if (isFront) {
            _frontBytes = bytes;
            ref.read(scanProvider.notifier).setFrontImage(bytes);
          } else {
            _backBytes = bytes;
            ref.read(scanProvider.notifier).setBackImage(bytes);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image capture failed: $e")),
        );
      }
    }
  }

  void _runAnalysis() async {
    final scanNotifier = ref.read(scanProvider.notifier);

    final res = await scanNotifier.analyzeDualImages(
      brandName: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
      productName: _productController.text.trim().isNotEmpty ? _productController.text.trim() : null,
      rawMarketingText: _claimsController.text.trim().isNotEmpty ? _claimsController.text.trim() : null,
      rawIngredientsText: _ingredientsController.text.trim().isNotEmpty ? _ingredientsController.text.trim() : null,
    );

    if (res != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: res)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dual-Pack Scanner",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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
            tooltip: "Load Benchmarks",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SampleProductSheet(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMutedDark,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt_outlined), text: "Camera Dual-Snap"),
            Tab(icon: Icon(Icons.edit_note_outlined), text: "Manual / Paste Text"),
          ],
        ),
      ),
      body: scanState.isLoading
          ? _buildLoadingState(scanState.loadingMessage ?? "Analyzing...")
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDualCameraTab(),
                _buildManualTextTab(),
              ],
            ),
    );
  }

  Widget _buildLoadingState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Auditing Packaging Compliance",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualCameraTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Front Pack
          _buildCaptureStepCard(
            stepNumber: "1",
            title: "Front of Pack (Marketing)",
            subtitle: "Capture marketing slogans, claims & brand badges",
            imageBytes: _frontBytes,
            isFront: true,
          ),
          const SizedBox(height: 16),

          // Step 2: Back Pack
          _buildCaptureStepCard(
            stepNumber: "2",
            title: "Back of Pack (Nutrition & Ingredients)",
            subtitle: "Capture ingredient hierarchy list & nutrition fact table",
            imageBytes: _backBytes,
            isFront: false,
          ),
          const SizedBox(height: 24),

          // Optional Product Details
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
                Text(
                  "Product Info (Optional)",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _brandController,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimaryDark),
                        decoration: const InputDecoration(
                          hintText: "Brand Name (e.g. Britannia)",
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _productController,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimaryDark),
                        decoration: const InputDecoration(
                          hintText: "Product Name (e.g. Atta Marie)",
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_frontBytes != null || _backBytes != null) ? _runAnalysis : () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SampleProductSheet(),
                );
              },
              icon: const Icon(Icons.bolt_rounded),
              label: Text(
                (_frontBytes != null || _backBytes != null)
                    ? "Audit Packaging Claims"
                    : "Pick Test Benchmark / Snap Photos",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCaptureStepCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required Uint8List? imageBytes,
    required bool isFront,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: imageBytes != null ? AppColors.accent : AppColors.surfaceLightDark,
          width: imageBytes != null ? 1.5 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: imageBytes != null ? AppColors.accent : AppColors.surfaceDark,
                  child: Text(
                    stepNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (imageBytes != null)
                  const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
              ],
            ),
          ),

          if (imageBytes != null) ...[
            Container(
              height: 140,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: MemoryImage(imageBytes),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPickerOptions(isFront),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("Retake", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(isFront, ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 16, color: AppColors.accent),
                      label: const Text("Camera", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(isFront, ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 16, color: AppColors.textSecondaryDark),
                      label: const Text("Gallery", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPickerOptions(bool isFront) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.accent),
              title: const Text("Take Photo with Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isFront, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.accent),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isFront, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceLightDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You can paste marketing claims and back-panel ingredients text directly to audit compliance.",
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            "Brand & Product",
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _brandController,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimaryDark),
                  decoration: const InputDecoration(hintText: "Brand Name"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _productController,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimaryDark),
                  decoration: const InputDecoration(hintText: "Product Name"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            "Front-of-Pack Marketing Claims",
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _claimsController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimaryDark),
            decoration: const InputDecoration(
              hintText: "e.g., '100% Whole Wheat Goodness', 'Zero Added Sugar', 'Rich in Protein'",
            ),
          ),
          const SizedBox(height: 16),

          Text(
            "Back Panel Ingredients Text (Descending Order)",
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _ingredientsController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimaryDark),
            decoration: const InputDecoration(
              hintText: "e.g., Refined Wheat Flour (Maida) 58%, Palm Oil, Invert Sugar Syrup, Maltodextrin, Whole Wheat 12%, Caramel Color (INS 150d)...",
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.bolt_rounded),
              label: Text(
                "Run Compliance Audit",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
