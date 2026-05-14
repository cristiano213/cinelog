/// TMDB API configuration constants.
///
/// SECURITY NOTE: [apiKey] is intentionally left as a non-functional placeholder
/// in this commit. The real key is read from `.env` via `EnvConfig.tmdbApiKey`
/// in subsequent commits of Module 0.A.
///
/// Until the dotenv migration is complete, any code path that touches
/// [TmdbConstants.apiKey] will throw [UnimplementedError] at runtime,
/// making misuse loud and immediate rather than silent.
class TmdbConstants {
  // ignore: unused_element
  static String get apiKey => throw UnimplementedError(
        'TmdbConstants.apiKey is a placeholder. '
        'Migrate to EnvConfig.tmdbApiKey (Module 0.A, step "EnvConfig").',
      );

  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  // Poster sizes
  static const String posterSize = 'w500'; // 500px
  static const String backdropSize = 'w780'; // 780px

  // Timeout for API calls
  static const Duration apiTimeout = Duration(seconds: 10);
}