import uuid
import base64
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.product import Product
from app.models.scan_history import ScanHistory
from app.schemas.analysis import AnalysisRequest, AnalysisResponse
from app.services.ai_vision_service import ai_vision_service
from app.services.rule_engine import rule_engine

router = APIRouter()

@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_food_packaging(
    request: AnalysisRequest,
    db: Session = Depends(get_db)
):
    """Primary Multimodal Vision & Compliance Analysis Pipeline.
    Accepts front/back images (base64) or transcribed text, extracts claims/nutrition/LMPC declarations,
    runs deterministic Legal Metrology & FSSAI compliance rules, and persists to PostgreSQL.
    """
    # 1. Check if barcode already exists in DB cache
    if request.barcode:
        cached_product = db.query(Product).filter(Product.barcode == request.barcode).first()
        if cached_product:
            # Create a scan history record
            scan = ScanHistory(
                product_id=cached_product.id,
                detected_claims=cached_product.marketing_claims,
                claim_comparisons=cached_product.violations_summary,
                violations_found=cached_product.violations_summary,
                truth_score=cached_product.truth_score,
                verdict=cached_product.verdict,
            )
            db.add(scan)
            db.commit()
            db.refresh(scan)

            # Evaluate with user dietary preferences & LMPC
            eval_result = rule_engine.evaluate_compliance(
                marketing_claims=cached_product.marketing_claims or [],
                ingredients_list=[{"name": i} for i in (cached_product.raw_ingredients_text or "").split(", ")],
                nutrition=cached_product.nutrition_json or {},
                raw_ingredients_text=cached_product.raw_ingredients_text or "",
                user_preferences=request.user_dietary_preferences or {},
                product_category=cached_product.category or "Food",
                brand_name=cached_product.brand_name,
                product_name=cached_product.product_name,
                extra_fields={
                    "net_quantity_raw": request.net_quantity_raw,
                    "mrp_raw": request.mrp_raw,
                    "usp_raw": request.usp_raw,
                    "mfg_date_raw": request.mfg_date_raw,
                    "customer_care_raw": request.customer_care_raw,
                    "manufacturer_raw": request.manufacturer_raw,
                }
            )

            return AnalysisResponse(
                scan_id=scan.id,
                product_id=cached_product.id,
                brand_name=cached_product.brand_name,
                product_name=cached_product.product_name,
                barcode=cached_product.barcode,
                truth_score=eval_result["truth_score"],
                verdict=eval_result["verdict"],
                verdict_description=eval_result["verdict_description"],
                marketing_claims=cached_product.marketing_claims or [],
                claim_comparisons=eval_result["claim_comparisons"],
                violations=eval_result["violations"],
                ingredients=eval_result["ingredients"],
                suspicious_additives=eval_result["suspicious_additives"],
                nutrition_per_100g=eval_result["nutrition_per_100g"],
                dietary_warnings=eval_result["dietary_warnings"],
                healthier_alternatives=eval_result["healthier_alternatives"],
                mandatory_declarations=eval_result["mandatory_declarations"],
                font_readability=eval_result["font_readability"],
                pdf_report_available=True,
                created_at=scan.created_at,
            )

    # 2. Extract structured data via AI Vision / LLM
    extracted = await ai_vision_service.extract_label_data(
        front_image_base64=request.front_image_base64,
        back_image_base64=request.back_image_base64,
        raw_marketing_text=request.raw_marketing_text,
        raw_ingredients_text=request.raw_ingredients_text,
        raw_nutrition_text=request.raw_nutrition_text,
        product_name_hint=request.product_name,
        brand_name_hint=request.brand_name,
        net_quantity_hint=request.net_quantity_raw,
        mrp_hint=request.mrp_raw,
        usp_hint=request.usp_raw,
        mfg_date_hint=request.mfg_date_raw,
        customer_care_hint=request.customer_care_raw,
        manufacturer_hint=request.manufacturer_raw,
    )

    brand_name = extracted.get("brand_name") or request.brand_name or "Brand"
    product_name = extracted.get("product_name") or request.product_name or "Packaged Product"
    category = extracted.get("category") or "Packaged Food"
    marketing_claims = extracted.get("marketing_claims") or []
    ingredients_list = extracted.get("ingredients_list") or []
    raw_ingredients_text = extracted.get("raw_ingredients_text") or request.raw_ingredients_text or ""
    nutrition = extracted.get("nutrition_per_100g") or {}

    # 3. Run Deterministic Compliance Rule Engine
    eval_result = rule_engine.evaluate_compliance(
        marketing_claims=marketing_claims,
        ingredients_list=ingredients_list,
        nutrition=nutrition,
        raw_ingredients_text=raw_ingredients_text,
        user_preferences=request.user_dietary_preferences or {},
        product_category=category,
        brand_name=brand_name,
        product_name=product_name,
        extra_fields={
            **extracted,
            "net_quantity_raw": request.net_quantity_raw or extracted.get("net_quantity_raw"),
            "mrp_raw": request.mrp_raw or extracted.get("mrp_raw"),
            "usp_raw": request.usp_raw or extracted.get("usp_raw"),
            "mfg_date_raw": request.mfg_date_raw or extracted.get("mfg_date_raw"),
            "customer_care_raw": request.customer_care_raw or extracted.get("customer_care_raw"),
            "manufacturer_raw": request.manufacturer_raw or extracted.get("manufacturer_raw"),
        }
    )

    # 4. Upsert Product in PostgreSQL Database
    product = None
    if request.barcode:
        product = db.query(Product).filter(Product.barcode == request.barcode).first()

    violations_json = [v.model_dump() if hasattr(v, "model_dump") else v.dict() for v in eval_result["violations"]]
    alternatives_json = [a.model_dump() if hasattr(a, "model_dump") else a.dict() for a in eval_result["healthier_alternatives"]]
    comparisons_json = [c.model_dump() if hasattr(c, "model_dump") else c.dict() for c in eval_result["claim_comparisons"]]
    ingredients_json = [i.model_dump() if hasattr(i, "model_dump") else i.dict() for i in eval_result["ingredients"]]

    if not product:
        product = Product(
            barcode=request.barcode or f"GEN-{uuid.uuid4().hex[:8].upper()}",
            brand_name=brand_name,
            product_name=product_name,
            category=category,
            raw_ingredients_text=raw_ingredients_text,
            nutrition_json=nutrition,
            marketing_claims=marketing_claims,
            truth_score=eval_result["truth_score"],
            verdict=eval_result["verdict"],
            violations_summary=violations_json,
            alternatives=alternatives_json
        )
        db.add(product)
        db.commit()
        db.refresh(product)
    else:
        product.truth_score = eval_result["truth_score"]
        product.verdict = eval_result["verdict"]
        db.commit()

    # 5. Create Scan History Entry
    scan = ScanHistory(
        product_id=product.id,
        detected_claims=marketing_claims,
        claim_comparisons=comparisons_json,
        violations_found=violations_json,
        ingredient_analysis=ingredients_json,
        nutrition_per_100g=nutrition,
        truth_score=eval_result["truth_score"],
        verdict=eval_result["verdict"],
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)

    return AnalysisResponse(
        scan_id=scan.id,
        product_id=product.id,
        brand_name=product.brand_name,
        product_name=product.product_name,
        barcode=product.barcode,
        truth_score=eval_result["truth_score"],
        verdict=eval_result["verdict"],
        verdict_description=eval_result["verdict_description"],
        marketing_claims=marketing_claims,
        claim_comparisons=eval_result["claim_comparisons"],
        violations=eval_result["violations"],
        ingredients=eval_result["ingredients"],
        suspicious_additives=eval_result["suspicious_additives"],
        nutrition_per_100g=eval_result["nutrition_per_100g"],
        dietary_warnings=eval_result["dietary_warnings"],
        healthier_alternatives=eval_result["healthier_alternatives"],
        mandatory_declarations=eval_result["mandatory_declarations"],
        font_readability=eval_result["font_readability"],
        pdf_report_available=True,
        created_at=scan.created_at,
    )

