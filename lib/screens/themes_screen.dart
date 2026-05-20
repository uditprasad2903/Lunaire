import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../widgets/animated_moon.dart';
import '../widgets/sky_background.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

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
          child: Column(
            children: [
              _buildAppBar(context, p, theme),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: Mood.values.length,
                  itemBuilder: (context, i) {
                    final mood = Mood.values[i];
                    final preview = MoodThemes.palette(mood, theme.brightness);
                    final isSelected = mood == theme.currentMood;
                    return GestureDetector(
                      onTap: () => theme.setMood(mood),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: preview.skyGradient,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? preview.primary : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: preview.primary.withOpacity(0.4),
                                    blurRadius: 16,
                                  )
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: AnimatedMoon(
                                mood: mood,
                                palette: preview,
                                size: 90,
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(height: 4),
                                  Text(
                                    mood.label,
                                    style: GoogleFonts.poppins(
                                      color: preview.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: preview.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MoodPalette p, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Mood Themes',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 26, color: p.textPrimary, letterSpacing: 1.5)),
          const Spacer(),
          IconButton(
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode,
                color: p.textPrimary),
            onPressed: theme.toggleBrightness,
          ),
        ],
      ),
    );
  }
}
