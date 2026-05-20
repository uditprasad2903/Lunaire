import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SettingsService - manages user preferences for sound, haptic, etc.
/// Persisted via SharedPreferences.
class SettingsService extends ChangeNotifier {
  static const String _kSound = 'pref_sound_enabled';
  static const String _kHaptic = 'pref_haptic_enabled';
  static const String _kBurstIntensity = 'pref_burst_intensity'; // 0.5, 1.0, 1.5
  static const String _kAmbientAnim = 'pref_ambient_animations';
  static const String _kTrailEnabled = 'pref_trail_enabled';
  static const String _kHoldEnabled = 'pref_hold_enabled';

  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  double _burstIntensity = 0.3;  // Fixed at 30% for performance
  bool _ambientAnimations = true;
  bool _trailEnabled = true;
  bool _holdEnabled = true;
  bool _loaded = false;

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  double get burstIntensity => 0.3;  // Hardcoded — slider removed
  bool get ambientAnimations => _ambientAnimations;
  bool get trailEnabled => _trailEnabled;
  bool get holdEnabled => _holdEnabled;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_kSound) ?? true;
    _hapticEnabled = prefs.getBool(_kHaptic) ?? true;
    _burstIntensity = prefs.getDouble(_kBurstIntensity) ?? 1.0;
    _ambientAnimations = prefs.getBool(_kAmbientAnim) ?? true;
    _trailEnabled = prefs.getBool(_kTrailEnabled) ?? true;
    _holdEnabled = prefs.getBool(_kHoldEnabled) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSound(bool v) async {
    _soundEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSound, v);
    notifyListeners();
  }

  Future<void> setHaptic(bool v) async {
    _hapticEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHaptic, v);
    notifyListeners();
  }

  Future<void> setBurstIntensity(double v) async {
    _burstIntensity = v.clamp(0.3, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBurstIntensity, _burstIntensity);
    notifyListeners();
  }

  Future<void> setAmbientAnimations(bool v) async {
    _ambientAnimations = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAmbientAnim, v);
    notifyListeners();
  }

  Future<void> setTrailEnabled(bool v) async {
    _trailEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTrailEnabled, v);
    notifyListeners();
  }

  Future<void> setHoldEnabled(bool v) async {
    _holdEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHoldEnabled, v);
    notifyListeners();
  }
}
