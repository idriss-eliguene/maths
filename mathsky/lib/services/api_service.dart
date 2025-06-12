import 'dart:convert';
import 'package:http/http.dart' as http;

/// ⚠️  Change HOST if you test on a real device or iOS sim.
/// On Android emulator '10.0.2.2' pointe vers localhost de l’hôte.
const String _baseUrl = 'http://51.75.117.209:5000';

Future<Map<String, dynamic>> solveProblem(String problem) async {
  final res = await http.post(
    Uri.parse('$_baseUrl/solve'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'problem': problem.trim()}),
  );
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> studyFunction(String func) async {
  final res = await http.post(
    Uri.parse('$_baseUrl/study'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'function': func.trim()}),
  );
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}
