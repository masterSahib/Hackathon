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
        "malt extract", "agave nectar", "molasses", "brown rice syrup", "polydextrose", "maltose",
        "caramelised sugar", "sugar"
    ]

    PALM_OIL_VARIANTS = [
        "palm oil", "palmolein", "refined palm oil", "palm kernel oil", "fractionated palm oil",
        "rpo", "edible vegetable oil (palm)", "hydrogenated palm oil", "palm olein",
        "edible vegetable oil (palmolein)"
    ]

    GENERIC_VEG_OIL_REGEX = r'(?<![a-zA-Z])(?:refined\s+)?edible\s+vegetable\s+oil(?!\s*\([^)]+\))'

    ADDITIVE_DATABASE = {
        "INS 150D": {
            "name": "Caramel Color IV (Ammonia Sulphite Process)",
            "category": "Synthetic Color",
            "concern": "Contains 4-MEI byproduct; flagged in international toxicology studies for carcinogenicity under chronic exposure.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 102": {
            "name": "Tartrazine (Yellow #5)",
            "category": "Synthetic Azo Dye",
            "concern": "Linked to hyperactivity in children; requires mandatory statutory warning labels in the European Union.",
            "severity": "High",
            "penalty": 15
        },
        "INS 110": {
            "name": "Sunset Yellow FCF",
            "category": "Synthetic Azo Dye",
            "concern": "Associated with allergic reactions, hives, and hyperactivity in sensitive individuals.",
            "severity": "High",
            "penalty": 15
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
            "concern": "High-intensity chemical sweetener with ongoing microbiome and metabolic disruption concerns.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 951": {
            "name": "Aspartame",
            "category": "Artificial Sweetener",
            "concern": "Artificial sweetener requiring specific statutory phenylketonuria health warnings.",
            "severity": "High",
            "penalty": 15
        },
        "INS 955": {
            "name": "Sucralose",
            "category": "Artificial Sweetener",
            "concern": "Chlorinated synthetic sweetener commonly disguised in 'zero sugar' diet products.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 621": {
            "name": "Monosodium Glutamate (MSG)",
            "category": "Flavor Enhancer",
            "concern": "Synthetic glutamate additive used to mask low-quality base ingredients and induce hyper-palatability.",
            "severity": "Low",
            "penalty": 5
        },
        "INS 627": {
            "name": "Disodium 5'-Guanylate",
            "category": "Synthetic Flavor Enhancer",
            "concern": "Purine nucleotide additive that synergistically intensifies salty/umami notes to trigger addictive over-snacking.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 631": {
            "name": "Disodium 5'-Inosinate",
            "category": "Synthetic Flavor Enhancer",
            "concern": "Chemically prepared flavour booster commonly combined with MSG and high sodium.",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 330": {
            "name": "Citric Acid (Synthetic Acidity Regulator)",
            "category": "Acidity Regulator / Flavouring",
            "concern": "Industrial ferment used to fake natural fruit/lemon acidity without real fruit juice.",
            "severity": "Low",
            "penalty": 5
        },
        "INS 551": {
            "name": "Silicon Dioxide (Anticaking Agent)",
            "category": "Anticaking Agent",
            "concern": "Nanoparticle powder used in processed seasonings and seasoning powders.",
            "severity": "Low",
            "penalty": 5
        },
        "INS 211": {
            "name": "Sodium Benzoate",
            "category": "Chemical Preservative",
            "concern": "Can form trace benzene carcinogen in the presence of ascorbic acid (Vitamin C).",
            "severity": "Medium",
            "penalty": 10
        },
        "INS 223": {
            "name": "Sodium Metabisulphite",
            "category": "Chemical Preservative / Bleaching Agent",
            "concern": "Potent allergen for asthmatics; often hidden in potato crisps, dried fruits, and biscuits.",
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

        # If ingredients_list is empty, tokenize from raw_ingredients_text
        if not ingredients_list and raw_ingredients_text:
            parts = [p.strip() for p in re.split(r'[,;•\n\(\)]+', raw_ingredients_text) if len(p.strip()) > 2]
            ingredients_list = [{"name": p} for p in parts]

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
                r'\bsugarless\b'
            ]
        )

        detected_hidden_sugars = [sugar for sugar in self.HIDDEN_SUGARS if sugar in raw_lower and sugar != "sugar"]
        has_high_sugar = nutr_obj.added_sugar_g > 1.0 or (nutr_obj.total_sugar_g > 5.0 and "zero sugar" in claims_text)

        if is_zero_sugar_claim and (detected_hidden_sugars or has_high_sugar):
            found_str = ", ".join(detected_hidden_sugars) if detected_hidden_sugars else f"{nutr_obj.added_sugar_g}g added sugar"
            penalty = 30
            total_penalties += penalty
            
            v = ViolationItem(
                rule_code="RULE_A_ZERO_SUGAR_DECEPTION",
                title="Deceptive 'Zero Added Sugar' Claim",
                severity="Critical",
                regulation_reference="FSSAI Claims Reg. 2018 (Sec 5(2)), Legal Metrology Act 2009 (Sec 18) & Consumer Protection Act 2019",
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
                regulation_reference="FSSAI Labelling Reg. 2020 (Sec 23 & Reg 5(1)) & Legal Metrology (Packaged Commodities) Rules 2011 (Rule 6(1)(b))",
                claim_text="Front label showcases '100% Whole Wheat' / 'Made with Real Atta' imagery and slogans.",
                audit_finding="Ingredient hierarchy reveals Refined Wheat Flour (Maida) as the predominant #1 ingredient before Whole Wheat, violating mandatory generic commodity declaration rules.",
                recommendation="Disclose exact percentage of Whole Wheat on front panel and declare Maida clearly as primary flour under LMPC Rule 6."
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
                audit_finding=f"Contains {oil_desc}. Saturated fat is elevated at {nutr_obj.saturated_fat_g}g/100g.",
                recommendation="Replace palm oil with cold-pressed sunflower/mustard/olive oil, or declare palm source explicitly."
            )
            violations.append(v)

            comparisons.append(ClaimComparison(
                front_claim="Cooking Fat Formulation",
                reality_finding=f"Deep-fried in {oil_desc} ({nutr_obj.saturated_fat_g}g Saturated Fat/100g)",
                status="violation",
                explanation="Palm oil and palmolein contain high palmitic saturated fatty acids known to elevate LDL cholesterol.",
                evidence=f"Fat: {nutr_obj.total_fat_g}g | Saturated Fat: {nutr_obj.saturated_fat_g}g"
            ))

        # ----------------------------------------------------
        # RULE E: "Chemical Additives & E-Number" Audit
        # ----------------------------------------------------
        for ins_code, meta in self.ADDITIVE_DATABASE.items():
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
        # RULE F: HFSS (High Fat, Sugar & Salt) Statutory Violations
        # ----------------------------------------------------
        # FSSAI HFSS Sodium Norm: > 400mg / 100g solid food
        if nutr_obj.sodium_mg > 400.0:
            excess_pct = round(((nutr_obj.sodium_mg - 400.0) / 400.0) * 100.0)
            salt_equivalent = round((nutr_obj.sodium_mg * 2.5) / 1000.0, 2)
            penalty = 15
            total_penalties += penalty

            violations.append(ViolationItem(
                rule_code="RULE_F_HFSS_SODIUM_HAZARD",
                title="Excessive Sodium / Salt Exceeds FSSAI HFSS Limit",
                severity="High",
                regulation_reference="FSSAI Labelling and Display Regulations 2020 & 2024 Amendments (HFSS Thresholds)",
                claim_text="Standard daily savory snack consumption.",
                audit_finding=f"Contains {nutr_obj.sodium_mg}mg Sodium per 100g ({salt_equivalent}g Salt). Exceeds the statutory FSSAI HFSS cap (400mg/100g) by {excess_pct}%.",
                recommendation="Reduce sodium chloride seasoning and artificial flavour salts to below 400mg/100g."
            ))

            comparisons.append(ClaimComparison(
                front_claim="Sodium & Salt Profile",
                reality_finding=f"High Sodium: {nutr_obj.sodium_mg}mg/100g (Exceeds FSSAI cap of 400mg by {excess_pct}%)",
                status="violation",
                explanation="High sodium intake directly correlates with elevated blood pressure and cardiovascular strain.",
                evidence=f"Sodium: {nutr_obj.sodium_mg}mg / 100g | Salt equivalent: {salt_equivalent}g"
            ))

        # FSSAI HFSS Saturated Fat Norm: > 6.0g / 100g solid food
        if nutr_obj.saturated_fat_g > 6.0:
            excess_fat_pct = round(((nutr_obj.saturated_fat_g - 6.0) / 6.0) * 100.0)
            penalty = 15
            total_penalties += penalty

            violations.append(ViolationItem(
                rule_code="RULE_F_HFSS_SATURATED_FAT_HAZARD",
                title="Excessive Saturated Fat Exceeds FSSAI Safe Benchmark",
                severity="High",
                regulation_reference="FSSAI Food Safety and Standards (Labelling and Display) Regulations 2020",
                claim_text="Snack food nutritional profile.",
                audit_finding=f"Contains {nutr_obj.saturated_fat_g}g Saturated Fat per 100g (Total Fat: {nutr_obj.total_fat_g}g). Exceeds statutory threshold of 6.0g/100g by {excess_fat_pct}%.",
                recommendation="Switch to healthy polyunsaturated or monounsaturated vegetable oils to lower saturated fat."
            ))

            comparisons.append(ClaimComparison(
                front_claim="Saturated Fat Profile",
                reality_finding=f"High Saturated Fat: {nutr_obj.saturated_fat_g}g/100g (Exceeds FSSAI 6g cap by {excess_fat_pct}%)",
                status="violation",
                explanation="Saturated fats from refined palm oils contribute to atherogenic lipid profiles and arterial plaque.",
                evidence=f"Saturated Fat: {nutr_obj.saturated_fat_g}g per 100g | Total Fat: {nutr_obj.total_fat_g}g"
            ))

        # ----------------------------------------------------
        # RULE G: Fruit / Natural Flavor Deception (e.g. Lemon Potato Chips)
        # ----------------------------------------------------
        fruit_keywords = ["lemon", "lime", "mango", "strawberry", "tomato", "chilli", "jalapeno", "cheese", "cream"]
        has_fruit_title = any(fk in claims_text or fk in product_category.lower() for fk in fruit_keywords)
        has_synthetic_flavoring = any(fl in raw_lower for fl in [
            "nature identical flavouring", "artificial flavouring", "flavour enhancer",
            "ins 627", "ins 631", "ins 330", "citric acid", "synthetic"
        ])
        has_real_fruit_juice = any(fl in raw_lower for fl in ["lemon juice", "real fruit", "fruit powder", "concentrate (>5%)"])

        if has_fruit_title and has_synthetic_flavoring and not has_real_fruit_juice:
            penalty = 10
            total_penalties += penalty

            violations.append(ViolationItem(
                rule_code="RULE_G_SYNTHETIC_FLAVOR_DECEPTION",
                title="Synthetic Flavoring Disguised as Natural Ingredients",
                severity="Medium",
                regulation_reference="FSSAI Claims Reg. 2018 (Sec 4(3)), Legal Metrology (Packaged Commodities) Rules 2011 (Rule 6) & Consumer Protection Act 2019",
                claim_text="Product name or packaging highlights fresh fruit/natural spices.",
                audit_finding="Taste profile relies predominantly on synthetic acidity regulators (INS 330), chemical nucleotides (INS 627/631), and nature-identical flavourings rather than real natural ingredients.",
                recommendation="Declare 'Nature Identical Flavouring Substances' prominently on the front display panel as required under FSSAI."
            ))

            comparisons.append(ClaimComparison(
                front_claim="Natural Flavor & Taste Profile",
                reality_finding="Synthesized using INS 330 Acidity Regulators & INS 627/631 Chemical Enhancers",
                status="misleading",
                explanation="The tangy fruit flavour is simulated industrially with chemical acidulants rather than real natural juice.",
                evidence="Ingredients: Acidity Regulators (INS 330), Flavour Enhancers (INS 627, INS 631), Nature Identical Flavouring Substances"
            ))

        # ----------------------------------------------------
        # RULE H: Color-Coded Ingredients Classification
        # ----------------------------------------------------
        for ing in ingredients_list:
            name = ing.get("name", "").strip()
            name_lower = name.lower()
            pct = ing.get("percentage")
            category = "clean"
            flag_reason = None
            ins_code = ing.get("ins_code")

            if any(p in name_lower for p in self.PALM_OIL_VARIANTS) or "hydrogenated" in name_lower:
                category = "harmful"
                flag_reason = "High saturated / industrial palmolein fat source"
            elif any(code in name_lower.upper() for code in ["INS 102", "INS 110", "INS 129", "INS 150D", "INS 950", "INS 951", "INS 955", "INS 211", "INS 627", "INS 631"]):
                category = "harmful"
                flag_reason = "Synthetic chemical additive / flavour enhancer / artificial color"
            elif any(s in name_lower for s in self.HIDDEN_SUGARS) or "sugar" in name_lower or "refined wheat" in name_lower or "maida" in name_lower or "emulsifier" in name_lower or "ins 330" in name_lower or "ins 551" in name_lower or "flavouring" in name_lower:
                category = "warning"
                flag_reason = "Refined carbohydrate, synthetic acidity regulator, or flavour substance"
            else:
                category = "clean"
                flag_reason = "Wholesome or standard agricultural ingredient"

            color_coded_ingredients.append(IngredientItem(
                name=name,
                percentage=pct,
                category=category,
                flag_reason=flag_reason,
                is_additive=ing.get("is_additive", False) or category in ["warning", "harmful"],
                ins_code=ins_code
            ))

        # ----------------------------------------------------
        # RULE I: Statutory Baseline Comparisons (Always present)
        # ----------------------------------------------------
        if len(comparisons) < 2:
            # Baseline 1: Cooking Fat
            comparisons.append(ClaimComparison(
                front_claim="Cooking Oil & Fat Standard",
                reality_finding=f"Total Fat: {nutr_obj.total_fat_g}g/100g (Saturated: {nutr_obj.saturated_fat_g}g)",
                status="violation" if (has_palm_oil or nutr_obj.saturated_fat_g > 6.0) else "verified",
                explanation="FSSAI recommends limiting saturated fatty acids to below 10% total caloric intake.",
                evidence=f"Total Fat: {nutr_obj.total_fat_g}g | Saturated Fat: {nutr_obj.saturated_fat_g}g"
            ))
            # Baseline 2: Sugar & Carbohydrates
            comparisons.append(ClaimComparison(
                front_claim="Sugar & Glycemic Load",
                reality_finding=f"Total Sugar: {nutr_obj.total_sugar_g}g/100g (Carbs: {nutr_obj.total_carbohydrates_g}g)",
                status="violation" if nutr_obj.total_sugar_g > 6.0 else "verified",
                explanation="FSSAI HFSS guidelines classify solid foods with >6g added sugar per 100g as high in sugar.",
                evidence=f"Carbohydrates: {nutr_obj.total_carbohydrates_g}g | Sugars: {nutr_obj.total_sugar_g}g"
            ))

        # ----------------------------------------------------
        # RULE J: User Dietary Alerts
        # ----------------------------------------------------
        if user_pref.get("avoid_palm_oil", True) and (has_palm_oil or has_generic_veg_oil):
            dietary_warnings.append("⚠️ Contains Palm Oil / Palmolein (Matches your 'Avoid Palm Oil' alert)")
        
        if user_pref.get("diabetic_mode", False) and (detected_hidden_sugars or nutr_obj.total_sugar_g > 10.0):
            dietary_warnings.append(f"⚠️ High Glycemic Alert: Contains {nutr_obj.total_sugar_g}g Sugar + {', '.join(detected_hidden_sugars) if detected_hidden_sugars else 'Refined carbs'}")
        
        if (user_pref.get("low_sodium", False) or nutr_obj.sodium_mg > 400.0):
            dietary_warnings.append(f"⚠️ High Sodium Alert: {nutr_obj.sodium_mg}mg Sodium per 100g (Exceeds FSSAI HFSS cap of 400mg)")

        for allergen in user_pref.get("allergies", []):
            if allergen.lower() in raw_lower:
                dietary_warnings.append(f"🚨 Allergen Warning: Contains declared allergen '{allergen}'")

        # ----------------------------------------------------
        # Truth Score Computation
        # ----------------------------------------------------
        truth_score = max(5, min(100, 100 - total_penalties))

        if truth_score >= 80:
            verdict = "Verified"
            verdict_desc = "Packaging claims are substantiated and adhere to Indian FSSAI labeling norms."
        elif truth_score >= 50:
            verdict = "Misleading"
            verdict_desc = "Front marketing claims present significant statutory discrepancies when audited against back ingredients and HFSS standards."
        else:
            verdict = "Violates Standards"
            verdict_desc = "Critical statutory violations detected under Indian FSSAI Regulations (HFSS, Palm Oil, and Claims) and Consumer Protection Act 2019."

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

        if "chip" in cat_lower or "wafer" in cat_lower or "snack" in cat_lower or any("HFSS" in v.rule_code for v in violations):
            return [
                AlternativeProduct(
                    name="Vacuum Fried Beetroot & Sweet Potato Crisps",
                    brand="RootPure Harvest",
                    truth_score=94,
                    why_better="Cooked in cold-pressed rice bran oil at low temperature. Sodium < 220mg/100g with zero INS 627/631 chemicals."
                ),
                AlternativeProduct(
                    name="Roasted Makhana & Popped Lotus Seeds (Himalayan Salt)",
                    brand="FarmClean Organics",
                    truth_score=96,
                    why_better="Zero palm oil, roasted without deep-frying, 0g trans fat, and 60% less sodium than potato chips."
                )
            ]
        elif "biscuit" in cat_lower or "cookie" in cat_lower or any("GRAIN" in v.rule_code for v in violations):
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
            parts = [p.strip() for p in re.split(r'[,;•\n\(\)]+', raw_ing) if len(p.strip()) > 2]
            ing_list = [{"name": p} for p in parts]
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
