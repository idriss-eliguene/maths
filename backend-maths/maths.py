from flask import Flask, request, jsonify
from sympy import symbols, Eq, simplify, solve
import re

app = Flask(__name__)

# Fonction utilitaire pour ajouter les opérateurs de multiplication
def add_multiplication_operators(expression):
    # Remplace "2x" par "2*x"
    return re.sub(r'(\d)([a-zA-Z])', r'\1*\2', expression)

@app.route('/solve', methods=['POST'])
def solve_problem():
    try:
        data = request.get_json(force=True)
        print("DEBUG: Received JSON data:", data)

        if not data or 'problem' not in data:
            return jsonify({'solution': 'Missing problem key.'}), 400

        problem = data['problem']

        # Optionnel : extraire la partie après les deux-points (OCR)
        if ':' in problem:
            problem = problem.split(':', 1)[-1].strip()

        # Ajoute les opérateurs de multiplication implicite
        problem = add_multiplication_operators(problem)
        print("DEBUG: Problem after preprocessing:", problem)

        x = symbols('x')
        solution = None

        # Résolution d'équation
        if '=' in problem:
            left, right = problem.split('=')
            expr = Eq(simplify(left.strip()), simplify(right.strip()))
            solution = solve(expr, x)
        else:
            solution = simplify(problem)

        return jsonify({'solution': str(solution)})

    except Exception as e:
        print(f"ERROR: {e}")
        return jsonify({'solution': f'Error: {str(e)}'}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

