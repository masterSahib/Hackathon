from typing import Optional, List, Dict, Any
from pydantic import BaseModel
from datetime import datetime

class ProductBase(BaseModel):
    barcode: Optional[str] = None
    brand_name: str
    product_name: str
    category: Optional[str] = "Packaged Food"
    front_image_url: Optional[str] = None
    back_image_url: Optional[str] = None
    raw_ingredients_text: Optional[str] = None
    nutrition_json: Optional[Dict[str, Any]] = None
    marketing_claims: Optional[List[str]] = []
    truth_score: Optional[int] = 100
    verdict: Optional[str] = "Verified"

class ProductCreate(ProductBase):
    pass

class ProductResponse(ProductBase):
    id: str
    violations_summary: Optional[List[Dict[str, Any]]] = []
    alternatives: Optional[List[Dict[str, Any]]] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
