import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/balance_models.dart';

class ForecastChart extends StatelessWidget {
  final List<ForecastPoint> forecasts;
  final double currentBalance;

  const ForecastChart({
    Key? key,
    required this.forecasts,
    required this.currentBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const Center(child: Text('No forecast data'));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 500,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 7,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < forecasts.length) {
                      final date = DateTime.parse(forecasts[value.toInt()].date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('d/M').format(date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1000,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            minX: 0,
            maxX: forecasts.length.toDouble() - 1,
            minY: _getMinY(),
            maxY: _getMaxY(),
            lineBarsData: [
              // Predicted line
              LineChartBarData(
                spots: forecasts
                    .asMap()
                    .entries
                    .map((e) => FlSpot(
                          e.key.toDouble(),
                          e.value.predicted,
                        ))
                    .toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              // Upper bound
              LineChartBarData(
                spots: forecasts
                    .asMap()
                    .entries
                    .map((e) => FlSpot(
                          e.key.toDouble(),
                          e.value.upper,
                        ))
                    .toList(),
                isCurved: true,
                color: Colors.blue.withOpacity(0.3),
                barWidth: 1,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
              // Lower bound
              LineChartBarData(
                spots: forecasts
                    .asMap()
                    .entries
                    .map((e) => FlSpot(
                          e.key.toDouble(),
                          e.value.lower,
                        ))
                    .toList(),
                isCurved: true,
                color: Colors.blue.withOpacity(0.3),
                barWidth: 1,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMinY() {
    final allValues = forecasts.expand((f) => [f.lower, f.predicted, f.upper]);
    final min = allValues.reduce((a, b) => a < b ? a : b);
    return (min - 500).floorToDouble();
  }

  double _getMaxY() {
    final allValues = forecasts.expand((f) => [f.lower, f.predicted, f.upper]);
    final max = allValues.reduce((a, b) => a > b ? a : b);
    return (max + 500).ceilToDouble();
  }
}
