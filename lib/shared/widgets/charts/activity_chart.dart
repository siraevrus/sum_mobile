import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

/// График активности (барный)
class ActivityChart extends StatelessWidget {
  final List<ActivityData> data;
  final String title;
  final bool showLegend;

  const ActivityChart({
    super.key,
    required this.data,
    this.title = 'Активность',
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // График
            SizedBox(
              height: 200,
              child: BarChart(
                _buildBarChartData(),
                swapAnimationDuration: const Duration(milliseconds: 300),
              ),
            ),
            
            if (showLegend) ...[
              const SizedBox(height: 16),
              _buildLegend(context),
            ],
          ],
        ),
      ),
    );
  }

  BarChartData _buildBarChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _getMaxY(),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final item = data[group.x.toInt()];
            final value = rodIndex == 0 ? item.completed : item.pending;
            final label = rodIndex == 0 ? 'Выполнено' : 'В ожидании';
            
            return BarTooltipItem(
              '${item.period}\n$label: $value',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    data[index].period,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const Text('');
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _getInterval(),
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      barGroups: _buildBarGroups(),
      gridData: FlGridData(
        show: true,
        horizontalInterval: _getInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
        drawVerticalLine: false,
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          // Выполненные
          BarChartRodData(
            toY: item.completed.toDouble(),
            color: AppColors.success,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          // В ожидании
          BarChartRodData(
            toY: item.pending.toDouble(),
            color: AppColors.warning,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          context,
          color: AppColors.success,
          label: 'Выполнено',
        ),
        const SizedBox(width: 20),
        _buildLegendItem(
          context,
          color: AppColors.warning,
          label: 'В ожидании',
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, {
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;
    
    double maxValue = 0;
    for (final item in data) {
      final itemMax = [item.completed, item.pending].reduce((a, b) => a > b ? a : b);
      if (itemMax > maxValue) {
        maxValue = itemMax.toDouble();
      }
    }
    
    return maxValue * 1.2; // Добавляем 20% сверху
  }

  double _getInterval() {
    final maxY = _getMaxY();
    return maxY / 5; // 5 делений
  }
}

/// Данные для графика активности
class ActivityData {
  final String period;
  final int completed;
  final int pending;

  const ActivityData({
    required this.period,
    required this.completed,
    required this.pending,
  });
}
