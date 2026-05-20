import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/theme_provider.dart';
import '../widgets/animated_moon.dart';
import '../widgets/sky_background.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthService>();
    await auth.loadFromPrefs();
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      body: SkyBackground(
        palette: theme.palette,
        isDark: theme.isDark,
        mood: theme.currentMood,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedMoon(
                mood: theme.currentMood,
                palette: theme.palette,
                size: 180,
              ),
              const SizedBox(height: 32),
              Text(
                'Lunaire',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: theme.palette.textPrimary,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'where the moon reflects your soul',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: theme.palette.textSecondary,
                  letterSpacing: 2,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
