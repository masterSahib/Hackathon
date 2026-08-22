# 🚀 Render Deployment Guide for LabelTruth Backend

This step-by-step guide explains how to deploy the **LabelTruth FastAPI Backend** to [Render.com](https://render.com) so your mobile app can connect to it from anywhere in the world.

---

## 📋 Prerequisites
1. A free account on [Render.com](https://render.com).
2. A GitHub account with this repository pushed.
3. Your PostgreSQL database URL and OpenRouter API key.

---

## ⚡ Option 1: Automatic Deployment using Render Blueprint (Recommended)

1. **Push your code to GitHub**:
   ```bash
   git add .
   git commit -m "Deploy LabelTruth backend to Render"
   git push origin main
   ```

2. **Deploy Blueprint on Render**:
   - Go to your [Render Dashboard](https://dashboard.render.com/).
   - Click the **New +** button at the top right and select **Blueprint**.
   - Connect your GitHub repository.
   - Render will detect `backend/render.yaml` automatically and configure the Web Service and PostgreSQL database.
   - Click **Apply**.

3. **Set Environment Variables**:
   In your Render Dashboard under the `labeltruth-backend` service, go to **Environment** and verify/add:
   - `DATABASE_URL`: `postgresql://teamproject_stan_user:6lArYf6jRPwu6EBySOJYE0H7PxrJHPTU@dpg-da4u168u01pc73dbn9e0-a.oregon-postgres.render.com/teamproject_stan`
   - `AI_API_KEY`: `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`
   - `OPENROUTER_MODEL`: `nvidia/nemotron-3-ultra-550b-a55b:free`
   - `OPENROUTER_VISION_MODEL`: `nvidia/nemotron-nano-12b-v2-vl:free`
   - `OPENROUTER_FALLBACK_MODEL`: `google/gemini-2.5-flash`

---

## 🛠️ Option 2: Manual Web Service Deployment on Render

If you prefer to configure manually:

1. In Render Dashboard, click **New +** > **Web Service**.
2. Connect your GitHub repository.
3. Configure the settings:
   - **Name**: `labeltruth-backend`
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: `Free`
4. Add the following **Environment Variables**:
   ```ini
   PYTHON_VERSION=3.10.0
   DATABASE_URL=postgresql://teamproject_stan_user:6lArYf6jRPwu6EBySOJYE0H7PxrJHPTU@dpg-da4u168u01pc73dbn9e0-a.oregon-postgres.render.com/teamproject_stan
   AI_API_KEY=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
   OPENROUTER_MODEL=nvidia/nemotron-3-ultra-550b-a55b:free
   OPENROUTER_VISION_MODEL=nvidia/nemotron-nano-12b-v2-vl:free
   OPENROUTER_FALLBACK_MODEL=google/gemini-2.5-flash
   ```
5. Click **Create Web Service**.

---

## 🔍 How to Verify Your Live Render Backend

Once Render finishes building, you will get a live URL (e.g., `https://labeltruth-backend.onrender.com`).

Test the following endpoints in your browser:
- Health Check: `https://<your-render-url>.onrender.com/health`
  - Expected: `{"status": "healthy", "service": "LabelTruth Backend API", "version": "1.0.0"}`
- Interactive Swagger UI: `https://<your-render-url>.onrender.com/docs`

---

## 📱 Connecting Your Phone App to Live Render Backend

1. Open the **LabelTruth App** on your phone.
2. Tap the **Settings** icon (top right or bottom navigation "Alerts").
3. In the **Backend API Connection** section:
   - Enter your Render URL in the API Base URL box: `https://<your-render-url>.onrender.com`
   - Or tap the **"Render Cloud API"** preset button.
   - Tap the **Save** icon.
4. Your phone app will now communicate directly with the live Render cloud backend!
