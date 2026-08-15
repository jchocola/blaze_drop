import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// High-speed progress bar: cyan→orange gradient fill with a striped overlay
/// (DESIGN.md "Progress Bars" — striped pattern signals fast movement).
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.progress,
    this.height = 10,
  });

  /// 0..1.
  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRect(
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Track.
            Positioned.fill(
              child: ColoredBox(color: AppColors.surfaceContainerHighest),
            ),
            // Fill.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width * clamped,
              child: CustomPaint(
                painter: _StripedFillPainter(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryContainer,
                      AppColors.secondaryContainer,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripedFillPainter extends CustomPainter {
  _StripedFillPainter({required this.gradient});

  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..shader = gradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, fillPaint);

    // Diagonal stripes.
    final stripe = Paint()
      ..color = AppColors.onPrimary.withValues(alpha: 0.22);
    const stripeWidth = 8.0;
    const gap = 6.0;
    final path = Path();
    for (var x = -size.height; x < size.width + size.height; x += stripeWidth + gap) {
      path
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + stripeWidth, 0)
        ..lineTo(x + stripeWidth, size.height)
        ..close();
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(path, stripe);
    canvas.restore();

    // Leading edge.
    canvas.drawRect(
      Rect.fromLTWH(size.width - 2, 0, 2, size.height),
      Paint()..color = AppColors.secondaryContainer,
    );
  }

  @override
  bool shouldRepaint(covariant _StripedFillPainter oldDelegate) => false;
}
