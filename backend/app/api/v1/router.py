from fastapi import APIRouter
from app.api.v1.endpoints import analyze, products, report, scans, rules, users, chat

api_router = APIRouter()

api_router.include_router(analyze.router, tags=["Compliance & Vision Analysis"])
api_router.include_router(products.router, prefix="/products", tags=["Products & Barcode Cache"])
api_router.include_router(scans.router, prefix="/scans", tags=["Scan History"])
api_router.include_router(report.router, prefix="/report", tags=["Statutory PDF Reports"])
api_router.include_router(rules.router, prefix="/rules", tags=["Compliance Regulations"])
api_router.include_router(users.router, prefix="/users", tags=["User Profile & Dietary Alerts"])
api_router.include_router(chat.router, prefix="/chat", tags=["Product AI Chat Assistant"])
