from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1.router import api_router

# Create database tables automatically
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="LabelTruth: AI-Powered Misleading Food Packaging & FSSAI Compliance Audit Backend",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include v1 Router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {
        "app": "LabelTruth API",
        "version": settings.VERSION,
        "status": "online",
        "docs": "/docs",
        "description": "AI-Powered Misleading Food Packaging & FSSAI Compliance Detector"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "labeltruth-backend"}
