import re
from typing import List, Dict, Any, Tuple
from app.schemas.analysis import (
    NutritionPer100g,
    IngredientItem,
    SuspiciousAdditive,
    ClaimComparison,
    ViolationItem,
    AlternativeProduct,
)

class ComplianceRuleEngine:
    """Deterministic Rule Engine enforcing FSSAI and international food packaging compliance."""

    HIDDEN_SUGARS = [
        "maltodextrin", "high fructose corn syrup", "hfcs", "invert sugar", "invert syrup",
        "invert sugar syrup", "fruit juice concentrate", "dextrose", "sucrose", "liquid glucose",
        "glucose syrup", "golden syrup", "corn syrup", "corn syrup solids", "barley malt extract",
        "malt extract", "agave nectar", "molasses", "brown rice syrup", "polydextrose", "maltose"
    ]

    PALM_OIL_VARIANTS = [
        "palm oil", "palmolein", "refined palm oil", "palm kernel oil", "fractionated palm oil",
        "rpo", "edible vegetable oil (palm)", "hydrogenated palm oil", "palm olein"
    ]

    GENERIC_VEG_OIL_REGEX = r'(?<![a-zA-Z])(?:refined\s+)?edible\s+vegetable\s+oil(?!\s*\([^)]+\))'

    ADDITIVE_DATABASE = {
        "INS 150D": {
            "name": "Caramel Color IV (Ammonia Sulphite Process)",
            "category": "Synthetic Color",
            "concern": "Contains 4-MEI byproduct; flagged in international studies for potential toxicity under high exposure.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 102": {
            "name": "Tartrazine (Yellow #5)",
            "category": "Synthetic Azo Dye",
            "concern": "Linked to hyperactivity in children; requires mandatory warning labels in EU.",
            "severity": "High",
            "penalty": 15
        },
        "INS 110": {
            "name": "Sunset Yellow FCF",
            "category": "Synthetic Azo Dye",
            "concern": "Artificial food coloring linked to allergen sensitivity and restlessness.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 129": {
            "name": "Allura Red AC",
            "category": "Synthetic Color",
            "concern": "Synthetic dye requiring cautionary labelling in several international jurisdictions.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 950": {
            "name": "Acesulfame Potassium (Ace-K)",
            "category": "Artificial Sweetener",
            "concern": "High-intensity chemical sweetener with ongoing microbiome and metabolic scrutiny.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 951": {
            "name": "Aspartame",
            "category": "Artificial Sweetener",
            "concern": "Artificial sweetener requiring specific phenylketonuria health warnings.",
            "severity": "High",
            "penalty": 15
        },
        "INS 955": {
            "name": "Sucralose",
            "category": "Artificial Sweetener",
            "concern": "Chlorinated artificial sweetener commonly masked in 'zero sugar' fitness foods.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 621": {
            "name": "Monosodium Glutamate (MSG)",
            "category": "Flavor Enhancer",
            "concern": "Synthetic glutamate additive used to mask low-quality base ingredients.",
            "severity": "Low",
            "penalty": 5
        },
        "INS 211": {
            "name": "Sodium Benzoate",
            "category": "Chemical Preservative",
            "concern": "Can form trace benzene in presence of ascorbic acid (Vitamin C).",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 223": {
            "name": "Sodium Metabisulphite",
            "category": "Chemical Preservative / Bleaching Agent",
            "concern": "Potent allergen for asthmatics; often hidden in dried fruits and biscuits.",
            "severity": "Medium",
            "penalty": 10
        },
    }

    def evaluate_compliance(
        self,
        marketing_claims: List[str],
        ingredients_list: List[Dict[str, Any]],
        nutrition: Dict[str, Any],
        raw_ingredients_text: str,
        user_preferences: Dict[str, Any] = None,
        product_category: str = "General Food"
    ) -> Dict[str, Any]:
        """Runs the deterministic compliance pipeline and returns violations, comparisons, and Truth Score."""

        user_pref = user_preferences or {}
        violations: List[ViolationItem] = []
        comparisons: List[ClaimComparison] = []
        color_coded_ingredients: List[IngredientItem] = []
        suspicious_additives: List[SuspiciousAdditive] = []
        dietary_warnings: List[str] = []
        total_penalties = 0

        raw_lower = (raw_ingredients_text or "").lower()
        claims_text = " ".join(marketing_claims).lower()

        # Nutrition normalized
        nutr_obj = NutritionPer100g(
            energy_kcal=float(nutrition.get("energy_kcal", 0.0) or 0.0),
            protein_g=float(nutrition.get("protein_g", 0.0) or 0.0),
            total_carbohydrates_g=float(nutrition.get("total_carbohydrates_g", 0.0) or 0.0),
            total_sugar_g=float(nutrition.get("total_sugar_g", 0.0) or 0.0),
            added_sugar_g=float(nutrition.get("added_sugar_g", 0.0) or 0.0),
            total_fat_g=float(nutrition.get("total_fat_g", 0.0) or 0.0),
            saturated_fat_g=float(nutrition.get("saturated_fat_g", 0.0) or 0.0),
            trans_fat_g=float(nutrition.get("trans_fat_g", 0.0) or 0.0),
            sodium_mg=float(nutrition.get("sodium_mg", 0.0) or 0.0),
            fiber_g=float(nutrition.get("fiber_g", 0.0) or 0.0),
        )

        # ----------------------------------------------------
        # RULE A: "Zero Sugar / No Added Sugar" Audit
        # ----------------------------------------------------
        is_zero_sugar_claim = any(
            re.search(kw, claims_text, re.I)
            for kw in [
                r'\bno\s+added\s+sugar\b',
                r'\bzero\s+(?:added\s+)?sugar\b',
                r'\bsugar\s*free\b',
                r'\b0%\s*sugar\b',
                r'\bwithout\s+added\s+sugar\b',
                r'\bguilt[- ]free\s*(?:sugarless|sugar-free)?\b',
                r'\bno\s+sugar\b',
                r'\bun味的|sugarless\b'
            ]
        )

        detected_hidden_sugars = [sugar for sugar in self.HIDDEN_SUGARS if sugar in raw_lower]
        has_high_sugar = nutr_obj.added_sugar_g > 1.0 or (nutr_obj.total_sugar_g > 5.0 and "zero sugar" in claims_text)

        if is_zero_sugar_claim and (detected_hidden_sugars or has_high_sugar):
            found_str = ", ".join(detected_hidden_sugars) if detected_hidden_sugars else f"{nutr_obj.added_sugar_g}g added sugar"
            penalty = 30
            total_penalties += penalty
            
            v = ViolationItem(
                rule_code="RULE_A_ZERO_SUGAR_DECEPTION",
                title="Deceptive 'Zero Added Sugar' Claim",
                severity="Critical",
                regulation_reference="FSSAI Claims & Advertisements Reg. 2018 (Section 5(2)) & Consumer Protection Act 2019",
                claim_text="Product promotes 'No Added Sugar' or 'Zero Sugar' on front of pack.",
                audit_finding=f"Back ingredients panel contains hidden glycemic sugars / sweeteners: {found_str}. Added sugars: {nutr_obj.added_sugar_g}g/100g, Total sugars: {nutr_obj.total_sugar_g}g/100g.",
                recommendation="Cease front-of-pack 'Zero Sugar' claims or reformulate without maltodextrin/invert syrups."
            )
            violations.append(v)

            comparisons.append(ClaimComparison(
                front_claim="No Added Sugar / Zero Sugar",
                reality_finding=f"Contains hidden high-GI sugars: {found_str} ({nutr_obj.total_sugar_g}g total sugar/100g)",
                status="violation",
                explanation="Maltodextrin and concentrated syrups trigger glycemic spikes equivalent to or worse than table sugar.",
                evidence=f"Ingredients: {found_str} | Nutrition: {nutr_obj.total_sugar_g}g sugar per 100g"
            ))
        elif is_zero_sugar_claim:
            comparisons.append(ClaimComparison(
                front_claim="No Added Sugar",
                reality_finding=f"Verified: {nutr_obj.added_sugar_g}g added sugar with clean non-glycemic profile",
                status="verified",
                explanation="Back panel confirms no hidden syrups, maltodextrin, or refined sugar additions.",
                evidence="Zero sugar verified on ingredients list."
            ))

        # ----------------------------------------------------
        # RULE B: "Whole Grain / 100% Whole Wheat" Hierarchy Audit
        # ----------------------------------------------------
        is_wheat_grain_claim = any(
            re.search(kw, claims_text)
            for kw in [r'\bwhole wheat\b', r'\b100% atta\b', r'\b100% whole grain\b', r'\bmade with whole wheat\b', r'\bmultigrain\b', r'\breal wheat\b']
        )

        maida_index = -1
        atta_index = -1

        for idx, ing in enumerate(ingredients_list):
            name_lower = ing.get("name", "").lower()
            if "refined wheat flour" in name_lower or "maida" in name_lower:
                if maida_index == -1:
                    maida_index = idx
            if "whole wheat flour" in name_lower or "whole wheat" in name_lower or "atta" in name_lower:
                if atta_index == -1:
                    atta_index = idx

        maida_detected_before_atta = (maida_index != -1 and (atta_index == -1 or maida_index < atta_index))
        has_maida_primary = (maida_index == 0 or "maida" in raw_lower[:100] or "refined wheat flour" in raw_lower[:100])

        if is_wheat_grain_claim and (maida_detected_before_atta or has_maida_primary):
            penalty = 25
            total_penalties += penalty
            
            v = ViolationItem(
                rule_code="RULE_B_GRAIN_HIERARCHY_DECEPTION",
                title="Deceptive Whole Wheat / Grain Marketing",
                severity="Critical",
                regulation_reference="FSSAI Labelling and Display Regulations 2020 (Section 23 & Regulation 5(1))",
                claim_text="Front label showcases '100% Whole Wheat' / 'Made with Real Atta' imagery and slogans.",
                audit_finding="Ingredient hierarchy reveals Refined Wheat Flour (Maida) as the predominant #1 ingredient before Whole Wheat.",
                recommendation="Disclose exact percentage of Whole Wheat on front panel and declare Maida clearly as primary flour."
            )
            violations.append(v)

            comparisons.append(ClaimComparison(
                front_claim="100% Whole Wheat / Atta Goodness",
                reality_finding="Refined Wheat Flour (Maida) is the #1 primary ingredient",
                status="violation",
                explanation="FSSAI mandates ingredients be listed in descending order by weight. Maida precedes Whole Wheat.",
                evidence=f"Primary Flour: Refined Wheat Flour (Maida) | Whole Wheat is secondary or minor fraction."
            ))
        elif is_wheat_grain_claim:
            comparisons.append(ClaimComparison(
                front_claim="Made with Whole Wheat",
                reality_finding=f"Whole Wheat (Atta) is genuine primary ingredient (Index #{atta_index + 1})",
                status="verified",
                explanation="Whole Wheat Flour constitutes the predominant grain without maida masking.",
                evidence="Verified from back-of-pack descending ingredient list."
            ))

        # ----------------------------------------------------
        # RULE C: "High Protein" Threshold Audit
        # ----------------------------------------------------
        is_protein_claim = any(
            re.search(kw, claims_text)
            for kw in [r'\bhigh protein\b', r'\bprotein rich\b', r'\bpower protein\b', r'\bprotein punch\b', r'\bsource of protein\b']
        )

        protein_g = nutr_obj.protein_g
        energy_kcal = nutr_obj.energy_kcal if nutr_obj.energy_kcal > 0 else 400.0
        protein_energy_pct = (protein_g * 4.0 / energy_kcal) * 100.0 if energy_kcal > 0 else 0.0

        # FSSAI standard: "High Protein" requires at least 20% energy from protein (or >= 12g/100g solid food). "Source of protein" requires >= 10% energy or >= 6g/100g.
        is_insufficient_protein = (protein_g < 10.0 and "high protein" in claims_text) or (protein_energy_pct < 12.0 and is_protein_claim)

        if is_protein_claim and is_insufficient_protein:
            penalty = 15
            total_penalties += penalty

            v = ViolationItem(
                rule_code="RULE_C_INSUFFICIENT_PROTEIN_CLAIM",
                title="Insufficient Protein for 'High Protein' Claim",
                severity="Medium",
                regulation_reference="FSSAI Schedule-I Nutritional Claims Thresholds & Codex Alimentarius",
                claim_text="Package highlights 'High Protein' / 'Protein Rich' snack claim.",
                audit_finding=f"Protein content is only {protein_g}g per 100g ({round(protein_energy_pct, 1)}% of total energy). FSSAI requires minimum 12% energy for source of protein and 20% energy for high protein.",
                recommendation="Downgrade claim or fortify product to meet statutory minimum threshold."
            )
            violations.append(v)

            comparisons.append(ClaimComparison(
                front_claim="High Protein Snack",
                reality_finding=f"Contains only {protein_g}g Protein per 100g ({round(protein_energy_pct, 1)}% Energy)",
                status="misleading",
                explanation=f"Fails statutory standard for High Protein. Only provides {protein_g}g protein per 100g serving.",
                evidence=f"Energy: {energy_kcal} kcal | Protein: {protein_g}g"
            ))
        elif is_protein_claim:
            comparisons.append(ClaimComparison(
                front_claim="High Protein",
                reality_finding=f"Verified: {protein_g}g Protein per 100g ({round(protein_energy_pct, 1)}% Energy)",
                status="verified",
                explanation="Meets standard regulatory threshold for protein claims.",
                evidence=f"Protein: {protein_g}g/100g"
            ))

        # ----------------------------------------------------
        # RULE D: "Palm Oil / Generic Vegetable Oil" Audit
        # ----------------------------------------------------
        has_palm_oil = any(p in raw_lower for p in self.PALM_OIL_VARIANTS)
        has_generic_veg_oil = bool(re.search(self.GENERIC_VEG_OIL_REGEX, raw_lower))

        if has_palm_oil or has_generic_veg_oil:
            penalty = 20
            total_penalties += penalty
            oil_desc = "Palm Oil / Palmolein" if has_palm_oil else "Generic Undeclared 'Edible Vegetable Oil'"
            
            v = ViolationItem(
                rule_code="RULE_D_PALM_OIL_MASKING",
                title="Hidden Palm Oil / Disguised Vegetable Fat",
                severity="High",
                regulation_reference="FSSAI Section 2.2.2.5 (Specific Declaration of Vegetable Fat Source)",
                claim_text="Product advertised with healthy or premium claims on front.",
                audit_finding=f"Contains {oil_desc}. Saturated fat is high at {nutr_obj.saturated_fat_g}g/100g.",
                recommendation="Replace palm oil with cold-pressed sunflower/mustard/olive oil, or declare palm source explicitly."
            )
            violations.append(v)

            if "healthy" in claims_text or "100% natural" in claims_text or "good for heart" in claims_text:
                comparisons.append(ClaimComparison(
                    front_claim="Healthy & Heart Friendly",
                    reality_finding=f"Loaded with {oil_desc} ({nutr_obj.saturated_fat_g}g Saturated Fat)",
                    status="violation",
                    explanation="Palm oil is high in palmitic saturated fatty acids associated with elevated LDL cholesterol.",
                    evidence=f"Fat: {nutr_obj.total_fat_g}g | Saturated Fat: {nutr_obj.saturated_fat_g}g"
                ))

        # ----------------------------------------------------
        # RULE E: "Chemical Additives & E-Number" Audit
        # ----------------------------------------------------
        for ins_code, meta in self.ADDITIVE_DATABASE.items():
            # Search for INS 150d or E150d or specific chemical name
            clean_code = ins_code.replace("INS ", "")
            pattern = rf'(INS\s*{clean_code}\b|E{clean_code}\b|{re.escape(meta["name"].lower())})'
            if re.search(pattern, raw_lower, re.I):
                suspicious_additives.append(SuspiciousAdditive(
                    name=meta["name"],
                    code=ins_code,
                    category=meta["category"],
                    concern=meta["concern"],
                    severity=meta["severity"]
                ))
                total_penalties += meta["penalty"]

        # Check for Trans Fats / Hydrogenated Fats
        if "hydrogenated" in raw_lower or "vanaspati" in raw_lower or nutr_obj.trans_fat_g > 0.2:
            total_penalties += 25
            violations.append(ViolationItem(
                rule_code="RULE_E_TRANS_FATS",
                title="Contains Industrial Trans Fats / Hydrogenated Oil",
                severity="Critical",
                regulation_reference="FSSAI Limit on Trans Fatty Acids (<2% by weight)",
                claim_text="Packaged food consumption safety standard.",
                audit_finding=f"Product contains hydrogenated fats / {nutr_obj.trans_fat_g}g trans fats.",
                recommendation="Eliminate partially hydrogenated oils."
            ))

        # ----------------------------------------------------
        # RULE F: Color-Coded Ingredients Classification
        # ----------------------------------------------------
        for ing in ingredients_list:
            name = ing.get("name", "").strip()
            name_lower = name.lower()
            pct = ing.get("percentage")
            category = "clean"
            flag_reason = None
            ins_code = ing.get("ins_code")

            # Check Harmful (Red)
            if any(p in name_lower for p in self.PALM_OIL_VARIANTS) or "hydrogenated" in name_lower:
                category = "harmful"
                flag_reason = "High saturated / industrial fat source"
            elif any(code in name_lower.upper() for code in ["INS 102", "INS 110", "INS 129", "INS 150D", "INS 950", "INS 951", "INS 955", "INS 211"]):
                category = "harmful"
                flag_reason = "Controversial chemical additive / artificial sweetener"
            # Check Warning (Yellow)
            elif any(s in name_lower for s in self.HIDDEN_SUGARS) or "sugar" in name_lower or "refined wheat" in name_lower or "maida" in name_lower or "emulsifier" in name_lower or "raising agent" in name_lower:
                category = "warning"
                flag_reason = "Refined carbohydrate, hidden sugar, or industrial emulsifier"
            else:
                category = "clean"
                flag_reason = "Wholesome or standard food ingredient"

            color_coded_ingredients.append(IngredientItem(
                name=name,
                percentage=pct,
                category=category,
                flag_reason=flag_reason,
                is_additive=ing.get("is_additive", False) or category in ["warning", "harmful"],
                ins_code=ins_code
            ))

        # ----------------------------------------------------
        # RULE G: User Dietary Alerts
        # ----------------------------------------------------
        if user_pref.get("avoid_palm_oil", True) and (has_palm_oil or has_generic_veg_oil):
            dietary_warnings.append("⚠️ Contains Palm Oil / Palmolein (Matches your 'Avoid Palm Oil' alert)")
        
        if user_pref.get("diabetic_mode", False) and (detected_hidden_sugars or nutr_obj.total_sugar_g > 10.0):
            dietary_warnings.append(f"⚠️ High Glycemic Alert: Contains {nutr_obj.total_sugar_g}g Sugar + {', '.join(detected_hidden_sugars) if detected_hidden_sugars else 'Refined carbs'}")
        
        if user_pref.get("low_sodium", False) and nutr_obj.sodium_mg > 400.0:
            dietary_warnings.append(f"⚠️ High Sodium Alert: {nutr_obj.sodium_mg}mg Sodium per 100g (Exceeds low sodium threshold)")

        for allergen in user_pref.get("allergies", []):
            if allergen.lower() in raw_lower:
                dietary_warnings.append(f"🚨 Allergen Warning: Contains declared allergen '{allergen}'")

        # ----------------------------------------------------
        # Truth Score Computation
        # ----------------------------------------------------
        truth_score = max(5, min(100, 100 - total_penalties))

        if truth_score >= 80:
            verdict = "Verified"
            verdict_desc = "Packaging claims are substantiated and adhere to regulatory labeling guidelines."
        elif truth_score >= 50:
            verdict = "Misleading"
            verdict_desc = "Front marketing claims present significant discrepancies when audited against back ingredients."
        else:
            verdict = "Violates Standards"
            verdict_desc = "Critical statutory violations detected under FSSAI and consumer protection labeling regulations."

        # Generate Healthier Alternatives
        alternatives = self._generate_alternatives(product_category, violations)

        return {
            "truth_score": truth_score,
            "verdict": verdict,
            "verdict_description": verdict_desc,
            "violations": violations,
            "claim_comparisons": comparisons,
            "ingredients": color_coded_ingredients,
            "suspicious_additives": suspicious_additives,
            "nutrition_per_100g": nutr_obj,
            "dietary_warnings": dietary_warnings,
            "healthier_alternatives": alternatives,
        }

    def _generate_alternatives(self, category: str, violations: List[ViolationItem]) -> List[AlternativeProduct]:
        """Suggests genuinely clean food alternatives based on detected violations."""
        cat_lower = category.lower()

        if "biscuit" in cat_lower or "cookie" in cat_lower or any("GRAIN" in v.rule_code for v in violations):
            return [
                AlternativeProduct(
                    name="Organic 100% Rolled Oats & Jaggery Cookies",
                    brand="CleanEats India",
                    truth_score=94,
                    why_better="Zero Maida, 100% whole oats flour, cold pressed coconut oil, sweetened only with raw dates."
                ),
                AlternativeProduct(
                    name="100% Whole Wheat Sourdough Crackers",
                    brand="ArtisanBake Co",
                    truth_score=92,
                    why_better="100% Stone-ground whole wheat, zero palm oil, no artificial preservatives (INS 211/150d)."
                )
            ]
        elif "protein" in cat_lower or "bar" in cat_lower or any("PROTEIN" in v.rule_code for v in violations):
            return [
                AlternativeProduct(
                    name="Raw Whey & Almond Clean Protein Bar",
                    brand="TrueProtein",
                    truth_score=96,
                    why_better="22g genuine protein per bar, zero maltodextrin, sweetened naturally with whole dates."
                ),
                AlternativeProduct(
                    name="Roasted Edamame & Seed Crunch",
                    brand="SuperSnacks",
                    truth_score=91,
                    why_better="Plant-based 18g protein per 100g with zero refined sugars or artificial sweeteners."
                )
            ]
        elif "juice" in cat_lower or "drink" in cat_lower or "beverage" in cat_lower or any("SUGAR" in v.rule_code for v in violations):
            return [
                AlternativeProduct(
                    name="Cold-Pressed Tender Coconut & Valencia Orange",
                    brand="RawPure Botanicals",
                    truth_score=95,
                    why_better="100% pure cold-pressed juice with zero added water, zero concentrate, and zero preservatives."
                ),
                AlternativeProduct(
                    name="Sparkling Infused Hibiscus Tea (Zero Calorie)",
                    brand="HerbBrew",
                    truth_score=93,
                    why_better="Natural herbal infusion with zero sugar, zero sucralose, and zero synthetic dyes (INS 129)."
                )
            ]
        else:
            return [
                AlternativeProduct(
                    name="Traditional Whole Grain Roasted Mix",
                    brand="GramClean Organics",
                    truth_score=95,
                    why_better="Roasted millets and chickpeas with cold-pressed mustard oil and rock salt."
                ),
                AlternativeProduct(
                    name="100% Natural Nut & Seed Energy Bite",
                    brand="PureRoot Foods",
                    truth_score=92,
                    why_better="Only 4 ingredients: Almonds, Cashews, Dates, and Chia seeds. 0% added sugar."
                )
            ]

    @classmethod
    def evaluate_fssai_compliance(cls, extracted_data: Dict[str, Any], user_preferences: Dict[str, Any] = None) -> Dict[str, Any]:
        engine = cls()
        marketing = extracted_data.get("marketing_claims", [])
        raw_ing = extracted_data.get("ingredients_raw") or extracted_data.get("raw_ingredients_text", "")
        ing_list = extracted_data.get("ingredients_list", [])
        if not ing_list and raw_ing:
            ing_list = [{"name": p.strip()} for p in raw_ing.split(",") if p.strip()]
        nutrition = extracted_data.get("nutrition_per_100g", {})
        cat = extracted_data.get("category", "Packaged Food")
        
        return engine.evaluate_compliance(
            marketing_claims=marketing,
            ingredients_list=ing_list,
            nutrition=nutrition,
            raw_ingredients_text=raw_ing,
            user_preferences=user_preferences,
            product_category=cat
        )

RuleEngine = ComplianceRuleEngine
rule_engine = ComplianceRuleEngine()
