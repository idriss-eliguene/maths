# app.py  -----------------------------------------------------------
"""
API Flask :  /solve  -> résolution pas-à-pas
             /study -> étude complète de f(x) (JSON garanti)
DeepSeek v3 via le router Hugging Face compatible OpenAI.
"""

import os, json, re, requests
from flask import Flask, request, jsonify

# ---------- config -------------------------------------------------
HF_TOKEN = os.getenv("HF_TOKEN")        #  export HF_TOKEN="hf_xxx"
if not HF_TOKEN:
    raise RuntimeError("Définis HF_TOKEN dans tes variables d'environnement")

API_URL = "https://router.huggingface.co/novita/v3/openai/chat/completions"
MODEL   = "deepseek/deepseek-v3-0324"
HEADERS = {"Authorization": f"Bearer {HF_TOKEN}", "Content-Type": "application/json"}

def ask_model(system: str, user: str, **extra) -> str:
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user",   "content": user},
        ],
        **extra
    }
    r = requests.post(API_URL, headers=HEADERS, json=payload, timeout=60)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

# ---------- helper : tente jusqu’à JSON ---------------------------
def ask_until_json(system: str, user: str, tries: int = 3):
    for _ in range(tries):
        answer = ask_model(system, user)
        try:
            return json.loads(answer)          # 1er essai : réponse déjà JSON
        except json.JSONDecodeError:
            # Cherche un bloc {...}
            m = re.search(r"\{.*\}", answer, re.S)
            if m:
                try:
                    return json.loads(m.group(0))
                except json.JSONDecodeError:
                    pass
    # Dernier recours : renvoyer brut
    return {"raw": answer}

# ---------- Flask --------------------------------------------------
app = Flask(__name__)

# /solve ------------------------------------------------------------
@app.route("/solve", methods=["POST"])
def solve():
    try:
        prob = request.get_json(force=True).get("problem", "").strip()
        if not prob:
            return jsonify({"solution": "No problem provided", "steps": []}), 400

        sol = ask_model(
            "You are a helpful assistant that explains math problems step by step.",
            f"Please solve the following math problem step by step:\n{prob}"
        )
        steps = [s for s in sol.split("\n") if s.strip()]
        return jsonify({"solution": sol, "steps": steps})
    except Exception as e:
        return jsonify({"solution": f"Error: {e}", "steps": []}), 400

# /study ------------------------------------------------------------
@app.route("/study", methods=["POST"])
def study():
    try:
        func = request.get_json(force=True).get("function", "").strip()
        if not func:
            return jsonify({"error": "No function provided"}), 400

        user_prompt = (
            f"Étudie complètement la fonction f(x) = {func}.\n"
            "Réponds exclusivement en JSON strict :\n"
            "{\n"
            '  "domaine": "...",\n'
            '  "limites": [{"x":"...","val":"..."}],\n'
            '  "derivative": "...",\n'
            '  "critical_points": ["..."],\n'
            '  "variation_table": [{"interval":"...","f_prime":"+|-","f":"↗|↘"}],\n'
            '  "concavity": [{"interval":"...","type":"convexe|concave"}],\n'
            '  "asymptotes": ["..."],\n'
            '  "commentaire": "..." \n'
            "}"
        )

        data = ask_until_json(
            "You generate rigorous mathematical analysis and return JSON only.",
            user_prompt
        )
        return jsonify(data)
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# -------------------------------------------------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
