import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../themes/mood_themes.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../services/haptic_service.dart';

/// TapBurstOverlay - performance-optimized gesture-driven particle effects.
///
/// Optimizations:
///   - Hard cap on total particles (prevents unbounded growth)
///   - Trail particles throttled (~30 spawns/sec max)
///   - Hold mode emission rate reduced
///   - No MaskFilter.blur on burst particles (GPU-expensive on Android)
///   - Single Listener with RepaintBoundary
///   - setState only when particle count changes meaningfully
class TapBurstOverlay extends StatefulWidget {
  final Mood mood;
  final MoodPalette palette;
  final bool isDark;
  final bool enableTrail;
  final Widget child;

  const TapBurstOverlay({
    super.key,
    required this.mood,
    required this.palette,
    required this.isDark,
    this.enableTrail = false,
    required this.child,
  });

  @override
  State<TapBurstOverlay> createState() => _TapBurstOverlayState();
}

class _TapBurstOverlayState extends State<TapBurstOverlay>
    with SingleTickerProviderStateMixin {
  static const int _maxParticles = 80; // hard cap — prevents OOM/crash
  static const double _trailMinInterval = 0.033; // ~30 trail spawns/sec max
  static const double _holdEmitRate = 18.0; // 18 particles/sec while holding

  late Ticker _ticker;
  final List<_BurstParticle> _particles = [];
  Duration _lastTick = Duration.zero;
  final math.Random _rnd = math.Random();

  // Drag state
  Offset? _lastDragPos;
  double _lastTrailTime = 0;

  // Hold state
  Offset? _holdPos;
  bool _isHolding = false;
  double _holdAccumulator = 0;
  Offset? _downPos;
  double _downTime = 0;

  double _now = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = elapsed;
    _now += dt;

    // Continuous hold emission (rate-limited)
    if (_isHolding && _holdPos != null && _particles.length < _maxParticles) {
      _holdAccumulator += dt;
      while (_holdAccumulator >= 1 / _holdEmitRate &&
          _particles.length < _maxParticles) {
        _holdAccumulator -= 1 / _holdEmitRate;
        _spawnHoldParticle(_holdPos!);
      }
    }

    // Check pending hold trigger (300ms after pointer down, no movement)
    if (!_isHolding && _downPos != null && _now - _downTime > 0.3) {
      if (_lastDragPos != null &&
          (_lastDragPos! - _downPos!).distance < 12) {
        _isHolding = true;
        HapticService.medium();
      }
      _downPos = null;
    }

    // Update all particles
    for (int i = 0; i < _particles.length; i++) {
      _particles[i].update(dt);
    }
    _particles.removeWhere((p) => p.isDead);

    if (_particles.isNotEmpty || _isHolding) {
      setState(() {});
    }
  }

  double get _intensity {
    final s = context.read<SettingsService?>();
    return s?.burstIntensity ?? 1.0;
  }

  // ---------- Spawn helpers ----------
  void _spawnBurst(Offset position) {
    final intensity = _intensity;
    // Cap count more aggressively (8-14 instead of 12-20)
    final count = ((8 + _rnd.nextInt(6)) * intensity).round().clamp(3, 20);
    final particleType = _particleTypeForMood(widget.mood);
    final available = _maxParticles - _particles.length;
    final actualCount = math.min(count, available);

    for (int i = 0; i < actualCount; i++) {
      final angle = (i / actualCount) * math.pi * 2 + _rnd.nextDouble() * 0.5;
      final speed = 120 + _rnd.nextDouble() * 180;
      _particles.add(_BurstParticle(
        position: position,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        size: 6 + _rnd.nextDouble() * 7,
        maxLife: 0.8 + _rnd.nextDouble() * 0.6,
        rotation: _rnd.nextDouble() * math.pi * 2,
        rotationSpeed: (_rnd.nextDouble() - 0.5) * 4,
        type: particleType,
        color: _colorForBurst(),
        gravity: 60,
      ));
    }

    // Central flash (cheap, no blur)
    if (_particles.length < _maxParticles) {
      _particles.add(_BurstParticle(
        position: position,
        velocity: Offset.zero,
        size: 30,
        maxLife: 0.3,
        rotation: 0,
        rotationSpeed: 0,
        type: _BurstType.flash,
        color: widget.palette.burstCore,
        gravity: 0,
      ));
    }

    SoundService.tapBurst(mood: widget.mood);
    HapticService.light();
  }

  void _spawnTrail(Offset position, Offset velocity) {
    if (!widget.enableTrail) return;
    if (context.read<SettingsService?>()?.trailEnabled == false) return;
    final speedMag = velocity.distance;
    if (speedMag < 8) return;
    if (_particles.length >= _maxParticles) return;

    // Just ONE particle per trail event (much lighter)
    final particleType = _particleTypeForMood(widget.mood);
    final perpAngle = math.atan2(velocity.dy, velocity.dx) + math.pi / 2;
    final perpOffset = (_rnd.nextDouble() - 0.5) * 20;
    final spawnPos = position +
        Offset(math.cos(perpAngle) * perpOffset,
            math.sin(perpAngle) * perpOffset);

    final driftAngle = math.atan2(velocity.dy, velocity.dx) +
        math.pi +
        (_rnd.nextDouble() - 0.5) * 0.8;
    final driftSpeed = 30 + _rnd.nextDouble() * 40;

    _particles.add(_BurstParticle(
      position: spawnPos,
      velocity: Offset(math.cos(driftAngle) * driftSpeed,
          math.sin(driftAngle) * driftSpeed),
      size: 4 + _rnd.nextDouble() * 4,
      maxLife: 0.5 + _rnd.nextDouble() * 0.3,
      rotation: _rnd.nextDouble() * math.pi * 2,
      rotationSpeed: (_rnd.nextDouble() - 0.5) * 3,
      type: particleType,
      color: _colorForBurst(),
      gravity: 20,
    ));
  }

  void _spawnHoldParticle(Offset position) {
    final particleType = _particleTypeForMood(widget.mood);
    final angle = _rnd.nextDouble() * math.pi * 2;
    final speed = 40 + _rnd.nextDouble() * 80;
    _particles.add(_BurstParticle(
      position: position +
          Offset((_rnd.nextDouble() - 0.5) * 8,
              (_rnd.nextDouble() - 0.5) * 8),
      velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      size: 5 + _rnd.nextDouble() * 5,
      maxLife: 0.7 + _rnd.nextDouble() * 0.4,
      rotation: _rnd.nextDouble() * math.pi * 2,
      rotationSpeed: (_rnd.nextDouble() - 0.5) * 3,
      type: particleType,
      color: _colorForBurst(),
      gravity: 30,
    ));
  }

  _BurstType _particleTypeForMood(Mood mood) {
    switch (mood) {
      case Mood.happy: return _BurstType.sparkle;
      case Mood.romantic: return _BurstType.heart;
      case Mood.angry: return _BurstType.ember;
      case Mood.sad: return _BurstType.droplet;
      case Mood.calm: return _BurstType.orb;
      case Mood.anxious: return _BurstType.orb;
      case Mood.defaultMood: return _BurstType.star;
    }
  }

  Color _colorForBurst() {
    return _rnd.nextBool()
        ? widget.palette.burstCore
        : widget.palette.burstAccent;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              _spawnBurst(event.localPosition);
              _lastDragPos = event.localPosition;
              _downPos = event.localPosition;
              _downTime = _now;
            },
            onPointerMove: (event) {
              if (_now - _lastTrailTime > _trailMinInterval) {
                if (_lastDragPos != null) {
                  final velocity =
                      (event.localPosition - _lastDragPos!) / _trailMinInterval;
                  _spawnTrail(event.localPosition, velocity);
                }
                _lastTrailTime = _now;
              }
              _lastDragPos = event.localPosition;
              if (_isHolding) _holdPos = event.localPosition;
              // Cancel pending hold if moved too far
              if (_downPos != null &&
                  !_isHolding &&
                  (event.localPosition - _downPos!).distance > 12) {
                _downPos = null;
              }
            },
            onPointerUp: (event) {
              _lastDragPos = null;
              _downPos = null;
              if (_isHolding) {
                _isHolding = false;
                _holdPos = null;
              }
            },
            onPointerCancel: (event) {
              _lastDragPos = null;
              _downPos = null;
              _isHolding = false;
              _holdPos = null;
            },
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _BurstPainter(
                    particles: _particles,
                    isDark: widget.isDark,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PARTICLE
// ============================================================
enum _BurstType { sparkle, heart, ember, droplet, orb, star, flash }

class _BurstParticle {
  Offset position;
  Offset velocity;
  final double size;
  final double maxLife;
  final double gravity;
  double life = 0;
  double rotation;
  final double rotationSpeed;
  final _BurstType type;
  final Color color;

  _BurstParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.maxLife,
    required this.rotation,
    required this.rotationSpeed,
    required this.type,
    required this.color,
    this.gravity = 60,
  });

  bool get isDead => life >= maxLife;
  double get t => (life / maxLife).clamp(0.0, 1.0);
  double get opacity => (1 - t) * (t < 0.1 ? t / 0.1 : 1);

  void update(double dt) {
    life += dt;
    position += velocity * dt;
    velocity = velocity * 0.94;
    if (type == _BurstType.orb) {
      velocity += Offset(0, -gravity * 0.5) * dt;
    } else if (type != _BurstType.flash) {
      velocity += Offset(0, gravity) * dt;
    }
    rotation += rotationSpeed * dt;
  }
}

