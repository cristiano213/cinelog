import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_review.dart';
import 'local_storage_provider.dart';

class ReviewsNotifier extends Notifier<List<UserReview>> {
  @override
  List<UserReview> build() {
    return [];
  }

  /// Carica le review da disk
  Future<void> loadFromDisk() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.init();
    final reviews = await storage.loadUserReviews();
    state = reviews;
  }

  /// Aggiunge o aggiorna una review
  Future<void> addOrUpdateReview({
    required String movieId,
    required String movieTitle,
    required int userRating,
    required String reviewText,
  }) async {
    UserReview? existing;
    try {
      existing = state.firstWhere((r) => r.movieId == movieId);
    } catch (e) {
      existing = null;
    }

    if (existing != null) {
      // Update
      state = state.map((r) {
        if (r.movieId != movieId) return r;
        return r.copyWith(
          userRating: userRating,
          reviewText: reviewText,
          timestamp: DateTime.now(),
        );
      }).toList();
    } else {
      // Add
      final review = UserReview(
        movieId: movieId,
        movieTitle: movieTitle,
        userRating: userRating,
        reviewText: reviewText,
        timestamp: DateTime.now(),
      );
      state = [...state, review];
    }

    await _save();
  }

  /// Rimuove una review
  Future<void> removeReview(String movieId) async {
    state = state.where((r) => r.movieId != movieId).toList();
    await _save();
  }

  /// Ottiene review per un film
  UserReview? getReview(String movieId) {
    try {
      return state.firstWhere(
        (r) => r.movieId == movieId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Salva su disk
  Future<void> _save() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.init();
    await storage.saveUserReviews(state);
  }
}

final reviewsProvider = NotifierProvider<ReviewsNotifier, List<UserReview>>(ReviewsNotifier.new);
