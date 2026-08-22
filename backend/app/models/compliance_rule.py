import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, JSON, Text
from app.core.database import Base

class ComplianceRule(Base):
    __tablename__ = "compliance_rules"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    rule_code = Column(String, unique=True, index=True, nullable=False)
    claim_keyword = Column(String, nullable=False, index=True)
    violation_condition_json = Column(JSON, default=dict)
    severity = Column(String, nullable=False, default="Medium")  # Low, Medium, High, Critical
    regulation_reference = Column(String, nullable=False)  # e.g., "FSSAI Section 23", "FSSAI Claims Reg 2018 Sec 5"
    description = Column(Text, nullable=True)
    penalty_score = Column(JSON, default=dict)
    created_at = Column(DateTime, default=datetime.utcnow)
