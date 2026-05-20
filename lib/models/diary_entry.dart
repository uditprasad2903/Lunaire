import 'package:hive/hive.dart';
import '../themes/mood_themes.dart';

part 'diary_entry.g.dart';

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  int moodIndex;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  List<String> mediaUrls;

  @HiveField(6)
  String? userId;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.moodIndex,
    required this.createdAt,
    this.mediaUrls = const [],
    this.userId,
  });

  Mood get mood => Mood.values[moodIndex];

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'moodIndex': moodIndex,
        'createdAt': createdAt.toIso8601String(),
        'mediaUrls': mediaUrls,
        'userId': userId,
      };

  factory DiaryEntry.fromMap(Map<String, dynamic> map) => DiaryEntry(
        id: map['id'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        moodIndex: map['moodIndex'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
        mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
        userId: map['userId'] as String?,
      );
}
