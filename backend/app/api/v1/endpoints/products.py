from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.product import Product
from app.schemas.product import ProductResponse
from app.services.rule_engine import rule_engine
from app.schemas.analysis import AnalysisResponse

router = APIRouter()

@router.get("/barcode/{barcode}", response_model=AnalysisResponse)
async def get_product_by_barcode(
    barcode: str,
    db: Session = Depends(get_db)
):
    """Fast cache lookup for scanned barcode."""
    product = db.query(Product).filter(Product.barcode == barcode).first()
    if not product:
        raise HTTPException(
            status_code=404,
            detail=f"Product with barcode '{barcode}' not found in database. Please capture front & back pack photos to audit."
        )

    # Re-evaluate compliance for fresh report
    raw_ing = product.raw_ingredients_text or ""
    eval_result = rule_engine.evaluate_compliance(
        marketing_claims=product.marketing_claims or [],
        ingredients_list=[{"name": p.strip()} for p in raw_ing.split(",") if p.strip()],
        nutrition=product.nutrition_json or {},
        raw_ingredients_text=raw_ing,
        product_category=product.category or "Packaged Food"
    )

    return AnalysisResponse(
        scan_id=f"CACHED-{product.id[:8]}",
        product_id=product.id,
        brand_name=product.brand_name,
        product_name=product.product_name,
        barcode=product.barcode,
        truth_score=eval_result["truth_score"],
        verdict=eval_result["verdict"],
        verdict_description=eval_result["verdict_description"],
        marketing_claims=product.marketing_claims or [],
        claim_comparisons=eval_result["claim_comparisons"],
        violations=eval_result["violations"],
        ingredients=eval_result["ingredients"],
        suspicious_additives=eval_result["suspicious_additives"],
        nutrition_per_100g=eval_result["nutrition_per_100g"],
        dietary_warnings=eval_result["dietary_warnings"],
        healthier_alternatives=eval_result["healthier_alternatives"],
        pdf_report_available=True,
        created_at=product.created_at,
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
