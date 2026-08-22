from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, DietaryPreferences

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(db: Session = Depends(get_db)):
    """Retrieves or auto-creates default user profile with dietary preferences."""
    user = db.query(User).first()
    if not user:
        user = User(
            name="Health Conscious User",
            email="consumer@labeltruth.ai",
            dietary_preferences={
                "allergies": [],
                "diabetic_mode": False,
                "avoid_palm_oil": True,
                "low_sodium": False,
                "vegan": False,
                "avoid_artificial_sweeteners": True
            }
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user

@router.put("/me/preferences", response_model=UserResponse)
async def update_dietary_preferences(
    preferences: DietaryPreferences,
    db: Session = Depends(get_db)
):
    """Updates user dietary preferences and alert triggers."""
    user = db.query(User).first()
    if not user:
        user = User(
            name="Health Conscious User",
            email="consumer@labeltruth.ai",
            dietary_preferences=preferences.dict()
        )
        db.add(user)
    else:
        user.dietary_preferences = preferences.dict()
    db.commit()
    db.refresh(user)
    return user
