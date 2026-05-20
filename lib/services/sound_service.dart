import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/mood_themes.dart';
import 'settings_service.dart';

/// SoundService - plays audible feedback on app interactions.
///
/// Uses TWO mechanisms for reliable audio across all phones:
///   1. Feedback.forTap(context) — uses Android/iOS native click sound,
///      which is properly audible and respects accessibility settings.
///   2. SystemSound.play() — backup, in case Feedback misses.
///
/// On Android the click sound is controlled by:
///   Settings → Sounds & Vibration → Touch sounds (must be enabled)
class SoundService {
  static SettingsService? _settings;
  // We need a BuildContext to call Feedback.forTap. The app's navigator
  // key gives us a reliable one anywhere in the app.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void attachSettings(SettingsService s) {
    _settings = s;
  }

  static bool get _enabled => _settings?.soundEnabled ?? true;

  /// Soft tap sound (used on tap burst).
  static Future<void> tapBurst({Mood? mood}) async {
    if (!_enabled) return;
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Feedback.forTap(ctx); // loud, audible on most Androids
    }
    // Backup
    await SystemSound.play(SystemSoundType.click);
  }

  /// Slightly different sound for important events (save, AI reply, etc.)
  static Future<void> chime() async {
    if (!_enabled) return;
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Feedback.forLongPress(ctx); // a tiny bit different from forTap
    }
    await SystemSound.play(SystemSoundType.alert);
  }
}
