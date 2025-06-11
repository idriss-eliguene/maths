import 'package:flutter/material.dart';
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

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _solution = null;
      _steps.clear();
    });
    try {
      final data = await solveProblem(_ctrl.text);
      setState(() {
        _solution = data['solution'] as String?;
        _steps = List<String>.from(data['steps'] as List? ?? const []);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Énoncé du problème',
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
            Text('Solution complète :',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(_solution!),
            const Divider(),
            Text('Étapes :',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ..._steps.map((s) => Text('• $s')),
          ],
        ],
      ),
    );
  }
}
