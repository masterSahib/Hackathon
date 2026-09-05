import uuid
from app.core.database import SessionLocal, engine, Base, run_migrations
from app.models.product import Product
from app.models.compliance_rule import ComplianceRule
from app.models.scan_history import ScanHistory
from app.models.user import User
from app.services.rule_engine import rule_engine

def seed_database():
    run_migrations()
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Create default user if not exists
    user = db.query(User).first()
    if not user:
        user = User(
            name="Officer Rajesh Verma",
            email="rajesh.verma@doca.gov.in",
            role="OFFICER",
            badge_number="LMPC-NZ-2026-442",
            jurisdiction="North Zone Enforcement Directorate, New Delhi",
            department="Legal Metrology & Packaging Enforcement",
            organization="Department of Consumer Affairs (DoCA)",
            dietary_preferences={
                "allergies": ["Peanuts"],
                "diabetic_mode": True,
                "avoid_palm_oil": True,
                "low_sodium": False,
                "vegan": False,
                "avoid_artificial_sweeteners": True
            }
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        user.role = "OFFICER"
        user.badge_number = "LMPC-NZ-2026-442"
        user.department = "Legal Metrology & Packaging Enforcement"
        user.organization = "Department of Consumer Affairs (DoCA)"
        db.commit()

    # Seed Sample Products
    sample_products = [
        {
            "barcode": "8901030882101",
            "brand_name": "NutriWhole Foods",
            "product_name": "100% Whole Wheat Digestive Biscuits",
            "category": "Biscuits & Bakery",
            "marketing_claims": [
                "100% Whole Wheat Goodness",
                "Zero Added Sugar",
                "High Fibre & Heart Friendly",
                "No Artificial Colours"
            ],
            "raw_ingredients_text": "Refined Wheat Flour (Maida) 58%, Palm Oil, Invert Sugar Syrup, Maltodextrin, Whole Wheat Flour (Atta) 12%, Wheat Bran 4.5%, Raising Agents (INS 500ii, INS 503ii), Emulsifiers (INS 322), Caramel Color (INS 150d), Artificial Vanilla Flavour.",
            "net_quantity_raw": "150 g",
            "mrp_raw": "₹ 45.00 (incl. of all taxes)",
            "usp_raw": "₹ 0.30 per g",
            "mfg_date_raw": "MFD 06/2026",
            "customer_care_raw": "Consumer Care: 1800-200-8899, care@nutriwhole.in",
            "manufacturer_raw": "Manufactured by NutriWhole Foods Pvt Ltd, Plot 14, Industrial Estate, Bengaluru 560058, India",
            "nutrition_json": {
                "energy_kcal": 472.0,
                "protein_g": 6.2,
                "total_carbohydrates_g": 68.0,
                "total_sugar_g": 22.5,
                "added_sugar_g": 19.0,
                "total_fat_g": 20.0,
                "saturated_fat_g": 10.5,
                "trans_fat_g": 0.05,
                "sodium_mg": 460.0,
                "fiber_g": 3.1
            }
        },
        {
            "barcode": "8902040993202",
            "brand_name": "FitPower Nutrition",
            "product_name": "Max Protein Power Energy Bar",
            "category": "Health & Fitness Bars",
            "marketing_claims": [
                "High Protein Muscle Fuel",
                "Zero Sugar Added",
                "Guilt Free Healthy Snack",
                "Enriched with Real Nuts"
            ],
            "raw_ingredients_text": "Liquid Glucose, Invert Sugar Syrup, Soy Protein Crispies 8%, Maltodextrin, Palmolein, Milk Chocolate Coating, Sucralose (INS 955), Preservative (INS 211), Synthetic Chocolate Aroma.",
            "net_quantity_raw": "50 g",
            "mrp_raw": "₹ 80.00 (incl. of all taxes)",
            "usp_raw": "₹ 1.60 per g",
            "mfg_date_raw": "PKD 05/2026",
            "customer_care_raw": "Care: fitpower@nutrition.in | +91-98765-43210",
            "manufacturer_raw": "FitPower Nutra Labs, Sector 62, Noida 201309, India",
            "nutrition_json": {
                "energy_kcal": 410.0,
                "protein_g": 7.5,
                "total_carbohydrates_g": 62.0,
                "total_sugar_g": 28.0,
                "added_sugar_g": 25.0,
                "total_fat_g": 15.0,
                "saturated_fat_g": 8.0,
                "trans_fat_g": 0.1,
                "sodium_mg": 320.0,
                "fiber_g": 1.8
            }
        },
        {
            "barcode": "8903050114303",
            "brand_name": "PureOrchard Botanicals",
            "product_name": "100% Real Alphonso Mango Nectar",
            "category": "Fruit Beverages",
            "marketing_claims": [
                "100% Real Fruit Goodness",
                "Rich in Vitamin C",
                "No Added Preservatives",
                "Natural Taste of Real Mangoes"
            ],
            "raw_ingredients_text": "Water, Mango Pulp 18%, Sugar, Acidity Regulator (INS 330), Antioxidant (INS 300), Synthetic Food Color (INS 110 Sunset Yellow), Preservative (INS 211 Sodium Benzoate).",
            "net_quantity_raw": "200 ml",
            "mrp_raw": "₹ 35.00 (incl. of all taxes)",
            "usp_raw": "₹ 0.175 per ml",
            "mfg_date_raw": "MFD 07/2026",
            "customer_care_raw": "Grievance Officer: support@pureorchard.com",
            "manufacturer_raw": "PureOrchard Agro Pvt Ltd, Ratnagiri, Maharashtra 415612, India",
            "nutrition_json": {
                "energy_kcal": 68.0,
                "protein_g": 0.3,
                "total_carbohydrates_g": 16.5,
                "total_sugar_g": 15.8,
                "added_sugar_g": 12.5,
                "total_fat_g": 0.1,
                "saturated_fat_g": 0.0,
                "trans_fat_g": 0.0,
                "sodium_mg": 45.0,
                "fiber_g": 0.2
            }
        },
        {
            "barcode": "8904060225404",
            "brand_name": "CleanOats Organics",
            "product_name": "100% Rolled Oats & Seed Sourdough Crackers",
            "category": "Organic Clean Snacks",
            "marketing_claims": [
                "100% Whole Grain Oats",
                "Cold Pressed Virgin Coconut Oil",
                "Zero Refined Sugar",
                "No Artificial Additives"
            ],
            "raw_ingredients_text": "Whole Rolled Oats Flour 72%, Cold Pressed Virgin Coconut Oil 14%, Chia Seeds 6%, Pumpkin Seeds 5%, Rock Salt 2%, Rosemary Extract 1%.",
            "net_quantity_raw": "100 g",
            "mrp_raw": "₹ 120.00 (incl. of all taxes)",
            "usp_raw": "₹ 1.20 per g",
            "mfg_date_raw": "PKD 08/2026",
            "customer_care_raw": "Helpline: 1800-444-1234, hello@cleanoats.org",
            "manufacturer_raw": "CleanOats Bio Farm, Ooty Valley, Tamil Nadu 643001, India",
            "nutrition_json": {
                "energy_kcal": 435.0,
                "protein_g": 14.2,
                "total_carbohydrates_g": 54.0,
                "total_sugar_g": 1.8,
                "added_sugar_g": 0.0,
                "total_fat_g": 16.5,
                "saturated_fat_g": 6.5,
                "trans_fat_g": 0.0,
                "sodium_mg": 180.0,
                "fiber_g": 9.5
            }
        }
    ]

    for p_data in sample_products:
        existing = db.query(Product).filter(Product.barcode == p_data["barcode"]).first()
        
        # Evaluate compliance
        ing_items = [{"name": p.strip()} for p in p_data["raw_ingredients_text"].split(",") if p.strip()]
        eval_result = rule_engine.evaluate_compliance(
            marketing_claims=p_data["marketing_claims"],
            ingredients_list=ing_items,
            nutrition=p_data["nutrition_json"],
            raw_ingredients_text=p_data["raw_ingredients_text"],
            product_category=p_data["category"],
            brand_name=p_data["brand_name"],
            product_name=p_data["product_name"],
            extra_fields=p_data
        )

        violations_json = [v.model_dump() if hasattr(v, "model_dump") else v.dict() for v in eval_result["violations"]]
        alternatives_json = [a.model_dump() if hasattr(a, "model_dump") else a.dict() for a in eval_result["healthier_alternatives"]]
        comparisons_json = [c.model_dump() if hasattr(c, "model_dump") else c.dict() for c in eval_result["claim_comparisons"]]
        ingredients_json = [i.model_dump() if hasattr(i, "model_dump") else i.dict() for i in eval_result["ingredients"]]

        if not existing:
            prod = Product(
                barcode=p_data["barcode"],
                brand_name=p_data["brand_name"],
                product_name=p_data["product_name"],
                category=p_data["category"],
                raw_ingredients_text=p_data["raw_ingredients_text"],
                nutrition_json=p_data["nutrition_json"],
                marketing_claims=p_data["marketing_claims"],
                truth_score=eval_result["truth_score"],
                verdict=eval_result["verdict"],
                violations_summary=violations_json,
                alternatives=alternatives_json
            )
            db.add(prod)
            db.commit()
            db.refresh(prod)

            # Add a scan history entry
            scan = ScanHistory(
                user_id=user.id,
                product_id=prod.id,
                detected_claims=p_data["marketing_claims"],
                claim_comparisons=comparisons_json,
                violations_found=violations_json,
                ingredient_analysis=ingredients_json,
                nutrition_per_100g=p_data["nutrition_json"],
                truth_score=eval_result["truth_score"],
                verdict=eval_result["verdict"],
            )
            db.add(scan)
            db.commit()
            print(f"Seeded product: {prod.product_name} (Truth Score: {prod.truth_score})", flush=True)
        else:
            existing.truth_score = eval_result["truth_score"]
            existing.verdict = eval_result["verdict"]
            existing.violations_summary = violations_json
            existing.alternatives = alternatives_json
            db.commit()
            print(f"Updated product: {existing.product_name} (Truth Score: {existing.truth_score})", flush=True)

    db.close()
    print("Database seeding completed successfully!", flush=True)

if __name__ == "__main__":
    seed_database()
