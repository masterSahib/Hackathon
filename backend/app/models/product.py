import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, JSON, Text, Float
from app.core.database import Base

class Product(Base):
    __tablename__ = "products"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    barcode = Column(String, unique=True, index=True, nullable=True)
    brand_name = Column(String, nullable=False, index=True)
    product_name = Column(String, nullable=False, index=True)
    category = Column(String, nullable=True, default="Packaged Food")
    front_image_url = Column(String, nullable=True)
    back_image_url = Column(String, nullable=True)
    raw_ingredients_text = Column(Text, nullable=True)
    nutrition_json = Column(JSON, default=dict)
    marketing_claims = Column(JSON, default=list)
    truth_score = Column(Integer, default=100)
    verdict = Column(String, default="Verified")  # Verified, Misleading, Violates Standards
    violations_summary = Column(JSON, default=list)
    alternatives = Column(JSON, default=list)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
