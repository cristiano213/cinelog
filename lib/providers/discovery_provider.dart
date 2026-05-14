import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import 'movie_provider.dart';

/// Stato per la paginazione della Discovery
class DiscoveryState {
  final List<Movie> movies;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasReachedMax;

  DiscoveryState({
    this.movies = const [],
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });

  DiscoveryState copyWith({
    List<Movie>? movies,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasReachedMax,
  }) {
    return DiscoveryState(
      movies: movies ?? this.movies,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

/// Notifier per gestire la lista infinita di film
class DiscoveryNotifier extends FamilyAsyncNotifier<DiscoveryState, MovieCategory> {
  
  @override
  FutureOr<DiscoveryState> build(MovieCategory arg) async {
    // Caricamento iniziale (Pagina 1)
    final repo = ref.read(movieRepositoryProvider);
    final firstPage = await repo.getMoviesByCategory(arg, page: 1);
    
    return DiscoveryState(
      movies: firstPage,
      currentPage: 1,
      hasReachedMax: firstPage.isEmpty,
    );
  }

  /// Carica la pagina successiva
  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || currentState.hasReachedMax) return;

    // Imposta lo stato di caricamento
    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final repo = ref.read(movieRepositoryProvider);
      final nextPage = currentState.currentPage + 1;
      
      final newMovies = await repo.getMoviesByCategory(arg, page: nextPage);

      if (newMovies.isEmpty) {
        state = AsyncData(currentState.copyWith(
          isLoadingMore: false, 
          hasReachedMax: true,
        ));
      } else {
        state = AsyncData(currentState.copyWith(
          movies: [...currentState.movies, ...newMovies],
          currentPage: nextPage,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }
}

/// Provider globale per la Discovery Paginata
final discoveryProvider = AsyncNotifierProviderFamily<DiscoveryNotifier, DiscoveryState, MovieCategory>(
  () => DiscoveryNotifier(),
);