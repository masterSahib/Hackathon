import httpx
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
from fastapi import APIRouter, HTTPException, Depends
from app.core.config import settings

router = APIRouter()

class ChatMessage(BaseModel):
    role: str  # "user" or "assistant"
    content: str

class ProductChatRequest(BaseModel):
    product_name: str
    brand_name: Optional[str] = "Brand"
    truth_score: Optional[int] = 50
    verdict: Optional[str] = "Misleading"
    marketing_claims: Optional[List[str]] = []
    ingredients_text: Optional[str] = ""
    nutrition: Optional[Dict[str, Any]] = {}
    violations: Optional[List[Dict[str, Any]]] = []
    user_question: str
    chat_history: Optional[List[ChatMessage]] = []

class ProductChatResponse(BaseModel):
    reply: str
    suggestions: Optional[List[str]] = []

CHAT_SYSTEM_PROMPT = """You are 'LabelTruth AI' — an expert Food Safety Auditor, Clinical Nutritionist, and Regulatory Compliance Officer specializing in Indian FSSAI statutory standards, ICMR-NIN dietary guidelines, and consumer protection laws.

You are analyzing a specific food product that was just scanned by the user.

You have full access to:
- The product's brand and name
- Front-of-pack marketing claims
- Exact back-panel ingredients list and percentages
- Nutritional values per 100g (Calories, Total Sugars, Added Sugars, Saturated Fat, Sodium, Protein)
- Deterministic FSSAI violation findings (e.g. Grain hierarchy deception under Sec 23, Palm oil masking under Sec 2.2.2.5, HFSS sodium/saturated fat exceedance, synthetic additives like INS 150d/627/631/330).

Guidelines:
1. Provide concise, clear, and scientifically authoritative answers in friendly Indian English.
2. Directly answer the consumer's question (e.g. safety for diabetics, children, heart health, weight loss, chemical safety).
3. Quote specific regulatory standards (FSSAI, ICMR-NIN) and exact ingredient lab stats from the context when relevant.
4. Give practical, constructive advice and suggest cleaner whole-food alternatives when appropriate.
5. Format your answer with neat bullet points and bold highlights for readability.
"""

@router.post("/product", response_model=ProductChatResponse)
async def chat_about_product(request: ProductChatRequest):
    """Interactive AI Chat to answer custom questions about the audited food product."""
    if not request.user_question.strip():
        raise HTTPException(status_code=400, detail="Question cannot be empty.")

    # Build contextual system knowledge about the audited product
    product_context = f"""
AUDITED PRODUCT CONTEXT:
- Product: {request.brand_name} - {request.product_name}
- Truth Score: {request.truth_score}/100 ({request.verdict})
- Front Claims: {', '.join(request.marketing_claims) if request.marketing_claims else 'None'}
- Ingredients: {request.ingredients_text or 'Not provided'}
- Nutrition (per 100g): {request.nutrition}
- Statutory Violations: {request.violations}
"""

    messages = [
        {"role": "system", "content": f"{CHAT_SYSTEM_PROMPT}\n\n{product_context}"}
    ]

    # Include recent chat history
    if request.chat_history:
        for msg in request.chat_history[-6:]:
            messages.append({"role": msg.role, "content": msg.content})

    # Add current user question
    messages.append({"role": "user", "content": request.user_question})

    headers = {
        "Authorization": f"Bearer {settings.AI_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://github.com/masterSahib/Hackathon",
        "X-Title": "LabelTruth-FSSAI-Chat",
    }

    payload = {
        "model": settings.OPENROUTER_MODEL or "google/gemini-2.5-flash",
        "messages": messages,
        "temperature": 0.3,
        "max_tokens": 800,
    }

    try:
        async with httpx.AsyncClient(timeout=25.0) as client:
            resp = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                json=payload
            )

            if resp.status_code == 200:
                data = resp.json()
                reply_text = data["choices"][0]["message"]["content"].strip()
                return ProductChatResponse(
                    reply=reply_text,
                    suggestions=[
                        "Is this safe for daily consumption?",
                        "What makes the saturated fat or sodium high?",
                        "What are healthy clean alternatives?",
                    ]
                )
            else:
                # Fallback to secondary model if rate-limited
                fallback_payload = dict(payload)
                fallback_payload["model"] = "google/gemini-2.5-flash"
                resp_fb = await client.post(
                    "https://openrouter.ai/api/v1/chat/completions",
                    headers=headers,
                    json=fallback_payload
                )
                if resp_fb.status_code == 200:
                    data = resp_fb.json()
                    return ProductChatResponse(
                        reply=data["choices"][0]["message"]["content"].strip(),
                        suggestions=[
                            "How does this violate FSSAI guidelines?",
                            "Is this safe for children?",
                        ]
                    )
                raise HTTPException(status_code=502, detail="AI service temporarily unavailable.")
    except Exception as e:
        print(f"[ProductChat] Error: {e}")
        # Deterministic intelligent fallback reply based on FSSAI guidelines
        return ProductChatResponse(
            reply=f"**Analysis for {request.product_name}:**\n\n"
                  f"Based on our FSSAI statutory audit, this product scored **{request.truth_score}/100 ({request.verdict})**.\n\n"
                  f"- **Ingredients Profile**: {request.ingredients_text[:150] if request.ingredients_text else 'Contains processed additives'}\n"
                  f"- **Regulatory Guidance**: Products with Truth Score below 60 have significant gaps between front-of-pack claims and back-panel ingredient realities. We recommend opting for whole-food alternatives.",
            suggestions=["What are healthier alternatives?", "Explain the ingredients"]
        )
