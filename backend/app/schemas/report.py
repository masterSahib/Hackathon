from typing import Optional, List, Dict, Any
from pydantic import BaseModel

class GeneratePdfRequest(BaseModel):
    scan_id: Optional[str] = None
    product_name: str
    brand_name: str
    barcode: Optional[str] = None
    truth_score: int
    verdict: str
    marketing_claims: List[str]
    claim_comparisons: List[Dict[str, Any]]
    violations: List[Dict[str, Any]]
    ingredients: List[Dict[str, Any]]
    nutrition: Dict[str, Any]
    complainant_name: Optional[str] = "Concerned Consumer"
    state_jurisdiction: Optional[str] = "Central FSSAI & National Consumer Helpline"

class GeneratePdfResponse(BaseModel):
    success: bool
    message: str
    filename: str
    download_url: Optional[str] = None
    pdf_base64: Optional[str] = None
