"""
Flask math-solver that uses the DeepSeek v3 model
via Hugging Face’s /openai/chat/completions endpoint.
-----------------------------------------------------------------
Prerequisites:
  pip install flask requests python-dotenv   # or however you manage deps
  export HF_TOKEN="hf_***"                   # your Hugging Face token
-----------------------------------------------------------------
"""

import os
import requests
from flask import Flask, request, jsonify

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------
HF_TOKEN = os.getenv("HF_TOKEN")  # set this in your shell / .env
if not HF_TOKEN:
    raise RuntimeError("HF_TOKEN environment variable is not set")

API_URL = "https://router.huggingface.co/novita/v3/openai/chat/completions"
MODEL_ID = "deepseek/deepseek-v3-0324"

HEADERS = {
    "Authorization": f"Bearer {HF_TOKEN}",
    "Content-Type": "application/json"
}

# ------------------------------------------------------------------
# Helper: send a prompt to DeepSeek and return the answer text
# ------------------------------------------------------------------
def query_deepseek(prompt: str) -> str:
    payload = {
        "model": MODEL_ID,
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are a helpful assistant that explains "
                    "math problems step by step."
                )
            },
            {"role": "user", "content": prompt}
        ]
        # You can add temperature, max_tokens, etc. if you like
    }

    response = requests.post(API_URL, headers=HEADERS, json=payload, timeout=60)
    response.raise_for_status()                          # ← will raise for HTTP≠200
    data = response.json()

    # Hugging Face router mimics the OpenAI schema:
    # { "choices": [ { "message": { "content": "..." } } ] }
    return data["choices"][0]["message"]["content"].strip()


# ------------------------------------------------------------------
# Flask app
# ------------------------------------------------------------------
app = Flask(__name__)

@app.route("/solve", methods=["POST"])
def solve_problem():
    try:
        data = request.get_json(force=True)
        problem = data.get("problem", "").strip()
        if not problem:
            return jsonify({"solution": "No problem provided", "steps": []}), 400

        prompt = f"Please solve the following math problem step by step: {problem}"
        solution = query_deepseek(prompt)
        steps = [line for line in solution.split("\n") if line.strip()]

        return jsonify({"solution": solution, "steps": steps})

    except requests.HTTPError as e:
        # e.response.json() often has more detail
        return jsonify({"solution": f"API error: {e}", "steps": []}), 502
    except Exception as e:
        return jsonify({"solution": f"Error: {str(e)}", "steps": []}), 400


# ------------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------------
if __name__ == "__main__":
    # For production you’d run via gunicorn/uvicorn/etc.
    app.run(host="0.0.0.0", port=5000, debug=True)
