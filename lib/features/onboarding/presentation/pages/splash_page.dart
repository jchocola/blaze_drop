import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_logo.dart';
import '../../../../core/widgets/section_label.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

/// Splash screen (2s). Shows the brand mark, then routes to either the
/// permission screen or Home based on the initial permission check.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _logoScale;
  late final Animation<double> _scan;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashDuration,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    _scan = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
    );
    _controller.forward();

    // Kick off the permission check; the BlocListener handles navigation.
    context.read<OnboardingCubit>().initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (!state.isInitialized) {
          return;
        }
        if (state.shouldEnterHome) {
          context.go(AppConstants.homePath);
        } else {
          context.go(AppConstants.onboardingPath);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Ambient radial glow behind the logo.
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.25),
                    radius: 0.9,
                    colors: [
                      Color(0x3300E5FF),
                      AppColors.background,
                      AppColors.background,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // Subtle grid overlay.
            Positioned.fill(child: _GridOverlay()),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _logoScale,
                        child: BlazeLogo(size: 104),
                      ),
                      const SizedBox(height: 24),
                      _Wordmark(),
                      const SizedBox(height: 10),
                      SectionLabel(
                        text: AppConstants.tagline,
                        color: AppColors.primaryContainer,
                        showBar: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom status line + progress.
            Positioned(
              left: AppConstants.gutter,
              right: AppConstants.gutter,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    text: 'SYS.INIT // CHECKING PERMISSIONS',
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _scan,
                    builder: (context, _) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _scan.value.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  const Divider(thickness: 1, color: AppColors.outlineVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'BLAZE',
          style: AppTextStyles.displayLg.copyWith(
            fontSize: 40,
            color: AppColors.primaryContainer,
          ),
        ),
        Text(
          'DROP',
          style: AppTextStyles.displayLg.copyWith(
            fontSize: 40,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _GridOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 44.0;
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.18)
      ..strokeWidth = 0.6;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final r = size.shortestSide * 0.55;
    final center = size.center(Offset.zero);
    final arcPaint = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, r * (i + 1) / 4, arcPaint);
    }
    // Diagonal scan line for a subtle radar feel.
    final scan = DateTime.now().millisecondsSinceEpoch % 3000 / 3000;
    final angle = scan * 2 * math.pi;
    final end =
        center + Offset(math.cos(angle), math.sin(angle)) * size.shortestSide;
    final scanPaint = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    canvas.drawLine(center, end, scanPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
