import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedBackgroundOverlay extends StatefulWidget {
  final double opacity;

  const AnimatedBackgroundOverlay({super.key, this.opacity = 1.0});

  @override
  State<AnimatedBackgroundOverlay> createState() => _AnimatedBackgroundOverlayState();
}

class _AnimatedBackgroundOverlayState extends State<AnimatedBackgroundOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _AnimatedBackgroundPainter(progress: _controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedBackgroundPainter extends CustomPainter {
  final double progress;

  const _AnimatedBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    _paintMovingGlow(canvas, size);
    _paintWave(canvas, size, 0.72, 0.22, Colors.red.withValues(alpha: 0.20));
    _paintWave(canvas, size, 0.84, 0.16, Colors.redAccent.withValues(alpha: 0.12));
    _paintParticles(canvas, size);
  }

  void _paintMovingGlow(Canvas canvas, Size size) {
    final x = size.width * (0.15 + 0.7 * (0.5 + 0.5 * math.sin(progress * math.pi * 2)));
    final y = size.height * (0.32 + 0.08 * math.cos(progress * math.pi * 2));
    final radius = size.shortestSide * 0.38;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.redAccent.withValues(alpha: 0.14),
          Colors.red.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));

    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  void _paintWave(Canvas canvas, Size size, double baseline, double heightFactor, Color color) {
    final path = Path();
    final waveHeight = size.height * heightFactor;
    final baseY = size.height * baseline;
    final phase = progress * math.pi * 2;

    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    for (double x = 0; x <= size.width; x += 12) {
      final normalized = x / size.width;
      final wave = math.sin((normalized * math.pi * 2.4) + phase) * waveHeight * 0.18;
      final secondary = math.cos((normalized * math.pi * 4.0) - phase * 0.7) * waveHeight * 0.08;
      path.lineTo(x, baseY + wave + secondary);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintParticles(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.redAccent.withValues(alpha: 0.18);

    for (int i = 0; i < 34; i++) {
      final seed = i * 0.137;
      final loop = (progress + seed) % 1.0;
      final x = size.width * ((math.sin(i * 12.9898) * 43758.5453).abs() % 1.0);
      final y = size.height * (1.05 - loop * 1.2);
      final drift = math.sin((loop * math.pi * 2) + i) * 24;
      final radius = 1.8 + (i % 5) * 0.7;

      canvas.drawCircle(Offset(x + drift, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
