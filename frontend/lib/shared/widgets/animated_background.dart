import 'dart:math';
import 'package:flutter/material.dart';

/// Animated mesh-gradient background with floating orbs.
class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({
    super.key,
    this.child,
    this.colors,
    this.orbCount = 5,
    this.speed = 1.0,
  });

  final Widget? child;
  final List<Color>? colors;
  final int orbCount;
  final double speed;

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.orbCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: (4000 + _random.nextInt(6000)) ~/ widget.speed,
        ),
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(c))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColors =
        widget.colors ??
        [
          scheme.primary.withValues(alpha: 0.15),
          scheme.secondary.withValues(alpha: 0.12),
          scheme.tertiary.withValues(alpha: 0.10),
          scheme.primary.withValues(alpha: 0.08),
          scheme.secondary.withValues(alpha: 0.06),
        ];

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge(_controllers),
            builder: (context, _) {
              return CustomPaint(
                painter: _MeshPainter(
                  progress: _animations.map((a) => a.value).toList(),
                  colors: baseColors,
                  orbCount: widget.orbCount,
                ),
              );
            },
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.progress,
    required this.colors,
    required this.orbCount,
  });

  final List<double> progress;
  final List<Color> colors;
  final int orbCount;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.transparent);

    for (int i = 0; i < orbCount; i++) {
      final t = progress[i];
      final cx = size.width * (0.2 + 0.6 * sin(t * 2 * pi + i));
      final cy = size.height * (0.2 + 0.6 * cos(t * 2 * pi + i * 1.3));
      final radius = size.width * (0.25 + 0.15 * sin(t * pi));

      final gradient = RadialGradient(
        colors: [
          colors[i % colors.length].withValues(alpha: 0.5),
          colors[i % colors.length].withValues(alpha: 0.0),
        ],
      );

      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => true;
}

/// Subtle floating particles background.
class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key, this.particleCount = 20, this.child});

  final int particleCount;
  final Widget? child;

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(
                  progress: _controller.value,
                  count: widget.particleCount,
                  scheme: Theme.of(context).colorScheme,
                ),
              );
            },
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.count,
    required this.scheme,
  });

  final double progress;
  final int count;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < count; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final r = 1.5 + random.nextDouble() * 2.5;
      final speed = 0.2 + random.nextDouble() * 0.5;
      final offset = (progress * size.height * speed + baseY) % size.height;

      final paint = Paint()
        ..color = scheme.primary.withValues(
          alpha: 0.06 + random.nextDouble() * 0.08,
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(baseX, offset), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
