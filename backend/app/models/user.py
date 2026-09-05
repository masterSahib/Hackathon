import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, JSON
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False, default="Guest User")
    email = Column(String, unique=True, index=True, nullable=True)
    role = Column(String, default="CONSUMER", nullable=False)  # CONSUMER, OFFICER, ADMIN
    badge_number = Column(String, nullable=True)
    jurisdiction = Column(String, nullable=True)
    department = Column(String, nullable=True)
    organization = Column(String, nullable=True)
    dietary_preferences = Column(JSON, default=lambda: {
        "allergies": [],
        "diabetic_mode": False,
        "avoid_palm_oil": True,
        "low_sodium": False,
        "vegan": False,
        "avoid_artificial_sweeteners": True
    })
    created_at = Column(DateTime, default=datetime.utcnow)
