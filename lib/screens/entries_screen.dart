import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../widgets/sky_background.dart';
import '../services/diary_service.dart';
import '../services/haptic_service.dart';
import '../models/diary_entry.dart';
import 'write_entry_screen.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  late List<DiaryEntry> _all;
  String _query = '';
  Mood? _filterMood;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _all = DiaryService.getAllEntries();
    });
  }

  List<DiaryEntry> get _filtered {
    Iterable<DiaryEntry> list = _all;
    if (_filterMood != null) {
      list = list.where((e) => e.mood == _filterMood);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where(
          (e) => e.title.toLowerCase().contains(q) || e.content.toLowerCase().contains(q));
    }
    return list.toList();
  }

  Future<void> _editEntry(DiaryEntry e) async {
    HapticService.light();
    final updated = await Navigator.push<DiaryEntry>(
      context,
      MaterialPageRoute(builder: (_) => WriteEntryScreen(existing: e)),
    );
    if (updated != null) _refresh();
  }

  Future<void> _confirmDelete(DiaryEntry e) async {
    HapticService.medium();
    final palette = context.read<ThemeProvider>().palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text('Delete entry?',
                style: TextStyle(color: palette.textPrimary, fontSize: 18)),
          ],
        ),
        content: Text(
          '"${e.title}" hamesha ke liye delete ho jaayegi. Yeh undo nahi ho sakta.',
          style: TextStyle(color: palette.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: TextStyle(color: palette.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            icon: const Icon(Icons.delete, color: Colors.white, size: 16),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DiaryService.deleteEntry(e.id);
      HapticService.heavy();
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🗑 "${e.title}" deleted'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final p = theme.palette;
    final filtered = _filtered;

    return Scaffold(
      body: SkyBackground(
        palette: p,
        isDark: theme.isDark,
        mood: theme.currentMood,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, p, _all.length),
              _buildSearchBar(p),
              if (_all.isNotEmpty) _buildMoodFilter(p),
              Expanded(
                child: _all.isEmpty
                    ? _buildEmpty(p)
                    : filtered.isEmpty
                        ? _buildNoResults(p)
                        : RefreshIndicator(
                            onRefresh: () async => _refresh(),
                            color: p.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final e = filtered[i];
                                return _buildEntryCard(e, p, theme.brightness);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MoodPalette p, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Entries',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 26, color: p.textPrimary, letterSpacing: 1)),
              if (total > 0)
                Text('$total entries',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: p.textSecondary)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: p.textSecondary),
            onPressed: () {
              HapticService.light();
              _refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(MoodPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          style: TextStyle(color: p.textPrimary),
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search entries…',
            hintStyle: TextStyle(color: p.textSecondary, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: p.textSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.clear, color: p.textSecondary, size: 18),
                    onPressed: () => setState(() => _query = ''),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodFilter(MoodPalette p) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterChip('All', _filterMood == null, () {
            HapticService.select();
            setState(() => _filterMood = null);
          }, p),
          const SizedBox(width: 8),
          ...Mood.values.map((m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _filterChip(
                  '${m.emoji} ${m.label}',
                  _filterMood == m,
                  () {
                    HapticService.select();
                    setState(() => _filterMood = _filterMood == m ? null : m);
                  },
                  p,
                ),
              )),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap, MoodPalette p) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.primary : p.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: selected ? Colors.white : p.textPrimary,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildEmpty(MoodPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 72, color: p.textSecondary),
            const SizedBox(height: 20),
            Text('No entries yet',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 28, color: p.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Apne pehle thought, feeling ya memory ko\nLunaire mein record karo 🌙',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: p.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: p.primary),
              icon: const Icon(Icons.edit_note, color: Colors.white),
              label: const Text('Write first entry'),
              onPressed: () async {
                final saved = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WriteEntryScreen()),
                );
                if (saved != null) _refresh();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(MoodPalette p) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: p.textSecondary),
          const SizedBox(height: 16),
          Text('Kuch nahi mila',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, color: p.textPrimary)),
          const SizedBox(height: 4),
          Text('Try a different search or mood filter',
              style: GoogleFonts.poppins(fontSize: 12, color: p.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntry e, MoodPalette p, Brightness brightness) {
    final moodPalette = MoodThemes.palette(e.mood, brightness);
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmDelete(e);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _showEntryDetail(e),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: moodPalette.primary, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: moodPalette.primary.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.mood.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cormorantGaramond(
                                  fontSize: 20,
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2)),
                          const SizedBox(height: 2),
                          Text(
                              DateFormat('d MMM • h:mm a').format(e.createdAt),
                              style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: p.textSecondary,
                                  letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                    // Action buttons
                    Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: Icon(Icons.edit_outlined,
                                size: 18, color: p.textSecondary),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _editEntry(e),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent.withOpacity(0.7)),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDelete(e),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 8, 8, 0),
                  child: Text(
                    e.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: p.textSecondary,
                        height: 1.5),
                  ),
                ),
                if (e.mediaUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(34, 10, 8, 0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_outlined,
                            size: 14, color: p.textSecondary),
                        const SizedBox(width: 4),
                        Text('${e.mediaUrls.length} attachment${e.mediaUrls.length > 1 ? "s" : ""}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: p.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEntryDetail(DiaryEntry e) {
    final theme = context.read<ThemeProvider>();
    final palette = MoodThemes.palette(e.mood, theme.brightness);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scroll) {
            return SingleChildScrollView(
              controller: scroll,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: palette.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('${e.mood.emoji}  ${e.mood.label}',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: palette.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: palette.primary),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _editEntry(e);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDelete(e);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(e.title,
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 34,
                          color: palette.textPrimary,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  Text(
                      DateFormat('EEEE, d MMM yyyy • h:mm a')
                          .format(e.createdAt),
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: palette.textSecondary)),
                  const SizedBox(height: 24),
                  Text(e.content,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: palette.textPrimary,
                          height: 1.7)),
                  if (e.mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: e.mediaUrls.map((path) {
                        final isVideo = path.toLowerCase().endsWith('.mp4');
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: palette.surface,
                          ),
                          child: isVideo
                              ? Icon(Icons.videocam,
                                  size: 32, color: palette.primary)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.broken_image,
                                              color: palette.primary)),
                                ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
