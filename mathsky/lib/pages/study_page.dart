// lib/pages/study_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/variation_table.dart';
import '../widgets/function_plot.dart';

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

  /* ---------------------- réseau ---------------------- */
  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });
    try {
      _data = await studyFunction(_ctrl.text);
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  /* --------------------- affichage -------------------- */
  Widget _buildResult() {
    if (_data == null) return const SizedBox.shrink();
    final d = _data!;

    // Si le modèle n’a pas renvoyé un JSON structuré
    if (d.containsKey('raw')) {
      return SelectableText(d['raw'] as String);
    }

    // Listes protégées contre null
    final crit    = (d['critical_points']  as List?) ?? const [];
    final limites = (d['limites']          as List?) ?? const [];
    final varTab  = (d['variation_table']  as List?) ?? const [];
    final concav  = (d['concavity']        as List?) ?? const [];
    final asympt  = (d['asymptotes']       as List?) ?? const [];

    return ListView(
      children: [
        /* --------- champs principaux ------------------ */
        Text('Domaine : ${d['domaine'] ?? '—'}'),
        Text('Dérivée : ${d['derivative'] ?? '—'}'),
        Text('Points critiques : ${crit.join(', ')}'),
        const SizedBox(height: 12),

        /* --------- Limites ---------------------------- */
        Text('Limites :',
            style: Theme.of(context).textTheme.titleSmall),
        ...limites.map((l) =>
            Text(' • x→${l['x']}   f(x)→ ${l['val']}')),
        const SizedBox(height: 12),

        /* --------- Tableau de variations -------------- */
        Text('Tableau de variations :',
            style: Theme.of(context).textTheme.titleSmall),
        varTab.isNotEmpty
            ? VariationTable(rows: List<Map<String, dynamic>>.from(varTab))
            : const Text(' —'),
        const SizedBox(height: 12),

        /* --------- Tracé de la courbe ----------------- */
        Text('Courbe :', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(
          height: 250,
          child: FunctionPlot(expression: _ctrl.text),
        ),
        const SizedBox(height: 12),

        /* --------- Concavité -------------------------- */
        Text('Concavité :',
            style: Theme.of(context).textTheme.titleSmall),
        ...concav.map((c) =>
            Text(' • ${c['interval']} : ${c['type']}')),
        const SizedBox(height: 12),

        /* --------- Asymptotes ------------------------- */
        Text('Asymptotes : ${asympt.join(', ')}'),
        const Divider(),
        Text(d['commentaire'] ?? ''),
      ],
    );
  }

  /* -------------------- build ------------------------ */
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator())
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
