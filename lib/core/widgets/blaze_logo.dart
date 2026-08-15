import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// BlazeDrop brand mark: a sharp hexagon badge with a neon bolt.
///
/// Drawn with a custom painter to stay crisp at any size and to match the
/// "luminance & stroke" elevation language of DESIGN.md.
class BlazeLogo extends StatelessWidget {
  const BlazeLogo({super.key, this.size = 96, this.strokeColor});

  /// Edge length of the square bounding box.
  final double size;

  /// Color of the bolt and hexagon stroke. Defaults to Electric Cyan.
  final Color? strokeColor;

  @override
  Widget build(BuildContext context) {
    final color = strokeColor ?? AppColors.primaryContainer;
    return CustomPaint(
      size: Size.square(size),
      painter: _BlazeLogoPainter(color: color),
    );
  }
}

class _BlazeLogoPainter extends CustomPainter {
  const _BlazeLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final hexagon = _hexagonPath(center, radius);

    // Dark fill (Level 0 base).
    canvas.drawPath(hexagon, Paint()..color = AppColors.surfaceContainerLowest);

    // Outer "glow" stroke.
    canvas.drawPath(
      hexagon,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    // Inner accent stroke.
    canvas.drawPath(
      hexagon,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Lightning bolt.
    canvas.drawPath(_boltPath(center, radius), Paint()..color = color);
  }

  Path _hexagonPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.92);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Path _boltPath(Offset center, double radius) {
    const points = <Offset>[
      Offset(0.10, -0.60),
      Offset(-0.28, 0.05),
      Offset(-0.02, 0.05),
      Offset(-0.10, 0.60),
      Offset(0.28, -0.05),
      Offset(0.02, -0.05),
    ];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = center + points[i] * (radius * 0.86);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _BlazeLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
