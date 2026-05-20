import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../widgets/sky_background.dart';
import '../widgets/reactive_moon.dart';
import '../models/diary_entry.dart';
import '../services/ai_service.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

class WriteEntryScreen extends StatefulWidget {
  /// Pass an existing DiaryEntry to edit it. Null means create new.
  final DiaryEntry? existing;
  const WriteEntryScreen({super.key, this.existing});

  @override
  State<WriteEntryScreen> createState() => _WriteEntryScreenState();
}

class _WriteEntryScreenState extends State<WriteEntryScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final List<String> _mediaPaths = [];
  Mood? _selectedMood;
  Mood? _suggestedMood;
  bool _moodJustChanged = false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _contentCtrl.text = widget.existing!.content;
      _selectedMood = widget.existing!.mood;
      _mediaPaths.addAll(widget.existing!.mediaUrls);
    }
  }

  void _onContentChanged(String text) {
    if (text.length > 20) {
      final detected = AIService.detectMood(text);
      if (detected != _suggestedMood) {
        setState(() {
          _suggestedMood = detected;
          _moodJustChanged = true;
        });
        HapticService.select();
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => _moodJustChanged = false);
        });
      }
    }
  }

  void _onMoodSelected(Mood m) {
    setState(() {
      _selectedMood = m;
      _moodJustChanged = true;
    });
    HapticService.medium();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _moodJustChanged = false);
    });
  }

  Future<void> _pickMedia(bool isVideo) async {
    HapticService.select();
    final picker = ImagePicker();
    final XFile? file = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _mediaPaths.add(file.path));
      HapticService.light();
    }
  }

  Future<void> _saveEntry() async {
    if (_contentCtrl.text.trim().isEmpty) {
      HapticService.medium();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write something first')));
      return;
    }
    setState(() => _saving = true);
    final mood = _selectedMood ?? _suggestedMood ?? Mood.defaultMood;
    final auth = context.read<AuthService>();
    final theme = context.read<ThemeProvider>();

    final entry = DiaryEntry(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim().isEmpty
          ? 'Untitled — ${DateTime.now().toIso8601String().substring(0, 10)}'
          : _titleCtrl.text.trim(),
      content: _contentCtrl.text,
      moodIndex: mood.index,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      mediaUrls: _mediaPaths,
      userId: auth.userId,
    );

    // Persist to local DB (addEntry uses put → handles both create + update)
    await DiaryService.addEntry(entry);

    // Apply mood theme to entire app
    theme.setMood(mood);

    HapticService.heavy();
    SoundService.chime();

    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? '🌙 Entry updated (${mood.label} ${mood.emoji})'
            : '🌙 Entry saved with ${mood.label} mood ${mood.emoji}'),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final activeMood = _selectedMood ?? _suggestedMood ?? theme.currentMood;
    final activePalette = MoodThemes.palette(activeMood, theme.brightness);
    final p = theme.palette;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        child: SkyBackground(
          palette: activePalette,
          isDark: theme.isDark,
          mood: activeMood,
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(p),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ReactiveMoon(
                            mood: activeMood,
                            palette: activePalette,
                            size: 110,
                            justChanged: _moodJustChanged,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Whisper text from moon
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              _moonWhisper(activeMood),
                              key: ValueKey(activeMood),
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: activePalette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _titleCtrl,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 26,
                            color: activePalette.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Give it a title…',
                            hintStyle:
                                TextStyle(color: activePalette.textSecondary),
                            border: InputBorder.none,
                            filled: false,
                          ),
                        ),
                        Divider(color: activePalette.textSecondary.withOpacity(0.2)),
                        TextField(
                          controller: _contentCtrl,
                          onChanged: _onContentChanged,
                          maxLines: 12,
                          style: GoogleFonts.poppins(
                            color: activePalette.textPrimary,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Pour your heart out…\n\nWhat are you feeling tonight?',
                            hintStyle:
                                TextStyle(color: activePalette.textSecondary),
                            border: InputBorder.none,
                            filled: false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_suggestedMood != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: activePalette.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 18, color: activePalette.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Mood detected: ${_suggestedMood!.label} ${_suggestedMood!.emoji}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: activePalette.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text('Choose your mood',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: activePalette.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Mood.values.map((m) {
                            final selected = m == _selectedMood;
                            return GestureDetector(
                              onTap: () => _onMoodSelected(m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? activePalette.primary
                                      : activePalette.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: activePalette.primary
                                                .withOpacity(0.4),
                                            blurRadius: 12,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  '${m.emoji} ${m.label}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: selected
                                        ? Colors.white
                                        : activePalette.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _mediaButton(Icons.photo_outlined, 'Photo',
                                () => _pickMedia(false), activePalette),
                            const SizedBox(width: 10),
                            _mediaButton(Icons.videocam_outlined, 'Video',
                                () => _pickMedia(true), activePalette),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_mediaPaths.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _mediaPaths.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final path = _mediaPaths[i];
                                final isVideo =
                                    path.toLowerCase().endsWith('.mp4');
                                return Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: activePalette.surface,
                                      ),
                                      child: isVideo
                                          ? Icon(Icons.videocam,
                                              size: 30,
                                              color: activePalette.primary)
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.file(File(path),
                                                  fit: BoxFit.cover),
                                            ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _mediaPaths.removeAt(i)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _saveEntry,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.bookmark_add_outlined,
                                    color: Colors.white),
                            label: Text(_saving
                                ? 'Saving…'
                                : (_isEditing ? 'Update Entry' : 'Save Entry')),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: activePalette.primary),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _moonWhisper(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return 'The moon smiles with you ✨';
      case Mood.sad:
        return 'The moon listens. Let it out. 🌒';
      case Mood.angry:
        return 'The moon burns. Take a breath. 🔥';
      case Mood.calm:
        return 'The moon glows softly. 🌙';
      case Mood.romantic:
        return 'The moon blushes with your heart. 💗';
      case Mood.anxious:
        return 'The moon is here. You\'re safe. 🌫️';
      case Mood.defaultMood:
        return 'The moon is watching, gently.';
    }
  }

  Widget _mediaButton(
      IconData icon, String label, VoidCallback onTap, MoodPalette p) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: p.primary),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: p.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(MoodPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: p.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(_isEditing ? 'Edit Entry' : 'New Entry',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, color: p.textPrimary)),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
