import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Animated radar sweep used while the node scans for peers
/// (FUNCTIONALITY.md §4.1).
///
/// Draws concentric rings, a rotating cyan sweep wedge and a few fixed blips
/// to suggest live spectrum analysis. Driven by a repeating [AnimationController].
class RadarScan extends StatefulWidget {
  const RadarScan({super.key, this.size = 180, this.blipCount = 4});

  final double size;
  final int blipCount;

  @override
  State<RadarScan> createState() => _RadarScanState();
}

class _RadarScanState extends State<RadarScan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _RadarPainter(
            sweep: _controller.value * 2 * math.pi,
            blipCount: widget.blipCount,
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.sweep, required this.blipCount});

  final double sweep;
  final int blipCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final ringPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, ringPaint);
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primaryContainer.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Crosshairs.
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ringPaint,
    );

    // Rotating sweep wedge.
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweep - 0.55,
        endAngle: sweep,
        colors: [
          AppColors.primaryContainer.withValues(alpha: 0.0),
          AppColors.primaryContainer.withValues(alpha: 0.45),
          AppColors.primaryContainer.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sweepPaint);

    // Leading edge line.
    final edge =
        center + Offset(math.cos(sweep), math.sin(sweep)) * radius;
    canvas.drawLine(
      center,
      edge,
      Paint()
        ..color = AppColors.primaryContainer.withValues(alpha: 0.9)
        ..strokeWidth = 1.5,
    );

    // Static blips (deterministic by index).
    for (var i = 0; i < blipCount; i++) {
      final angle = (i * 1.9) % (2 * math.pi);
      final distance = radius * (0.35 + (i % 3) * 0.22);
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        pos,
        2.4,
        Paint()..color = AppColors.tertiaryContainer.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.sweep != sweep;
}
