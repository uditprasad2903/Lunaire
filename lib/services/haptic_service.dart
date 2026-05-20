import 'package:flutter/services.dart';
import '../themes/mood_themes.dart';
import 'settings_service.dart';

/// HapticService - triggers device vibration for app interactions.
/// Uses Flutter's built-in HapticFeedback (no extra dependency needed).
class HapticService {
  static SettingsService? _settings;

  static void attachSettings(SettingsService s) {
    _settings = s;
  }

  static bool get _enabled => _settings?.hapticEnabled ?? true;

  /// Light tap (used on tap burst — quick & subtle)
  static Future<void> light() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium tap (used on long-press start, save success)
  static Future<void> medium() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap (used on important events: entry saved, mood detected)
  static Future<void> heavy() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback (used when toggling settings, swapping themes)
  static Future<void> select() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Mood-tuned haptic — different moods feel different
  static Future<void> forMood(Mood mood) async {
    if (!_enabled) return;
    switch (mood) {
      case Mood.angry:
        await HapticFeedback.heavyImpact();
        break;
      case Mood.happy:
      case Mood.romantic:
        await HapticFeedback.mediumImpact();
        break;
      case Mood.sad:
      case Mood.anxious:
        await HapticFeedback.selectionClick();
        break;
      case Mood.calm:
      case Mood.defaultMood:
        await HapticFeedback.lightImpact();
        break;
    }
  }
}
