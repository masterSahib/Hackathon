import os
from typing import List
from dotenv import load_dotenv

# Load .env file
load_dotenv()

class Settings:
    PROJECT_NAME: str = os.getenv("PROJECT_NAME", "LabelTruth API")
    VERSION: str = os.getenv("VERSION", "1.0.0")
    API_V1_STR: str = os.getenv("API_V1_STR", "/api/v1")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() in ("true", "1", "t")

    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://teamproject_stan_user:6lArYf6jRPwu6EBySOJYE0H7PxrJHPTU@dpg-da4u168u01pc73dbn9e0-a.oregon-postgres.render.com/teamproject_stan"
    )

    # OpenRouter / AI Vision
    AI_API_KEY: str = os.getenv(
        "AI_API_KEY",
        "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"
    )
    OPENROUTER_MODEL: str = os.getenv("OPENROUTER_MODEL", "nvidia/nemotron-3-ultra-550b-a55b:free")
    OPENROUTER_VISION_MODEL: str = os.getenv("OPENROUTER_VISION_MODEL", "nvidia/nemotron-nano-12b-v2-vl:free")
    OPENROUTER_FALLBACK_MODEL: str = os.getenv("OPENROUTER_FALLBACK_MODEL", "google/gemini-2.5-flash")

    # CORS
    CORS_ORIGINS: List[str] = ["*"]

settings = Settings()
