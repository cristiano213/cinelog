import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment variables loaded from `.env`.
///
/// Use this class everywhere instead of reading `dotenv.env` directly.
/// Each getter returns a non-nullable [String] and throws [StateError]
/// at first access if the variable is missing or empty in `.env`,
/// failing fast and clearly rather than propagating nulls.
///
/// Loaded once in `main()` via `await dotenv.load(fileName: '.env')`.
class EnvConfig {
  EnvConfig._(); // No instances. Static-only.

  /// TMDB v3 auth key. Required from Module 0.A.
  static String get tmdbApiKey => _required('TMDB_API_KEY');

  /// Supabase project URL. Required from Module 1.
  static String get supabaseUrl => _required('SUPABASE_URL');

  /// Supabase anon (public) key. Required from Module 1.
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');

  /// Google Places API key. Required from Module 3.
  static String get googlePlacesApiKey => _required('GOOGLE_PLACES_API_KEY');

  /// Reads a required env variable. Throws [StateError] if missing or empty.
  static String _required(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing env variable: $key. '
        'Check that .env exists in project root and contains a non-empty $key entry.',
      );
    }
    return value;
  }
}