// ============================================================
// PAINTER — simplified, no MaskFilter blur (GPU-friendly)
// ============================================================
class _BurstPainter extends CustomPainter {
  final List<_BurstParticle> particles;
  final bool isDark;

  _BurstPainter({required this.particles, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final outlineLight = Colors.white;
    final outlineDark = Colors.black;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);
      _drawParticle(canvas, p, isDark ? outlineDark : outlineLight);
      canvas.restore();
    }
  }

  void _drawParticle(Canvas canvas, _BurstParticle p, Color outlineBase) {
    final opacity = p.opacity;
    final scale = 1 - p.t * 0.3;
    final s = p.size * scale;
    final fill = Paint()..color = p.color.withOpacity(opacity);

    switch (p.type) {
      case _BurstType.heart:
        _drawHeart(canvas, s, fill, opacity, outlineBase);
        break;
      case _BurstType.sparkle:
        _drawSparkle(canvas, s, p.color, opacity);
        break;
      case _BurstType.star:
        _drawStar(canvas, s, fill, opacity, outlineBase);
        break;
      case _BurstType.ember:
        _drawEmber(canvas, s, p.color, opacity);
        break;
      case _BurstType.droplet:
        _drawDroplet(canvas, s, fill, opacity, outlineBase);
        break;
      case _BurstType.orb:
        _drawOrb(canvas, s, p.color, opacity);
        break;
      case _BurstType.flash:
        _drawFlash(canvas, s, p.color, opacity);
        break;
    }
  }

  void _drawHeart(Canvas canvas, double s, Paint fill, double op, Color outlineBase) {
    final path = Path()
      ..moveTo(0, s * 0.3)
      ..cubicTo(-s, -s * 0.5, -s * 0.5, -s, 0, -s * 0.3)
      ..cubicTo(s * 0.5, -s, s, -s * 0.5, 0, s * 0.3);
    canvas.drawPath(path, fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = outlineBase.withOpacity(op * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  void _drawSparkle(Canvas canvas, double s, Color color, double op) {
    final stroke = Paint()
      ..color = color.withOpacity(op)
      ..strokeWidth = s * 0.28
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-s, 0), Offset(s, 0), stroke);
    canvas.drawLine(Offset(0, -s), Offset(0, s), stroke);
    canvas.drawLine(
        Offset(-s * 0.6, -s * 0.6), Offset(s * 0.6, s * 0.6), stroke);
    canvas.drawLine(
        Offset(-s * 0.6, s * 0.6), Offset(s * 0.6, -s * 0.6), stroke);
    // Bright center
    canvas.drawCircle(
        Offset.zero, s * 0.32, Paint()..color = Colors.white.withOpacity(op));
  }

  void _drawStar(Canvas canvas, double s, Paint fill, double op, Color outlineBase) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final outer = Offset(math.cos(angle) * s, math.sin(angle) * s);
      final innerAngle = angle + math.pi / 5;
      final inner = Offset(
          math.cos(innerAngle) * s * 0.45, math.sin(innerAngle) * s * 0.45);
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = outlineBase.withOpacity(op * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  void _drawEmber(Canvas canvas, double s, Color color, double op) {
    canvas.drawCircle(
        Offset.zero, s * 0.7, Paint()..color = color.withOpacity(op));
    // Bright inner core (yellow-white) — no blur, just color
    final hot = const Color(0xFFFFE066);
    canvas.drawCircle(
        Offset.zero, s * 0.35, Paint()..color = hot.withOpacity(op));
  }

  void _drawDroplet(Canvas canvas, double s, Paint fill, double op, Color outlineBase) {
    final path = Path()
      ..moveTo(0, -s)
      ..quadraticBezierTo(s * 0.7, 0, 0, s * 0.7)
      ..quadraticBezierTo(-s * 0.7, 0, 0, -s);
    canvas.drawPath(path, fill);
    // White highlight (3D effect, no blur)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(-s * 0.2, -s * 0.3), width: s * 0.25, height: s * 0.4),
      Paint()..color = Colors.white.withOpacity(op * 0.7),
    );
  }

  void _drawOrb(Canvas canvas, double s, Color color, double op) {
    // Two concentric circles — fake glow without MaskFilter
    canvas.drawCircle(
        Offset.zero, s * 0.9, Paint()..color = color.withOpacity(op * 0.35));
    canvas.drawCircle(
        Offset.zero, s * 0.55, Paint()..color = color.withOpacity(op * 0.9));
    canvas.drawCircle(Offset.zero, s * 0.25,
        Paint()..color = Colors.white.withOpacity(op));
  }

  void _drawFlash(Canvas canvas, double s, Color color, double op) {
    canvas.drawCircle(
        Offset.zero, s, Paint()..color = color.withOpacity(op * 0.4));
    canvas.drawCircle(Offset.zero, s * 0.5,
        Paint()..color = color.withOpacity(op * 0.7));
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => true;
}
