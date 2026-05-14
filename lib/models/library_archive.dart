import 'movie.dart';

class LibraryArchive {
  final List<Movie> films;

  const LibraryArchive({required this.films});

  bool contains(String movieId) => films.any((f) => f.id == movieId);

  LibraryArchive addMovie(Movie movie) {
    if (contains(movie.id)) return this;
    return LibraryArchive(films: [...films, movie]);
  }
  
  LibraryArchive removeMovie(String movieId) {
    return LibraryArchive(films: films.where((f) => f.id != movieId).toList());
  }

  factory LibraryArchive.fromJson(Map<String, dynamic> json) {
    final filmsList = (json['films'] as List?)?.map((f) => Movie.fromJson(f)).toList() ?? [];
    return LibraryArchive(films: filmsList);
  }

  Map<String, dynamic> toJson() {
    return {
      'films': films.map((f) => f.toJson()).toList(),
    };
  }
}