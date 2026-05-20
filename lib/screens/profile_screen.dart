import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../widgets/sky_background.dart';
import '../widgets/animated_moon.dart';
import '../services/auth_service.dart';
import '../services/diary_service.dart';
import '../services/haptic_service.dart';
import '../models/diary_entry.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<DiaryEntry> _entries;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _entries = DiaryService.getAllEntries();
    });
  }

  int _computeCurrentStreak() {
    if (_entries.isEmpty) return 0;
    final dates = _entries
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList();
    int streak = 0;
    var current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);
    if (!dates.contains(current)) {
      current = current.subtract(const Duration(days: 1));
      if (!dates.contains(current)) return 0;
    }
    while (dates.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Mood? _computeTopMood() {
    if (_entries.isEmpty) return null;
    final counts = <Mood, int>{};
    for (final e in _entries) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AuthService>();
    final p = theme.palette;
    final streak = _computeCurrentStreak();
    final topMood = _computeTopMood();
    final longestStreak = DiaryService.getLongestStreak();
    final words = DiaryService.getTotalWordCount();
    final thisWeek = DiaryService.getThisWeekCount();

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(p, auth, theme),
                      const SizedBox(height: 24),
                      _buildStatsGrid(p, _entries.length, streak, longestStreak,
                          words, thisWeek, topMood),
                      const SizedBox(height: 16),
                      if (auth.favoriteAffirmation != null &&
                          auth.favoriteAffirmation!.trim().isNotEmpty)
                        _buildAffirmationCard(auth.favoriteAffirmation!, p),
                      const SizedBox(height: 16),
                      _buildAchievements(p, _entries.length, streak,
                          longestStreak, words, thisWeek),
                      const SizedBox(height: 16),
                      _buildActionList(p, auth),
                      const SizedBox(height: 16),
                      _buildAbout(p),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Header (avatar + name + bio + member since)
  // ============================================================
  Widget _buildHeader(MoodPalette p, AuthService auth, ThemeProvider theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedMoon(
                mood: theme.currentMood, palette: p, size: 110, animate: false),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showAvatarPicker(auth),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.background, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          auth.avatarEmoji ?? '🌙',
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showEditProfileSheet(auth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                auth.displayName ?? 'Moonchild',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 28, color: p.textPrimary),
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, size: 14, color: p.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          auth.email ?? '—',
          style: GoogleFonts.poppins(fontSize: 12, color: p.textSecondary),
        ),
        if (auth.bio != null && auth.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '"${auth.bio}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: p.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
        if (auth.memberSince != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🌙 Moonchild since ${DateFormat('MMM y').format(auth.memberSince!)}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: p.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // Stats grid (6 tiles)
  // ============================================================
  Widget _buildStatsGrid(MoodPalette p, int total, int streak, int longestStreak,
      int words, int thisWeek, Mood? topMood) {
    final tiles = [
      _StatData('$total', 'Total entries', Icons.menu_book),
      _StatData('$streak', 'Current streak', Icons.local_fire_department),
      _StatData('$longestStreak', 'Longest streak', Icons.emoji_events),
      _StatData('$thisWeek', 'This week', Icons.calendar_today),
      _StatData('${_fmtWords(words)}', 'Words written', Icons.edit_note),
      _StatData(topMood != null ? topMood.emoji : '—', 'Top mood',
          Icons.favorite),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) {
        final t = tiles[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(t.icon, color: p.primary, size: 18),
              const SizedBox(height: 6),
              Text(t.value,
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary)),
              const SizedBox(height: 2),
              Text(t.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 9.5, color: p.textSecondary)),
            ],
          ),
        );
      },
    );
  }

  String _fmtWords(int w) {
    if (w >= 1000) return '${(w / 1000).toStringAsFixed(1)}k';
    return '$w';
  }

  // ============================================================
  // Affirmation card
  // ============================================================
  Widget _buildAffirmationCard(String text, MoodPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.primary.withOpacity(0.2), p.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote, color: p.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: p.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text('— your affirmation',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: p.textSecondary, letterSpacing: 1)),
        ],
      ),
    );
  }

  // ============================================================
  // Achievements
  // ============================================================
  Widget _buildAchievements(MoodPalette p, int total, int streak,
      int longestStreak, int words, int thisWeek) {
    final achievements = [
      _Achievement(
        icon: '✍️',
        label: 'First entry',
        desc: 'Wrote your first entry',
        unlocked: total >= 1,
      ),
      _Achievement(
        icon: '📅',
        label: '3 day streak',
        desc: 'Wrote 3 days in a row',
        unlocked: longestStreak >= 3,
      ),
      _Achievement(
        icon: '🔥',
        label: '7 day streak',
        desc: 'A full week of writing',
        unlocked: longestStreak >= 7,
      ),
      _Achievement(
        icon: '🌙',
        label: '30 day streak',
        desc: 'Monthly devotee',
        unlocked: longestStreak >= 30,
      ),
      _Achievement(
        icon: '📚',
        label: '10 entries',
        desc: 'Diary regular',
        unlocked: total >= 10,
      ),
      _Achievement(
        icon: '✨',
        label: '50 entries',
        desc: 'Storyteller',
        unlocked: total >= 50,
      ),
      _Achievement(
        icon: '💫',
        label: '100 entries',
        desc: 'Lifelong journalist',
        unlocked: total >= 100,
      ),
      _Achievement(
        icon: '📝',
        label: '1000 words',
        desc: 'Wrote 1000+ words',
        unlocked: words >= 1000,
      ),
    ];
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: p.primary),
              const SizedBox(width: 8),
              Text('Achievements',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 20, color: p.textPrimary)),
              const Spacer(),
              Text('$unlockedCount / ${achievements.length}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: p.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (_, i) {
              final a = achievements[i];
              return Tooltip(
                message: '${a.label}\n${a.desc}',
                child: Opacity(
                  opacity: a.unlocked ? 1.0 : 0.3,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: a.unlocked
                          ? p.primary.withOpacity(0.15)
                          : p.background.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: a.unlocked
                            ? p.primary.withOpacity(0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(a.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 8.5, color: p.textSecondary)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Action list (settings, export, clear, sign out)
  // ============================================================
  Widget _buildActionList(MoodPalette p, AuthService auth) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.format_quote,
            title: 'My affirmation',
            subtitle: auth.favoriteAffirmation == null ||
                    auth.favoriteAffirmation!.trim().isEmpty
                ? 'Add a quote you live by'
                : auth.favoriteAffirmation!,
            onTap: () => _showAffirmationDialog(auth),
            p: p,
          ),
          _divider(p),
          _actionTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Sound, haptic, animations',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            p: p,
          ),
          _divider(p),
          _actionTile(
            icon: Icons.download_outlined,
            title: 'Export entries',
            subtitle: 'Save all entries as a text file',
            onTap: _exportEntries,
            p: p,
          ),
          _divider(p),
          _actionTile(
            icon: Icons.delete_sweep_outlined,
            title: 'Clear all entries',
            subtitle: 'Delete all diary entries forever',
            danger: true,
            onTap: _confirmClearAll,
            p: p,
          ),
          _divider(p),
          _actionTile(
            icon: Icons.logout,
            title: 'Sign out',
            subtitle: 'Aap wapas aaoge, hum yahin hain 🌙',
            danger: true,
            onTap: () => _confirmSignOut(auth),
            p: p,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required MoodPalette p,
    bool danger = false,
  }) {
    final color = danger ? Colors.redAccent : p.primary;
    return InkWell(
      onTap: () {
        HapticService.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: p.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _divider(MoodPalette p) {
    return Divider(
        color: p.textSecondary.withOpacity(0.08),
        height: 1,
        indent: 16,
        endIndent: 16);
  }

  // ============================================================
  // About card
  // ============================================================
  Widget _buildAbout(MoodPalette p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('Lunaire',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 24, color: p.textPrimary, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('where the moon reflects your soul',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: p.textSecondary)),
          const SizedBox(height: 12),
          Text('Version 1.0.0',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: p.textSecondary)),
          const SizedBox(height: 8),
          Text('Made with 🌙 + ❤️',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: p.textSecondary)),
        ],
      ),
    );
  }

  // ============================================================
  // App bar
  // ============================================================
  Widget _buildAppBar(BuildContext context, MoodPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Profile',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 26, color: p.textPrimary, letterSpacing: 1)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: p.textSecondary),
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Edit profile bottom sheet
  // ============================================================
  void _showEditProfileSheet(AuthService auth) {
    final theme = context.read<ThemeProvider>();
    final p = theme.palette;
    final nameCtrl = TextEditingController(text: auth.displayName ?? '');
    final bioCtrl = TextEditingController(text: auth.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit profile',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 26, color: p.textPrimary)),
              const SizedBox(height: 20),
              _profileField('Name', nameCtrl, p, hint: 'Apna naam'),
              const SizedBox(height: 16),
              _profileField('Bio', bioCtrl, p,
                  hint: 'Ek line apne baare mein', maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: p.primary),
                  onPressed: () async {
                    await auth.updateProfile(
                      displayName: nameCtrl.text.trim(),
                      bio: bioCtrl.text.trim(),
                    );
                    HapticService.medium();
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileField(String label, TextEditingController c, MoodPalette p,
      {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          maxLines: maxLines,
          style: TextStyle(color: p.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: p.textSecondary, fontSize: 13),
            filled: true,
            fillColor: p.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Avatar picker
  // ============================================================
  void _showAvatarPicker(AuthService auth) {
    final theme = context.read<ThemeProvider>();
    final p = theme.palette;
    final emojis = [
      '🌙', '✨', '🌟', '💫', '🌸', '🌺', '🌻', '🌹',
      '🦋', '🐱', '🐶', '🦊', '🐰', '🦉', '🦄',
      '☕', '📚', '🎨', '🎵', '✍️', '💗', '🤍', '💜',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: p.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Choose your avatar',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 22, color: p.textPrimary)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: emojis.map((e) {
                final selected = auth.avatarEmoji == e;
                return GestureDetector(
                  onTap: () async {
                    HapticService.select();
                    await auth.updateProfile(avatarEmoji: e);
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected ? p.primary.withOpacity(0.2) : p.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? p.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Affirmation dialog
  // ============================================================
  void _showAffirmationDialog(AuthService auth) {
    final theme = context.read<ThemeProvider>();
    final p = theme.palette;
    final c = TextEditingController(text: auth.favoriteAffirmation ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Your affirmation',
            style: TextStyle(color: p.textPrimary, fontSize: 18)),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: p.textPrimary),
          decoration: InputDecoration(
            hintText: '"I am enough, just as I am."',
            hintStyle: TextStyle(color: p.textSecondary, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: p.primary),
            onPressed: () async {
              await auth.updateProfile(
                  favoriteAffirmation: c.text.trim());
              HapticService.medium();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Export entries (save to local file + show snackbar with path)
  // ============================================================
  Future<void> _exportEntries() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No entries to export'),
      ));
      return;
    }
    final theme = context.read<ThemeProvider>();
    final p = theme.palette;

    try {
      final text = DiaryService.exportAsText();
      final dir = await getApplicationDocumentsDirectory();
      final fname =
          'lunaire_export_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${dir.path}/$fname');
      await file.writeAsString(text);

      // Also copy to clipboard for convenience
      await Clipboard.setData(ClipboardData(text: text));

      HapticService.heavy();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: p.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: p.primary),
                const SizedBox(width: 8),
                Text('Exported!',
                    style: TextStyle(color: p.textPrimary, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_entries.length} entries saved to:',
                  style: TextStyle(color: p.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    file.path,
                    style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 11,
                        fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Full text bhi clipboard mein copy ho gaya ✨',
                    style: TextStyle(color: p.textSecondary, fontSize: 11)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK', style: TextStyle(color: p.primary)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // ============================================================
  // Clear all entries
  // ============================================================
  Future<void> _confirmClearAll() async {
    final theme = context.read<ThemeProvider>();
    final p = theme.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Clear all entries?',
                style: TextStyle(color: p.textPrimary, fontSize: 18)),
          ],
        ),
        content: Text(
          'Yeh permanent hai. Sab ${_entries.length} entries hamesha ke liye delete ho jaayengi.\n\nExport karna chahoge pehle?',
          style: TextStyle(color: p.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete all', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DiaryService.clearAll();
      HapticService.heavy();
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🗑 All entries cleared'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ============================================================
  // Sign out confirmation
  // ============================================================
  Future<void> _confirmSignOut(AuthService auth) async {
    final theme = context.read<ThemeProvider>();
    final p = theme.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out?',
            style: TextStyle(color: p.textPrimary, fontSize: 18)),
        content: Text(
          'Aap wapas sign in kar sakte ho. Aapki entries safe rahengi.',
          style: TextStyle(color: p.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: p.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }
}

class _StatData {
  final String value;
  final String label;
  final IconData icon;
  _StatData(this.value, this.label, this.icon);
}

class _Achievement {
  final String icon;
  final String label;
  final String desc;
  final bool unlocked;
  _Achievement({
    required this.icon,
    required this.label,
    required this.desc,
    required this.unlocked,
  });
}
