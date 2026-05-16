import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stress_detection_app/config/app_theme.dart';

/// Speedometer-style gauge for detected stress (1–10) during pressure phase.
class StressSpeedometer extends StatelessWidget {
  const StressSpeedometer({
    super.key,
    required this.level,
    this.label = 'Detected stress',
  });

  final double level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final value = level.clamp(1.0, 10.0);
    final color = _colorFor(value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 72,
              child: CustomPaint(
                painter: _GaugePainter(value: value, color: color),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusText(value),
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (value - 1) / 9,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(double v) {
    if (v <= 3) return 'Low — system expects more urgency';
    if (v <= 6) return 'Moderate';
    return 'High stress detected';
  }

  Color _colorFor(double v) {
    if (v <= 3) return AppTheme.success;
    if (v <= 6) return AppTheme.warning;
    return AppTheme.danger;
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;

    const startAngle = math.pi * 0.85;
    const sweepAngle = math.pi * 1.3;

    final track = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      track,
    );

    final progress = (value - 1) / 9;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      fill,
    );

    final needleAngle = startAngle + sweepAngle * progress;
    final needleEnd = Offset(
      center.dx + radius * 0.75 * math.cos(needleAngle),
      center.dy + radius * 0.75 * math.sin(needleAngle),
    );
    final needle = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needle);

    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}
