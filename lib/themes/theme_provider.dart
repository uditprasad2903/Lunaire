import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mood_themes.dart';

class ThemeProvider extends ChangeNotifier {
  Mood _currentMood = Mood.defaultMood;
  Brightness _brightness = Brightness.dark;

  Mood get currentMood => _currentMood;
  Brightness get brightness => _brightness;
  bool get isDark => _brightness == Brightness.dark;

  MoodPalette get palette => MoodThemes.palette(_currentMood, _brightness);
  ThemeData get currentTheme => MoodThemes.buildTheme(_currentMood, _brightness);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final moodIndex = prefs.getInt('mood') ?? Mood.defaultMood.index;
    final isDark = prefs.getBool('isDark') ?? true;
    _currentMood = Mood.values[moodIndex];
    _brightness = isDark ? Brightness.dark : Brightness.light;
    notifyListeners();
  }

  Future<void> setMood(Mood mood) async {
    _currentMood = mood;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mood', mood.index);
    notifyListeners();
  }

  Future<void> toggleBrightness() async {
    _brightness = isDark ? Brightness.light : Brightness.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    notifyListeners();
  }
}
