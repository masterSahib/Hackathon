from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, DietaryPreferences, UserBase, RoleSwitchRequest, UserRole

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(db: Session = Depends(get_db)):
    """Retrieves or auto-creates default user profile with role & dietary preferences."""
    user = db.query(User).first()
    if not user:
        user = User(
            name="Enforcement Officer Sharma",
            email="officer.sharma@doca.gov.in",
            role="OFFICER",
            badge_number="LMPC-DL-2026-881",
            jurisdiction="North Zone Directorate, New Delhi",
            department="Legal Metrology & Packaging Enforcement",
            organization="Department of Consumer Affairs (DoCA)",
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

@router.put("/me", response_model=UserResponse)
async def update_user_profile(
    profile: UserBase,
    db: Session = Depends(get_db)
):
    """Updates user profile including Role (OFFICER / CONSUMER), Badge Number, and Jurisdiction."""
    user = db.query(User).first()
    if not user:
        user = User(
            name=profile.name,
            email=profile.email,
            role=profile.role.value if hasattr(profile.role, "value") else str(profile.role),
            badge_number=profile.badge_number,
            jurisdiction=profile.jurisdiction,
            department=profile.department,
            organization=profile.organization,
            dietary_preferences=profile.dietary_preferences.dict() if profile.dietary_preferences else {}
        )
        db.add(user)
    else:
        user.name = profile.name
        if profile.email:
            user.email = profile.email
        user.role = profile.role.value if hasattr(profile.role, "value") else str(profile.role)
        user.badge_number = profile.badge_number
        user.jurisdiction = profile.jurisdiction
        user.department = profile.department
        user.organization = profile.organization
        if profile.dietary_preferences:
            user.dietary_preferences = profile.dietary_preferences.dict()

    db.commit()
    db.refresh(user)
    return user

@router.post("/me/switch-role", response_model=UserResponse)
async def switch_user_role(
    req: RoleSwitchRequest,
    db: Session = Depends(get_db)
):
    """Switches active session role between Enforcement Officer (LMPC Inspector) and Consumer Advocate."""
    user = db.query(User).first()
    if not user:
        user = User(name="Active User")
        db.add(user)

    user.role = req.role.value if hasattr(req.role, "value") else str(req.role)
    if req.badge_number:
        user.badge_number = req.badge_number
    if req.jurisdiction:
        user.jurisdiction = req.jurisdiction
    if req.department:
        user.department = req.department

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
            role="CONSUMER",
            dietary_preferences=preferences.dict()
        )
        db.add(user)
    else:
        user.dietary_preferences = preferences.dict()
    db.commit()
    db.refresh(user)
    return user
