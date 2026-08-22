from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime

class NutritionPer100g(BaseModel):
    energy_kcal: Optional[float] = Field(0.0, description="Energy in kcal per 100g")
    protein_g: Optional[float] = Field(0.0, description="Protein in grams per 100g")
    total_carbohydrates_g: Optional[float] = Field(0.0, description="Total Carbohydrates in grams per 100g")
    total_sugar_g: Optional[float] = Field(0.0, description="Total Sugar in grams per 100g")
    added_sugar_g: Optional[float] = Field(0.0, description="Added Sugar in grams per 100g")
    total_fat_g: Optional[float] = Field(0.0, description="Total Fat in grams per 100g")
    saturated_fat_g: Optional[float] = Field(0.0, description="Saturated Fat in grams per 100g")
    trans_fat_g: Optional[float] = Field(0.0, description="Trans Fat in grams per 100g")
    sodium_mg: Optional[float] = Field(0.0, description="Sodium in mg per 100g")
    fiber_g: Optional[float] = Field(0.0, description="Dietary Fiber in grams per 100g")

class IngredientItem(BaseModel):
    name: str
    percentage: Optional[float] = None
    category: str = "neutral"  # clean (green), warning (yellow), harmful (red)
    flag_reason: Optional[str] = None
    is_additive: bool = False
    ins_code: Optional[str] = None

class SuspiciousAdditive(BaseModel):
    name: str
    code: Optional[str] = None  # e.g., INS 150d, INS 621, INS 955
    category: str  # Artificial Sweetener, Synthetic Color, Preservative, Palm Fraction, Emulsifier
    concern: str
    severity: str = "Medium"  # Low, Medium, High, Critical

class ClaimComparison(BaseModel):
    front_claim: str
    reality_finding: str
    status: str  # verified (green), misleading (amber), violation (red)
    explanation: str
    evidence: str

class ViolationItem(BaseModel):
    rule_code: str
    title: str
    severity: str  # Low, Medium, High, Critical
    regulation_reference: str  # e.g., "FSSAI Packaging and Labelling Reg. 2020 Sec 23"
    claim_text: str
    audit_finding: str
    recommendation: str

class AlternativeProduct(BaseModel):
    name: str
    brand: str
    truth_score: int
    why_better: str

class AnalysisRequest(BaseModel):
    barcode: Optional[str] = None
    brand_name: Optional[str] = None
    product_name: Optional[str] = None
    front_image_base64: Optional[str] = None
    back_image_base64: Optional[str] = None
    raw_marketing_text: Optional[str] = None
    raw_ingredients_text: Optional[str] = None
    raw_nutrition_text: Optional[str] = None
    user_dietary_preferences: Optional[Dict[str, Any]] = None

class AnalysisResponse(BaseModel):
    scan_id: str
    product_id: str
    brand_name: str
    product_name: str
    barcode: Optional[str] = None
    truth_score: int
    verdict: str  # "Verified", "Misleading", "Violates Standards"
    verdict_description: str
    marketing_claims: List[str]
    claim_comparisons: List[ClaimComparison]
    violations: List[ViolationItem]
    ingredients: List[IngredientItem]
    suspicious_additives: List[SuspiciousAdditive]
    nutrition_per_100g: NutritionPer100g
    dietary_warnings: List[str] = []
    healthier_alternatives: List[AlternativeProduct] = []
    pdf_report_available: bool = True
    created_at: datetime
