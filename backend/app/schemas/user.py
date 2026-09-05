from typing import Optional, List, Dict, Any
from enum import Enum
from pydantic import BaseModel, EmailStr
from datetime import datetime

class UserRole(str, Enum):
    CONSUMER = "CONSUMER"          # Citizen / Consumer Advocate
    OFFICER = "OFFICER"            # Legal Metrology / Food Safety Officer
    ADMIN = "ADMIN"                # Enforcement Directorate Administrator

class DietaryPreferences(BaseModel):
    allergies: List[str] = []
    diabetic_mode: bool = False
    avoid_palm_oil: bool = True
    low_sodium: bool = False
    vegan: bool = False
    avoid_artificial_sweeteners: bool = True

class UserBase(BaseModel):
    name: str = "User"
    email: Optional[EmailStr] = None
    role: UserRole = UserRole.CONSUMER
    badge_number: Optional[str] = None
    jurisdiction: Optional[str] = None
    department: Optional[str] = None
    organization: Optional[str] = None
    dietary_preferences: Optional[DietaryPreferences] = None

class UserCreate(UserBase):
    password: Optional[str] = None

class RoleSwitchRequest(BaseModel):
    role: UserRole
    badge_number: Optional[str] = None
    jurisdiction: Optional[str] = None
    department: Optional[str] = None

class UserResponse(UserBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
