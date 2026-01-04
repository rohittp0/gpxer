import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';

/// Elevation profile chart using fl_chart
class ElevationChart extends StatelessWidget {
  final List<LatLng> points;
  final List<double?> elevations;

  const ElevationChart({
    super.key,
    required this.points,
    required this.elevations,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out null elevations
    final validElevations = <double>[];
    final validIndices = <int>[];

    for (int i = 0; i < elevations.length; i++) {
      if (elevations[i] != null) {
        validElevations.add(elevations[i]!);
        validIndices.add(i);
      }
    }

    // Check if we have enough elevation data
    if (validElevations.length < 10) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No elevation profile available.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Prepare data points for chart
    final spots = <FlSpot>[];
    for (int i = 0; i < validElevations.length; i++) {
      spots.add(FlSpot(i.toDouble(), validElevations[i]));
    }

    // Find min and max for better scaling
    final minElevation = validElevations.reduce((a, b) => a < b ? a : b);
    final maxElevation = validElevations.reduce((a, b) => a > b ? a : b);
    final range = maxElevation - minElevation;
    final padding = range * 0.1;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range / 4,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()} m',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          minY: minElevation - padding,
          maxY: maxElevation + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(0)} m',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
