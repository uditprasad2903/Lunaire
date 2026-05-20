import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../widgets/sky_background.dart';
import '../services/settings_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsService>();
    final p = theme.palette;

    return Scaffold(
      body: SkyBackground(
        palette: p,
        isDark: theme.isDark,
        mood: theme.currentMood,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, p),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _section('Feedback', p),
                    _switchTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Sound effects',
                      subtitle: 'Soft chime on taps, AI replies, etc.',
                      value: settings.soundEnabled,
                      onChanged: (v) async {
                        await settings.setSound(v);
                        if (v) SoundService.tapBurst();
                      },
                      p: p,
                    ),
                    _switchTile(
                      icon: Icons.vibration,
                      title: 'Haptic feedback',
                      subtitle: 'Vibration on taps and interactions',
                      value: settings.hapticEnabled,
                      onChanged: (v) async {
                        await settings.setHaptic(v);
                        if (v) HapticService.medium();
                      },
                      p: p,
                    ),
                    const SizedBox(height: 24),
                    _section('Animations', p),
                    _switchTile(
                      icon: Icons.auto_awesome,
                      title: 'Ambient animations',
                      subtitle: 'Twinkling stars, shooting stars, particles',
                      value: settings.ambientAnimations,
                      onChanged: (v) => settings.setAmbientAnimations(v),
                      p: p,
                    ),
                    _switchTile(
                      icon: Icons.swipe_outlined,
                      title: 'Chat swipe trail',
                      subtitle: 'In AI chat: particles follow your finger when you drag',
                      value: settings.trailEnabled,
                      onChanged: (v) => settings.setTrailEnabled(v),
                      p: p,
                    ),
                    const SizedBox(height: 24),
                    _section('Try it', p),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Tap anywhere outside this card to feel a burst 🌙',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: p.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            children: [
                              _testChip('Test sound', Icons.volume_up, () => SoundService.chime(), p),
                              _testChip('Test haptic', Icons.vibration,
                                  () => HapticService.heavy(), p),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, MoodPalette p) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: p.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required MoodPalette p,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: p.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: p.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: p.primary,
          ),
        ],
      ),
    );
  }

  Widget _sliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required MoodPalette p,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: p.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary)),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: p.textSecondary)),
                  ],
                ),
              ),
              Text('${(value * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                      color: p.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 17,
            activeColor: p.primary,
            inactiveColor: p.primary.withOpacity(0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _testChip(String label, IconData icon, VoidCallback onTap, MoodPalette p) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: p.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MoodPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Settings',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 26, color: p.textPrimary, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
