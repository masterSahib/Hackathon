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
        assert len(rules) >= 5
        rule_codes = [r["code"] for r in rules]
        assert "RULE_A_ZERO_SUGAR_DECEPTION" in rule_codes
        assert "RULE_B_GRAIN_HIERARCHY_DECEPTION" in rule_codes
        assert "RULE_C_INSUFFICIENT_PROTEIN_CLAIM" in rule_codes
        assert "RULE_D_PALM_OIL_MASKING" in rule_codes
        assert "RULE_G_LMPC_MANDATORY_DECLARATIONS" in rule_codes

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
        product_category="Biscuits",
        brand_name="NutriWhole",
        product_name="100% Whole Wheat Digestive Biscuits",
        extra_fields={
            "net_quantity_raw": "150 g",
            "mrp_raw": "₹ 45.00 (incl. of all taxes)",
            "usp_raw": "₹ 0.30 per g",
            "mfg_date_raw": "MFD 06/2026",
            "customer_care_raw": "care@nutriwhole.in | 1800-200-8899",
            "manufacturer_raw": "NutriWhole Foods Pvt Ltd, Bangalore, India"
        }
    )

    assert result["truth_score"] <= 45
    assert result["verdict"] == "Violates Standards"
    viol_codes = [v.rule_code for v in result["violations"]]
    assert "RULE_A_ZERO_SUGAR_DECEPTION" in viol_codes
    assert "RULE_B_GRAIN_HIERARCHY_DECEPTION" in viol_codes
    assert "RULE_D_PALM_OIL_MASKING" in viol_codes
    assert result["mandatory_declarations"] is not None
    assert result["mandatory_declarations"].total_declarations == 7
    assert result["font_readability"] is not None
    assert result["font_readability"].is_font_compliant is True

def test_lmpc_mandatory_declarations_and_font_analysis():
    # Test LMPC Rule 6 extraction & Rule 7 font compliance
    raw_text = "Manufactured by Alpha Foods Ltd, Okhla Phase 3, New Delhi 110020. Net Qty: 250 g. MRP Rs. 95 (incl. of all taxes). USP Rs. 0.38/g. Mfd: 07/2026. Helpline: 1800-111-222, care@alpha.in"
    m_audit = rule_engine.evaluate_lmpc_mandatory_declarations(
        raw_text=raw_text,
        brand_name="Alpha Foods",
        product_name="Roasted Multigrain Mixture",
        extra_fields={}
    )
    assert m_audit.total_declarations == 7
    assert m_audit.passed_count >= 6
    assert m_audit.compliance_percentage >= 80.0

    # Test Font Readability under Rule 7
    f_audit = rule_engine.evaluate_font_size_and_readability(
        pdp_area_sq_cm=250.0,
        net_quantity_g_or_ml=250.0,
        detected_font_height_mm=4.5
    )
    assert f_audit.min_required_font_height_mm == 4.0
    assert f_audit.detected_font_height_mm == 4.5
    assert f_audit.is_font_compliant is True

@pytest.mark.anyio
async def test_dashboard_metrics_endpoint():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/scans/dashboard/metrics")
        assert res.status_code == 200
        data = res.json()
        assert "total_inspections" in data
        assert "compliance_rate" in data
        assert "violation_categories" in data
        assert "critical_violations_flagged" in data

@pytest.mark.anyio
async def test_rbac_user_role_switch():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        # Get current user
        me_res = await client.get("/api/v1/users/me")
        assert me_res.status_code == 200
        user = me_res.json()
        assert "role" in user

        # Switch role to OFFICER
        switch_res = await client.post("/api/v1/users/me/switch-role", json={
            "role": "OFFICER",
            "badge_number": "LMPC-TEST-99",
            "jurisdiction": "Central Directorate",
            "department": "Legal Metrology Enforcement"
        })
        assert switch_res.status_code == 200
        updated = switch_res.json()
        assert updated["role"] == "OFFICER"
        assert updated["badge_number"] == "LMPC-TEST-99"

@pytest.mark.anyio
async def test_csv_and_pdf_export_endpoints():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        # 1. Analyze a scan
        payload = {
            "barcode": "8901030882101",
            "product_name": "Test Atta Biscuit",
            "brand_name": "NutriWhole",
            "raw_marketing_text": "100% Whole Wheat, Zero Added Sugar",
            "raw_ingredients_text": "Refined Wheat Flour (Maida) 58%, Palm Oil, Invert Sugar Syrup, Maltodextrin, Whole Wheat Flour 12%",
            "net_quantity_raw": "150 g",
            "mrp_raw": "₹ 45.00 (incl. of all taxes)",
            "usp_raw": "₹ 0.30 per g",
        }
        create_res = await client.post("/api/v1/analyze", json=payload)
        assert create_res.status_code == 200
        scan_id = create_res.json()["scan_id"]

        # 2. Test PDF download endpoint
        pdf_res = await client.get(f"/api/v1/report/download/{scan_id}")
        assert pdf_res.status_code == 200
        assert pdf_res.headers["content-type"] == "application/pdf"
        assert len(pdf_res.content) > 1000

        # 3. Test CSV download endpoint
        csv_res = await client.get(f"/api/v1/report/download-csv/{scan_id}")
        assert csv_res.status_code == 200
        assert "text/csv" in csv_res.headers["content-type"]
        assert "LABELTRUTH COMPLIANCE INSPECTION REPORT" in csv_res.text

        # 4. Test JSON docket download endpoint
        json_res = await client.get(f"/api/v1/report/download-json/{scan_id}")
        assert json_res.status_code == 200
        assert "application/json" in json_res.headers["content-type"]
        assert "truth_score" in json_res.json()
