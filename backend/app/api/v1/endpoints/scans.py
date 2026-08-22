from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.scan_history import ScanHistory
from app.models.product import Product
from app.schemas.analysis import AnalysisResponse
from app.services.rule_engine import rule_engine

router = APIRouter()

@router.get("/{scan_id}", response_model=AnalysisResponse)
async def get_scan_report(
    scan_id: str,
    db: Session = Depends(get_db)
):
    """Retrieves full audit report for a specific scan ID."""
    scan = db.query(ScanHistory).filter(ScanHistory.id == scan_id).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan record not found")

    product = db.query(Product).filter(Product.id == scan.product_id).first()
    brand_name = product.brand_name if product else "Unknown Brand"
    product_name = product.product_name if product else "Packaged Food"
    barcode = product.barcode if product else None
    raw_ing = product.raw_ingredients_text if product else ""

    eval_result = rule_engine.evaluate_compliance(
        marketing_claims=scan.detected_claims or [],
        ingredients_list=[{"name": p.strip()} for p in raw_ing.split(",") if p.strip()],
        nutrition=scan.nutrition_per_100g or {},
        raw_ingredients_text=raw_ing,
    )

    return AnalysisResponse(
        scan_id=scan.id,
        product_id=scan.product_id,
        brand_name=brand_name,
        product_name=product_name,
        barcode=barcode,
        truth_score=scan.truth_score,
        verdict=scan.verdict,
        verdict_description=eval_result["verdict_description"],
        marketing_claims=scan.detected_claims or [],
        claim_comparisons=eval_result["claim_comparisons"],
        violations=eval_result["violations"],
        ingredients=eval_result["ingredients"],
        suspicious_additives=eval_result["suspicious_additives"],
        nutrition_per_100g=eval_result["nutrition_per_100g"],
        dietary_warnings=eval_result["dietary_warnings"],
        healthier_alternatives=eval_result["healthier_alternatives"],
        pdf_report_available=True,
        created_at=scan.created_at,
    )

@router.get("/", response_model=List[dict])
async def list_recent_scans(
    limit: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Lists recent scans with summary metrics for the home screen carousel."""
    scans = db.query(ScanHistory).order_by(ScanHistory.created_at.desc()).limit(limit).all()
    results = []
    for s in scans:
        prod = db.query(Product).filter(Product.id == s.product_id).first()
        results.append({
            "id": s.id,
            "product_id": s.product_id,
            "product_name": prod.product_name if prod else "Audited Product",
            "brand_name": prod.brand_name if prod else "Brand",
            "truth_score": s.truth_score,
            "verdict": s.verdict,
            "claims_count": len(s.detected_claims or []),
            "violations_count": len(s.violations_found or []),
            "created_at": s.created_at.isoformat(),
        })
    return results
