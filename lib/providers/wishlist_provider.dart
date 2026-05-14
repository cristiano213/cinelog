import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../models/wishlist.dart';
import 'local_storage_provider.dart';

class WishlistNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() {
    return [];
  }

  /// Carica wishlist da disk
  Future<void> loadFromDisk() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.init();
    final wishlist = await storage.loadWishlist();
    state = wishlist.films;
  }

  /// Aggiunge un film alla wishlist
  Future<void> addMovie(Movie movie) async {
    if (!contains(movie.id)) {
      state = [...state, movie];
      await _save();
    }
  }

  /// Rimuove un film dalla wishlist
  Future<void> removeMovie(String movieId) async {
    state = state.where((f) => f.id != movieId).toList();
    await _save();
  }

  /// Verifica se un film è nella wishlist
  bool contains(String movieId) => state.any((f) => f.id == movieId);

  /// Salva su disk
  Future<void> _save() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.init();
    final wishlist = Wishlist(films: state);
    await storage.saveWishlist(wishlist);
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<Movie>>(WishlistNotifier.new);
