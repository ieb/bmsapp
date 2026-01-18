import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class SocGauge extends StatelessWidget {
  final double percentage; // 0 to 100

  const SocGauge({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(240, 240),
            painter: _GaugePainter(percentage: percentage),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    percentage.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    '%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'SOC',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;

  _GaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Background Arc
    final bgPaint = Paint()
      ..color = const Color(0xFF254646)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground Arc
    final fgPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final sweepAngle = 2 * pi * (percentage / 100);
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-pi / 2); // Start from top
    
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0,
      sweepAngle,
      false,
      fgPaint,
    );
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
