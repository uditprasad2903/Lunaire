import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../themes/theme_provider.dart';
import '../themes/mood_themes.dart';
import '../widgets/sky_background.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  late List<DiaryEntry> _entries;
  int _rangeDays = 7; // 7 / 30 / 90

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

  /// Returns one MoodPoint per day in the selected range.
  /// For days with multiple entries, picks the most-frequent mood.
  /// For days with no entries, returns null (gap in chart).
  List<_DayMood> _aggregate() {
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _rangeDays - 1));

    final out = <_DayMood>[];
    for (int i = 0; i < _rangeDays; i++) {
      final day = startDay.add(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final dayEntries = _entries
          .where((e) => e.createdAt.isAfter(day) && e.createdAt.isBefore(next))
          .toList();
      if (dayEntries.isEmpty) {
        out.add(_DayMood(day: day, mood: null));
        continue;
      }
      // Pick most frequent mood
      final counts = <Mood, int>{};
      for (final e in dayEntries) {
        counts[e.mood] = (counts[e.mood] ?? 0) + 1;
      }
      final dominant =
          counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      out.add(_DayMood(day: day, mood: dominant));
    }
    return out;
  }

  /// Counts entries per mood (across all-time data)
  Map<Mood, int> _moodCounts() {
    final counts = <Mood, int>{};
    for (final e in _entries) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    return counts;
  }

  Mood? _topMood() {
    final counts = _moodCounts();
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int _currentStreak() {
    if (_entries.isEmpty) return 0;
    final dates = _entries
        .map((e) =>
            DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    var current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);
    // Allow streak to start either today or yesterday
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

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final p = theme.palette;
    final data = _aggregate();
    final hasAnyData = _entries.isNotEmpty;
    final top = _topMood();
    final streak = _currentStreak();
    final counts = _moodCounts();

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
                child: !hasAnyData
                    ? _buildEmpty(p)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildStatsRow(p, _entries.length, streak, top),
                            const SizedBox(height: 20),
                            _buildRangePicker(p),
                            const SizedBox(height: 16),
                            _buildChartCard(data, p),
                            const SizedBox(height: 20),
                            _buildMoodBreakdown(counts, p),
                            const SizedBox(height: 20),
                            _buildInsightCard(top, streak, p),
                            const SizedBox(height: 40),
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

  // ============= Sections =============

  Widget _buildEmpty(MoodPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: p.textSecondary),
            const SizedBox(height: 20),
            Text('No mood data yet',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 26, color: p.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Diary entries likho — mood patterns yahan dikhne lagenge 🌙',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: p.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(MoodPalette p, int total, int streak, Mood? top) {
    return Row(
      children: [
        Expanded(child: _statTile('$total', 'Total entries', Icons.menu_book, p)),
        const SizedBox(width: 10),
        Expanded(
            child: _statTile('$streak', 'Day streak', Icons.local_fire_department, p)),
        const SizedBox(width: 10),
        Expanded(
            child: _statTile(
                top != null ? top.emoji : '—', 'Top mood', Icons.favorite, p)),
      ],
    );
  }

  Widget _statTile(String value, String label, IconData icon, MoodPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: p.primary, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  color: p.textPrimary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, color: p.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRangePicker(MoodPalette p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _rangeChip('7 days', _rangeDays == 7, () => setState(() => _rangeDays = 7), p),
        const SizedBox(width: 8),
        _rangeChip('30 days', _rangeDays == 30, () => setState(() => _rangeDays = 30), p),
        const SizedBox(width: 8),
        _rangeChip('90 days', _rangeDays == 90, () => setState(() => _rangeDays = 90), p),
      ],
    );
  }

  Widget _rangeChip(String label, bool selected, VoidCallback onTap, MoodPalette p) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.primary : p.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: selected ? Colors.white : p.textPrimary,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildChartCard(List<_DayMood> data, MoodPalette p) {
    // Convert to FlSpots; gaps for null days. Use mood.index for y-axis (0-6).
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final m = data[i].mood;
      if (m != null) spots.add(FlSpot(i.toDouble(), m.index.toDouble()));
    }

    final hasData = spots.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text('Mood trend',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 22, color: p.textPrimary)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: !hasData
                ? Center(
                    child: Text('Is range mein koi entry nahi',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: p.textSecondary)))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: (Mood.values.length - 1).toDouble(),
                      minX: 0,
                      maxX: (data.length - 1).toDouble(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= Mood.values.length) {
                                return const SizedBox();
                              }
                              return Text(Mood.values[i].emoji,
                                  style: const TextStyle(fontSize: 14));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (data.length / 6).ceilToDouble().clamp(1, 30),
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    DateFormat('d/M').format(data[i].day),
                                    style: TextStyle(
                                        color: p.textSecondary,
                                        fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: p.textSecondary.withOpacity(0.1),
                            strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: p.primary,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) {
                              final mood = Mood.values[spot.y.toInt()];
                              final moodColor =
                                  MoodThemes.palette(mood, Brightness.dark)
                                      .primary;
                              return FlDotCirclePainter(
                                  radius: 5,
                                  color: moodColor,
                                  strokeColor: Colors.white,
                                  strokeWidth: 1.5);
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                p.primary.withOpacity(0.35),
                                p.primary.withOpacity(0.0)
                              ],
                            ),
                          ),
                          spots: spots,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBreakdown(Map<Mood, int> counts, MoodPalette p) {
    if (counts.isEmpty) return const SizedBox.shrink();
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood breakdown',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, color: p.textPrimary)),
          const SizedBox(height: 14),
          ...sorted.map((entry) {
            final pct = total == 0 ? 0.0 : entry.value / total;
            final moodColor =
                MoodThemes.palette(entry.key, Brightness.dark).primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                      width: 24,
                      child: Text(entry.key.emoji,
                          style: const TextStyle(fontSize: 18))),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 78,
                      child: Text(entry.key.label,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: p.textPrimary))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: p.background,
                        valueColor: AlwaysStoppedAnimation(moodColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 36,
                      child: Text('${entry.value}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: p.textSecondary,
                              fontWeight: FontWeight.w600))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Mood? top, int streak, MoodPalette p) {
    final msg = _insightMessage(top, streak);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: p.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: p.textPrimary, height: 1.5)),
          ),
        ],
      ),
    );
  }

  String _insightMessage(Mood? top, int streak) {
    if (top == null) {
      return 'Likhna shuru karo — pattern dikhne lagenge yahan 🌙';
    }
    final streakPart = streak > 1 ? ' $streak din ka streak chal raha hai!' : '';
    switch (top) {
      case Mood.happy:
        return 'Aap zyada **Happy** mood mein rahe ho. ${top.emoji} Yeh acha sign hai!$streakPart';
      case Mood.sad:
        return 'Lately aap **Sad** feel kar rahe ho. ${top.emoji} Apne dil ki baat likhte rehna helpful hai.$streakPart';
      case Mood.angry:
        return '**Angry** mood haavi raha hai. ${top.emoji} Likhna gussa nikalne ka safe way hai.$streakPart';
      case Mood.calm:
        return 'Aap zyaadatar **Calm** rahe ho. ${top.emoji} Beautiful — peace hold karo.$streakPart';
      case Mood.romantic:
        return 'Bahut **Romantic** vibes hain in dino. ${top.emoji}$streakPart';
      case Mood.anxious:
        return '**Anxious** feel zyada hua hai. ${top.emoji} Slow breaths + small wins. You\'re doing fine.$streakPart';
      case Mood.defaultMood:
        return 'Mood mix-and-match rahe hain. ${top.emoji} Likhte raho, clarity aayegi.$streakPart';
    }
  }

  Widget _buildAppBar(BuildContext context, MoodPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Mood Tracker',
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
}

class _DayMood {
  final DateTime day;
  final Mood? mood;
  _DayMood({required this.day, this.mood});
}
