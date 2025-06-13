String extractMathExpression(String raw) {
  // Supprimer les sauts de ligne et caractères inutiles
  final cleaned = raw.replaceAll('\n', ' ').replaceAll(RegExp(r'[^a-zA-Z0-9\(\)\+\-\*/\^=\. ]'), '').trim();

  // Chercher des expressions de la forme f(x) = ...
  final regex = RegExp(r'(f\(.*?\)\s*=\s*[^=]+)');
  final match = regex.firstMatch(cleaned);

  if (match != null) {
    return match.group(1)!;
  }

  // Sinon, on retourne la ligne la plus longue
  final lines = cleaned.split(' ');
  lines.sort((a, b) => b.length.compareTo(a.length));
  return lines.firstWhere((line) => line.length > 4, orElse: () => cleaned);
}
