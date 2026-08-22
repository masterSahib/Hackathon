import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, JSON, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class ScanHistory(Base):
    __tablename__ = "scan_history"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    detected_claims = Column(JSON, default=list)
    claim_comparisons = Column(JSON, default=list)
    violations_found = Column(JSON, default=list)
    ingredient_analysis = Column(JSON, default=list)
    nutrition_per_100g = Column(JSON, default=dict)
    truth_score = Column(Integer, default=100)
    verdict = Column(String, default="Verified")
    report_pdf_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    product = relationship("Product", foreign_keys=[product_id])
    user = relationship("User", foreign_keys=[user_id])
