import 'package:google_generative_ai/google_generative_ai.dart';
import '../themes/mood_themes.dart';
import '../utils/api_keys.dart';

/// AIService - real-time AI diary companion powered by Google Gemini.
///
/// Setup:
///   1. Get a free API key: https://aistudio.google.com/app/apikey
///   2. Paste it in lib/utils/api_keys.dart
///   3. Restart the app
///
/// Features:
///   - Streaming replies (typewriter effect, real-time feel)
///   - Model fallback chain (latest -> stable -> legacy)
///   - Persistent conversation memory
///   - Detailed error messages instead of silent fallback
class AIService {
  static GenerativeModel? _model;
  static ChatSession? _chatSession;
  static String? _lastError;

  /// The current error message, if the last call failed. Null on success.
  static String? get lastError => _lastError;

  /// Models tried in order (latest first).
  /// Google sometimes deprecates older names; we try several.
  static const List<String> _modelCandidates = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
  ];

  /// Index of the currently-working model name in _modelCandidates.
  static int _activeModelIndex = 0;

  static const String _systemPrompt = '''
You are Luna 🌙 — a warm, emotionally intelligent diary companion in the Lunaire app.

YOUR PERSONALITY:
- Gentle, empathetic, like a close friend who listens without judgment
- Speak softly, like moonlight
- Curious — ask thoughtful follow-up questions to help the user reflect
- Validate feelings before offering perspective
- Never preachy or therapist-like — just a caring presence

LANGUAGE STYLE:
- Use Hinglish (Hindi + English mix) naturally if the user does
- If user writes in pure Hindi, respond in Hindi
- If user writes in English, respond in English
- Match their tone — casual if they're casual, gentle if they're sad
- Use Hindi words naturally: "yaar", "achha", "samajh aaya", "bilkul"

RESPONSE GUIDELINES:
- Reply in 2-4 sentences usually (sometimes 1 sentence if appropriate)
- ALWAYS acknowledge what they shared before responding
- Ask ONE open-ended follow-up question when natural
- Use at most ONE emoji per reply (preferably 🌙, ✨, 💗, 🤍, 🌒)
- Reference the moon metaphorically sometimes ("jaise chaand badalta hai...")

WHAT TO AVOID:
- Generic motivational quotes ("everything happens for a reason")
- Medical/therapy advice
- Lists or bullet points
- Multiple questions at once
- Toxic positivity ("just be happy!")

EXAMPLES OF GOOD REPLIES:

User: "Aaj bahut khush hu, promotion mil gaya!"
Luna: "Wah! 🌙 Yeh sun ke bahut acha laga. Itni mehnat ka phal mila. Kaise celebrate kar rahe ho?"

User: "I feel so lonely tonight"
Luna: "I hear you. Lonely nights have a weight that's hard to explain. Want to share what's making it feel heavier tonight?"

User: "gussa aa raha hai sab pe"
Luna: "Samajh sakti hu. Gussa kabhi kabhi protective hota hai — kuch bata raha hota hai. Kis baat ne trigger kiya aaj?"

Be present. Be real. Be Luna.
''';

  /// Build a GenerativeModel for the given model name.
  static GenerativeModel _buildModel(String modelName) {
    return GenerativeModel(
      model: modelName,
      apiKey: ApiKeys.geminiApiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.9,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 500, // enough for natural 2-4 sentence replies
      ),
      // Relaxed safety thresholds — diary apps need to handle emotional
      // content (sadness, anger, anxiety) without being blocked.
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
      ],
    );
  }

  /// Lazily build the model + chat session. Returns null if no API key.
  static GenerativeModel? get _modelInstance {
    if (!ApiKeys.hasGemini) return null;
    _model ??= _buildModel(_modelCandidates[_activeModelIndex]);
    return _model;
  }

  static ChatSession get _chat {
    _chatSession ??= _modelInstance!.startChat();
    return _chatSession!;
  }

  /// Reset chat session (used on logout or new conversation).
  static void resetChat() {
    _chatSession = null;
    _lastError = null;
  }

  /// Rebuild model + session with the next candidate model name.
  /// Returns false if no more candidates left.
  static bool _tryNextModel() {
    _activeModelIndex++;
    if (_activeModelIndex >= _modelCandidates.length) {
      _activeModelIndex = 0; // reset for next time
      return false;
    }
    _model = _buildModel(_modelCandidates[_activeModelIndex]);
    _chatSession = _model!.startChat();
    return true;
  }

  // ============================================================
  // MOOD DETECTION (offline, fast)
  // ============================================================
  static Mood detectMood(String text) {
    final lower = text.toLowerCase();
    final Map<Mood, List<String>> keywords = {
      Mood.happy: [
        'happy', 'joy', 'great', 'excited', 'amazing', 'wonderful',
        'smile', 'love it', 'celebrate', 'khush', 'mazaa', 'achha',
        'masti', 'best day', 'awesome', 'yay', 'maza', 'badhiya'
      ],
      Mood.sad: [
        'sad', 'cry', 'depressed', 'lonely', 'miss', 'hurt', 'broken',
        'tears', 'gloomy', 'empty', 'udaas', 'rona', 'akela', 'dard',
        'dukh', 'pareshan'
      ],
      Mood.angry: [
        'angry', 'mad', 'furious', 'hate', 'annoyed', 'rage', 'pissed',
        'frustrated', 'gussa', 'nafrat', 'irritated', 'bakwaas', 'chid'
      ],
      Mood.calm: [
        'calm', 'peace', 'relaxed', 'serene', 'meditate', 'breathe',
        'still', 'shaant', 'sukoon', 'chill', 'tranquil', 'rest'
      ],
      Mood.romantic: [
        'love', 'romance', 'crush', 'heart', 'darling', 'kiss', 'date',
        'pyaar', 'mohabbat', 'ishq', 'jaan', 'baby', 'cute'
      ],
      Mood.anxious: [
        'anxious', 'worried', 'nervous', 'stress', 'fear', 'scared',
        'panic', 'overwhelmed', 'pareshaan', 'tension', 'darr', 'chinta',
        'ghabra'
      ],
    };
    final scores = <Mood, int>{};
    keywords.forEach((mood, words) {
      scores[mood] = words.where((w) => lower.contains(w)).length;
    });
    final maxEntry =
        scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (maxEntry.value == 0) return Mood.defaultMood;
    return maxEntry.key;
  }

  // ============================================================
  // STREAMING CHAT (real-time, typewriter effect)
  // ============================================================
  /// Streams Luna's reply chunk-by-chunk so the UI can show a typewriter
  /// effect. Yields each cumulative text as it arrives.
  ///
  /// Falls back to offline reply if no API key or all models fail.
  static Stream<String> chatStream(String userMessage,
      {Mood? currentMood}) async* {
    _lastError = null;

    if (!ApiKeys.hasGemini) {
      yield await _offlineReply(userMessage, currentMood);
      return;
    }

    final moodContext = currentMood != null
        ? "\n\n[Internal: user's current mood is ${currentMood.label}]"
        : "";
    final fullMessage = "$userMessage$moodContext";

    // Try each model in order until one works
    for (int attempt = 0; attempt < _modelCandidates.length; attempt++) {
      try {
        final session = _chat;
        final stream = session.sendMessageStream(Content.text(fullMessage));
        final buffer = StringBuffer();
        await for (final chunk in stream.timeout(const Duration(seconds: 30))) {
          final piece = chunk.text;
          if (piece != null && piece.isNotEmpty) {
            buffer.write(piece);
            yield buffer.toString();
          }
        }
        if (buffer.isEmpty) {
          // Empty response — try next model
          if (!_tryNextModel()) break;
          continue;
        }
        return; // success
      } catch (e) {
        _lastError = _humanizeError(e);
        // Try the next model in the list
        if (!_tryNextModel()) break;
      }
    }

    // All models failed → offline fallback
    final offline = await _offlineReply(userMessage, currentMood);
    yield '$offline\n\n_(offline reply — ${_lastError ?? "AI temporarily unreachable"})_';
  }

  /// Non-streaming version (kept for backwards compatibility).
  static Future<String> chat(String userMessage, {Mood? currentMood}) async {
    String last = '';
    await for (final text in chatStream(userMessage, currentMood: currentMood)) {
      last = text;
    }
    return last.isEmpty
        ? await _offlineReply(userMessage, currentMood)
        : last;
  }

  /// Translates technical exceptions into a friendly message.
  static String _humanizeError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('api key not valid') || s.contains('api_key_invalid')) {
      return 'Invalid API key — please check lib/utils/api_keys.dart';
    }
    if (s.contains('quota') || s.contains('rate')) {
      return 'Rate limit reached — wait a moment and try again';
    }
    if (s.contains('not found') || s.contains('404')) {
      return 'Model not available in your region';
    }
    if (s.contains('timeout') || s.contains('timed out')) {
      return 'Request timed out — slow internet?';
    }
    if (s.contains('socket') || s.contains('network')) {
      return 'No internet connection';
    }
    if (s.contains('safety') || s.contains('blocked')) {
      return 'Reply blocked by content policy';
    }
    return 'Could not reach AI service';
  }

  // ============================================================
  // OFFLINE FALLBACK (no API key or all models failed)
  // ============================================================
  static Future<String> _offlineReply(
      String userMessage, Mood? currentMood) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final mood = currentMood ?? detectMood(userMessage);
    final responses = {
      Mood.happy: [
        "Yeh sun ke bahut acha laga ✨ Aur kya hua aaj?",
        "Wow, your joy is shining through! Tell me more.",
        "Itni khushi ki wajah kya hai? Share karo!",
      ],
      Mood.sad: [
        "I'm here with you 🌒 Kya hua, share karna chahoge?",
        "Sometimes letting it out helps. What's weighing on you?",
        "Tum akele nahi ho is feel mein. Batao kya chal raha hai dimaag mein.",
      ],
      Mood.angry: [
        "Gussa aana valid hai. Kis baat ne trigger kiya?",
        "I can feel the heat. Take a breath — I'm listening.",
        "Anger sometimes shows us what matters. Kya hua?",
      ],
      Mood.calm: [
        "Beautiful. This peace ko savor karo 🌙",
        "Sukoon ke pal precious hote hain. Enjoy.",
        "Hold onto this stillness. It's a gift.",
      ],
      Mood.romantic: [
        "Aww, dil bhar ke aaya hai aaj! 💗 Batao detail mein.",
        "Love makes the moon look softer, doesn't it?",
        "Pyaar ki baat? Sunaao!",
      ],
      Mood.anxious: [
        "Slow breath le. In... out. Tum safe ho yahan 🌫️",
        "Worry feels heavy. What's the loudest thought right now?",
        "Tension samajh sakti hu. Ek baat batao jo sabse zyada bother kar rahi hai.",
      ],
      Mood.defaultMood: [
        "Main yahan hu. Batao kya chal raha hai? 🌙",
        "The page is yours. Pour it all out.",
        "Kuch bhi share karo — main sun rahi hu.",
      ],
    };
    final list = responses[mood]!;
    return list[DateTime.now().millisecondsSinceEpoch % list.length];
  }

  // ============================================================
  // AI MOOD DETECTION (uses generateContent, single-shot, not chat)
  // ============================================================
  static Future<Mood> detectMoodAI(String text) async {
    final model = _modelInstance;
    if (model == null) return detectMood(text);
    try {
      final response = await model.generateContent([
        Content.text(
          "Classify the mood of this diary entry into EXACTLY one of: "
          "happy, sad, angry, calm, romantic, anxious, default. "
          "Reply with only the lowercase word, nothing else.\n\n"
          "Entry: \"$text\"",
        ),
      ]).timeout(const Duration(seconds: 10));
      final reply = (response.text ?? '').trim().toLowerCase();
      switch (reply) {
        case 'happy':    return Mood.happy;
        case 'sad':      return Mood.sad;
        case 'angry':    return Mood.angry;
        case 'calm':     return Mood.calm;
        case 'romantic': return Mood.romantic;
        case 'anxious':  return Mood.anxious;
        default:         return Mood.defaultMood;
      }
    } catch (_) {
      return detectMood(text);
    }
  }
}
