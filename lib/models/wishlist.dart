import 'movie.dart';

class Wishlist {
  final List<Movie> films;

  const Wishlist({required this.films});

  bool contains(String movieId) => films.any((f) => f.id == movieId);

  Wishlist addMovie(Movie movie) {
    if (contains(movie.id)) return this;  
    return Wishlist(films: [...films, movie]);
  }

  Wishlist removeMovie(String movieId) {
    return Wishlist(films: films.where((f) => f.id != movieId).toList());
  }

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    final filmsList = (json['films'] as List?)?.map((f) => Movie.fromJson(f)).toList() ?? [];
    return Wishlist(films: filmsList);
  }

  Map<String, dynamic> toJson() {
    return {
      'films': films.map((f) => f.toJson()).toList(),
    };
  }
}