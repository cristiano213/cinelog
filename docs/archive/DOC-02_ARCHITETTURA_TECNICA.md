# CineLog 2.0 — Architettura Tecnica e Modelli Dati

**Versione:** 1.0  
**Data:** Maggio 2026  
**Scope:** Architettura Riverpod, modelli Dart, flussi di dati, persistenza  
**Audience:** Developer che implementa le feature

---

## Indice

1. [Overview Architettura](#overview)
2. [Struttura Cartelle del Progetto](#structure)
3. [Modelli Dart Dettagliati](#modelli)
4. [Provider Riverpod: Catalogo Completo](#providers)
5. [Notifier Customizzati](#notifiers)
6. [AsyncValue e Error Handling](#asyncvalue)
7. [Flussi di Dato Critici](#flussi)
8. [Persistence Layer (JSON + shared_preferences)](#persistence)

---

## <a id="overview"></a>1. Overview dell'Architettura

### 1.1 Pilastri Tecnici

```
┌─────────────────────────────────────────────────────┐
│            Flutter UI Layer (Widgets)               │
│  (DiscoveryScreen, DetailScreen, DashboardScreen)  │
└──────────────────────┬──────────────────────────────┘
                       │ observa/modifica stato
┌──────────────────────▼──────────────────────────────┐
│   Riverpod State Management                         │
│  ┌─────────────────────────────────────────────┐   │
│  │ Provider Layer:                             │   │
│  │ - movieListProvider (FutureProvider)       │   │
│  │ - wishlistProvider (Notifier)              │   │
│  │ - financeProvider (Notifier)               │   │
│  │ - reviewsProvider (Notifier)               │   │
│  │ - cinemateNotesProvider (Notifier)        │   │
│  └─────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────┘
                       │ lettura/scrittura
┌──────────────────────▼──────────────────────────────┐
│   Repository / Local Storage Layer                 │
│  ┌─────────────────────────────────────────────┐   │
│  │ MovieRepository (TMDB API integration)      │   │
│  │ LocalStorageService (shared_preferences)    │   │
│  │ JsonSerializer (dart:convert)               │   │
│  └─────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────┘
                       │
                ┌──────┴───────┬──────────┐
                │              │          │
        ┌───────▼──────┐  ┌────▼─────┐  │
        │  TMDB API    │  │   File   │  │
        │              │  │   System │  │
        └──────────────┘  └──────────┘  │
                          (shared_prefs)│
```

### 1.2 Filosofia

- **Single Source of Truth**: Ogni stato ha un unico provider
- **Immutabilità**: I modelli sono immutabili (final fields)
- **Async-First**: Ogni operazione esterna è async (API, disk I/O)
- **Error Handling**: AsyncValue.error per ogni fallimento
- **No Side Effects**: I provider sono pure (stessi input = stesso output)

---

## <a id="structure"></a>2. Struttura Cartelle del Progetto

```
cinelog/
├── lib/
│   ├── main.dart                          # Entry point, ProviderScope
│   │
│   ├── models/                            # Dart classes immutabili
│   │   ├── movie.dart                     # Movie (da TMDB) + smallPosterUrl/fullPosterUrl
│   │   ├── finance_entry.dart             # FinanceLedgerEntry
│   │   ├── user_review.dart               # UserReview
│   │   └── cinema_note.dart               # CinemaNote
│   │
│   ├── repositories/                      # Data access layer
│   │   ├── movie_repository.dart          # TMDB API + caching 5min
│   │   └── local_storage_service.dart     # shared_preferences wrapper
│   │
│   ├── providers/                         # Riverpod state management
│   │   ├── movie_provider.dart            # movieListProvider, genreMoviesProvider, movieRepositoryProvider
│   │   ├── discovery_provider.dart        # discoveryProvider (paginazione infinita)
│   │   ├── wishlist_provider.dart         # Notifier<List<Movie>>
│   │   ├── finance_provider.dart          # Notifier<List<FinanceLedgerEntry>>
│   │   ├── reviews_provider.dart          # Notifier<List<UserReview>>
│   │   ├── cinema_notes_provider.dart     # Notifier<List<CinemaNote>>
│   │   └── stats_provider.dart            # Provider computed AppStats
│   │
│   ├── screens/                           # UI screens
│   │   ├── discovery_screen.dart          # 6 sezioni carousel + "Vedi tutti"
│   │   ├── search_screen.dart             # Ricerca testo + filtri genere + infinite scroll
│   │   ├── movie_detail_screen.dart       # Dettaglio film + Hero
│   │   ├── dashboard_screen.dart          # Cronologia visioni + stats
│   │   ├── social_notes_screen.dart       # Review + appunti cinema
│   │   └── main_navigation_screen.dart    # BottomNavigationBar (3 tab)
│   │
│   ├── widgets/                           # Componenti riutilizzabili
│   │   ├── movie_card.dart                # Card con CachedNetworkImage (w185)
│   │   ├── stat_card.dart
│   │   ├── rating_comparison_chart.dart   # CustomPaint (da implementare)
│   │   └── register_cinema_visit_dialog.dart
│   │
│   └── core/
│       └── constants.dart                 # ⚠️ TMDB API key, baseUrl, timeout
│
├── docs/
│   ├── DOC-01_VISIONE_ANALISI_FUNZIONALE.md
│   ├── DOC-02_ARCHITETTURA_TECNICA.md     # ← Questo file
│   ├── DOC-03_ROADMAP_SVILUPPO.md
│   ├── DOC-04_SCHEMA_DATI_PERSISTENZA.md
│   ├── DOC-05_GUIDA_TMDB_API.md
│   └── DOC-06_NOTE_TECNICHE_RIVERPOD.md
│
└── pubspec.yaml
```

---

## <a id="modelli"></a>3. Modelli Dart Dettagliati

### 3.1 Movie (Da TMDB)

```dart
// lib/models/movie.dart

class Movie {
  final String id;              // TMDB ID (numerico come String)
  final String title;
  final String description;     // Sinossi completa
  final String posterUrl;       // https://image.tmdb.org/t/p/w500/...
  final String backdropUrl;     // https://image.tmdb.org/t/p/original/...
  final double rating;          // Voto TMDB 0-10
  final int durationMinutes;
  final DateTime releaseDate;
  final String genre;           // "Action, Sci-Fi, Thriller"
  final List<String> cast;      // ["Brad Pitt", "Edward Norton"]

  const Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.durationMinutes,
    required this.releaseDate,
    required this.genre,
    required this.cast,
  });

  // Computed properties (per UI)
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String get releaseYear => releaseDate.year.toString();

  String get castString => cast.take(3).join(', ');  // Primi 3 attori

  // JSON serialization
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'].toString(),
      title: json['title'] ?? 'Unknown',
      description: json['overview'] ?? '',
      posterUrl: json['poster_path'] ?? '',
      backdropUrl: json['backdrop_path'] ?? '',
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      durationMinutes: json['runtime'] ?? 0,
      releaseDate: DateTime.tryParse(json['release_date'] ?? '') ?? DateTime.now(),
      genre: json['genres']?.map((g) => g['name']).join(', ') ?? 'Unknown',
      cast: List<String>.from(json['credits']?['cast']?.map((c) => c['name']) ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': description,
      'poster_path': posterUrl,
      'backdrop_path': backdropUrl,
      'vote_average': rating,
      'runtime': durationMinutes,
      'release_date': releaseDate.toIso8601String(),
      'genre': genre,
      'cast': cast,
    };
  }

  // Copia con override (utile per modifiche)
  Movie copyWith({
    String? id,
    String? title,
    String? description,
    String? posterUrl,
    String? backdropUrl,
    double? rating,
    int? durationMinutes,
    DateTime? releaseDate,
    String? genre,
    List<String>? cast,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      releaseDate: releaseDate ?? this.releaseDate,
      genre: genre ?? this.genre,
      cast: cast ?? this.cast,
    );
  }
}
```

### 3.2 FinanceLedgerEntry (Nuovo)

```dart
// lib/models/finance_entry.dart

class FinanceLedgerEntry {
  final String id;              // UUID generato localmente
  final String movieId;         // Link a Movie
  final String movieTitle;      // Snapshot (nel caso il film fosse rimosso da TMDB)
  final String cinema;          // "Cineworld Kings Road"
  final double priceEur;        // 9.50
  final DateTime dateTime;      // Quando visto
  final int count;              // Default 1, aumenta se vedo 2 volte

  const FinanceLedgerEntry({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.cinema,
    required this.priceEur,
    required this.dateTime,
    this.count = 1,
  });

  // Computed
  String get formattedPrice => '€${priceEur.toStringAsFixed(2)}';
  String get monthKey => '${dateTime.year}-${dateTime.month}';  // Per aggregazioni
  int get dayOfMonth => dateTime.day;
  
  // Totale per questa entry (se count > 1)
  double get totalPrice => priceEur * count;

  // JSON serialization
  factory FinanceLedgerEntry.fromJson(Map<String, dynamic> json) {
    return FinanceLedgerEntry(
      id: json['id'] ?? '',
      movieId: json['movieId'] ?? '',
      movieTitle: json['movieTitle'] ?? 'Unknown',
      cinema: json['cinema'] ?? 'Unknown Cinema',
      priceEur: (json['priceEur'] ?? 0.0).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
      count: json['count'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'movieTitle': movieTitle,
      'cinema': cinema,
      'priceEur': priceEur,
      'dateTime': dateTime.toIso8601String(),
      'count': count,
    };
  }

  FinanceLedgerEntry copyWith({
    String? id,
    String? movieId,
    String? movieTitle,
    String? cinema,
    double? priceEur,
    DateTime? dateTime,
    int? count,
  }) {
    return FinanceLedgerEntry(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      cinema: cinema ?? this.cinema,
      priceEur: priceEur ?? this.priceEur,
      dateTime: dateTime ?? this.dateTime,
      count: count ?? this.count,
    );
  }
}
```

### 3.3 UserReview (Nuovo)

```dart
// lib/models/user_review.dart

class UserReview {
  final String movieId;
  final String movieTitle;      // Snapshot
  final int userRating;         // 0-10 (0 = non votato)
  final String reviewText;      // Testo libero (max 500 char)
  final DateTime timestamp;

  const UserReview({
    required this.movieId,
    required this.movieTitle,
    required this.userRating,
    required this.reviewText,
    required this.timestamp,
  });

  // Computed
  bool get hasRating => userRating > 0;
  bool get isPositive => userRating >= 7;
  bool get hasReviewText => reviewText.trim().isNotEmpty;

  // JSON
  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      movieId: json['movieId'] ?? '',
      movieTitle: json['movieTitle'] ?? 'Unknown',
      userRating: json['userRating'] ?? 0,
      reviewText: json['reviewText'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'movieTitle': movieTitle,
      'userRating': userRating,
      'reviewText': reviewText,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  UserReview copyWith({
    String? movieId,
    String? movieTitle,
    int? userRating,
    String? reviewText,
    DateTime? timestamp,
  }) {
    return UserReview(
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      userRating: userRating ?? this.userRating,
      reviewText: reviewText ?? this.reviewText,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
```

### 3.4 CinemaNote (Nuovo)

```dart
// lib/models/cinema_note.dart

class CinemaNote {
  final String cinemaName;      // "Cineworld Kings Road"
  final String note;            // Appunti utente (es. "sala comoda")
  final double avgPriceEur;     // Calcolato da Finance
  final int visitCount;         // Aggregato da Finance
  final DateTime lastVisit;

  const CinemaNote({
    required this.cinemaName,
    required this.note,
    required this.avgPriceEur,
    required this.visitCount,
    required this.lastVisit,
  });

  String get frequencyLabel => '$visitCount volte';

  // JSON
  factory CinemaNote.fromJson(Map<String, dynamic> json) {
    return CinemaNote(
      cinemaName: json['cinemaName'] ?? 'Unknown',
      note: json['note'] ?? '',
      avgPriceEur: (json['avgPriceEur'] ?? 0.0).toDouble(),
      visitCount: json['visitCount'] ?? 0,
      lastVisit: DateTime.parse(json['lastVisit'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cinemaName': cinemaName,
      'note': note,
      'avgPriceEur': avgPriceEur,
      'visitCount': visitCount,
      'lastVisit': lastVisit.toIso8601String(),
    };
  }

  CinemaNote copyWith({
    String? cinemaName,
    String? note,
    double? avgPriceEur,
    int? visitCount,
    DateTime? lastVisit,
  }) {
    return CinemaNote(
      cinemaName: cinemaName ?? this.cinemaName,
      note: note ?? this.note,
      avgPriceEur: avgPriceEur ?? this.avgPriceEur,
      visitCount: visitCount ?? this.visitCount,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }
}
```

### 3.5 Wishlist e LibraryArchive (Container Models)

```dart
// lib/models/wishlist.dart

class Wishlist {
  final List<Movie> films;

  const Wishlist({required this.films});

  bool contains(String movieId) => films.any((f) => f.id == movieId);

  Wishlist addMovie(Movie movie) {
    if (contains(movie.id)) return this;  // No duplicates
    return Wishlist(films: [...films, movie]);
  }

  Wishlist removeMovie(String movieId) {
    return Wishlist(films: films.where((f) => f.id != movieId).toList());
  }

  // JSON
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

// lib/models/library_archive.dart

class LibraryArchive {
  final List<Movie> films;

  const LibraryArchive({required this.films});

  bool contains(String movieId) => films.any((f) => f.id == movieId);

  LibraryArchive addMovie(Movie movie) {
    if (contains(movie.id)) return this;
    return LibraryArchive(films: [...films, movie]);
  }

  // JSON simile a Wishlist
  // ...
}
```

---

## <a id="providers"></a>4. Provider Riverpod: Catalogo Completo

### 4.1 DISCOVERY Provider

```dart
// lib/providers/movie_provider.dart

enum MovieCategory { nowPlaying, upcoming, topRated, trending }

final movieRepositoryProvider = Provider((ref) => MovieRepository());

// Caroselli: categoria + pagina
final movieListProvider = FutureProvider.family<List<Movie>, (MovieCategory, int)>(
  (ref, args) async {
    final (category, page) = args;
    return ref.watch(movieRepositoryProvider).getMoviesByCategory(category, page: page);
  },
);

// Caroselli per genere TMDB (genreId es. 28 = Azione)
final genreMoviesProvider = FutureProvider.family<List<Movie>, int>(
  (ref, genreId) async {
    return ref.watch(movieRepositoryProvider).getMoviesByGenre(genreId);
  },
);
```

**Uso in widget (carosello):**
```dart
final moviesAsync = ref.watch(movieListProvider((MovieCategory.nowPlaying, 1)));
// oppure
final moviesAsync = ref.watch(genreMoviesProvider(28)); // Azione
```

### 4.1b DISCOVERY Paginata (AsyncNotifierProviderFamily)

```dart
// lib/providers/discovery_provider.dart
// Usata per liste verticali con scroll infinito

final discoveryProvider = AsyncNotifierProviderFamily<DiscoveryNotifier, DiscoveryState, MovieCategory>(
  () => DiscoveryNotifier(),
);

// DiscoveryState contiene: movies, currentPage, isLoading, hasReachedMax
// Notifier espone: loadNextPage()
```

### 4.1c SEARCH Provider (StateNotifier.autoDispose)

```dart
// lib/screens/search_screen.dart
// Scoped alla vita di SearchScreen (autoDispose → reset quando si esce)

final searchNotifierProvider = StateNotifierProvider.autoDispose<SearchNotifier, SearchPageState>(
  (ref) => SearchNotifier(ref.read(movieRepositoryProvider)),
);
```

`SearchNotifier` gestisce: query testuale, set di genreId attivi, categoria iniziale, paginazione con generation counter (evita risultati stale da richieste parallele).

**Logica fetch (priorità):**
1. `query.isNotEmpty` → `searchMovies(query, page)`
2. `genreIds.isNotEmpty` → `getMoviesByGenres(genreIds, page)` (AND su TMDB)
3. `category != null` → `getMoviesByCategory(category, page)`
4. default → `MovieCategory.trending`

**Init dal widget:**
```dart
// initState — deve essere posticipato con addPostFrameCallback
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(searchNotifierProvider.notifier).initialize(
    category: widget.initialCategory,
    genreIds: widget.initialGenreIds,
  );
});
```

### 4.2 LIBRARY Provider (Notifier)

```dart
// lib/providers/wishlist_provider.dart

class WishlistNotifier extends Notifier<Wishlist> {
  late LocalStorageService _storage;

  @override
  Wishlist build() {
    _storage = LocalStorageService();
    // Carica wishlist salvata
    return _storage.loadWishlist();
  }

  // Aggiungi film a wishlist
  Future<void> addMovie(Movie movie) async {
    state = state.addMovie(movie);
    await _storage.saveWishlist(state);
  }

  // Rimuovi
  Future<void> removeMovie(String movieId) async {
    state = state.removeMovie(movieId);
    await _storage.saveWishlist(state);
  }

  // Controlla se esiste
  bool contains(String movieId) => state.contains(movieId);
}

final wishlistProvider = NotifierProvider<WishlistNotifier, Wishlist>(() {
  return WishlistNotifier();
});

// Simile per library_archive_provider.dart
```

### 4.3 FINANCE Provider (Notifier)

```dart
// lib/providers/finance_provider.dart

class FinanceLedgerNotifier extends Notifier<List<FinanceLedgerEntry>> {
  late LocalStorageService _storage;

  @override
  List<FinanceLedgerEntry> build() {
    _storage = LocalStorageService();
    return _storage.loadFinanceLedger();
  }

  // Aggiungi nuova visione
  Future<void> addVisione(String movieId, String movieTitle, String cinema, double price) async {
    final newEntry = FinanceLedgerEntry(
      id: Uuid().v4(),  // UUID unico
      movieId: movieId,
      movieTitle: movieTitle,
      cinema: cinema,
      priceEur: price,
      dateTime: DateTime.now(),
      count: 1,
    );
    
    state = [...state, newEntry];
    await _storage.saveFinanceLedger(state);
  }

  // Incrementa count se stesso film, stesso cinema, stesso giorno
  Future<void> incrementVisione(String movieId, String cinema, double price) async {
    final today = DateTime.now();
    final existing = state.firstWhereOrNull((e) =>
      e.movieId == movieId &&
      e.cinema == cinema &&
      e.dateTime.year == today.year &&
      e.dateTime.month == today.month &&
      e.dateTime.day == today.day
    );

    if (existing != null) {
      // Aggiorna count
      state = state.map((e) =>
        e.id == existing.id ? e.copyWith(count: e.count + 1) : e
      ).toList();
    } else {
      // Nuova entry
      await addVisione(movieId, '', cinema, price);
    }
    await _storage.saveFinanceLedger(state);
  }

  // Elimina voce
  Future<void> removeEntry(String entryId) async {
    state = state.where((e) => e.id != entryId).toList();
    await _storage.saveFinanceLedger(state);
  }

  // Aggiorna entry (modifica prezzo/cinema)
  Future<void> updateEntry(String entryId, {double? newPrice, String? newCinema}) async {
    state = state.map((e) =>
      e.id == entryId ? e.copyWith(
        priceEur: newPrice ?? e.priceEur,
        cinema: newCinema ?? e.cinema,
      ) : e
    ).toList();
    await _storage.saveFinanceLedger(state);
  }

  // Statistiche calcolate (computed)
  double get totalSpent => state.fold(0.0, (sum, e) => sum + e.totalPrice);
  int get totalCount => state.fold(0, (sum, e) => sum + e.count);
  double get avgPrice => totalCount == 0 ? 0 : totalSpent / totalCount;
  Set<String> get cinemaList => state.map((e) => e.cinema).toSet();
}

final financeProvider = NotifierProvider<FinanceLedgerNotifier, List<FinanceLedgerEntry>>(() {
  return FinanceLedgerNotifier();
});
```

### 4.4 REVIEWS Provider (Notifier)

```dart
// lib/providers/reviews_provider.dart

class UserReviewsNotifier extends Notifier<List<UserReview>> {
  late LocalStorageService _storage;

  @override
  List<UserReview> build() {
    _storage = LocalStorageService();
    return _storage.loadUserReviews();
  }

  Future<void> addOrUpdateReview(String movieId, String movieTitle, int rating, String text) async {
    final existing = state.firstWhereOrNull((r) => r.movieId == movieId);
    
    if (existing != null) {
      // Update
      state = state.map((r) =>
        r.movieId == movieId ? r.copyWith(
          userRating: rating,
          reviewText: text,
          timestamp: DateTime.now(),
        ) : r
      ).toList();
    } else {
      // Insert
      final newReview = UserReview(
        movieId: movieId,
        movieTitle: movieTitle,
        userRating: rating,
        reviewText: text,
        timestamp: DateTime.now(),
      );
      state = [...state, newReview];
    }
    await _storage.saveUserReviews(state);
  }

  UserReview? getReview(String movieId) =>
    state.firstWhereOrNull((r) => r.movieId == movieId);

  // Statistiche
  double get avgRating => state.isEmpty ? 0 :
    state.fold(0.0, (sum, r) => sum + r.userRating) / state.length;

  int get totalReviews => state.length;
}

final reviewsProvider = NotifierProvider<UserReviewsNotifier, List<UserReview>>(() {
  return UserReviewsNotifier();
});
```

### 4.5 CINEMA NOTES Provider (Notifier)

```dart
// lib/providers/cinema_notes_provider.dart

class CinemaNotesNotifier extends Notifier<List<CinemaNote>> {
  late LocalStorageService _storage;

  @override
  List<CinemaNote> build() {
    _storage = LocalStorageService();
    // Nota: i dati vengono ricalcolati da Finance
    _recalculateFromLedger();
    return _storage.loadCinemaNotes();
  }

  // Aggiorna appunti su un cinema
  Future<void> updateNote(String cinemaName, String note) async {
    final existing = state.firstWhereOrNull((c) => c.cinemaName == cinemaName);
    
    if (existing != null) {
      state = state.map((c) =>
        c.cinemaName == cinemaName ? c.copyWith(note: note) : c
      ).toList();
    }
    await _storage.saveCinemaNotes(state);
  }

  // Ricalcola statistiche da Finance
  void _recalculateFromLedger() {
    // Legge financeProvider e aggrega cinema
    // TODO: implementare in stato futuro
  }
}

final cinemaNotesProvider = NotifierProvider<CinemaNotesNotifier, List<CinemaNote>>(() {
  return CinemaNotesNotifier();
});
```

### 4.6 STATS Provider (Rimodelato)

```dart
// lib/providers/stats_provider.dart

class AppStatsNotifier extends Notifier<AppStats> {
  @override
  AppStats build() {
    // Calcola statistiche aggregando i dati
    final financeList = ref.watch(financeProvider);
    final reviews = ref.watch(reviewsProvider);
    
    return AppStats.fromData(financeList, reviews);
  }
}

class AppStats {
  final int totalMoviesWatched;
  final int totalMinutesWatched;
  final double totalSpent;
  final double avgTicketCost;
  final double avgUserRating;
  final int totalReviews;
  final Map<String, int> genreDistribution;
  final Map<String, double> monthlySpendings;  // "2026-05": 85.50

  const AppStats({
    required this.totalMoviesWatched,
    required this.totalMinutesWatched,
    required this.totalSpent,
    required this.avgTicketCost,
    required this.avgUserRating,
    required this.totalReviews,
    required this.genreDistribution,
    required this.monthlySpendings,
  });

  // Computed
  String get formattedTotalSpent => '€${totalSpent.toStringAsFixed(2)}';
  String get formattedAvgCost => '€${avgTicketCost.toStringAsFixed(2)}';

  // Factory: costruisce da financeList e reviews
  factory AppStats.fromData(List<FinanceLedgerEntry> ledger, List<UserReview> reviews) {
    final totalSpent = ledger.fold(0.0, (sum, e) => sum + e.totalPrice);
    final totalCount = ledger.fold(0, (sum, e) => sum + e.count);
    
    // Aggregare spesa per mese
    final monthlyMap = <String, double>{};
    for (var entry in ledger) {
      final key = entry.monthKey;
      monthlyMap[key] = (monthlyMap[key] ?? 0) + entry.totalPrice;
    }

    return AppStats(
      totalMoviesWatched: totalCount,
      totalMinutesWatched: 0,  // TODO: da finire
      totalSpent: totalSpent,
      avgTicketCost: totalCount == 0 ? 0 : totalSpent / totalCount,
      avgUserRating: reviews.isEmpty ? 0 :
        reviews.fold(0, (sum, r) => sum + r.userRating) / reviews.length,
      totalReviews: reviews.length,
      genreDistribution: {},  // TODO: aggregare da film
      monthlySpendings: monthlyMap,
    );
  }
}

final statsProvider = NotifierProvider<AppStatsNotifier, AppStats>(() {
  return AppStatsNotifier();
});
```

---

## <a id="notifiers"></a>5. Notifier Customizzati (Approfondimento)

### 5.1 Anatomia di un Notifier

```dart
class WishlistNotifier extends Notifier<Wishlist> {
  // La parte "setup" dell'operazione
  late LocalStorageService _storage;

  // Metodo obbligatorio: restituisce lo stato iniziale
  @override
  Wishlist build() {
    _storage = LocalStorageService();
    return _storage.loadWishlist();  // Carica da disk al boot
  }

  // Metodo che modifica lo stato (mutazione atomica)
  Future<void> addMovie(Movie movie) async {
    // 1. Modifichiamo lo stato
    state = state.addMovie(movie);

    // 2. Persisti sul disco
    await _storage.saveWishlist(state);

    // 3. Se la save fallisce, l'eccezione propaga (il caller deve gestire)
  }
}
```

**Flusso:**
1. Widget consume il provider
2. Provider chiama `build()` → carica stato iniziale
3. Widget chiama metodo del Notifier (es. `addMovie()`)
4. Notifier modifica `state`
5. Tutti i widget che osservano il provider vengono notificati automaticamente
6. Persistenza su disco avviene in background

### 5.2 Error Handling in Notifier

```dart
Future<void> addMovieWithErrorHandling(Movie movie) async {
  try {
    state = state.addMovie(movie);
    await _storage.saveWishlist(state);
  } catch (e) {
    // Rollback: ripristina lo stato precedente se salva fallisce
    state = state.removeMovie(movie.id);
    rethrow;  // Propaga errore al caller
  }
}
```

Nel widget:

```dart
onPressed: () async {
  try {
    await ref.read(wishlistProvider.notifier).addMovie(movie);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aggiunto a Wishlist')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
    );
  }
}
```

### 5.3 Invalidation e Refresh

Se uno stato dipende da un altro, usiamo `ref.invalidate()`:

```dart
// In Finance Notifier, quando elimino una visione
Future<void> removeEntry(String entryId) async {
  state = state.where((e) => e.id != entryId).toList();
  await _storage.saveFinanceLedger(state);
  
  // Invalida i provider che dipendono da me
  ref.invalidate(statsProvider);  // I stats ora si ricalcolano
  ref.invalidate(cinemaNotesProvider);  // Anche i cinema notes
}
```

---

## <a id="asyncvalue"></a>6. AsyncValue e Error Handling

### 6.1 AsyncValue: The Pattern

Quando un provider carica da API, lo stato è un `AsyncValue<T>`:

```dart
// Il provider ritorna AsyncValue<List<Movie>>
final movieListProvider = FutureProvider<List<Movie>>((ref) async {
  // Se tutto va bene → AsyncValue.data(movies)
  // Se errore → AsyncValue.error(exception)
  // Mentre carica → AsyncValue.loading()
});
```

### 6.2 Gestione nel Widget

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final moviesAsync = ref.watch(movieListProvider);

  return moviesAsync.when(
    // Caso 1: Dati disponibili
    data: (movies) => ListView(
      children: movies.map((m) => MovieCard(movie: m)).toList(),
    ),
    
    // Caso 2: Caricamento in corso
    loading: () => const Center(
      child: CircularProgressIndicator(),
    ),
    
    // Caso 3: Errore
    error: (error, stackTrace) => Center(
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text('Errore: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(movieListProvider),
            child: const Text('Riprova'),
          ),
        ],
      ),
    ),
  );
}
```

### 6.3 AsyncValue.whenData (Syntactic Sugar)

```dart
// Shorthand se ti importa solo del caso "data"
final movies = ref.watch(movieListProvider).whenData((data) => data).value;

// O più diretto:
final asyncMovies = ref.watch(movieListProvider);
if (asyncMovies.hasValue) {
  final movies = asyncMovies.value!;  // Safe perché hasValue
  // usa movies...
}
```

---

## <a id="flussi"></a>7. Flussi di Dato Critici

### 7.1 Flusso: Discovery → DetailScreen → Registra Visione

```
┌─ User in DiscoveryScreen
│  └─ ref.watch(movieListProvider(MovieCategory.nowPlaying))
│     └─ AsyncValue.data([Movie(...), Movie(...), ...])
│
├─ Tap su film poster
├─ Navigator.push(MovieDetailScreen(movie))
│
├─ MovieDetailScreen build:
│  ├─ ref.watch(reviewsProvider) → lista review
│  │
│  └─ ref.watch(financeProvider) → lista visioni
│     ├─ Per mostrare: "Hai visto questo film? Sì, XX volte"
│
├─ Tap "REGISTRA VISIONE AL CINEMA"
├─ Dialog appare (prezzo + cinema)
│
├─ User inserisce dati, tap "Conferma"
│  │
│  ├─ ref.read(financeProvider.notifier).addVisione(...)
│  │  ├─ Crea FinanceLedgerEntry
│  │  ├─ Salva in shared_preferences
│  │  └─ ref.invalidate(statsProvider)
│  │
│  └─ ref.read(libraryArchiveProvider.notifier).addMovie(...)
│     └─ Aggiunge il film all'archivio visti (opzionale)
│
└─ Snackbar: "Visione registrata €X.XX presso Cinema Y"
```

### 7.2 Flusso: Cambio Tab → Dashboard

```
┌─ User tap tab "Dashboard" in BottomNavigationBar
│
├─ DashboardScreen build:
│  ├─ ref.watch(financeProvider)
│  │  └─ Carica dalla shared_preferences
│  │
│  ├─ ref.watch(statsProvider)
│  │  └─ Ricalcola da financeProvider + reviewsProvider
│  │
│  └─ ref.watch(cinemaNotesProvider)
│     └─ Carica cinema notes con aggregazioni
│
├─ Render stat cards
│  ├─ totalSpent = stats.totalSpent
│  ├─ avgPrice = stats.avgTicketCost
│  ├─ cinemaList = finance.cinemaList.length
│
├─ Render cronologia
│  └─ ListView.builder di financeProvider.state
│     └─ Ogni entry: [Film - Cinema - €Price] [⋮ delete]
│
└─ User tap "FILTRI"
   ├─ BottomSheet apre
   ├─ User seleziona filtri (cinema, genere, periodo)
   └─ state.where((e) => ...) filtra la lista
```

---

## <a id="persistence"></a>8. Persistence Layer

### 8.1 LocalStorageService (Wrapper su shared_preferences)

```dart
// lib/repositories/local_storage_service.dart

class LocalStorageService {
  static const String _wishlistKey = 'wishlist';
  static const String _archiveKey = 'library_archive';
  static const String _financeKey = 'finance_ledger';
  static const String _reviewsKey = 'user_reviews';
  static const String _notesKey = 'cinema_notes';

  late SharedPreferences _prefs;

  // Lazy initialization
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===== WISHLIST =====
  Wishlist loadWishlist() {
    _ensureInit();
    final json = _prefs.getString(_wishlistKey);
    if (json == null || json.isEmpty) {
      return const Wishlist(films: []);
    }
    return Wishlist.fromJson(jsonDecode(json));
  }

  Future<void> saveWishlist(Wishlist wishlist) async {
    await _init();
    await _prefs.setString(_wishlistKey, jsonEncode(wishlist.toJson()));
  }

  // ===== FINANCE LEDGER =====
  List<FinanceLedgerEntry> loadFinanceLedger() {
    _ensureInit();
    final json = _prefs.getString(_financeKey);
    if (json == null || json.isEmpty) {
      return [];
    }
    final list = jsonDecode(json) as List;
    return list.map((item) => FinanceLedgerEntry.fromJson(item)).toList();
  }

  Future<void> saveFinanceLedger(List<FinanceLedgerEntry> ledger) async {
    await _init();
    final jsonList = ledger.map((e) => e.toJson()).toList();
    await _prefs.setString(_financeKey, jsonEncode(jsonList));
  }

  // ===== USER REVIEWS =====
  List<UserReview> loadUserReviews() {
    _ensureInit();
    final json = _prefs.getString(_reviewsKey);
    if (json == null || json.isEmpty) {
      return [];
    }
    final list = jsonDecode(json) as List;
    return list.map((item) => UserReview.fromJson(item)).toList();
  }

  Future<void> saveUserReviews(List<UserReview> reviews) async {
    await _init();
    final jsonList = reviews.map((r) => r.toJson()).toList();
    await _prefs.setString(_reviewsKey, jsonEncode(jsonList));
  }

  // Simili per cinema_notes, library_archive, ...

  void _ensureInit() {
    if (!_prefs.initialized) {
      throw Exception('SharedPreferences not initialized');
    }
  }
}
```

### 8.2 JSON Serialization Strategy

Ogni modello implementa:
- `fromJson(Map<String, dynamic>)` → Dart object
- `toJson() → Map<String, dynamic>`

Nel LocalStorageService:
- Load: JSON string → `jsonDecode()` → fromJson() → Dart object
- Save: Dart object → toJson() → `jsonEncode()` → JSON string → disk

### 8.3 Backup / Export (Opzionale)

```dart
// Esporta tutti i dati come single JSON
Future<String> exportAllData() async {
  final allData = {
    'wishlist': loadWishlist().toJson(),
    'archive': loadLibraryArchive().toJson(),
    'finance': loadFinanceLedger().map((e) => e.toJson()).toList(),
    'reviews': loadUserReviews().map((r) => r.toJson()).toList(),
    'cinema_notes': loadCinemaNotes().map((n) => n.toJson()).toList(),
    'export_timestamp': DateTime.now().toIso8601String(),
  };
  return jsonEncode(allData);
}
```

L'utente può copiare il JSON, conservarlo, e ripristinarlo su un altro device.

---

## 9. Conclusione

L'architettura è **modulare, testabile, e scalabile**:

- **Modelli**: Immutabili, JSON-serializzabili
- **Provider**: Single source of truth per ogni dato
- **Notifier**: Gestiscono logica + persistenza
- **LocalStorageService**: Interfaccia verso shared_preferences
- **AsyncValue**: Gestisce loading/error automaticamente

Nel prossimo documento (DOC-03), definiremo il roadmap di implementazione passo dopo passo.

---

**Documento redatto: Maggio 2026**  
**Prossimo:** DOC-03 — Roadmap di Sviluppo
