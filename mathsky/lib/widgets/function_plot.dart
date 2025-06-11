import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:math_expressions/math_expressions.dart';

/// Affiche la courbe y = f(x) sur [xmin, xmax].
class FunctionPlot extends StatelessWidget {
  final String expression;
  final double xmin;
  final double xmax;
  final int samples;           // nombre de points

  const FunctionPlot({
    super.key,
    required this.expression,
    this.xmin = -10,
    this.xmax = 10,
    this.samples = 400,
  });

  @override
  Widget build(BuildContext context) {
    // ----- parse l'expression ------------------------------
    final parser = Parser();
    late Expression exp;
    try {
      exp = parser.parse(expression);
    } catch (_) {
      return const Text('Expression invalide');
    }
    final contextModel = ContextModel();

    // ----- génère les points -------------------------------
    final step = (xmax - xmin) / samples;
    final List<FlSpot> points = [];
    for (int i = 0; i <= samples; i++) {
      final x = xmin + i * step;
      contextModel.bindVariable(Variable('x'), Number(x));
      double y;
      try {
        y = exp.evaluate(EvaluationType.REAL, contextModel).toDouble();
        if (y.isInfinite || y.isNaN) continue; // ignore asymptotes
      } catch (_) {
        continue;
      }
      points.add(FlSpot(x, y));
    }
    if (points.length < 2) {
      return const Text('Pas de points traçables');
    }

    // ----- détermine l'échelle Y automatique ---------------
    final ys = points.map((p) => p.y);
    final ymin = ys.reduce(math.min);
    final ymax = ys.reduce(math.max);

    return LineChart(
      LineChartData(
        minX: xmin,
        maxX: xmax,
        minY: ymin,
        maxY: ymax,
        backgroundColor: Colors.white,
        gridData: FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
