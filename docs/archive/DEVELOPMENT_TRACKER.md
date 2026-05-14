# CineLog — Development Tracker

**Aggiornato:** Maggio 2026  
**Stato:** ✅ Fase 1-3 complete | ⚠️ Fase 4 in progress (~50%) | ⏳ Fase 5 pianificata

---

## Task Corrente

### ⚠️ Fase 4 — UI Avanzate

| Task | File | Stato |
|------|------|-------|
| MovieDetailScreen — sezione review (rating + testo) | `lib/screens/movie_detail_screen.dart` | ⏳ Da fare |
| MovieDetailScreen — confronto voto utente vs TMDB | `lib/widgets/rating_comparison_chart.dart` | ⏳ Da fare |
| DashboardScreen — cronologia scrollabile + elimina | `lib/screens/dashboard_screen.dart` | ⏳ Da fare |
| DashboardScreen — filtri (cinema, periodo) | `lib/screens/dashboard_screen.dart` | ⏳ Da fare |
| SocialNotesScreen — film votati + appunti cinema | `lib/screens/social_notes_screen.dart` | ⏳ Da fare |
| CustomPaint bar chart (spesa mensile) | `lib/widgets/rating_comparison_chart.dart` | ⏳ Da fare |

---

## Stato Fasi

| Fase | Status | Note |
|------|--------|------|
| **Fase 1** — Modelli + struttura | ✅ DONE | 6 modelli, LocalStorageService, 6 provider |
| **Fase 2** — Persistenza locale | ✅ DONE | Load/save su disk, UUID, init provider |
| **Fase 3** — TMDB API + Discovery | ✅ DONE | Paginazione, search, carousel, error handling |
| **Fase 4** — UI avanzate | ⚠️ PARTIAL (~50%) | Discovery/Search completi; mancano review, dashboard, social |
| **Fase 5** — Testing + polish | ⏳ PLANNED | Test coverage 0%, dopo Fase 4 |

**Tempo rimanente stimato:** ~6-8 giorni part-time

---

## Blockers / Issues

| Issue | Severity | Status |
|-------|----------|--------|
| TMDB API key non configurata in `constants.dart` | 🔴 HIGH | ⏳ Da fare (blocca tutto) |
| MovieDetailScreen — sezione review/rating | 🟡 MEDIUM | ⏳ Fase 4 |
| DashboardScreen — filtri e lista visioni | 🟡 MEDIUM | ⏳ Fase 4 |
| Test coverage = 0% | 🟡 MEDIUM | ⏳ Fase 5 |

---

## Checklist Completato

### ✅ Fase 3 — TMDB API Integration
- [x] MovieRepository con caching (5 min TTL)
- [x] `rethrow` nel catch → Riverpod entra in error state correttamente
- [x] `searchMovies(query)` — endpoint `/search/movie`
- [x] `getMoviesByGenre(genreId)` — endpoint `/discover/movie`
- [x] `getMoviesByGenres(List<int>)` — multi-genere AND (comma-separated)
- [x] Error handling: 401/429/timeout mostrano UI con retry button
- [x] Scroll infinito in DiscoveryScreen (discoveryProvider paginato)

### ✅ Performance e Bug Fix
- [x] `CachedNetworkImage` con disk cache
- [x] `memCacheWidth: 240` per limitare RAM (80px widget × 3x DPR)
- [x] Endpoint `w185` invece di `w500` per thumbnail (riduzione ~85% payload)
- [x] `smallPosterUrl` getter su Movie model
- [x] **Hero tag duplicati**: rimosso `Hero` da `_MoviePosterCard` nei carousel — lo stesso film può comparire in più sezioni contemporaneamente causando crash. `Hero` rimane solo in `MovieCard` (lista verticale, film unici)

### ✅ Discovery Screen (redesign completo)
- [x] 6 sezioni carousel orizzontali: Ora al Cinema, Prossime Uscite, I Grandi Cult, Azione, Animazione, Commedia
- [x] Bottone "Vedi tutti" su ogni sezione → SearchScreen pre-filtrata
- [x] Icona search in AppBar → SearchScreen

### ✅ Search Screen (nuovo)
- [x] Barra di ricerca stilizzata con campo testo
- [x] Badge sull'icona filtri (rosso quando generi attivi)
- [x] Tag rimovibili per filtri attivi (query, categoria, generi)
- [x] Bottom sheet con 17 generi come FilterChip (Wrap, aggiornamento live)
- [x] Infinite scroll paginato (ScrollController + StateNotifier)
- [x] Testo e generi si escludono a vicenda (limitazione API TMDB)
- [x] Default (nessun filtro): mostra Trending
- [x] Fix bug: `addPostFrameCallback` per evitare modifica provider durante build

