import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final Widget? centerWidget;
  
  const CircularGauge({
    super.key,
    required this.value,
    this.size = 150,
    this.strokeWidth = 12,
    this.color = const Color(0xFFFFC700),
    this.backgroundColor = const Color(0xFF1E3A5F),
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              value: value,
              strokeWidth: strokeWidth,
              color: color,
              backgroundColor: backgroundColor,
            ),
          ),
          if (centerWidget != null) centerWidget!,
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  _GaugePainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * value;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

// Specialized gauge for savings goal
class SavingsGoalGauge extends StatelessWidget {
  final double current;
  final double target;
  
  const SavingsGoalGauge({
    super.key,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (current / target * 100).clamp(0, 100);
    final value = current / target;
    
    return CircularGauge(
      value: value,
      size: 180,
      strokeWidth: 16,
      centerWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percentage.toInt()}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFC700),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'MONTHLY SAVINGS GOAL',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B9AAD),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${current.toStringAsFixed(0)} / \$${target.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Risk score gauge
class RiskScoreGauge extends StatelessWidget {
  final double score; // 0 to 10
  
  const RiskScoreGauge({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return CircularGauge(
      value: score / 10,
      size: 120,
      strokeWidth: 10,
      color: _getScoreColor(score),
      centerWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _getScoreColor(score),
            ),
          ),
          const Text(
            '/10',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B9AAD),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score < 3) return const Color(0xFF4CAF50); // Green - low risk
    if (score < 6) return const Color(0xFFFFC700); // Yellow - medium risk
    return const Color(0xFFFF5252); // Red - high risk
  }
}

// Liquidity score gauge (large percentage)
class LiquidityScoreGauge extends StatelessWidget {
  final double percentage; // 0 to 100
  
  const LiquidityScoreGauge({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return CircularGauge(
      value: percentage / 100,
      size: 200,
      strokeWidth: 20,
      centerWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFC700),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Optimal',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}
