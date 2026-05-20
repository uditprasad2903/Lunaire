import 'package:flutter/material.dart';
import '../themes/mood_themes.dart';
import 'animated_moon.dart';

/// ReactiveMoon - a moon that smoothly transitions size, mood, and color
/// when the user's mood changes. Includes a "pulse" animation when mood
/// is freshly detected from text.
class ReactiveMoon extends StatefulWidget {
  final Mood mood;
  final MoodPalette palette;
  final double size;
  final bool justChanged; // triggers pulse + glow

  const ReactiveMoon({
    super.key,
    required this.mood,
    required this.palette,
    this.size = 120,
    this.justChanged = false,
  });

  @override
  State<ReactiveMoon> createState() => _ReactiveMoonState();
}

class _ReactiveMoonState extends State<ReactiveMoon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _wasJustChanged = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant ReactiveMoon old) {
    super.didUpdateWidget(old);
    if (widget.justChanged && !_wasJustChanged) {
      _wasJustChanged = true;
      _pulseController.forward(from: 0).then((_) {
        _wasJustChanged = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        // 0 -> 1 -> 0 pulse curve
        final t = _pulseController.value;
        final pulse = (t < 0.5) ? t * 2 : (1 - t) * 2;
        final extraScale = 1 + pulse * 0.15;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          width: widget.size * extraScale,
          height: widget.size * extraScale,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.7, end: 1.0).animate(anim),
                  child: child,
                ),
              );
            },
            child: AnimatedMoon(
              key: ValueKey(widget.mood),
              mood: widget.mood,
              palette: widget.palette,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}
