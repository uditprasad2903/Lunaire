import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../services/auth_service.dart';
import '../widgets/animated_moon.dart';
import '../widgets/sky_background.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final ok = _isSignUp
        ? await auth.signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            displayName: _nameCtrl.text.trim().isEmpty
                ? _emailCtrl.text.split('@').first
                : _nameCtrl.text.trim())
        : await auth.signIn(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showSnack('Authentication failed');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final p = theme.palette;

    return Scaffold(
      body: SkyBackground(
        palette: p,
        isDark: theme.isDark,
        mood: theme.currentMood,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                AnimatedMoon(mood: theme.currentMood, palette: p, size: 120),
                const SizedBox(height: 16),
                Text(
                  'Lunaire',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40,
                    color: p.textPrimary,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSignUp ? 'Create your moonlit space' : 'Welcome back, moonchild',
                  style: GoogleFonts.poppins(color: p.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 40),
                if (_isSignUp)
                  _buildField(_nameCtrl, 'Your name', Icons.person_outline, p),
                if (_isSignUp) const SizedBox(height: 16),
                _buildField(_emailCtrl, 'Email', Icons.email_outlined, p),
                const SizedBox(height: 16),
                _buildField(_passCtrl, 'Password', Icons.lock_outline, p,
                    obscure: true),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : "New to Lunaire? Create an account",
                    style: TextStyle(color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      MoodPalette p,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: p.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: p.textSecondary),
      ),
    );
  }
}
