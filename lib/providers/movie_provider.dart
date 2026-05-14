import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/movie_repository.dart';
import '../models/movie.dart';

enum MovieCategory { nowPlaying, upcoming, topRated, trending }

// Provider del repository
final movieRepositoryProvider = Provider((ref) => MovieRepository());

final movieListProvider =
    FutureProvider.family<List<Movie>, (MovieCategory, int)>(
  (ref, args) async {
    final (category, page) = args;
    final repo = ref.watch(movieRepositoryProvider);
    return await repo.getMoviesByCategory(category, page: page);
  },
);

final genreMoviesProvider = FutureProvider.family<List<Movie>, int>(
  (ref, genreId) async {
    final repo = ref.watch(movieRepositoryProvider);
    return await repo.getMoviesByGenre(genreId);
  },
);
