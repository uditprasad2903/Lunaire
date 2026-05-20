import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService - currently uses local SharedPreferences as a stub
/// so the app runs out of the box. After running `flutterfire configure`,
/// uncomment the Firebase code paths to enable real authentication.
class AuthService extends ChangeNotifier {
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _userId;
  String? _email;
  String? _displayName;
  String? _bio;
  String? _avatarEmoji;
  DateTime? _memberSince;
  String? _favoriteAffirmation;

  String? get userId => _userId;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get bio => _bio;
  String? get avatarEmoji => _avatarEmoji ?? '🌙';
  DateTime? get memberSince => _memberSince;
  String? get favoriteAffirmation => _favoriteAffirmation;
  bool get isLoggedIn => _userId != null;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    _displayName = prefs.getString('displayName');
    _bio = prefs.getString('bio');
    _avatarEmoji = prefs.getString('avatarEmoji');
    final memberStr = prefs.getString('memberSince');
    _memberSince = memberStr != null ? DateTime.tryParse(memberStr) : null;
    _favoriteAffirmation = prefs.getString('favoriteAffirmation');
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // STUB:
      _userId = DateTime.now().millisecondsSinceEpoch.toString();
      _email = email;
      _displayName = displayName;
      _memberSince = DateTime.now();
      _avatarEmoji = '🌙';
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SignUp error: $e');
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      // STUB:
      _userId = DateTime.now().millisecondsSinceEpoch.toString();
      _email = email;
      _displayName = email.split('@').first;
      _memberSince ??= DateTime.now();
      _avatarEmoji ??= '🌙';
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SignIn error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _userId = null;
    _email = null;
    _displayName = null;
    _bio = null;
    _avatarEmoji = null;
    _memberSince = null;
    _favoriteAffirmation = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  /// Update editable profile fields
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarEmoji,
    String? favoriteAffirmation,
  }) async {
    if (displayName != null) _displayName = displayName;
    if (bio != null) _bio = bio;
    if (avatarEmoji != null) _avatarEmoji = avatarEmoji;
    if (favoriteAffirmation != null) _favoriteAffirmation = favoriteAffirmation;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_userId != null) await prefs.setString('userId', _userId!);
    if (_email != null) await prefs.setString('email', _email!);
    if (_displayName != null) await prefs.setString('displayName', _displayName!);
    if (_bio != null) await prefs.setString('bio', _bio!);
    if (_avatarEmoji != null) await prefs.setString('avatarEmoji', _avatarEmoji!);
    if (_memberSince != null) {
      await prefs.setString('memberSince', _memberSince!.toIso8601String());
    }
    if (_favoriteAffirmation != null) {
      await prefs.setString('favoriteAffirmation', _favoriteAffirmation!);
    }
  }
}
