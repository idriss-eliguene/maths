import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/variation_table.dart';
import '../widgets/function_plot.dart';
import '../widgets/image_scan_button.dart';
import 'dart:async';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  final _ctrl = TextEditingController(text: '(x^2 - 1)/(x + 2)');

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });

    try {
      final result = await studyFunction(_ctrl.text);
      setState(() => _data = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildResult() {
    if (_data == null) return const SizedBox.shrink();
    final d = _data!;

    if (d.containsKey('raw')) return SelectableText(d['raw'] as String);

    final crit    = (d['critical_points']  as List?) ?? const [];
    final limites = (d['limites']          as List?) ?? const [];
    final varTab  = (d['variation_table']  as List?) ?? const [];
    final concav  = (d['concavity']        as List?) ?? const [];
    final asympt  = (d['asymptotes']       as List?) ?? const [];

    return ListView(
      children: [
        Text('Domaine : ${d['domaine'] ?? '—'}'),
        Text('Dérivée : ${d['derivative'] ?? '—'}'),
        Text('Points critiques : ${crit.join(', ')}'),
        const SizedBox(height: 12),

        Text('Limites :', style: Theme.of(context).textTheme.titleSmall),
        ...limites.map((l) => Text(' • x→${l['x']}   f(x)→ ${l['val']}')),
        const SizedBox(height: 12),

        Text('Tableau de variations :', style: Theme.of(context).textTheme.titleSmall),
        varTab.isNotEmpty
            ? VariationTable(rows: List<Map<String, dynamic>>.from(varTab))
            : const Text(' —'),
        const SizedBox(height: 12),

        Text('Courbe :', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: 250, child: FunctionPlot(expression: _ctrl.text)),
        const SizedBox(height: 12),

        Text('Concavité :', style: Theme.of(context).textTheme.titleSmall),
        ...concav.map((c) => Text(' • ${c['interval']} : ${c['type']}')),
        const SizedBox(height: 12),

        Text('Asymptotes : ${asympt.join(', ')}'),
        const Divider(),
        Text(d['commentaire'] ?? ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: "Scanner une image",
                  icon: const Icon(Icons.image_search),
                  onPressed: () async {
                    final expression = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        final completer = Completer<String>();
                        return AlertDialog(
                          title: const Text('Scan d\'image'),
                          content: ImageScanButton(
                            onTextScanned: (text) {
                              completer.complete(text);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    );

                    if (expression != null && expression.isNotEmpty) {
                      setState(() => _ctrl.text = expression);
                      _run();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'f(x) =',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _run,
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator())
                  : const Text('Étudier'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_data != null) Expanded(child: _buildResult()),
          ],
        ),
      );
}
