import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/diary_entry.dart';

class DiaryService {
  static const String _boxName = 'diary_entries';
  static Box<DiaryEntry>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DiaryEntryAdapter());
    }
    _box = await Hive.openBox<DiaryEntry>(_boxName);
  }

  static Future<void> addEntry(DiaryEntry entry) async {
    await _box?.put(entry.id, entry);
  }

  static Future<void> deleteEntry(String id) async {
    await _box?.delete(id);
  }

  static Future<void> clearAll() async {
    await _box?.clear();
  }

  static List<DiaryEntry> getAllEntries() {
    final entries = _box?.values.toList() ?? [];
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  static DiaryEntry? getEntry(String id) => _box?.get(id);

  /// Export all entries as a single human-readable text string.
  static String exportAsText() {
    final entries = getAllEntries();
    final buf = StringBuffer();
    buf.writeln('═══════════════════════════════════════');
    buf.writeln('         LUNAIRE DIARY EXPORT');
    buf.writeln('═══════════════════════════════════════');
    buf.writeln('Exported on: ${DateTime.now().toString().substring(0, 19)}');
    buf.writeln('Total entries: ${entries.length}');
    buf.writeln('═══════════════════════════════════════\n');
    for (final e in entries) {
      buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('📅 ${e.createdAt.toString().substring(0, 16)}');
      buf.writeln('${e.mood.emoji} Mood: ${e.mood.label}');
      buf.writeln('📝 ${e.title}');
      buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buf.writeln(e.content);
      if (e.mediaUrls.isNotEmpty) {
        buf.writeln('\n📎 ${e.mediaUrls.length} attachment(s)');
      }
      buf.writeln('\n');
    }
    buf.writeln('═══════════════════════════════════════');
    buf.writeln('   End of export · Made with 🌙 by Lunaire');
    buf.writeln('═══════════════════════════════════════');
    return buf.toString();
  }

  /// Total word count across all entries
  static int getTotalWordCount() {
    return getAllEntries().fold<int>(
      0,
      (sum, e) => sum + e.content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
    );
  }

  /// Entries this week
  static int getThisWeekCount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return getAllEntries().where((e) => e.createdAt.isAfter(weekStartDay)).length;
  }

  /// Longest streak ever recorded
  static int getLongestStreak() {
    final entries = getAllEntries();
    if (entries.isEmpty) return 0;
    final dates = entries
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList()
      ..sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (dates[i].difference(dates[i - 1]).inDays > 1) {
        current = 1;
      }
    }
    return longest;
  }
}
