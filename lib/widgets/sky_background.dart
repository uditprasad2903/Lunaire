import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../themes/mood_themes.dart';
import 'tap_burst_overlay.dart';

/// Sky background with twinkling stars + shooting stars + mood particles.
/// Works in both light and dark mode — colors adapt to the palette.
class SkyBackground extends StatefulWidget {
  final MoodPalette palette;
  final bool isDark;
  final Mood mood;
  final bool enableTrail;
  final Widget child;

  const SkyBackground({
    super.key,
    required this.palette,
    required this.isDark,
    required this.child,
    this.mood = Mood.defaultMood,
    this.enableTrail = false,
  });

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground>
    with TickerProviderStateMixin {
  late AnimationController _twinkleController;
  late AnimationController _shootController;
  late AnimationController _particleController;

  // Static twinkling stars
  final List<_Star> _stars = List.generate(15, (i) {
    final rnd = math.Random(i);
    return _Star(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      size: rnd.nextDouble() * 2 + 0.6,
      twinkleSpeed: rnd.nextDouble() * 2 + 0.8,
      offset: rnd.nextDouble() * math.pi * 2,
    );
  });

  // Shooting stars (multiple, with staggered timing)
  final List<_ShootingStar> _shootingStars = [];
  final math.Random _rnd = math.Random();

  // Floating particles (mood-specific)
  final List<_Particle> _particles = List.generate(5, (i) {
    final rnd = math.Random(i + 100);
    return _Particle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      size: rnd.nextDouble() * 4 + 2,
      speed: rnd.nextDouble() * 0.3 + 0.1,
      offset: rnd.nextDouble() * math.pi * 2,
      driftX: (rnd.nextDouble() - 0.5) * 0.3,
    );
  });

  @override
  void initState() {
    super.initState();

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _shootController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(_maybeSpawnShootingStar);
    _shootController.repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Spawn one initial shooting star
    _spawnShootingStar();
  }

  void _maybeSpawnShootingStar() {
    // ~ every 2-4 seconds spawn a new one
    if (_rnd.nextDouble() < 0.002) {
      _spawnShootingStar();
    }
    // Clean up finished ones
    _shootingStars.removeWhere((s) => s.progress >= 1.0);
    // Update progress of active ones
    for (final s in _shootingStars) {
      s.progress += 0.012; // controls speed
    }
  }

