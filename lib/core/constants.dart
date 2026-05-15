import 'config/env_config.dart';

/// TMDB API configuration constants.
///
/// [apiKey] is loaded from `.env` via [EnvConfig] at runtime.
/// All other constants are compile-time and live here.
class TmdbConstants {
  /// TMDB v3 auth key. Loaded from `.env`.
  static String get apiKey => EnvConfig.tmdbApiKey;

  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  // Poster sizes
  static const String posterSize = 'w500'; // 500px
  static const String backdropSize = 'w780'; // 780px

  // Timeout for API calls
  static const Duration apiTimeout = Duration(seconds: 10);
}