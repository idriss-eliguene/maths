import 'package:flutter/material.dart';

/// Affiche le tableau de variations (x / f’ / f) à partir
/// de la liste JSON `variation_table` retournée par l’API.
class VariationTable extends StatelessWidget {
  /// Exemple d’élément :
  /// { "interval":"(-∞;-2)", "f_prime":"+", "f":"↗" }
  final List<Map<String, dynamic>> rows;

  const VariationTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.shade400;

    return Table(
      border: TableBorder.all(color: borderColor),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {0: FixedColumnWidth(120)},
      children: [
        _rowHeader('x', rows.map((e) => e['interval'] as String)),
        _rowHeader("f'(x)", rows.map((e) => e['f_prime'] as String)),
        _rowArrows(rows.map((e) => e['f'] as String)),
      ],
    );
  }

  /* ---------- helpers ---------- */

  TableRow _rowHeader(String label, Iterable<String> cells) => TableRow(
        decoration: const BoxDecoration(color: Color(0xFFEFF0F3)),
        children: [
          _HeaderCell(label),
          ...cells.map(_DataCell.new),
        ],
      );

  TableRow _rowArrows(Iterable<String> dirs) => TableRow(
        children: [
          const _HeaderCell('f(x)'),
          ...dirs.map(_ArrowCell.new),
        ],
      );
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}

class _DataCell extends StatelessWidget {
  final String text;
  const _DataCell(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(text, textAlign: TextAlign.center),
      );
}

class _ArrowCell extends StatelessWidget {
  final String dir; // ↗ ou ↘
  const _ArrowCell(this.dir);

  @override
  Widget build(BuildContext context) {
    final up = dir.contains('↗');
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Icon(
        up ? Icons.arrow_upward : Icons.arrow_downward,
        size: 18,
        color: up ? Colors.green : Colors.red,
      ),
    );
  }
}
