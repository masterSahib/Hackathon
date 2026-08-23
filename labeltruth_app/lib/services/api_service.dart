import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/scan_result.dart';

class ApiService {
  late final Dio _dio;
  String _baseUrl = ApiEndpoints.defaultBaseUrl;

  ApiService({String? customBaseUrl}) {
    _baseUrl = customBaseUrl ?? ApiEndpoints.defaultBaseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 35),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  String get currentBaseUrl => _baseUrl;

  /// Analyze food packaging claims & ingredients via FastAPI backend
  Future<ScanResult> analyzePackaging({
    String? frontImageBase64,
    String? backImageBase64,
    String? rawMarketingText,
    String? rawIngredientsText,
    String? rawNutritionText,
    String? barcode,
    String? brandName,
    String? productName,
    Map<String, dynamic>? userPreferences,
  }) async {
    try {
      final payload = {
        'front_image_base64': frontImageBase64,
        'back_image_base64': backImageBase64,
        'raw_marketing_text': rawMarketingText,
        'raw_ingredients_text': rawIngredientsText,
        'raw_nutrition_text': rawNutritionText,
        'barcode': barcode,
        'brand_name': brandName,
        'product_name': productName,
        'user_dietary_preferences': userPreferences,
      };

      final response = await _dio.post(
        ApiEndpoints.analyze,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ScanResult.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message ?? "Network connection failed";
      throw Exception(msg);
    } catch (e) {
      throw Exception("Audit analysis error: $e");
    }
  }

  /// Fast Barcode lookup from DB cache & live Open Food Facts
  Future<ScanResult> lookupBarcode(String barcode) async {
    try {
      final clean = barcode.trim().replaceAll(" ", "").replaceAll("-", "");
      final response = await _dio.get('${ApiEndpoints.barcodeLookup}/$clean');
      if (response.statusCode == 200 && response.data != null) {
        return ScanResult.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception("Barcode not found");
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message ?? "Barcode not found in registry";
      throw Exception(msg);
    } catch (e) {
      throw Exception("Barcode lookup failed: $e");
    }
  }

  /// Get recent scans history
  Future<List<RecentScanItem>> getRecentScans() async {
    try {
      final response = await _dio.get(ApiEndpoints.scansList);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => RecentScanItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get specific past scan report
  Future<ScanResult> getScanReport(String scanId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.scanDetail}/$scanId');
      if (response.statusCode == 200 && response.data != null) {
        return ScanResult.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception("Report not found");
    } catch (e) {
      rethrow;
    }
  }

  /// Generate FSSAI Notice PDF (returns base64 string)
  Future<String> generateViolationPdf(ScanResult scan, {String complainantName = "Concerned Consumer"}) async {
    try {
      final payload = {
        'scan_id': scan.scanId,
        'product_name': scan.productName,
        'brand_name': scan.brandName,
        'barcode': scan.barcode,
        'truth_score': scan.truthScore,
        'verdict': scan.verdict,
        'marketing_claims': scan.marketingClaims,
        'claim_comparisons': scan.claimComparisons.map((c) => c.toJson()).toList(),
        'violations': scan.violations.map((v) => v.toJson()).toList(),
        'ingredients': scan.ingredients.map((i) => i.toJson()).toList(),
        'nutrition': scan.nutritionPer100g.toJson(),
        'complainant_name': complainantName,
      };

      final response = await _dio.post(
        ApiEndpoints.generatePdf,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['pdf_base64'] as String;
      }
      throw Exception("PDF generation failed");
    } catch (e) {
      throw Exception("Unable to generate PDF notice: $e");
    }
  }

  /// Ask Custom Question to AI Regulatory Auditor about scanned product
  Future<String> askProductChat({
    required String productName,
    String? brandName,
    int? truthScore,
    String? verdict,
    List<String>? marketingClaims,
    String? ingredientsText,
    Map<String, dynamic>? nutrition,
    List<Map<String, dynamic>>? violations,
    required String userQuestion,
    List<Map<String, String>>? chatHistory,
  }) async {
    try {
      final payload = {
        'product_name': productName,
        'brand_name': brandName ?? 'Brand',
        'truth_score': truthScore ?? 50,
        'verdict': verdict ?? 'Misleading',
        'marketing_claims': marketingClaims ?? [],
        'ingredients_text': ingredientsText ?? '',
        'nutrition': nutrition ?? {},
        'violations': violations ?? [],
        'user_question': userQuestion,
        'chat_history': chatHistory ?? [],
      };

      final response = await _dio.post(
        ApiEndpoints.productChat,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['reply'] as String;
      }
      throw Exception("AI chat failed to respond");
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message ?? "Failed to connect to AI Assistant";
      throw Exception(msg);
    } catch (e) {
      throw Exception("AI Chat Error: $e");
    }
  }
}
