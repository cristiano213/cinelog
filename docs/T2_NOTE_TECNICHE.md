# CineLog — Note Tecniche Riverpod e Pattern Flutter

**Tier:** 2 — Riferimento tecnico stabile  
**Versione:** 1.0  
**Aggiornato:** Maggio 2026  
**Scope:** Pattern Riverpod realmente usati nel progetto v1. Estende `T2_ARCHITETTURA.md`.  
**Attenzione:** I pattern descritti nelle sezioni 5 e 6 sono legacy (v1). Saranno rimossi nel Modulo 2 (migrazione Supabase).

---

## Indice

1. [Setup e inizializzazione](#1-setup-e-inizializzazione)
2. [Tipologie di provider usati](#2-tipologie-di-provider-usati)
3. [Pattern AsyncNotifier con Family](#3-pattern-asyncnotifier-con-family)
4. [Pattern Provider computed (derivati)](#4-pattern-provider-computed-derivati)
5. [Persistenza locale (v1 legacy)](#5-persistenza-locale-v1-legacy)
6. [Caricamento eager all'avvio (v1 legacy)](#6-caricamento-eager-allavvio-v1-legacy)
7. [Gotcha incontrati nel progetto](#7-gotcha-incontrati-nel-progetto)
8. [Migrazione attesa verso Supabase](#8-migrazione-attesa-verso-supabase)

---

## 1. Setup e inizializzazione

### 1.1 ProviderScope root

`ProviderScope` è il widget radice che abilita Riverpod. In CineLog è posizionato in `main()`, fuori da qualsiasi widget dell'app:

```dart
// lib/main.dart — void main()
void main() {
  runApp(
    const ProviderScope(
      child: CineLogApp(),
    ),
  );
}
```

Tutti i provider sono accessibili da qualsiasi nodo dell'albero sottostante.

### 1.2 Avvio condizionale su initializeAppProvider

Il widget `_InitializedApp` osserva `initializeAppProvider` (un `FutureProvider`) e mostra una splash con `CircularProgressIndicator` finché il caricamento non è completo. Se il caricamento va in errore, mostra un pannello di errore con il messaggio. Solo quando il future restituisce `data` viene mostrato `MainNavigationScreen`:

```dart
// lib/main.dart — _InitializedApp.build()
final initAsync = ref.watch(initializeAppProvider);

return initAsync.when(
  loading: () => const Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: CircularProgressIndicator()),
  ),
  error: (error, stackTrace) => Scaffold(/* ... */),
  data: (_) => const MainNavigationScreen(),
);
```

Questa configurazione è destinata a evolvere: con Supabase il caricamento all'avvio sarà on-demand per singola schermata, non più globale.

---

## 2. Tipologie di provider usati

Il progetto usa quattro tipologie distinte di provider.

### 2.1 `Provider` — valore singleton senza stato

Usato per esporre istanze di classi di servizio o repository. Non ha stato reattivo: ritorna sempre lo stesso oggetto.

```dart
// lib/providers/movie_provider.dart — top level
final movieRepositoryProvider = Provider((ref) => MovieRepository());

// lib/providers/local_storage_provider.dart — top level
final localStorageServiceProvider = Provider((ref) {
  return LocalStorageService();
});
```

### 2.2 `NotifierProvider` — stato sincronno mutabile

Usato per i dati persistiti localmente (lista visite, wishlist, recensioni, note cinema). Il `Notifier` espone metodi pubblici per la mutazione; lo stato è una lista immutabile sostituita ad ogni modifica.

```dart
// lib/providers/finance_provider.dart — top level
final financeProvider = NotifierProvider<FinanceLedgerNotifier, List<FinanceLedgerEntry>>(
  FinanceLedgerNotifier.new,
);

// lib/providers/reviews_provider.dart — top level
final reviewsProvider = NotifierProvider<ReviewsNotifier, List<UserReview>>(
  ReviewsNotifier.new,
);

// lib/providers/wishlist_provider.dart — top level
final wishlistProvider = NotifierProvider<WishlistNotifier, List<Movie>>(
  WishlistNotifier.new,
);

// lib/providers/cinema_notes_provider.dart — top level
final cinemaNotesProvider = NotifierProvider<CinemaNotesNotifier, List<CinemaNote>>(
  CinemaNotesNotifier.new,
);
```

### 2.3 `FutureProvider.family` — fetch asincrono parametrizzato

Usato per liste di film da TMDB. Il parametro `family` distingue le istanze per categoria+pagina o per genere.

```dart
// lib/providers/movie_provider.dart — top level

// (MovieCategory, int) come chiave family: categoria + pagina
final movieListProvider =
    FutureProvider.family<List<Movie>, (MovieCategory, int)>(
  (ref, args) async {
    final (category, page) = args;
    final repo = ref.watch(movieRepositoryProvider);
    return await repo.getMoviesByCategory(category, page: page);
  },
);

// int (genreId) come chiave family
final genreMoviesProvider = FutureProvider.family<List<Movie>, int>(
  (ref, genreId) async {
    final repo = ref.watch(movieRepositoryProvider);
    return await repo.getMoviesByGenre(genreId);
  },
);
```

### 2.4 `AsyncNotifierProviderFamily` — stato asincrono paginato parametrizzato

Usato per la schermata Discovery con infinite scroll. Combina `AsyncNotifier` (stato asincrono) e `family` (parametro `MovieCategory`).

```dart
// lib/providers/discovery_provider.dart — top level
final discoveryProvider = AsyncNotifierProviderFamily<DiscoveryNotifier, DiscoveryState, MovieCategory>(
  () => DiscoveryNotifier(),
);
```

---

## 3. Pattern AsyncNotifier con Family

### 3.1 Struttura dello stato

`DiscoveryState` incapsula la lista di film accumulata e il cursore di paginazione. Non è un `AsyncValue`: la paginazione è gestita internamente al Notifier.

```dart
// lib/providers/discovery_provider.dart — class DiscoveryState
class DiscoveryState {
  final List<Movie> movies;
  final int currentPage;
  final bool isLoadingMore;   // true durante il fetch della pagina N+1
  final bool hasReachedMax;   // true quando TMDB ritorna lista vuota

  DiscoveryState({
    this.movies = const [],
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });

  DiscoveryState copyWith({ /* ... */ }) { /* ... */ }
}
```

### 3.2 Metodo `build`

Carica la prima pagina al momento della prima osservazione del provider. Il parametro `arg` è la `MovieCategory` passata via `.family`:

```dart
// lib/providers/discovery_provider.dart — DiscoveryNotifier.build()
@override
FutureOr<DiscoveryState> build(MovieCategory arg) async {
  final repo = ref.read(movieRepositoryProvider);
  final firstPage = await repo.getMoviesByCategory(arg, page: 1);

  return DiscoveryState(
    movies: firstPage,
    currentPage: 1,
    hasReachedMax: firstPage.isEmpty,
  );
}
```

### 3.3 Metodo `loadNextPage`

Aggiunge le pagine successive alla lista accumulata. La UI chiama questo metodo allo scroll verso il fondo. Il flag `isLoadingMore` è settato prima del fetch per abilitare un indicatore di caricamento in-list senza resettare i dati esistenti:

```dart
// lib/providers/discovery_provider.dart — DiscoveryNotifier.loadNextPage()
Future<void> loadNextPage() async {
  final currentState = state.value;
  if (currentState == null || currentState.isLoadingMore || currentState.hasReachedMax) return;

  state = AsyncData(currentState.copyWith(isLoadingMore: true));

  try {
    final repo = ref.read(movieRepositoryProvider);
    final nextPage = currentState.currentPage + 1;
    final newMovies = await repo.getMoviesByCategory(arg, page: nextPage);

    if (newMovies.isEmpty) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false, hasReachedMax: true));
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
```

Nota: in caso di errore nella fetch di una pagina successiva, lo stato torna a `isLoadingMore: false` senza perdere i film già caricati. L'errore viene silenziato — limite da affrontare in un task futuro.

---

## 4. Pattern Provider computed (derivati)

### 4.1 `appStatsProvider`

`appStatsProvider` è un `Provider<AppStats>` (non un `NotifierProvider`): non ha stato proprio, calcola tutto osservando due provider sorgente.

```dart
// lib/providers/stats_provider.dart — top level
final appStatsProvider = Provider<AppStats>((ref) {
  final ledger = ref.watch(financeProvider);   // osserva lista visite
  final reviews = ref.watch(reviewsProvider);  // osserva lista recensioni

  final totalSpent = ledger.fold<double>(0, (sum, e) => sum + e.totalPrice);
  final totalMoviesSeen = ledger.length;
  final avgTicketPrice = totalMoviesSeen > 0 ? totalSpent / totalMoviesSeen : 0.0;
  // ... altri calcoli ...

  return AppStats(
    totalSpent: totalSpent,
    totalMoviesSeen: totalMoviesSeen,
    avgTicketPrice: avgTicketPrice,
    avgUserRating: avgUserRating,
    spendingByMonth: spendingByMonth,
    favoriteCinema: favoriteCinema,
  );
});
```

### 4.2 Perché NON serve `ref.invalidate`

Quando `financeProvider` o `reviewsProvider` cambiano stato (via mutazione del Notifier), Riverpod notifica automaticamente tutti i provider che li osservano con `ref.watch`. `appStatsProvider` si ricalcola di conseguenza senza bisogno di invalidazione manuale.

Il pattern `ref.invalidate(appStatsProvider)` presente in `finance_provider.dart` dentro `updateEntry` è ridondante (vedi sezione 7.1).

---

## 5. Persistenza locale (v1 legacy)

Questo pattern verrà rimosso nel Modulo 2 (migrazione a Supabase).

### 5.1 Struttura

Ogni `Notifier` che gestisce dati persistiti ha due metodi privati/pubblici:

- `loadFromDisk()` — chiamato all'avvio da `initializeAppProvider`; legge da `SharedPreferences` e popola `state`
- `_save()` — chiamato dopo ogni mutazione; serializza `state` in JSON e scrive su `SharedPreferences`

Esempio canonico in `ReviewsNotifier`:

```dart
// lib/providers/reviews_provider.dart — ReviewsNotifier

Future<void> loadFromDisk() async {
  final storage = ref.read(localStorageServiceProvider);
  await storage.init();
  final reviews = await storage.loadUserReviews();
  state = reviews;
}

Future<void> addOrUpdateReview({ /* ... */ }) async {
  // 1. muta state
  state = [...state, review];
  // 2. persiste
  await _save();
}

Future<void> _save() async {
  final storage = ref.read(localStorageServiceProvider);
  await storage.init();
  await storage.saveUserReviews(state);
}
```

### 5.2 LocalStorageService

`LocalStorageService` (`lib/repositories/local_storage_service.dart`) è un wrapper attorno a `SharedPreferences`. Ogni dominio ha una chiave stringa costante:

| Chiave             | Tipo persistito          |
|--------------------|--------------------------|
| `finance_ledger`   | `List<FinanceLedgerEntry>` |
| `user_reviews`     | `List<UserReview>`        |
| `cinema_notes`     | `List<CinemaNote>`        |
| `wishlist`         | `Wishlist`                |
| `library_archive`  | `LibraryArchive`          |

I metodi `load*` e `save*` serializzano/deserializzano via `jsonEncode`/`jsonDecode`. Gli errori sono catturati con `try/catch` e loggati con `print` (problema #7 — vedi sezione 7.3).

### 5.3 Flusso completo

```
Utente esegue azione
  → Notifier.metodoX()
    → state = [...state, nuovoItem]   // Riverpod notifica i widget
    → _save()
      → LocalStorageService.save*()
        → SharedPreferences.setString(chiave, jsonEncode(state))
```

---

## 6. Caricamento eager all'avvio (v1 legacy)

Questo pattern verrà abbandonato a partire dal Modulo 1/2.

### 6.1 `initializeAppProvider`

Un `FutureProvider` che carica tutti i dati in parallelo prima di mostrare l'app:

```dart
// lib/providers/app_initialization_provider.dart — top level
final initializeAppProvider = FutureProvider((ref) async {
  final futures = <Future<void>>[
    ref.read(financeProvider.notifier).loadFromDisk(),
    ref.read(reviewsProvider.notifier).loadFromDisk(),
    ref.read(wishlistProvider.notifier).loadFromDisk(),
    ref.read(cinemaNotesProvider.notifier).loadFromDisk(),
  ];

  await Future.wait<void>(futures);
  return true;
});
```

I quattro `loadFromDisk()` girano in parallelo via `Future.wait`. Il provider ritorna `true` solo quando tutti e quattro sono completi.

### 6.2 Problema strutturale

Con Supabase il caricamento sarà on-demand: ogni schermata farà il proprio fetch quando viene aperta, non al boot. `initializeAppProvider` e il pattern `loadFromDisk()` saranno rimossi completamente nel Modulo 2.

---

## 7. Gotcha incontrati nel progetto

### 7.1 `ref.invalidate` ridondante in `updateEntry`

```dart
// lib/providers/finance_provider.dart — FinanceLedgerNotifier.updateEntry()
Future<void> updateEntry(String entryId, { /* ... */ }) async {
  state = state.map(/* ... */).toList();
  await _save();

  ref.invalidate(appStatsProvider);    // RIDONDANTE: appStatsProvider fa ref.watch(financeProvider)
  ref.invalidate(cinemaNotesProvider); // CORRETTO solo se cinemaNotesProvider non osserva financeProvider
}
```

`appStatsProvider` osserva `financeProvider` con `ref.watch`: si ricalcola automaticamente quando `state` di `financeProvider` cambia. La chiamata `ref.invalidate(appStatsProvider)` è quindi ridondante e può causare un doppio rebuild in `addVisione` (dove invece è stata correttamente rimossa).

`ref.invalidate(cinemaNotesProvider)` in `updateEntry` è invece discutibile: `CinemaNotesNotifier` legge `financeProvider` con `ref.read` (non `ref.watch`) dentro `updateCinemaNote`, quindi non si aggiorna automaticamente. L'invalidazione serve per triggerare un reload, ma crea un accoppiamento implicito non documentato.

### 7.2 `try/catch` su `firstWhere` in `getReview`

Dart lancia `StateError` (non restituisce `null`) quando `firstWhere` non trova un elemento e manca `orElse`. Il pattern usato in `ReviewsNotifier`:

```dart
// lib/providers/reviews_provider.dart — ReviewsNotifier.getReview()
UserReview? getReview(String movieId) {
  try {
    return state.firstWhere((r) => r.movieId == movieId);
  } catch (e) {
    return null;
  }
}
```

Funziona, ma il `catch` cattura qualsiasi eccezione. L'alternativa idiomatica è `firstWhereOrNull` (da `package:collection`) o `firstWhere` con `orElse: () => null` — entrambe eviterebbero il `try/catch` e renderebbero l'intenzione esplicita.

### 7.3 `storage.init()` chiamato ripetutamente

`LocalStorageService.init()` chiama `SharedPreferences.getInstance()` ad ogni invocazione di `loadFromDisk()` e `_save()`. `SharedPreferences.getInstance()` è idempotente (ritorna la stessa istanza se già inizializzata), ma la chiamata ripetuta è rumorosa e non necessaria.

Il problema deriva dalla scelta di non inizializzare `_prefs` nel costruttore di `LocalStorageService` (che non può essere `async`). Soluzione attesa nel Modulo 2: `LocalStorageService` sarà rimosso in favore di Supabase.

### 7.4 `print` invece di `debugPrint`

`LocalStorageService` usa `print(...)` per loggare errori nei metodi `load*` e `save*`. In Flutter, `print` non è filtrato in release build (a differenza di `debugPrint`) e può causare leak di informazioni. Da correggere nel Modulo 0.B.

---

## 8. Migrazione attesa verso Supabase

Per il pattern architetturale target, vedi `T2_ARCHITETTURA.md` §4-5 (TODO: da produrre).

In sintesi:

| v1 (attuale)                            | v2 (Modulo 2+)                              |
|-----------------------------------------|---------------------------------------------|
| `Notifier<List<T>>`                     | `AsyncNotifier<List<T>>`                    |
| `loadFromDisk()` + `_save()`            | metodi del `Repository` Supabase            |
| `LocalStorageService` (SharedPrefs)     | `SupabaseClient` via repository             |
| `initializeAppProvider` (eager load)    | rimosso; ogni screen fa fetch on-demand     |
| stato sincronno in `build()`            | stato asincrono in `build()` con `await`    |

Il passaggio da `Notifier` a `AsyncNotifier` introduce `AsyncValue` nello stato di ogni provider: i widget dovranno usare `.when()` anche per i provider di dati utente, non solo per i provider TMDB.
