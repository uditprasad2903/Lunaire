import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../widgets/animated_moon.dart';
import '../widgets/sky_background.dart';
import 'write_entry_screen.dart';
import 'themes_screen.dart';
import 'ai_chat_screen.dart';
import 'mood_tracker_screen.dart';
import 'profile_screen.dart';
import 'entries_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final p = theme.palette;
    final now = DateTime.now();

    return Scaffold(
      body: SkyBackground(
        palette: p,
        isDark: theme.isDark,
        mood: theme.currentMood,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, p, theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      AnimatedMoon(mood: theme.currentMood, palette: p, size: 160),
                      const SizedBox(height: 24),
                      Text(
                        _greeting(now),
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 32,
                          color: p.textPrimary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(now),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: p.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current mood: ${theme.currentMood.label} ${theme.currentMood.emoji}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: p.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildQuickWriteCard(context, p),
                      const SizedBox(height: 20),
                      _buildFeatureGrid(context, p),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: p.primary,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const WriteEntryScreen())),
        icon: const Icon(Icons.edit_note, color: Colors.white),
        label: const Text('Write', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Goodnight';
  }

  Widget _buildTopBar(BuildContext context, MoodPalette p, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Text('Lunaire',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 28, color: p.textPrimary, letterSpacing: 2)),
          const Spacer(),
          IconButton(
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode,
                color: p.textPrimary),
            onPressed: theme.toggleBrightness,
          ),
          IconButton(
            icon: Icon(Icons.person_outline, color: p.textPrimary),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickWriteCard(BuildContext context, MoodPalette p) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WriteEntryScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_stories, color: p.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How are you feeling?',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Pour your heart onto the page',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: p.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: p.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, MoodPalette p) {
    final items = [
      _FeatureItem('My Entries', Icons.book_outlined, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EntriesScreen()));
      }),
      _FeatureItem('Themes', Icons.palette_outlined, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ThemesScreen()));
      }),
      _FeatureItem('AI Companion', Icons.chat_bubble_outline, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AIChatScreen()));
      }),
      _FeatureItem('Mood Tracker', Icons.show_chart, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MoodTrackerScreen()));
      }),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: items
          .map((i) => GestureDetector(
                onTap: i.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(i.icon, color: p.primary, size: 32),
                      const SizedBox(height: 8),
                      Text(i.title,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: p.textPrimary)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _FeatureItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _FeatureItem(this.title, this.icon, this.onTap);
}