@router.post("/scan/upload", response_model=AnalysisResponse)
async def upload_and_analyze_scan(
    front_image: Optional[UploadFile] = File(None),
    back_image: Optional[UploadFile] = File(None),
    barcode: Optional[str] = Form(None),
    brand_name: Optional[str] = Form(None),
    product_name: Optional[str] = Form(None),
    raw_marketing_text: Optional[str] = Form(None),
    raw_ingredients_text: Optional[str] = Form(None),
    net_quantity: Optional[str] = Form(None),
    mrp: Optional[str] = Form(None),
    usp: Optional[str] = Form(None),
    db: Session = Depends(get_db)
):
    """Accepts multipart/form-data upload for front and back packaging camera photos."""
    front_b64 = None
    back_b64 = None

    if front_image:
        front_bytes = await front_image.read()
        front_b64 = base64.b64encode(front_bytes).decode("utf-8")

    if back_image:
        back_bytes = await back_image.read()
        back_b64 = base64.b64encode(back_bytes).decode("utf-8")

    req = AnalysisRequest(
        barcode=barcode,
        brand_name=brand_name,
        product_name=product_name,
        front_image_base64=front_b64,
        back_image_base64=back_b64,
        raw_marketing_text=raw_marketing_text,
        raw_ingredients_text=raw_ingredients_text,
        net_quantity_raw=net_quantity,
        mrp_raw=mrp,
        usp_raw=usp,
    )

    return await analyze_food_packaging(req, db)
