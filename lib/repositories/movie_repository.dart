import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';

class MovieRepository {
  static final _cache = <String, (DateTime, List<Movie>)>{};
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Mappa categoria a endpoint TMDB
  String _getEndpoint(MovieCategory category) {
    switch (category) {
      case MovieCategory.nowPlaying:
        return '/movie/now_playing';
      case MovieCategory.upcoming:
        return '/movie/upcoming';
      case MovieCategory.topRated:
        return '/movie/top_rated';
      case MovieCategory.trending:
        return '/trending/movie/week';
    }
  }

  /// Carica film da TMDB per categoria e pagina
  Future<List<Movie>> getMoviesByCategory(
    MovieCategory category, {
    int page = 1,
  }) async {
    final cacheKey = '${category.name}_p$page';

    if (_cache.containsKey(cacheKey)) {
      final (timestamp, movies) = _cache[cacheKey]!;
      if (DateTime.now().difference(timestamp).inMinutes < _cacheTtl.inMinutes) {
        return movies;
      }
    }

    final endpoint = _getEndpoint(category);
    final url = '${TmdbConstants.baseUrl}$endpoint?api_key=${TmdbConstants.apiKey}&page=$page&language=it';
    
    return _fetchMovies(url, cacheKey);
  }

  /// NOVITÀ: Ricerca film per testo
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    final encodedQuery = Uri.encodeComponent(query);
    final url = '${TmdbConstants.baseUrl}/search/movie?api_key=${TmdbConstants.apiKey}&query=$encodedQuery&page=$page&language=it';
    return _fetchMovies(url, 'search_${query}_p$page');
  }

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    final url = '${TmdbConstants.baseUrl}/discover/movie?api_key=${TmdbConstants.apiKey}&with_genres=$genreId&page=$page&language=it&sort_by=popularity.desc';
    return _fetchMovies(url, 'genre_${genreId}_p$page');
  }

  /// Scopri film per lista di generi (AND — comma-separated)
  Future<List<Movie>> getMoviesByGenres(List<int> genreIds, {int page = 1}) async {
    final param = genreIds.join(',');
    final url = '${TmdbConstants.baseUrl}/discover/movie?api_key=${TmdbConstants.apiKey}&with_genres=$param&page=$page&language=it&sort_by=popularity.desc';
    return _fetchMovies(url, 'genres_${param}_p$page');
  }

  /// Helper privato per gestire la chiamata HTTP e il parsing
  Future<List<Movie>> _fetchMovies(String url, String cacheKey) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(TmdbConstants.apiTimeout);

      if (response.statusCode != 200) {
        throw Exception('TMDB error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map;
      final results = data['results'] as List? ?? [];

      final movies = results
          .map((m) => Movie.fromTmdbJson(m as Map<String, dynamic>))
          .toList();

      _cache[cacheKey] = (DateTime.now(), movies);
      return movies;
    } catch (e) {
      print('Error fetching movies from $url: $e');
      rethrow;
    }
  }

  /// Carica dettagli di un film (con cast)
  Future<Movie?> getMovieDetails(String movieId) async {
    try {
      final url = '${TmdbConstants.baseUrl}/movie/$movieId?api_key=${TmdbConstants.apiKey}&append_to_response=credits&language=it';
      final response = await http.get(Uri.parse(url)).timeout(TmdbConstants.apiTimeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Movie.fromTmdbJson(data);
    } catch (e) {
      print('Error fetching movie details: $e');
      return null;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}