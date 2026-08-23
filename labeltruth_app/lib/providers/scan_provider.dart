import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';

class ScanState {
  final bool isLoading;
  final String? loadingMessage;
  final String? errorMessage;
  final ScanResult? currentResult;
  final List<RecentScanItem> recentScans;
  final Uint8List? frontImageBytes;
  final Uint8List? backImageBytes;

  ScanState({
    this.isLoading = false,
    this.loadingMessage,
    this.errorMessage,
    this.currentResult,
    this.recentScans = const [],
    this.frontImageBytes,
    this.backImageBytes,
  });

  ScanState copyWith({
    bool? isLoading,
    String? loadingMessage,
    String? errorMessage,
    ScanResult? currentResult,
    List<RecentScanItem>? recentScans,
    Uint8List? frontImageBytes,
    Uint8List? backImageBytes,
    bool clearCurrentResult = false,
    bool clearImages = false,
  }) {
    return ScanState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      errorMessage: errorMessage,
      currentResult: clearCurrentResult ? null : (currentResult ?? this.currentResult),
      recentScans: recentScans ?? this.recentScans,
      frontImageBytes: clearImages ? null : (frontImageBytes ?? this.frontImageBytes),
      backImageBytes: clearImages ? null : (backImageBytes ?? this.backImageBytes),
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final Ref _ref;
  late final ApiService _apiService;

  ScanNotifier(this._ref) : super(ScanState()) {
    final settings = _ref.read(settingsProvider);
    _apiService = ApiService(customBaseUrl: settings.backendUrl);
    loadRecentScans();
  }

  void setFrontImage(Uint8List bytes) {
    state = state.copyWith(frontImageBytes: bytes);
  }

  void setBackImage(Uint8List bytes) {
    state = state.copyWith(backImageBytes: bytes);
  }

  void clearImages() {
    state = state.copyWith(clearImages: true);
  }

  Future<void> loadRecentScans() async {
    try {
      final scans = await _apiService.getRecentScans();
      state = state.copyWith(recentScans: scans);
    } catch (_) {}
  }

  Future<ScanResult?> analyzeDualImages({
    String? brandName,
    String? productName,
    String? rawMarketingText,
    String? rawIngredientsText,
  }) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: "Extracting packaging claims & ingredients with AI Vision...",
      errorMessage: null,
    );

    try {
      final settings = _ref.read(settingsProvider);
      _apiService.updateBaseUrl(settings.backendUrl);

      String? frontB64 = state.frontImageBytes != null
          ? base64Encode(state.frontImageBytes!)
          : null;
      String? backB64 = state.backImageBytes != null
          ? base64Encode(state.backImageBytes!)
          : null;

      final result = await _apiService.analyzePackaging(
        frontImageBase64: frontB64,
        backImageBase64: backB64,
        brandName: brandName,
        productName: productName,
        rawMarketingText: rawMarketingText,
        rawIngredientsText: rawIngredientsText,
        userPreferences: settings.toDietaryPreferencesMap(),
      );

      state = state.copyWith(
        isLoading: false,
        currentResult: result,
      );

      await loadRecentScans();
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Analysis failed: ${e.toString()}",
      );
      return null;
    }
  }

  Future<ScanResult?> lookupBarcode(String barcode) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: "Looking up barcode cache in database...",
      errorMessage: null,
    );

    try {
      final settings = _ref.read(settingsProvider);
      _apiService.updateBaseUrl(settings.backendUrl);

      final result = await _apiService.lookupBarcode(barcode);
      state = state.copyWith(
        isLoading: false,
        currentResult: result,
      );
      await loadRecentScans();
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Product not in cache. Please capture front and back photos to run full audit.",
      );
      return null;
    }
  }

  Future<ScanResult?> loadScanById(String scanId, {String? barcode, String? productId}) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: "Retrieving audit report...",
      errorMessage: null,
    );

    try {
      final settings = _ref.read(settingsProvider);
      _apiService.updateBaseUrl(settings.backendUrl);

      ScanResult? result;
      try {
        result = await _apiService.getScanReport(scanId);
      } catch (_) {
        if (barcode != null && barcode.isNotEmpty) {
          result = await _apiService.lookupBarcode(barcode);
        } else if (productId != null && productId.isNotEmpty) {
          result = await _apiService.getScanReport(productId);
        }
      }

      if (result != null) {
        state = state.copyWith(
          isLoading: false,
          currentResult: result,
        );
        return result;
      }
      throw Exception("Audit report not found");
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Unable to load scan report: $e",
      );
      return null;
    }
  }

  void setCurrentResult(ScanResult result) {
    state = state.copyWith(currentResult: result);
  }

  void clearCurrentResult() {
    state = state.copyWith(clearCurrentResult: true);
  }

  Future<String?> generateComplaintPdf(ScanResult scan, {String complainantName = "Concerned Consumer"}) async {
    try {
      final b64Pdf = await _apiService.generateViolationPdf(scan, complainantName: complainantName);
      return b64Pdf;
    } catch (e) {
      return null;
    }
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(ref);
});
