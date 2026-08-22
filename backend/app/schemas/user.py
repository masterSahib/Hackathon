from typing import Optional, List, Dict, Any
from pydantic import BaseModel, EmailStr
from datetime import datetime

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
    dietary_preferences: Optional[DietaryPreferences] = None

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
