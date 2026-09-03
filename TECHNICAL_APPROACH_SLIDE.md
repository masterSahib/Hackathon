# 🛠️ SLIDE: Technical Approach
**Problem Statement ID: 26034** | **System Architecture & Implementation Pipeline**

---

### 1. 🏗️ 4-Stage End-to-End Technical Pipeline

```
[ 1. CAPTURE & INGESTION ] ──► [ 2. MULTIMODAL AI & OCR ] ──► [ 3. RULE COMPLIANCE ENGINE ] ──► [ 4. ENFORCEMENT & REPORTING ]
 • Dual-Pack Camera Snap         • Gemini 2.5 Flash Vision         • LMPC Rules 2011 (Rule 6, 7-9)  • 100-Point Truth Score Dashboard
 • Mobile Barcode Scanner        • PDP Text & Layout Extraction    • FSSAI HFSS & Hierarchy Audit    • Court-Admissible Notice PDF
 • E-Commerce Image URL          • Barcode Decoupled Resolution    • Mathematical Threshold Checks   • Interactive AI Assistant Chat
```

---

### 2. ⚙️ Technology Stack

| Layer | Technologies Used | Purpose |
| :--- | :--- | :--- |
| **Mobile & Web Client** | **Flutter (Dart), Riverpod, CameraX** | Cross-platform UI, dual camera capture, state management, and real-time offline-first caching. |
| **Backend & API** | **Python (FastAPI), Uvicorn, Pydantic v2** | High-performance asynchronous REST API (<100ms response time), statutory routing & validation. |
| **Multimodal AI & NLP**| **Google Gemini 2.5 Flash, OpenRouter** | Zero-shot optical extraction of PDP text, mandatory declaration detection, and conversational legal Q&A. |
| **Rule Engine** | **Deterministic Python Rule Engine** | 100% accurate mathematical & regex validation of LMPC Rule 6 mandatory fields, font size, and Unit Sale Price. |
| **Database & Storage** | **PostgreSQL (Render Cloud), SQLAlchemy** | Relational inspection history, photo evidence dockets, product SKU registry, and audit trail. |
| **Document Generation**| **ReportLab Engine** | Automated rendering of digitally timestamped, official statutory violation notice PDFs. |

---

### 3. 🧠 Core Methodologies & Algorithms
- **Dual-Pack Layout & Vision Parsing**: Multimodal LLM prompts instruct the vision model to isolate the Principal Display Panel (PDP) and extract 8 structured JSON key-value pairs (Manufacturer, Generic Name, Net Qty, USP, MRP, Date, Grievance Info).
- **Deterministic Rule Engine (No Hallucinations)**: While Vision AI extracts text, all legal compliance checks are strictly computed through hardcoded mathematical rules (e.g., `USP = MRP / Net_Qty`, `Font_Height >= PDP_Area_Ratio`).
- **Hybrid Registry Fallback**: Queries local PostgreSQL database first, falls back to Open Food Facts live API, and defaults to Gemini multimodal visual analysis if unlisted.
- **Asynchronous Scalability**: Non-blocking I/O enables officers to process batch audits in parallel without server bottlenecks.
