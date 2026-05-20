/// API keys configuration for Lunaire.
///
/// IMPORTANT: Do NOT commit real API keys. For production use, prefer:
///   - flutter_dotenv with a .env file (added to .gitignore)
///   - Firebase Remote Config
///   - Backend proxy that holds the key
///
/// Get a free Gemini API key:
///   https://aistudio.google.com/app/apikey
class ApiKeys {
  /// Paste your Gemini API key here.
  /// Leave empty string ('') to fall back to the offline keyword-based mood
  /// detector + canned replies.
  static const String geminiApiKey = 'AIzaSyBcyh0Xkpl6q-cy45CyDGC48yTr9naHoyo';

  static bool get hasGemini => geminiApiKey.isNotEmpty;
}
