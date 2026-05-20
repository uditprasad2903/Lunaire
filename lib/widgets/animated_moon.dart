import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../themes/mood_themes.dart';

/// AnimatedMoon - The signature element of Lunaire.
/// Renders a glowing moon whose shape & color reflect the current mood.
class AnimatedMoon extends StatefulWidget {
  final Mood mood;
  final MoodPalette palette;
  final double size;
  final bool animate;

  const AnimatedMoon({
    super.key,
    required this.mood,
    required this.palette,
    this.size = 120,
    this.animate = true,
  });

  @override
  State<AnimatedMoon> createState() => _AnimatedMoonState();
}

class _AnimatedMoonState extends State<AnimatedMoon>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _floatController]),
      builder: (context, _) {
        final glow = 0.6 + 0.4 * _glowController.value;
        final float = widget.animate ? math.sin(_floatController.value * math.pi) * 6 : 0;
        return Transform.translate(
          offset: Offset(0, -float.toDouble()),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _MoonPainter(
              mood: widget.mood,
              palette: widget.palette,
              glowIntensity: glow,
            ),
          ),
        );
      },
    );
  }
}

class _MoonPainter extends CustomPainter {
  final Mood mood;
  final MoodPalette palette;
  final double glowIntensity;

  _MoonPainter({
    required this.mood,
    required this.palette,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.7;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.moonGlow.withOpacity(0.6 * glowIntensity),
          palette.moonGlow.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2));
    canvas.drawCircle(center, radius * 2, glowPaint);

    // Inner glow
    final innerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.moonGlow.withOpacity(0.8 * glowIntensity),
          palette.moonGlow.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius * 1.4, innerGlow);

    switch (mood) {
      case Mood.happy:
      case Mood.defaultMood:
        _drawFullMoon(canvas, center, radius);
        break;
      case Mood.sad:
      case Mood.anxious:
        _drawCrescentMoon(canvas, center, radius);
        break;
      case Mood.angry:
        _drawBloodMoon(canvas, center, radius);
        break;
      case Mood.calm:
        _drawFullMoon(canvas, center, radius);
        _drawStars(canvas, size);
        break;
      case Mood.romantic:
        _drawFullMoon(canvas, center, radius);
        _drawHearts(canvas, size);
        break;
    }
  }

  void _drawFullMoon(Canvas canvas, Offset center, double radius) {
    final moonPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Color.lerp(palette.moonColor, Colors.white, 0.3)!,
          palette.moonColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, moonPaint);

    // Craters
    final craterPaint = Paint()
      ..color = palette.moonColor.withOpacity(0.4);
    canvas.drawCircle(center + Offset(radius * 0.3, -radius * 0.2), radius * 0.12, craterPaint);
    canvas.drawCircle(center + Offset(-radius * 0.2, radius * 0.3), radius * 0.08, craterPaint);
    canvas.drawCircle(center + Offset(radius * 0.1, radius * 0.4), radius * 0.06, craterPaint);
  }

  void _drawCrescentMoon(Canvas canvas, Offset center, double radius) {
    final moonPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Color.lerp(palette.moonColor, Colors.white, 0.3)!,
          palette.moonColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, moonPaint);

    // Cut out for crescent
    final cutoutPaint = Paint()
      ..color = palette.background
      ..blendMode = BlendMode.dstOut;
    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius * 2), Paint());
    canvas.drawCircle(center, radius, moonPaint);
    canvas.drawCircle(center + Offset(radius * 0.4, -radius * 0.1), radius * 0.95, cutoutPaint);
    canvas.restore();
  }

  void _drawBloodMoon(Canvas canvas, Offset center, double radius) {
    final moonPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        colors: [
          const Color(0xFFFF6B6B),
          palette.moonColor,
          const Color(0xFF8B0000),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, moonPaint);

    // Dark craters
    final craterPaint = Paint()
      ..color = const Color(0xFF4A0000).withOpacity(0.5);
    canvas.drawCircle(center + Offset(radius * 0.3, -radius * 0.2), radius * 0.15, craterPaint);
    canvas.drawCircle(center + Offset(-radius * 0.25, radius * 0.25), radius * 0.1, craterPaint);
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..color = palette.moonGlow.withOpacity(0.8);
    final positions = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.75),
      Offset(size.width * 0.25, size.height * 0.85),
    ];
    for (final p in positions) {
      _drawStar(canvas, p, 4, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final outer = Offset(
        center.dx + math.cos(angle) * size,
        center.dy + math.sin(angle) * size,
      );
      final innerAngle = angle + math.pi / 5;
      final inner = Offset(
        center.dx + math.cos(innerAngle) * size * 0.4,
        center.dy + math.sin(innerAngle) * size * 0.4,
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHearts(Canvas canvas, Size size) {
    final heartPaint = Paint()..color = palette.primary.withOpacity(0.7);
    _drawHeart(canvas, Offset(size.width * 0.2, size.height * 0.25), 8, heartPaint);
    _drawHeart(canvas, Offset(size.width * 0.8, size.height * 0.3), 6, heartPaint);
    _drawHeart(canvas, Offset(size.width * 0.15, size.height * 0.75), 7, heartPaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size, center.dy - size * 0.5,
      center.dx - size * 0.5, center.dy - size,
      center.dx, center.dy - size * 0.3,
    );
    path.cubicTo(
      center.dx + size * 0.5, center.dy - size,
      center.dx + size, center.dy - size * 0.5,
      center.dx, center.dy + size * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) =>
      old.glowIntensity != glowIntensity || old.mood != mood;
}
