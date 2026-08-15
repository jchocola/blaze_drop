import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Speedometer-style gauge for transfer progress (FUNCTIONALITY.md §4.3).
///
/// A bottom semicircle with a cyan→orange gradient stroke, tick marks, a
/// moving needle and a percentage readout in the middle.
class SpeedometerGauge extends StatelessWidget {
  const SpeedometerGauge({
    super.key,
    required this.progress,
    this.size = 200,
  });

  /// 0..1.
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size * 0.62,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpeedometerPainter(progress: clamped),
            ),
          ),
          Positioned(
            bottom: size * 0.06,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(clamped * 100).round()}%',
                  style: AppTextStyles.displayLg.copyWith(
                    fontSize: size * 0.18,
                    color: AppColors.primaryContainer,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  _SpeedometerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.12,
      size.width * 0.84,
      size.height * 1.7,
    );
    final center = Offset(size.width / 2, rect.bottom - size.height * 0.24);
    final radius = rect.width / 2;

    // Background track.
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = AppColors.surfaceContainerHighest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // Glow behind the progress arc.
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * progress,
      false,
      Paint()
        ..color = AppColors.secondaryContainer.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );

    // Progress arc with cyan→orange gradient.
    final shader = SweepGradient(
      startAngle: math.pi,
      endAngle: math.pi * 2,
      colors: const [
        AppColors.primaryContainer,
        AppColors.primaryContainer,
        AppColors.secondaryContainer,
      ],
    ).createShader(rect);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * progress,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // Tick marks at 0 / 25 / 50 / 75 / 100.
    for (var i = 0; i <= 4; i++) {
      final angle = math.pi + math.pi * i / 4;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = AppColors.outline.withValues(alpha: 0.8)
          ..strokeWidth = 2,
      );
    }

    // Needle.
    final needleAngle = math.pi + math.pi * progress;
    final needleTip =
        center + Offset(math.cos(needleAngle), math.sin(needleAngle)) * (radius - 14);
    canvas.drawLine(
      center,
      needleTip,
      Paint()
        ..color = AppColors.secondaryContainer
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      5,
      Paint()..color = AppColors.onSurface,
    );
    canvas.drawCircle(
      center,
      2.5,
      Paint()..color = AppColors.secondaryContainer,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