  void _spawnShootingStar() {
    if (_shootingStars.length >= 1) return;
    _shootingStars.add(_ShootingStar(
      startX: _rnd.nextDouble() * 0.6 - 0.1, // start somewhere left
      startY: _rnd.nextDouble() * 0.4,       // top half
      angle: math.pi / 6 + _rnd.nextDouble() * math.pi / 4, // diagonal
      length: 0.15 + _rnd.nextDouble() * 0.15,
      thickness: 1.5 + _rnd.nextDouble() * 1.5,
      progress: 0.0,
    ));
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _shootController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.palette.skyGradient,
        ),
      ),
      child: Stack(
        children: [
          if (context.select<SettingsService?, bool>(
              (s) => s?.ambientAnimations ?? true)) ...[
          // Twinkling stars layer
          AnimatedBuilder(
            animation: _twinkleController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _StarsPainter(
                  stars: _stars,
                  t: _twinkleController.value,
                  palette: widget.palette,
                  isDark: widget.isDark,
                ),
              );
            },
          ),

          // Floating particles (mood-specific)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlesPainter(
                  particles: _particles,
                  t: _particleController.value,
                  palette: widget.palette,
                  mood: widget.mood,
                  isDark: widget.isDark,
                ),
              );
            },
          ),

          // Shooting stars layer (always on top of stars)
          AnimatedBuilder(
            animation: _shootController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ShootingStarsPainter(
                  stars: _shootingStars,
                  palette: widget.palette,
                  isDark: widget.isDark,
                ),
              );
            },
          ),

          ],
          // Tap-burst layer: spawns mood-themed particles on tap
          Positioned.fill(
            child: TapBurstOverlay(
              mood: widget.mood,
              palette: widget.palette,
              isDark: widget.isDark,
              enableTrail: widget.enableTrail,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TWINKLING STARS
// ============================================================
class _Star {
  final double x, y, size, twinkleSpeed, offset;
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.offset,
  });
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  final MoodPalette palette;
  final bool isDark;

  _StarsPainter({
    required this.stars,
    required this.t,
    required this.palette,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // In light mode use primary tint for visibility, in dark use moonGlow
    final baseColor = isDark ? palette.moonGlow : palette.primary;

    for (final s in stars) {
      final twinkle =
          (math.sin(t * math.pi * 2 * s.twinkleSpeed + s.offset) + 1) / 2;
      final opacity =
          isDark ? (0.3 + twinkle * 0.7) : (0.15 + twinkle * 0.35);

      final paint = Paint()..color = baseColor.withOpacity(opacity);

      final center = Offset(s.x * size.width, s.y * size.height * 0.7);

      // Draw star as a glowing dot with cross-shaped sparkle
      canvas.drawCircle(center, s.size, paint);

      // Add subtle sparkle cross when bright
      if (twinkle > 0.6) {
        final sparklePaint = Paint()
          ..color = baseColor.withOpacity(opacity * 0.5)
          ..strokeWidth = 0.6;
        final len = s.size * (1.5 + twinkle * 2);
        canvas.drawLine(
            Offset(center.dx - len, center.dy),
            Offset(center.dx + len, center.dy),
            sparklePaint);
        canvas.drawLine(
            Offset(center.dx, center.dy - len),
            Offset(center.dx, center.dy + len),
            sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => true;
}

// ============================================================
// SHOOTING STARS
// ============================================================
class _ShootingStar {
  final double startX, startY, angle, length, thickness;
  double progress;
  _ShootingStar({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.length,
    required this.thickness,
    required this.progress,
  });
}

class _ShootingStarsPainter extends CustomPainter {
  final List<_ShootingStar> stars;
  final MoodPalette palette;
  final bool isDark;

  _ShootingStarsPainter({
    required this.stars,
    required this.palette,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final headColor = isDark ? Colors.white : palette.primary;
    final tailColor = palette.moonGlow;

    for (final s in stars) {
      if (s.progress <= 0 || s.progress >= 1) continue;

      // Travel diagonally across the screen
      final travelX = math.cos(s.angle) * size.width * 1.5;
      final travelY = math.sin(s.angle) * size.height * 1.5;

      final headX = s.startX * size.width + travelX * s.progress;
      final headY = s.startY * size.height + travelY * s.progress;

      // Tail
      final tailLength = s.length * size.width;
      final tailX = headX - math.cos(s.angle) * tailLength;
      final tailY = headY - math.sin(s.angle) * tailLength;

      // Fade in and out
      final fade = s.progress < 0.15
          ? s.progress / 0.15
          : s.progress > 0.85
              ? (1 - s.progress) / 0.15
              : 1.0;
      final alpha = (isDark ? 0.95 : 0.7) * fade;

      // Tail gradient line
      final tailPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s.thickness
        ..shader = LinearGradient(
          colors: [
            tailColor.withOpacity(0.0),
            tailColor.withOpacity(alpha * 0.6),
            headColor.withOpacity(alpha),
          ],
        ).createShader(Rect.fromPoints(
            Offset(tailX, tailY), Offset(headX, headY)));

      canvas.drawLine(
          Offset(tailX, tailY), Offset(headX, headY), tailPaint);

      // Bright head with glow
      // Simple two-circle glow without blur
      canvas.drawCircle(Offset(headX, headY), s.thickness * 1.8,
          Paint()..color = headColor.withOpacity(alpha * 0.35));

      final headPaint = Paint()..color = headColor.withOpacity(alpha);
      canvas.drawCircle(Offset(headX, headY), s.thickness, headPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShootingStarsPainter old) => true;
}

// ============================================================
// MOOD-SPECIFIC PARTICLES
// ============================================================
class _Particle {
  final double x, y, size, speed, offset, driftX;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.offset,
    required this.driftX,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final MoodPalette palette;
  final Mood mood;
  final bool isDark;

  _ParticlesPainter({
    required this.particles,
    required this.t,
    required this.palette,
    required this.mood,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Vertical drift (downward for petals, upward for mist, etc.)
      final dir = _isUpward(mood) ? -1 : 1;
      final yPos = ((p.y + t * p.speed * dir) % 1.0 + 1.0) % 1.0;
      final xPos = (p.x + math.sin(t * math.pi * 2 + p.offset) * p.driftX) % 1.0;

      final center = Offset(xPos * size.width, yPos * size.height);
      final opacity = isDark ? 0.4 : 0.25;

      _drawMoodParticle(canvas, center, p.size, opacity);
    }
  }

  bool _isUpward(Mood m) =>
      m == Mood.calm || m == Mood.anxious || m == Mood.defaultMood;

  void _drawMoodParticle(
      Canvas canvas, Offset center, double size, double opacity) {
    switch (mood) {
      case Mood.romantic:
        _drawHeart(canvas, center, size, palette.primary.withOpacity(opacity));
        break;
      case Mood.happy:
        _drawSparkle(canvas, center, size, palette.moonGlow.withOpacity(opacity));
        break;
      case Mood.sad:
        _drawDroplet(canvas, center, size, palette.moonGlow.withOpacity(opacity));
        break;
      case Mood.angry:
        _drawEmber(canvas, center, size, palette.primary.withOpacity(opacity));
        break;
      case Mood.calm:
      case Mood.anxious:
      case Mood.defaultMood:
        // Two-circle fake glow (no blur — GPU-friendly)
        canvas.drawCircle(center, size,
            Paint()..color = palette.moonGlow.withOpacity(opacity * 0.3));
        canvas.drawCircle(center, size * 0.5,
            Paint()..color = palette.moonGlow.withOpacity(opacity * 0.6));
        break;
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
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

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - size, center.dy),
        Offset(center.dx + size, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - size),
        Offset(center.dx, center.dy + size), paint);
    canvas.drawCircle(center, size * 0.3, Paint()..color = color);
  }

  void _drawDroplet(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(
        center.dx + size * 0.7, center.dy, center.dx, center.dy + size * 0.7);
    path.quadraticBezierTo(
        center.dx - size * 0.7, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  void _drawEmber(Canvas canvas, Offset center, double size, Color color) {
    canvas.drawCircle(center, size * 0.8,
        Paint()..color = color.withOpacity(color.opacity * 0.6));
    canvas.drawCircle(center, size * 0.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => true;
}
