class NutritionPer100g {
  final double energyKcal;
  final double proteinG;
  final double totalCarbohydratesG;
  final double totalSugarG;
  final double addedSugarG;
  final double totalFatG;
  final double saturatedFatG;
  final double transFatG;
  final double sodiumMg;
  final double fiberG;

  NutritionPer100g({
    this.energyKcal = 0.0,
    this.proteinG = 0.0,
    this.totalCarbohydratesG = 0.0,
    this.totalSugarG = 0.0,
    this.addedSugarG = 0.0,
    this.totalFatG = 0.0,
    this.saturatedFatG = 0.0,
    this.transFatG = 0.0,
    this.sodiumMg = 0.0,
    this.fiberG = 0.0,
  });

  factory NutritionPer100g.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NutritionPer100g();
    return NutritionPer100g(
      energyKcal: (json['energy_kcal'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      totalCarbohydratesG: (json['total_carbohydrates_g'] as num?)?.toDouble() ?? 0.0,
      totalSugarG: (json['total_sugar_g'] as num?)?.toDouble() ?? 0.0,
      addedSugarG: (json['added_sugar_g'] as num?)?.toDouble() ?? 0.0,
      totalFatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0.0,
      saturatedFatG: (json['saturated_fat_g'] as num?)?.toDouble() ?? 0.0,
      transFatG: (json['trans_fat_g'] as num?)?.toDouble() ?? 0.0,
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'energy_kcal': energyKcal,
    'protein_g': proteinG,
    'total_carbohydrates_g': totalCarbohydratesG,
    'total_sugar_g': totalSugarG,
    'added_sugar_g': addedSugarG,
    'total_fat_g': totalFatG,
    'saturated_fat_g': saturatedFatG,
    'trans_fat_g': transFatG,
    'sodium_mg': sodiumMg,
    'fiber_g': fiberG,
  };
}

class IngredientItem {
  final String name;
  final double? percentage;
  final String category; // 'clean', 'warning', 'harmful'
  final String? flagReason;
  final bool isAdditive;
  final String? insCode;

  IngredientItem({
    required this.name,
    this.percentage,
    this.category = 'clean',
    this.flagReason,
    this.isAdditive = false,
    this.insCode,
  });

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    return IngredientItem(
      name: json['name'] as String? ?? 'Ingredient',
      percentage: (json['percentage'] as num?)?.toDouble(),
      category: json['category'] as String? ?? 'clean',
      flagReason: json['flag_reason'] as String?,
      isAdditive: json['is_additive'] as bool? ?? false,
      insCode: json['ins_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'percentage': percentage,
    'category': category,
    'flag_reason': flagReason,
    'is_additive': isAdditive,
    'ins_code': insCode,
  };
}

class SuspiciousAdditive {
  final String name;
  final String? code;
  final String category;
  final String concern;
  final String severity;

  SuspiciousAdditive({
    required this.name,
    this.code,
    required this.category,
    required this.concern,
    this.severity = 'Medium',
  });

  factory SuspiciousAdditive.fromJson(Map<String, dynamic> json) {
    return SuspiciousAdditive(
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      category: json['category'] as String? ?? 'Additive',
      concern: json['concern'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'category': category,
    'concern': concern,
    'severity': severity,
  };
}

class ClaimComparison {
  final String frontClaim;
  final String realityFinding;
  final String status; // 'verified', 'misleading', 'violation'
  final String explanation;
  final String evidence;

  ClaimComparison({
    required this.frontClaim,
    required this.realityFinding,
    required this.status,
    required this.explanation,
    required this.evidence,
  });

  factory ClaimComparison.fromJson(Map<String, dynamic> json) {
    return ClaimComparison(
      frontClaim: json['front_claim'] as String? ?? '',
      realityFinding: json['reality_finding'] as String? ?? '',
      status: json['status'] as String? ?? 'violation',
      explanation: json['explanation'] as String? ?? '',
      evidence: json['evidence'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'front_claim': frontClaim,
    'reality_finding': realityFinding,
    'status': status,
    'explanation': explanation,
    'evidence': evidence,
  };
}

class ViolationItem {
  final String ruleCode;
  final String title;
  final String severity;
  final String regulationReference;
  final String claimText;
  final String auditFinding;
  final String recommendation;

  ViolationItem({
    required this.ruleCode,
    required this.title,
    required this.severity,
    required this.regulationReference,
    required this.claimText,
    required this.auditFinding,
    required this.recommendation,
  });

  factory ViolationItem.fromJson(Map<String, dynamic> json) {
    return ViolationItem(
      ruleCode: json['rule_code'] as String? ?? '',
      title: json['title'] as String? ?? 'Statutory Violation',
      severity: json['severity'] as String? ?? 'High',
      regulationReference: json['regulation_reference'] as String? ?? 'FSSAI Section 23',
      claimText: json['claim_text'] as String? ?? '',
      auditFinding: json['audit_finding'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'rule_code': ruleCode,
    'title': title,
    'severity': severity,
    'regulation_reference': regulationReference,
    'claim_text': claimText,
    'audit_finding': auditFinding,
    'recommendation': recommendation,
  };
}

class AlternativeProduct {
  final String name;
  final String brand;
  final int truthScore;
  final String whyBetter;

  AlternativeProduct({
    required this.name,
    required this.brand,
    required this.truthScore,
    required this.whyBetter,
  });

  factory AlternativeProduct.fromJson(Map<String, dynamic> json) {
    return AlternativeProduct(
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      truthScore: (json['truth_score'] as num?)?.toInt() ?? 90,
      whyBetter: json['why_better'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'brand': brand,
    'truth_score': truthScore,
    'why_better': whyBetter,
  };
}

class ScanResult {
  final String scanId;
  final String productId;
  final String brandName;
  final String productName;
  final String? barcode;
  final int truthScore;
  final String verdict;
  final String verdictDescription;
  final List<String> marketingClaims;
  final List<ClaimComparison> claimComparisons;
  final List<ViolationItem> violations;
  final List<IngredientItem> ingredients;
  final List<SuspiciousAdditive> suspiciousAdditives;
  final NutritionPer100g nutritionPer100g;
  final List<String> dietaryWarnings;
  final List<AlternativeProduct> healthierAlternatives;
  final bool pdfReportAvailable;
  final DateTime createdAt;

  ScanResult({
    required this.scanId,
    required this.productId,
    required this.brandName,
    required this.productName,
    this.barcode,
    required this.truthScore,
    required this.verdict,
    required this.verdictDescription,
    required this.marketingClaims,
    required this.claimComparisons,
    required this.violations,
    required this.ingredients,
    required this.suspiciousAdditives,
    required this.nutritionPer100g,
    this.dietaryWarnings = const [],
    this.healthierAlternatives = const [],
    this.pdfReportAvailable = true,
    required this.createdAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      scanId: json['scan_id'] as String? ?? 'SCAN-${DateTime.now().millisecondsSinceEpoch}',
      productId: json['product_id'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? 'Unknown Brand',
      productName: json['product_name'] as String? ?? 'Audited Product',
      barcode: json['barcode'] as String?,
      truthScore: (json['truth_score'] as num?)?.toInt() ?? 50,
      verdict: json['verdict'] as String? ?? 'Misleading',
      verdictDescription: json['verdict_description'] as String? ?? '',
      marketingClaims: (json['marketing_claims'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      claimComparisons: (json['claim_comparisons'] as List<dynamic>?)
              ?.map((e) => ClaimComparison.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      violations: (json['violations'] as List<dynamic>?)
              ?.map((e) => ViolationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => IngredientItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suspiciousAdditives: (json['suspicious_additives'] as List<dynamic>?)
              ?.map((e) => SuspiciousAdditive.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nutritionPer100g: NutritionPer100g.fromJson(json['nutrition_per_100g'] as Map<String, dynamic>?),
      dietaryWarnings: (json['dietary_warnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      healthierAlternatives: (json['healthier_alternatives'] as List<dynamic>?)
              ?.map((e) => AlternativeProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pdfReportAvailable: json['pdf_report_available'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class RecentScanItem {
  final String id;
  final String productId;
  final String productName;
  final String brandName;
  final int truthScore;
  final String verdict;
  final int claimsCount;
  final int violationsCount;
  final DateTime createdAt;

  RecentScanItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.truthScore,
    required this.verdict,
    required this.claimsCount,
    required this.violationsCount,
    required this.createdAt,
  });

  factory RecentScanItem.fromJson(Map<String, dynamic> json) {
    return RecentScanItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Product',
      brandName: json['brand_name'] as String? ?? 'Brand',
      truthScore: (json['truth_score'] as num?)?.toInt() ?? 50,
      verdict: json['verdict'] as String? ?? 'Misleading',
      claimsCount: (json['claims_count'] as num?)?.toInt() ?? 0,
      violationsCount: (json['violations_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
