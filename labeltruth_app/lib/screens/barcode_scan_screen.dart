import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/constants/app_colors.dart';
import '../providers/scan_provider.dart';
import 'result_screen.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    try {
      final scanNotifier = ref.read(scanProvider.notifier);
      final res = await scanNotifier.lookupBarcode(rawValue.trim());
      if (res != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: res)),
        );
      } else {
        if (mounted) {
          _showNotFoundDialog(rawValue.trim());
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotFoundDialog(rawValue.trim());
      }
    }
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: AppColors.warningAmber),
            const SizedBox(width: 8),
            Text(
              "Barcode Scanned",
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          "Barcode '$barcode' was scanned. To perform a complete FSSAI audit, please take photos of the Front and Back packaging.",
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
              _controller.start();
            },
            child: const Text("Scan Another"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to dual capture screen
            },
            child: const Text("Open Dual Camera"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Scan Product Barcode",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state.torchState == TorchState.on ? AppColors.accent : Colors.white,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Custom Scanner Overlay Box
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 2.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Bottom Instruction Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLightDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isProcessing
                          ? "Querying FSSAI database & Open Food Facts..."
                          : "Align barcode inside frame to audit ingredients & compliance.",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
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