---

## Checklist Fase 4 (In Progress)

### ⏳ Da fare
- [ ] MovieDetailScreen — sezione "La Tua Opinione" (Slider 0-10 + TextField)
- [ ] MovieDetailScreen — confronto voto utente vs TMDB (CustomPaint bar chart)
- [ ] DashboardScreen — cronologia visioni scrollabile con SliverList
- [ ] DashboardScreen — elimina entry con swipe o bottone
- [ ] DashboardScreen — filtri (cinema, periodo) come BottomSheet
- [ ] SocialNotesScreen — lista film votati ordinata per rating
- [ ] SocialNotesScreen — appunti cinema editabili

---

## File Chiave

| Ruolo | File |
|-------|------|
| Entry point | `lib/main.dart` |
| ⚠️ API key da configurare | `lib/core/constants.dart` |
| HTTP client TMDB | `lib/repositories/movie_repository.dart` |
| Provider film + generi | `lib/providers/movie_provider.dart` |
| Provider search paginata | `lib/screens/search_screen.dart` (`searchNotifierProvider`) |
| Provider discovery paginata | `lib/providers/discovery_provider.dart` |
| Persistenza locale | `lib/repositories/local_storage_service.dart` |
| Stato finanziario | `lib/providers/finance_provider.dart` |
| Registra visione (dialog) | `lib/widgets/register_cinema_visit_dialog.dart` |

---

## Quick Reference — Provider Catalogue

| Provider | Tipo | Stato | Uso |
|----------|------|-------|-----|
| `movieRepositoryProvider` | `Provider` | `MovieRepository` | Singleton HTTP client |
| `movieListProvider` | `FutureProvider.family<List<Movie>, (MovieCategory, int)>` | `AsyncValue<List<Movie>>` | Caroselli (categoria + pagina) |
| `genreMoviesProvider` | `FutureProvider.family<List<Movie>, int>` | `AsyncValue<List<Movie>>` | Caroselli per genreId |
| `discoveryProvider` | `AsyncNotifierProviderFamily<DiscoveryNotifier, DiscoveryState, MovieCategory>` | `AsyncValue<DiscoveryState>` | Lista infinita paginata |
| `searchNotifierProvider` | `StateNotifierProvider.autoDispose<SearchNotifier, SearchPageState>` | `SearchPageState` | Ricerca + filtro + paginazione |
| `financeProvider` | `NotifierProvider` | `List<FinanceLedgerEntry>` | Ledger spese |
| `reviewsProvider` | `NotifierProvider` | `List<UserReview>` | Review film |
| `cinemaNotesProvider` | `NotifierProvider` | `List<CinemaNote>` | Appunti cinema |
| `wishlistProvider` | `NotifierProvider` | `List<Movie>` | Wishlist |
| `appStatsProvider` | `Provider` (computed) | `AppStats` | Statistiche derivate |

---

## Quick Reference — Pattern Frequenti

### Flusso: "Vedi tutti" da Discovery a Search

```
Tap "Vedi tutti" sezione categoria
→ SearchScreen(initialCategory: MovieCategory.nowPlaying)
→ addPostFrameCallback → searchNotifier.initialize(category: ...)
→ _fetchNext() → repo.getMoviesByCategory(cat, page: 1)
→ ScrollController.pixels >= maxExtent - 300 → loadMore()
```

```
Tap "Vedi tutti" sezione genere
→ SearchScreen(initialGenreIds: [28])
→ searchNotifier.initialize(genreIds: [28])
→ _fetchNext() → repo.getMoviesByGenres([28], page: 1)
```

### Flusso: Registra visione

```
ref.watch(movieListProvider((categoria, pagina)))
→ Tap MovieCard → MovieDetailScreen
→ Tap "Registra" → RegisterCinemaVisitDialog
→ ref.read(financeProvider.notifier).addVisione(...)
→ ref.invalidate(appStatsProvider)
```

### Pattern Notifier (mutazione + persistenza)

```dart
class MyNotifier extends Notifier<List<T>> {
  @override
  List<T> build() => ref.read(localStorageProvider).loadItems();

  Future<void> add(T item) async {
    state = [...state, item];
    await ref.read(localStorageProvider).saveItems(state);
    ref.invalidate(dependentProvider);
  }
}
```

### AsyncValue nel widget

```dart
movieAsync.when(
  data: (movies) => ListView.builder(...),
  loading: () => const CircularProgressIndicator(),
  error: (err, _) => _ErrorWidget(error: err.toString()),
);
```

### Retry button pattern

```dart
TextButton(
  onPressed: () => ref.invalidate(movieListProvider),
  child: const Text('Riprova'),
)
```
