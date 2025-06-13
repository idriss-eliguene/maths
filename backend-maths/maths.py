# app.py

import os, json, re, requests, subprocess
from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
import logging
logging.basicConfig(level=logging.DEBUG)


# Configuration
HF_TOKEN = os.getenv("HF_TOKEN")
if not HF_TOKEN:
    raise RuntimeError("Please set your HF_TOKEN environment variable")

API_URL = "https://router.huggingface.co/novita/v3/openai/chat/completions"
MODEL = "deepseek/deepseek-v3-0324"
HEADERS = {"Authorization": f"Bearer {HF_TOKEN}", "Content-Type": "application/json"}
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Flask setup
app = Flask(__name__)
CORS(app)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Helper functions
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

def ask_until_json(system: str, user: str, tries: int = 3):
    for _ in range(tries):
        answer = ask_model(system, user)
        try:
            return json.loads(answer)
        except json.JSONDecodeError:
            m = re.search(r"\{.*\}", answer, re.S)
            if m:
                try:
                    return json.loads(m.group(0))
                except json.JSONDecodeError:
                    pass
    return {"raw": answer}

def run_latex_ocr(image_path: str) -> str:
    try:
        output = subprocess.check_output(
            ["python3", "latex_ocr/run.py", "--image", image_path],
            stderr=subprocess.STDOUT  # 👈 redirige stderr vers stdout
        )
        result = output.decode().strip()
        app.logger.debug(f"[OCR OUTPUT]: {result}")
        return result
    except subprocess.CalledProcessError as e:
        app.logger.debug(f"[OCR ERROR]: {e.output.decode()}")
        print(f"[OCR ERROR]: {e.output.decode()}")  # LOG l'erreur réelle
        return f"Error: {e.output.decode()}"


# Routes
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

@app.route("/scan", methods=["POST"])
def scan():
    try:
        file = request.files.get("image")
        if not file:
            return jsonify({"error": "No image uploaded"}), 400
        filename = secure_filename(file.filename)
        path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(path)

        text = run_latex_ocr(path)
        return jsonify({"text": text})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Launch app
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
