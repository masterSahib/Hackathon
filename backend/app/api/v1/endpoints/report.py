import base64
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.scan_history import ScanHistory
from app.models.product import Product
from app.schemas.report import GeneratePdfRequest, GeneratePdfResponse
from app.services.pdf_service import pdf_service
from app.services.rule_engine import rule_engine

router = APIRouter()

@router.post("/generate-pdf", response_model=GeneratePdfResponse)
async def generate_pdf_report(request: GeneratePdfRequest):
    """Generates official statutory violation PDF notice and returns base64 string."""
    try:
        report_dict = request.dict()
        pdf_b64 = pdf_service.generate_base64_pdf(report_dict)
        clean_name = "".join(c for c in request.product_name if c.isalnum() or c in (' ', '_', '-')).rstrip()
        filename = f"FSSAI_Notice_{clean_name.replace(' ', '_')}.pdf"

        return GeneratePdfResponse(
            success=True,
            message="FSSAI Grievance & Violation Notice PDF generated successfully.",
            filename=filename,
            pdf_base64=pdf_b64,
            download_url=f"/api/v1/report/download-direct"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"PDF Generation failed: {str(e)}")

@router.get("/download/{scan_id}")
async def download_scan_pdf(
    scan_id: str,
    db: Session = Depends(get_db)
):
    """Downloads a raw binary PDF report for a past scan."""
    scan = db.query(ScanHistory).filter(ScanHistory.id == scan_id).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan record not found")

    product = db.query(Product).filter(Product.id == scan.product_id).first()
    brand = product.brand_name if product else "Brand"
    pname = product.product_name if product else "Product"
    raw_ing = product.raw_ingredients_text if product else ""

    eval_result = rule_engine.evaluate_compliance(
        marketing_claims=scan.detected_claims or [],
        ingredients_list=[{"name": p.strip()} for p in raw_ing.split(",") if p.strip()],
        nutrition=scan.nutrition_per_100g or {},
        raw_ingredients_text=raw_ing,
    )

    report_payload = {
        "product_name": pname,
        "brand_name": brand,
        "barcode": product.barcode if product else "N/A",
        "truth_score": scan.truth_score,
        "verdict": scan.verdict,
        "marketing_claims": scan.detected_claims or [],
        "claim_comparisons": eval_result["claim_comparisons"],
        "violations": eval_result["violations"],
        "suspicious_additives": eval_result["suspicious_additives"],
        "ingredients": eval_result["ingredients"],
        "nutrition": scan.nutrition_per_100g or {},
    }

    pdf_bytes = pdf_service.generate_violation_notice(report_payload)
    clean_pname = "".join(c for c in pname if c.isalnum() or c in (' ', '_', '-')).replace(' ', '_')

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename=FSSAI_Violation_Notice_{clean_pname}.pdf"
        }
    )
