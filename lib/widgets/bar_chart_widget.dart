import 'package:flutter/material.dart';

class BarChartWidget extends StatelessWidget {
  final List<BarChartData> data;
  final double height;
  final double maxValue;
  final bool showLabels;
  
  const BarChartWidget({
    super.key,
    required this.data,
    this.height = 120,
    required this.maxValue,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bar
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      height: (item.value / maxValue) * (height - (showLabels ? 24 : 0)),
                    ),
                  ),
                  // Label
                  if (showLabels) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B9AAD),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BarChartData {
  final String label;
  final double value;
  final Color color;
  
  const BarChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}

// Growth chart (small bars for dashboard)
class GrowthChart extends StatelessWidget {
  final List<double> values;
  
  const GrowthChart({
    super.key,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          final isLast = index == values.length - 1;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: (value / maxValue) * 60,
                decoration: BoxDecoration(
                  color: isLast 
                      ? const Color(0xFFFFC700)
                      : const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Forecast chart (30-day liquidity with special markers)
class ForecastChart extends StatelessWidget {
  final List<ForecastData> data;
  
  const ForecastChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162639),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC700),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '30-Day',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A1628),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'WEEKLY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B9AAD),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'MONTHLY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B9AAD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.asMap().entries.map((entry) {
                final item = entry.value;
                final barHeight = (item.value / maxValue) * 100;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (item.isHighlight)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5252),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (item.isHighlight) const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'SEP 01',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  color: Color(0xFF8B9AAD),
                ),
              ),
              Text(
                'SEP 15',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  color: Color(0xFF8B9AAD),
                ),
              ),
              Text(
                'TODAY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFC700),
                ),
              ),
              Text(
                'SEP 30',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  color: Color(0xFF8B9AAD),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ForecastData {
  final double value;
  final Color color;
  final bool isHighlight;
  
  const ForecastData({
    required this.value,
    required this.color,
    this.isHighlight = false,
  });
}
