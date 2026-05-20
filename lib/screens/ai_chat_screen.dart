import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../widgets/sky_background.dart';
import '../widgets/animated_moon.dart';
import '../services/ai_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../services/settings_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<_Message> _messages = [
    _Message(
      text: "Hi, I'm Luna 🌙 your diary companion.\nTell me what's on your mind tonight.",
      isUser: false,
    ),
  ];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _thinking = false;

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    HapticService.light();
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _inputCtrl.clear();
      _thinking = true;
    });
    _scrollDown();

    final theme = context.read<ThemeProvider>();

    // Add an empty Luna message that we'll progressively fill as the
    // stream emits chunks (typewriter / real-time feel).
    final replyIndex = _messages.length;
    _messages.add(_Message(text: '', isUser: false));
    bool firstChunk = true;

    try {
      await for (final chunk in AIService.chatStream(text,
          currentMood: theme.currentMood)) {
        if (!mounted) return;
        if (firstChunk) {
          firstChunk = false;
          // First chunk arrived — hide the thinking indicator + play sound
          setState(() {
            _thinking = false;
          });
          SoundService.chime();
          HapticService.select();
        }
        setState(() {
          _messages[replyIndex] = _Message(text: chunk, isUser: false);
        });
        _scrollDown();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _messages[replyIndex] = _Message(
            text: "Sorry, kuch issue aaya: ${e.toString()}", isUser: false);
      });
    } finally {
      if (mounted && _thinking) {
        setState(() => _thinking = false);
      }
    }
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        enableTrail: context.watch<SettingsService>().trailEnabled,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(p, theme),
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_thinking ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length && _thinking) {
                      return _buildBubble("Luna is thinking…", false, p,
                          italic: true);
                    }
                    final m = _messages[i];
                    return _buildBubble(m.text, m.isUser, p);
                  },
                ),
              ),
              // Suggested prompts (only show when chat is empty)
              if (_messages.length <= 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _suggestionChip("Aaj acha din tha", p),
                        const SizedBox(width: 6),
                        _suggestionChip("Mann udaas hai", p),
                        const SizedBox(width: 6),
                        _suggestionChip("Help me reflect", p),
                        const SizedBox(width: 6),
                        _suggestionChip("Random thought", p),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: p.surface.withOpacity(0.8)),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        style: TextStyle(color: p.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Talk to Luna…',
                          hintStyle: TextStyle(color: p.textSecondary),
                          filled: true,
                          fillColor: p.background.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 20),
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

  Widget _buildAppBar(MoodPalette p, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          AnimatedMoon(
              mood: theme.currentMood, palette: p, size: 36, animate: false),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Luna',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22, color: p.textPrimary)),
              Text('your AI companion',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: p.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String text, MoodPalette p) {
    return GestureDetector(
      onTap: () {
        _inputCtrl.text = text;
        _send();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.primary.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(color: p.textPrimary, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser, MoodPalette p,
      {bool italic = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? p.primary : p.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: isUser ? Colors.white : p.textPrimary,
            fontSize: 14,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}
