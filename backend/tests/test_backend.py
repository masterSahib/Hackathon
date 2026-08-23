import pytest
import httpx
from app.main import app
from app.services.rule_engine import rule_engine
from app.services.pdf_service import pdf_service

@pytest.fixture
def anyio_backend():
    return 'asyncio'

@pytest.mark.anyio
async def test_root_and_health():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/")
        assert res.status_code == 200
        assert res.json()["status"] == "online"

        health = await client.get("/health")
        assert health.status_code == 200
        assert health.json()["status"] == "healthy"

@pytest.mark.anyio
async def test_rules_list():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/rules/")
        assert res.status_code == 200
        rules = res.json()
        assert len(rules) >= 4
        rule_codes = [r["code"] for r in rules]
        assert "RULE_A_ZERO_SUGAR_DECEPTION" in rule_codes
        assert "RULE_B_GRAIN_HIERARCHY_DECEPTION" in rule_codes
        assert "RULE_C_INSUFFICIENT_PROTEIN_CLAIM" in rule_codes
        assert "RULE_D_PALM_OIL_MASKING" in rule_codes

def test_rule_engine_zero_sugar_and_grain_deception():
    claims = ["100% Whole Wheat Goodness", "Zero Added Sugar", "Heart Friendly"]
    ingredients = [
        {"name": "Refined Wheat Flour (Maida)", "percentage": 60.0},
        {"name": "Palm Oil"},
        {"name": "Maltodextrin"},
        {"name": "Invert Sugar Syrup"},
        {"name": "Whole Wheat Flour (Atta)", "percentage": 10.0},
        {"name": "Caramel Color (INS 150d)"}
    ]
    nutrition = {
        "energy_kcal": 470.0,
        "protein_g": 6.0,
        "total_sugar_g": 22.0,
        "added_sugar_g": 18.0,
        "total_fat_g": 19.0,
        "saturated_fat_g": 9.5,
        "sodium_mg": 450.0
    }
    raw_text = "Refined Wheat Flour (Maida) 60%, Palm Oil, Maltodextrin, Invert Sugar Syrup, Whole Wheat Flour (Atta) 10%, Caramel Color (INS 150d)"

    result = rule_engine.evaluate_compliance(
        marketing_claims=claims,
        ingredients_list=ingredients,
        nutrition=nutrition,
        raw_ingredients_text=raw_text,
        product_category="Biscuits"
    )

    assert result["truth_score"] <= 45
    assert result["verdict"] == "Violates Standards"
    viol_codes = [v.rule_code for v in result["violations"]]
    assert "RULE_A_ZERO_SUGAR_DECEPTION" in viol_codes
    assert "RULE_B_GRAIN_HIERARCHY_DECEPTION" in viol_codes
    assert "RULE_D_PALM_OIL_MASKING" in viol_codes
    assert len(result["healthier_alternatives"]) >= 1

@pytest.mark.anyio
async def test_barcode_lookup_endpoint():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        # First analyze a product with barcode
        scan_payload = {
            "barcode": "8901030882101",
            "product_name": "NutriChoice Atta Biscuit",
            "brand_name": "Britannia",
            "raw_marketing_text": "100% Whole Wheat, Zero Sugar",
            "raw_ingredients_text": "Refined Wheat Flour (Maida) 58%, Palm Oil, Maltodextrin, Whole Wheat Flour 12%",
            "raw_nutrition_text": "Energy: 480 kcal, Sugar: 20g, Saturated Fat: 9g, Sodium: 450mg"
        }
        create_res = await client.post("/api/v1/analyze", json=scan_payload)
        assert create_res.status_code == 200

        # Now lookup the barcode
        res = await client.get("/api/v1/products/barcode/8901030882101")
        assert res.status_code == 200
        data = res.json()
        assert "brand_name" in data
        assert "truth_score" in data
        assert isinstance(data["truth_score"], int)
        assert len(data["claim_comparisons"]) >= 1

