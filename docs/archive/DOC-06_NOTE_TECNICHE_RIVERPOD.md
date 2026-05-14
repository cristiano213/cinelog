# CineLog 2.0 — Note Tecniche su Riverpod e Logica di Stato

**Versione:** 1.0  
**Data:** Maggio 2026  
**Scope:** Approfondi Riverpod, logica async, invalidation, pattern avanzati

---

## Indice

1. [Riverpod Fundamentals](#fundamentals)
2. [AsyncValue Pattern](#asyncvalue)
3. [Notifier e State Management](#notifiers)
4. [Invalidation e Refresh](#invalidation)
5. [Dependency Injection](#di)
6. [Error Handling Avanzato](#error-handling)
7. [Pattern: AsyncValue + Error Recovery](#patterns)
8. [Performance Tips](#performance)
9. [Testing Riverpod Providers](#testing)

---

## <a id="fundamentals"></a>1. Riverpod Fundamentals

### 1.1 Cosa è Riverpod?

**Riverpod** è un state management framework per Flutter che migliora Provider:

```
❌ Provider (deprecato)        ✅ Riverpod (nuovo)
┌──────────────────────────┐   ┌──────────────────────────┐
│ Tightly coupled to Build  │   │ Decoupled, testable      │
│ Context-dependent         │   │ Composition-based        │
│ Imperative               │   │ Declarative              │
└──────────────────────────┘   └──────────────────────────┘
```

### 1.2 Tre Tipi di Provider

```dart
// 1. SIMPLE PROVIDER (statico)
final nameProvider = Provider((ref) {
  return 'CineLog';
});

// 2. FUTURE PROVIDER (async, lazy)
final movieListProvider = FutureProvider((ref) async {
  return await repo.getMovies();
});

// 3. NOTIFIER PROVIDER (state + logica)
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final counterProvider = NotifierProvider<CounterNotifier, int>(() {
  return CounterNotifier();
});
```

### 1.3 Ciclo di Vita

```
1. CREATION
   final myProvider = Provider(...);

2. FIRST ACCESS
   final value = ref.watch(myProvider);
   └─ Provider esegue build() la prima volta
   └─ Stato cachato in memory

3. REUSE
   final value2 = ref.watch(myProvider);
   └─ Ritorna valore cachato (no rebuild)

4. INVALIDATION
   ref.invalidate(myProvider);
   └─ Cache svuotata

5. NEXT ACCESS
   final value3 = ref.watch(myProvider);
   └─ Esegue build() di nuovo
```

---

## <a id="asyncvalue"></a>2. AsyncValue Pattern

### 2.1 Anatomy of AsyncValue

`AsyncValue<T>` rappresenta lo stato di un'operazione asincrona:

```dart
// In memoria, uno di questi tre stati:

AsyncValue<List<Movie>>.data([movie1, movie2, ...])
  └─ Dati disponibili

AsyncValue<List<Movie>>.loading()
  └─ Caricamento in corso

AsyncValue<List<Movie>>.error(Exception(...))
  └─ Errore durante caricamento
```

### 2.2 Pattern when()

```dart
final moviesAsync = ref.watch(movieListProvider);

moviesAsync.when(
  // ✅ Dati arrivati
  data: (movies) => Text('${movies.length} film'),
  
  // ⏳ Loading
  loading: () => const CircularProgressIndicator(),
  
  // ❌ Errore
  error: (err, stack) => Text('Errore: $err'),
);
```

### 2.3 Pattern whenData (Syntactic Sugar)

Se ti importa **solo** del caso data:

```dart
// ❌ Verbose
moviesAsync.when(
  data: (movies) => ListView(...),
  loading: () => const SizedBox(),
  error: (_, __) => const SizedBox(),
);

// ✅ Conciso
moviesAsync.whenData((movies) => ListView(...));
```

### 2.4 Accesso al Valore con .value

```dart
// Se vuoi il valore grezzo (null se non ancora caricato)
final movies = moviesAsync.value;  // List<Movie>? or null

// Meglio con pattern matching
if (moviesAsync.hasValue) {
  final movies = moviesAsync.requireValue;
  // Safe: non è null
}
```

### 2.5 Skip Loading State (optimistic UI)

Mostra dati precedenti mentre carica nuovi:

```dart
final moviesAsync = ref.watch(movieListProvider);

moviesAsync.when(
  // Se già avevamo dati, mostrali mentre carica
  data: (movies) => ListView(...),
  
  loading: () {
    // C'era un previousValue? Usa quello
    if (moviesAsync.hasValue) {
      return ListView(children: moviesAsync.requireValue.map(...).toList());
    }
    return const CircularProgressIndicator();
  },
  
  error: (err, _) => ErrorWidget(message: '$err'),
);
```

---

## <a id="notifiers"></a>3. Notifier e State Management

### 3.1 Anatomy of Notifier

```dart
class FinanceLedgerNotifier extends Notifier<List<FinanceLedgerEntry>> {
  // Campi (setup)
  late LocalStorageService _storage;

  // Metodo build(): ritorna lo stato iniziale
  @override
  List<FinanceLedgerEntry> build() {
    _storage = LocalStorageService();
    return _storage.loadFinanceLedger();
  }

  // Metodi pubblici: mutano `state`
  Future<void> addVisione(String movieId, String cinema, double price) async {
    final newEntry = FinanceLedgerEntry(...);
    state = [...state, newEntry];  // ← Mutation trigger rebuild
    await _storage.saveFinanceLedger(state);
  }

  // Getter: computed values
  double get totalSpent => state.fold(0.0, (sum, e) => sum + e.totalPrice);
}

// Creazione del provider
final financeProvider = NotifierProvider<
  FinanceLedgerNotifier,
  List<FinanceLedgerEntry>
>(() => FinanceLedgerNotifier());
```

### 3.2 Accesso al Notifier (Read vs Watch)

```dart
// ❌ SBAGLIATO: watch del provider, no accesso a metodi
ref.watch(financeProvider);  // ← Questo NON è il Notifier

// ✅ CORRETTO: read il notifier
ref.read(financeProvider.notifier).addVisione(...);

// Differenza:
ref.watch(financeProvider)         // Accede a `state`, ribuilds se cambia
ref.read(financeProvider.notifier) // Accede al Notifier stesso, no rebuild
```

### 3.3 Mutation vs Immutability

```dart
// ❌ SBAGLIATO: mutazione in-place
state.add(newEntry);  // Modifica la lista originale!

// ✅ CORRETTO: crea nuova lista
state = [...state, newEntry];  // Copia la lista, poi aggiunge

// ✅ Alternativa: spread operator
state = [newEntry, ...state];  // Prepend

// ✅ Modifica elemento: map + copyWith
state = state.map((e) =>
  e.id == targetId ? e.copyWith(price: newPrice) : e
).toList();
```

### 3.4 Stato Iniziale da External Source

```dart
// Build() carica da disk, ma se disk fallisce?
@override
List<FinanceLedgerEntry> build() {
  _storage = LocalStorageService();
  
  try {
    return _storage.loadFinanceLedger();
  } catch (e) {
    debugPrint('Error loading ledger: $e');
    return [];  // Fallback: lista vuota
  }
}
```

---

## <a id="invalidation"></a>4. Invalidation e Refresh

### 4.1 Invalidate (svuota cache)

```dart
// Svuota la cache del provider
ref.invalidate(financeProvider);

// Alla prossima osservazione, build() eseguito di nuovo
// Utile quando: stato esterno è cambiato
```

### 4.2 Refresh (invalidate + riesecuzione immediata)

```dart
// Svuota cache e riesegue subito
final newData = await ref.refresh(movieListProvider);

// Se watch (non read), il widget ribuilderebbe automaticamente
```

### 4.3 Invalidare Dipendenze Correlate

Quando FinanceLedger cambia, stats devono ricalcolarsi:

```dart
class FinanceLedgerNotifier extends Notifier<List<FinanceLedgerEntry>> {
  @override
  List<FinanceLedgerEntry> build() {
    _storage = LocalStorageService();
    return _storage.loadFinanceLedger();
  }

  Future<void> addVisione(...) async {
    state = [...state, newEntry];
    await _storage.saveFinanceLedger(state);
    
    // ← Invalida i provider che dipendono da me
    ref.invalidate(statsProvider);  // Stats devono ricalcolarsi
    ref.invalidate(cinemaNotesProvider);  // Cinema notes anche
  }
}
```

### 4.4 Selective Invalidation

```dart
// Invalida solo una pagina di pagination
ref.invalidate(
  moviePageProvider((MovieCategory.nowPlaying, 1))
);

// Altre pagine (p2, p3) rimangono cachate
```

---

## <a id="di"></a>5. Dependency Injection

### 5.1 Inietazione di Dipendenze via Provider

```dart
// Definisci il servizio come provider
final localStorageServiceProvider = Provider((ref) {
  return LocalStorageService();
});

// Nel notifier, ietta la dipendenza
class FinanceLedgerNotifier extends Notifier<List<FinanceLedgerEntry>> {
  @override
  List<FinanceLedgerEntry> build() {
    // Richiedi la dipendenza
    final storage = ref.watch(localStorageServiceProvider);
    return storage.loadFinanceLedger();
  }
}
```

### 5.2 Override per Testing

```dart
// Nel test, puoi override la dipendenza
testWidgets('FinanceLedger works', (tester) async {
  final mockStorage = MockLocalStorageService();
  
  await tester.pumpWidget(
    ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(mockStorage),
      ],
      child: const CineLogApp(),
    ),
  );
  
  // Ora FinanceLedgerNotifier userà mockStorage instead di reale
});
```

---

## <a id="error-handling"></a>6. Error Handling Avanzato

### 6.1 Differenziare Tipi di Errore

```dart
// Nel FutureProvider, possono accadere vari errori

final movieListProvider = FutureProvider<List<Movie>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  
  try {
    return await repo.getMoviesByCategory(MovieCategory.nowPlaying);
  } on NetworkException catch (e) {
    throw NetworkException('📡 No internet: ${e.message}');
  } on AuthException catch (e) {
    throw AuthException('🔑 API key invalid: ${e.message}');
  } on RateLimitException catch (e) {
    throw RateLimitException('⏱️ Rate limited: ${e.message}');
  } on TimeoutException catch (e) {
    throw TimeoutException('⏳ Timeout: ${e.message}');
  } catch (e) {
    throw Exception('❌ Unexpected error: $e');
  }
});
```

### 6.2 Nel Widget: Pattern Match Errors

```dart
moviesAsync.when(
  data: (movies) => MovieList(movies: movies),
  
  loading: () => const Loader(),
  
  error: (error, stackTrace) {
    // Pattern match l'errore
    if (error is NetworkException) {
      return ErrorPage(
        title: 'No Internet',
        message: 'Connessione non disponibile',
        icon: Icons.wifi_off,
      );
    } else if (error is AuthException) {
      return ErrorPage(
        title: 'Auth Error',
        message: 'API key problem',
        icon: Icons.lock_outline,
      );
    } else if (error is RateLimitException) {
      return ErrorPage(
        title: 'Too Many Requests',
        message: 'Riprova tra 1 minuto',
        icon: Icons.hourglass_top,
      );
    } else {
      return ErrorPage(
        title: 'Unknown Error',
        message: error.toString(),
        icon: Icons.error_outline,
      );
    }
  },
);
```

### 6.3 Auto-Retry Logic

```dart
// Nel Notifier, implementa retry
class MovieListNotifier extends Notifier<AsyncValue<List<Movie>>> {
  int _retryCount = 0;
  static const _maxRetries = 3;

  @override
  Future<List<Movie>> build() async {
    final repo = ref.watch(movieRepositoryProvider);
    
    try {
      return await repo.getMovies();
    } catch (e) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: 2 * _retryCount));  // Exponential backoff
        return build();  // Retry
      }
      rethrow;  // Max retries exceeded
    }
  }
}
```

---

## <a id="patterns"></a>7. Pattern: AsyncValue + Error Recovery

### 7.1 Pattern: Try-Catch nel FutureProvider

```dart
final safemovieListProvider = FutureProvider<List<Movie>>((ref) async {
  try {
    final repo = ref.watch(movieRepositoryProvider);
    return await repo.getMoviesByCategory(MovieCategory.nowPlaying);
  } catch (e, stack) {
    // Log errore
    debugPrintStack(label: 'Movie Fetch Error: $e', stackTrace: stack);
    
    // Fallback: tenta cache locale
    final storage = ref.watch(localStorageServiceProvider);
    final cached = storage.loadCachedMovies();
    
    if (cached.isNotEmpty) {
      return cached;  // Serve dati vecchi se API fallisce
    }
    
    rethrow;  // Nessun fallback, propaga errore
  }
});
```

### 7.2 Pattern: Retry Button nel Widget

```dart
moviesAsync.when(
  error: (err, stack) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error, size: 64, color: Colors.red),
      const SizedBox(height: 16),
      Text(err.toString()),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () {
          ref.refresh(movieListProvider);  // Retry
        },
        child: const Text('Riprova'),
      ),
    ],
  ),
  data: (movies) => MovieList(movies: movies),
  loading: () => const Loader(),
);
```

### 7.3 Pattern: Loading con Optimistic UI

```dart
// Mostra dati vecchi mentre carica nuovi
moviesAsync.when(
  data: (newMovies) => MovieList(movies: newMovies),
  
  loading: () {
    // Se c'era un valore precedente, mostralo
    if (moviesAsync.hasValue) {
      return MovieList(
        movies: moviesAsync.requireValue,
        opacity: 0.5,  // Leggermente sbiadito
      );
    }
    return const Loader();
  },
  
  error: (err, _) => ErrorWidget(error: err),
);
```

---

## <a id="performance"></a>8. Performance Tips

### 8.1 Evita Over-Watch

```dart
// ❌ BAD: widget ribuilds ogni volta che state cambia
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(financeProvider);  // ← Rebuild se ledger cambia
    final stats = ref.watch(statsProvider);      // ← Rebuild se stats cambiano
    
    return Column(
      children: [
        Text('${ledger.length}'),
        Text('${stats.totalSpent}'),
      ],
    );
  }
}

// ✅ BETTER: suddividi in sotto-widget
class LedgerDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(financeProvider);
    return Text('${ledger.length}');
  }
}

class StatsDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    return Text('${stats.totalSpent}');
  }
}

// Nel parent:
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const LedgerDisplay(),  // Ribuilds solo se ledger cambia
        const StatsDisplay(),   // Ribuilds solo se stats cambiano
      ],
    );
  }
}
```

### 8.2 Selector Pattern (Select Specific Field)

```dart
// Se ledger è grande, ma vuoi solo il count
final ledgerCountProvider = Provider((ref) {
  final ledger = ref.watch(financeProvider);
  return ledger.length;  // Computed value
});

// Nel widget:
final count = ref.watch(ledgerCountProvider);  // Ribuilds solo se count cambia
```

### 8.3 Lazy vs Eager Initialization

```dart
// ❌ Eager: build() eseguito al boot
final movieListProvider = FutureProvider((ref) async {
  return await repo.getMovies();
});

// ✅ Lazy: build() eseguito solo quando osservato
final movieListProvider = FutureProvider((ref) async {
  return await repo.getMovies();
});

// Riverpod è lazy by default, OK
```

---

## <a id="testing"></a>9. Testing Riverpod Providers

### 9.1 Test Notifier Semplice

```dart
void main() {
  group('FinanceLedgerNotifier', () {
    late FinanceLedgerNotifier notifier;

    setUp(() {
      // Crea notifier senza dipendenze reali
      notifier = FinanceLedgerNotifier();
      
      // Mock dependencies (se necessario)
      // addTearDown(notifier.dispose);
    });

    test('build returns empty list initially', () {
      final state = notifier.build();
      expect(state, isEmpty);
    });

    test('addVisione adds entry to state', () {
      notifier.addVisione('550', 'Fight Club', 'Cineworld', 9.50);
      
      expect(notifier.state.length, 1);
      expect(notifier.state[0].movieTitle, 'Fight Club');
    });
  });
}
```

### 9.2 Test FutureProvider

```dart
void main() {
  group('movieListProvider', () {
    test('returns movie list on success', () async {
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        ],
      );

      final movies = await container.read(movieListProvider.future);
      
      expect(movies, isNotEmpty);
      expect(movies[0].title, 'Fight Club');
    });

    test('throws error on failure', () async {
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(
            MockMovieRepositoryThrows(),
          ),
        ],
      );

      expect(
        () => container.read(movieListProvider.future),
        throwsException,
      );
    });
  });
}
```

### 9.3 Test Widget con Provider

```dart
void main() {
  testWidgets('DashboardScreen displays stats', (tester) async {
    final mockLedger = [
      FinanceLedgerEntry(
        id: '1',
        movieId: '550',
        movieTitle: 'Fight Club',
        cinema: 'Cineworld',
        priceEur: 9.50,
        dateTime: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderContainer(
        overrides: [
          financeProvider.overrideWithValue(mockLedger),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    expect(find.text('€9.50'), findsOneWidget);
    expect(find.text('Cineworld'), findsOneWidget);
  });
}
```

---

## 10. Checklist: Riverpod Best Practices

- [ ] Provider creati come top-level constants
- [ ] Notifier ha metodi pubblici per mutazione
- [ ] No import di Notifier constructor diretto (via provider)
- [ ] FutureProvider ha error handling
- [ ] AsyncValue .when() pattern usato correttamente
- [ ] Invalidation implementato dove necessario
- [ ] Test coverage per Notifier > 80%
- [ ] No over-watch (widget suddiviso se necessario)
- [ ] Dependencies iniettate via Provider
- [ ] Lazy loading dove appropriato

---

## 11. Risorse

- [Riverpod Official Docs](https://riverpod.dev)
- [Riverpod GitHub](https://github.com/rrousselGit/riverpod)
- [Flutter State Management Comparison](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)

---

**Documento redatto: Maggio 2026**  
**Completo:** Tutti i 6 documenti di CineLog 2.0
