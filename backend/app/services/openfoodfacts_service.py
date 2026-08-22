import httpx
from datetime import datetime
from typing import Optional, Dict, Any, Tuple
from app.services.rule_engine import RuleEngine
from app.schemas.analysis import AnalysisResponse, NutritionPer100g

class OpenFoodFactsService:
    BASE_URL = "https://world.openfoodfacts.org/api/v2/product"
    USER_AGENT = "LabelTruth-FSSAI-Compliance-App/1.0 (https://github.com/masterSahib/Hackathon; support@labeltruth.in)"

    @classmethod
    async def fetch_product_by_barcode(cls, barcode: str) -> Optional[Dict[str, Any]]:
        """Fetch raw product data from Open Food Facts API."""
        clean_barcode = barcode.strip().replace(" ", "").replace("-", "")
        url = f"{cls.BASE_URL}/{clean_barcode}.json"
        
        headers = {
            "User-Agent": cls.USER_AGENT,
            "Accept": "application/json",
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    if data.get("status") == 1 and "product" in data:
                        return data["product"]
                return None
        except Exception as e:
            print(f"[OpenFoodFactsService] Error fetching barcode {clean_barcode}: {e}")
            return None

    @classmethod
    def parse_and_audit(
        cls,
        product_data: Dict[str, Any],
        barcode: str,
        user_preferences: Optional[Dict[str, Any]] = None
    ) -> AnalysisResponse:
        """Parse Open Food Facts raw product data and execute FSSAI compliance audit."""
        brand_name = product_data.get("brands") or product_data.get("brand_owner") or "Unknown Brand"
        if "," in brand_name:
            brand_name = brand_name.split(",")[0].strip()

        product_name = (
            product_data.get("product_name_en")
            or product_data.get("product_name")
            or product_data.get("generic_name")
            or f"Product {barcode}"
        )

        ingredients_text = (
            product_data.get("ingredients_text_en")
            or product_data.get("ingredients_text")
            or product_data.get("ingredients_text_in")
            or ""
        )

        labels_tags = product_data.get("labels_tags", [])
        clean_claims = []
        for tag in labels_tags:
            tag_clean = tag.replace("en:", "").replace("-", " ").title()
            if tag_clean and tag_clean not in clean_claims:
                clean_claims.append(tag_clean)

        lower_name = product_name.lower()
        if "whole wheat" in lower_name or "atta" in lower_name:
            if "100% Whole Wheat" not in clean_claims:
                clean_claims.append("100% Whole Wheat / Atta")
        if "zero sugar" in lower_name or "no added sugar" in lower_name or "sugar free" in lower_name:
            if "Zero Added Sugar" not in clean_claims:
                clean_claims.append("Zero Added Sugar")
        if "protein" in lower_name or "high protein" in lower_name:
            if "High Protein" not in clean_claims:
                clean_claims.append("High Protein")
        if "organic" in lower_name:
            if "100% Organic" not in clean_claims:
                clean_claims.append("100% Organic")
        if "digestive" in lower_name:
            clean_claims.append("High Dietary Fibre & Digestive Goodness")

        if not clean_claims:
            clean_claims = [f"{brand_name} {product_name} Healthy Formulation"]

        nutriments = product_data.get("nutriments", {})
        
        energy_kcal = float(
            nutriments.get("energy-kcal_100g")
            or nutriments.get("energy-kcal")
            or (float(nutriments.get("energy_100g", 0)) / 4.184)
            or 0.0
        )
        
        total_sugar = float(nutriments.get("sugars_100g") or nutriments.get("sugars") or 0.0)
        added_sugar = float(nutriments.get("added-sugars_100g") or nutriments.get("added-sugars") or 0.0)
        if added_sugar == 0.0 and total_sugar > 5.0:
            if any(s in ingredients_text.lower() for s in ["sugar", "invert syrup", "maltodextrin", "glucose", "corn syrup"]):
                added_sugar = round(total_sugar * 0.85, 1)

        protein_g = float(nutriments.get("proteins_100g") or nutriments.get("proteins") or 0.0)
        total_fat = float(nutriments.get("fat_100g") or nutriments.get("fat") or 0.0)
        saturated_fat = float(nutriments.get("saturated-fat_100g") or nutriments.get("saturated-fat") or 0.0)
        trans_fat = float(nutriments.get("trans-fat_100g") or nutriments.get("trans-fat") or 0.0)

        sodium_mg = float(nutriments.get("sodium_100g", 0)) * 1000.0
        if sodium_mg == 0.0:
            salt_g = float(nutriments.get("salt_100g") or nutriments.get("salt") or 0.0)
            sodium_mg = round(salt_g * 400.0, 1)

        fiber_g = float(nutriments.get("fiber_100g") or nutriments.get("fiber") or 0.0)
        total_carbs = float(nutriments.get("carbohydrates_100g") or nutriments.get("carbohydrates") or 0.0)

        nutrition = NutritionPer100g(
            energy_kcal=round(energy_kcal, 1),
            protein_g=round(protein_g, 1),
            total_carbohydrates_g=round(total_carbs, 1),
            total_sugar_g=round(total_sugar, 1),
            added_sugar_g=round(added_sugar, 1),
            total_fat_g=round(total_fat, 1),
            saturated_fat_g=round(saturated_fat, 1),
            trans_fat_g=round(trans_fat, 2),
            sodium_mg=round(sodium_mg, 1),
            fiber_g=round(fiber_g, 1),
        )

        extracted_data = {
            "brand_name": brand_name,
            "product_name": product_name,
            "category": product_data.get("categories", "Packaged Food"),
            "marketing_claims": clean_claims,
            "ingredients_raw": ingredients_text,
            "nutrition_per_100g": nutrition.dict(),
        }

        eval_dict = RuleEngine.evaluate_fssai_compliance(
            extracted_data=extracted_data,
            user_preferences=user_preferences,
        )

        return AnalysisResponse(
            scan_id=f"SCAN-OFF-{barcode}",
            product_id=f"PROD-{barcode}",
            brand_name=brand_name,
            product_name=product_name,
            barcode=barcode,
            truth_score=eval_dict["truth_score"],
            verdict=eval_dict["verdict"],
            verdict_description=eval_dict["verdict_description"],
            marketing_claims=clean_claims,
            claim_comparisons=eval_dict["claim_comparisons"],
            violations=eval_dict["violations"],
            ingredients=eval_dict["ingredients"],
            suspicious_additives=eval_dict["suspicious_additives"],
            nutrition_per_100g=eval_dict["nutrition_per_100g"],
            dietary_warnings=eval_dict["dietary_warnings"],
            healthier_alternatives=eval_dict["healthier_alternatives"],
            pdf_report_available=True,
            created_at=datetime.utcnow(),
        )