@pytest.mark.anyio
async def test_pdf_generation():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        payload = {
            "product_name": "Test NutriBiscuit",
            "brand_name": "TestBrand",
            "barcode": "8901030882101",
            "truth_score": 35,
            "verdict": "Violates Standards",
            "marketing_claims": ["Zero Added Sugar", "100% Whole Wheat"],
            "claim_comparisons": [
                {
                    "front_claim": "Zero Added Sugar",
                    "reality_finding": "Contains 18g Invert Sugar Syrup + Maltodextrin",
                    "status": "violation",
                    "explanation": "High glycemic index sugar substitutes",
                    "evidence": "Ingredients: Maltodextrin, Invert Sugar Syrup"
                }
            ],
            "violations": [
                {
                    "rule_code": "RULE_A_ZERO_SUGAR_DECEPTION",
                    "title": "Deceptive Zero Sugar Claim",
                    "severity": "Critical",
                    "regulation_reference": "FSSAI Section 23",
                    "claim_text": "Zero Added Sugar",
                    "audit_finding": "Contains 18g Added Sugars",
                    "recommendation": "Remove claim"
                }
            ],
            "ingredients": [
                {"name": "Maida", "category": "warning"},
                {"name": "Palm Oil", "category": "harmful"}
            ],
            "nutrition": {"energy_kcal": 470.0, "total_sugar_g": 22.0}
        }

        res = await client.post("/api/v1/report/generate-pdf", json=payload)
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is True
        assert len(data["pdf_base64"]) > 1000

def test_potato_chips_lemon_fssai_audit():
    claims = ["Tangy Lemon Potato Chips", "Zero Trans Fat", "Crispy & Crunchy"]
    ingredients = [
        {"name": "Potato", "percentage": 52.0},
        {"name": "Edible Vegetable Oil (Palmolein)"},
        {"name": "Seasoning (Salt, Spices, Sugar)"},
        {"name": "Acidity Regulator (INS 330)"},
        {"name": "Flavour Enhancers (INS 627, INS 631)"},
        {"name": "Nature Identical Flavouring Substances"}
    ]
    nutrition = {
        "energy_kcal": 550.0,
        "protein_g": 6.0,
        "total_fat_g": 35.0,
        "saturated_fat_g": 14.5,
        "trans_fat_g": 0.05,
        "sodium_mg": 820.0,
        "total_sugar_g": 3.0,
    }
    raw_text = "Potato (52%), Edible Vegetable Oil (Palmolein), Seasoning (Spices, Salt, Sugar, Acidity Regulator (INS 330), Flavour Enhancers (INS 627, INS 631), Nature Identical Flavouring Substances)"

    result = rule_engine.evaluate_compliance(
        marketing_claims=claims,
        ingredients_list=ingredients,
        nutrition=nutrition,
        raw_ingredients_text=raw_text,
        product_category="Potato Chips"
    )

    assert result["truth_score"] <= 50
    viol_codes = [v.rule_code for v in result["violations"]]
    assert "RULE_F_HFSS_SODIUM_HAZARD" in viol_codes
    assert "RULE_F_HFSS_SATURATED_FAT_HAZARD" in viol_codes
    assert "RULE_D_PALM_OIL_MASKING" in viol_codes
    assert len(result["claim_comparisons"]) >= 3
    assert len(result["healthier_alternatives"]) >= 1

@pytest.mark.anyio
async def test_product_chat_endpoint():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        payload = {
            "product_name": "Tangy Lemon Potato Chips",
            "brand_name": "TestSnacks",
            "truth_score": 42,
            "verdict": "Violates Standards",
            "marketing_claims": ["Zero Trans Fat"],
            "ingredients_text": "Potato, Palmolein Oil, Salt, Citric Acid (INS 330), INS 627",
            "nutrition": {"saturated_fat_g": 14.5, "sodium_mg": 820.0},
            "violations": [{"rule_code": "RULE_F_HFSS_SODIUM_HAZARD", "title": "Excessive Sodium"}],
            "user_question": "Why is this product not safe for high blood pressure?"
        }

        res = await client.post("/api/v1/chat/product", json=payload)
        assert res.status_code == 200
        data = res.json()
        assert "reply" in data
        assert len(data["reply"]) > 10
