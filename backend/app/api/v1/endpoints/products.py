import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.product import Product
from app.models.scan_history import ScanHistory
from app.schemas.product import ProductResponse
from app.services.rule_engine import RuleEngine
from app.services.openfoodfacts_service import OpenFoodFactsService
from app.schemas.analysis import AnalysisResponse

router = APIRouter()

@router.get("/barcode/{barcode}", response_model=AnalysisResponse)
async def get_product_by_barcode(
    barcode: str,
    db: Session = Depends(get_db)
):
    """
    Live barcode audit lookup:
    1. Checks PostgreSQL database for existing record.
    2. If not found, fetches real live product data from Open Food Facts API (Indian/Global registry).
    3. Runs FSSAI statutory compliance engine.
    4. Caches product in database and returns full compliance audit.
    """
    clean_barcode = barcode.strip().replace(" ", "").replace("-", "")
    product = db.query(Product).filter(Product.barcode == clean_barcode).first()
    
    if product:
        # Re-evaluate compliance for fresh report
        raw_ing = product.raw_ingredients_text or ""
        extracted_data = {
            "brand_name": product.brand_name,
            "product_name": product.product_name,
            "category": product.category or "Packaged Food",
            "marketing_claims": product.marketing_claims or [],
            "ingredients_raw": raw_ing,
            "nutrition_per_100g": product.nutrition_json or {},
        }
        
        eval_result = RuleEngine.evaluate_fssai_compliance(extracted_data=extracted_data)
        eval_dict = eval_result if isinstance(eval_result, dict) else eval_result.dict()

        return AnalysisResponse(
            scan_id=f"SCAN-DB-{product.id[:8]}",
            product_id=product.id,
            brand_name=product.brand_name,
            product_name=product.product_name,
            barcode=product.barcode,
            truth_score=eval_dict["truth_score"],
            verdict=eval_dict["verdict"],
            verdict_description=eval_dict["verdict_description"],
            marketing_claims=product.marketing_claims or [],
            claim_comparisons=eval_dict["claim_comparisons"],
            violations=eval_dict["violations"],
            ingredients=eval_dict["ingredients"],
            suspicious_additives=eval_dict["suspicious_additives"],
            nutrition_per_100g=eval_dict["nutrition_per_100g"],
            dietary_warnings=eval_dict["dietary_warnings"],
            healthier_alternatives=eval_dict["healthier_alternatives"],
            pdf_report_available=True,
            created_at=product.created_at,
        )

    # 2. Live lookup on Open Food Facts API
    off_data = await OpenFoodFactsService.fetch_product_by_barcode(clean_barcode)
    if off_data:
        audit_res = OpenFoodFactsService.parse_and_audit(off_data, clean_barcode)
        audit_dict = audit_res.dict()

        # Save product to PostgreSQL database
        new_prod_id = str(uuid.uuid4())
        new_product = Product(
            id=new_prod_id,
            barcode=clean_barcode,
            brand_name=audit_dict["brand_name"],
            product_name=audit_dict["product_name"],
            category=off_data.get("categories", "Packaged Food"),
            raw_ingredients_text=off_data.get("ingredients_text_en") or off_data.get("ingredients_text", ""),
            nutrition_json=audit_dict["nutrition_per_100g"],
            marketing_claims=audit_dict["marketing_claims"],
            truth_score=audit_dict["truth_score"],
            verdict=audit_dict["verdict"],
            violations_summary=[v["title"] for v in audit_dict["violations"]],
            alternatives=audit_dict["healthier_alternatives"],
            created_at=datetime.utcnow(),
        )
        db.add(new_product)

        # Record scan history
        scan_record = ScanHistory(
            id=str(uuid.uuid4()),
            product_id=new_prod_id,
            truth_score=audit_dict["truth_score"],
            verdict=audit_dict["verdict"],
            raw_marketing_text=", ".join(audit_dict["marketing_claims"]),
            raw_ingredients_text=off_data.get("ingredients_text_en") or off_data.get("ingredients_text", ""),
            created_at=datetime.utcnow(),
        )
        db.add(scan_record)
        db.commit()

        audit_dict["product_id"] = new_prod_id
        audit_dict["scan_id"] = scan_record.id
        return AnalysisResponse(**audit_dict)

    raise HTTPException(
        status_code=404,
        detail=f"Barcode '{clean_barcode}' was not found in database or Open Food Facts. Please use the Dual-Camera scan to audit this product directly!"
    )

@router.get("/", response_model=List[ProductResponse])
async def search_products(
    q: Optional[str] = Query(None, description="Search term for product or brand name"),
    category: Optional[str] = Query(None, description="Filter by category"),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Searches and lists verified and audited products."""
    query = db.query(Product)
    if q:
        search_pattern = f"%{q}%"
        query = query.filter(
            (Product.product_name.ilike(search_pattern)) |
            (Product.brand_name.ilike(search_pattern)) |
            (Product.barcode.ilike(search_pattern))
        )
    if category:
        query = query.filter(Product.category.ilike(f"%{category}%"))

    return query.order_by(Product.created_at.desc()).limit(limit).all()

@router.get("/{product_id}", response_model=ProductResponse)
async def get_product_by_id(
    product_id: str,
    db: Session = Depends(get_db)
):
    """Retrieves product details by ID."""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
