// lib/utils/text_cleaner.dart

String cleanOCRText(String raw) {
  final cleaned = raw
      .replaceAll('\n', ' ')
      .replaceAll(RegExp(r'[^\w\d\s\+\-\*/\^\=\(\)\.\[\]xXfF]'), '') // enlève les caractères indésirables
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();

  // Corrige les débuts courants inutiles
  final corrections = {
    'f(x)=': '',
    'fx=': '',
    'fx': '',
    'f =': '',
    'f(x)': '',
    'y=': '',
  };

  String expr = cleaned;
  for (final entry in corrections.entries) {
    expr = expr.replaceAll(entry.key, entry.value);
  }

  return expr.trim();
}

bool isLikelyMathExpression(String input) {
  return RegExp(r'[xX\d\+\-\*/\^\=\(\)]').hasMatch(input) && input.length > 3;
}
