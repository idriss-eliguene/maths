import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../services/api_service.dart';

class SolvePage extends StatefulWidget {
  const SolvePage({super.key});

  @override
  State<SolvePage> createState() => _SolvePageState();
}

class _SolvePageState extends State<SolvePage> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _solution;
  List<String> _steps = [];

  bool _isPureNumeric(String input) {
    final exp = input.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^[\d\.\+\-\*/\^\(\)]+$').hasMatch(exp);
  }

  Map<String, dynamic> _evaluateWithSteps(String input) {
    final parser = Parser();
    final context = ContextModel();

    Expression expr = parser.parse(input);
    List<String> steps = [expr.toString()];

    while (true) {
      final simplified = expr.simplify();
      if (simplified.toString() == expr.toString()) break;
      expr = simplified;
      steps.add(expr.toString());
    }

    final num value = expr.evaluate(EvaluationType.REAL, context);
    final result = value % 1 == 0 ? value.toInt().toString() : value.toString();

    steps.add(result);
    return {'result': result, 'steps': steps};
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _solution = null;
      _steps.clear();
    });

    final input = _ctrl.text.trim();

    try {
      if (_isPureNumeric(input)) {
        final res = _evaluateWithSteps(input);
        setState(() {
          _solution = '${input.replaceAll(RegExp(r"\s+"), "")} = ${res['result']}';
          _steps = List<String>.from(res['steps'] as List);
        });
      } else {
        final data = await solveProblem(input);
        setState(() {
          _solution = data['solution'] as String?;
          _steps = List<String>.from(data['steps'] as List? ?? const <String>[]);
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'Énoncé ou expression numérique',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _run,
              child: _loading
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator())
                  : const Text('Résoudre'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_solution != null) ...[
              Text('Solution :',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SelectableText(_solution!),
              const Divider(),
              if (_steps.isNotEmpty)
                Text('Étapes :',
                    style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: _steps.map((s) {
                    final trimmed = s.trim();
                    final isLatex = trimmed.startsWith(r'\[') && trimmed.endsWith(r'\]');
                    final clean = trimmed.replaceAll(r'\[', '').replaceAll(r'\]', '');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: isLatex
                          ? Math.tex(clean, textStyle: const TextStyle(fontSize: 16))
                          : Text(trimmed, style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );
}
