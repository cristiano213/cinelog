# CineLog — Roadmap Fasi 3-5

**Aggiornato:** Maggio 2026
**Fasi 1-3:** ✅ Completate — questo documento copre solo il lavoro rimanente.
**Stato corrente e task immediati:** vedi [DEVELOPMENT_TRACKER.md](DEVELOPMENT_TRACKER.md)

---

## Indice

1. [Fase 3 — TMDB API Integration](#fase3)
2. [Fase 4 — UI Avanzate](#fase4)
3. [Fase 5 — Testing e Polish](#fase5)

---

## <a id="fase3"></a>Fase 3 — TMDB API Integration ✅ COMPLETATA

**Prerequisito:** Fase 1-2 ✅

> Fase completata. Discovery è stata ridisegnata come home con 6 carousel + SearchScreen dedicata con infinite scroll e filtri genere.

### Task 3.1 — Configurare API Key ⚠️ ANCORA DA FARE

**File:** `lib/core/constants.dart`

```dart
class TmdbConstants {
  static const String apiKey = 'YOUR_API_KEY_HERE'; // ← da completare
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const Duration apiTimeout = Duration(seconds: 10);
}
```

Ottenere la key: https://www.themoviedb.org/settings/api → "API (v3 auth)"

**DoD:** API key funzionante, Discovery carica film, nessuna key committata su git.

---

### Task 3.2 — Paginazione ✅ COMPLETATO

Implementata in `SearchScreen` via `SearchNotifier` (StateNotifier con generation counter) e in `discovery_provider.dart` via `DiscoveryNotifier` (FamilyAsyncNotifier). Discovery è stata ridisegnata come home con 6 carousel orizzontali; la lista verticale paginata vive in SearchScreen.

---

### Task 3.3 — Error Handling ✅ COMPLETATO

- `rethrow` nel catch di `MovieRepository._fetchMovies` → Riverpod entra in error state
- UI error con `SliverFillRemaining` + icona cloud_off + retry in SearchScreen
- `SearchNotifier` ha generation counter per evitare risultati stale

---

### Task 3.4 — Test Repository (opzionale)

**File:** `test/repositories/movie_repository_test.dart`

Test con mock HTTP:

```dart
test('getMoviesByCategory returns movies on 200', () async {
  when(mockClient.get(any)).thenAnswer((_) async => http.Response(
    jsonEncode({'results': [{'id': 550, 'title': 'Fight Club', ...}]}),
    200,
  ));
  final movies = await repo.getMoviesByCategory(MovieCategory.nowPlaying);
  expect(movies, isNotEmpty);
  expect(movies[0].title, 'Fight Club');
});

test('throws on 401', () async {
  when(mockClient.get(any)).thenAnswer((_) async => http.Response('', 401));
  expect(() => repo.getMoviesByCategory(MovieCategory.nowPlaying), throwsException);
});
```

---

## <a id="fase4"></a>Fase 4 — UI Avanzate

**Durata:** 3-4 giorni (base già implementata) | **Prerequisito:** Fase 3

**Obiettivo:** Tutte le schermate funzionali: review, grafici, filtri.

### Task 4.1 — MovieDetailScreen: Sezione Review

**File:** `lib/screens/movie_detail_screen.dart`

Aggiungere dopo la sezione "Cast":

```dart
// La Tua Opinione
final review = ref.watch(reviewsProvider)
    .firstWhereOrNull((r) => r.movieId == movie.id);

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text('LA TUA OPINIONE', style: TextStyle(fontWeight: FontWeight.bold)),
    // Rating bar 0-10
    Slider(
      value: (review?.userRating ?? 0).toDouble(),
      min: 0,
      max: 10,
      divisions: 10,
      label: '${review?.userRating ?? 0}/10',
      onChanged: (val) => setState(() => _currentRating = val.round()),
    ),
    // Campo testo
    TextField(
      controller: _reviewController,
      maxLength: 500,
      decoration: const InputDecoration(hintText: 'La tua recensione...'),
    ),
    ElevatedButton(
      onPressed: () => ref.read(reviewsProvider.notifier)
          .addOrUpdateReview(movie.id, movie.title, _currentRating, _reviewController.text),
      child: const Text('Salva'),
    ),
    // Confronto voti
    if (review != null)
      Text('Tu: ${review.userRating}/10 | TMDB: ${movie.voteAverage}'),
  ],
)
```

**DoD:** Review salvabile, comparazione voto visibile, aggiornamento in tempo reale.

---

### Task 4.2 — CustomPaint: Confronto Rating

**File:** `lib/widgets/rating_comparison_chart.dart`

```dart
class RatingComparisonChart extends StatelessWidget {
  final double tmdbRating;
  final int userRating;

  const RatingComparisonChart({required this.tmdbRating, required this.userRating});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RatingPainter(tmdbRating, userRating.toDouble()),
      size: const Size(double.infinity, 120),
    );
  }
}

class _RatingPainter extends CustomPainter {
  final double tmdb;
  final double user;
  _RatingPainter(this.tmdb, this.user);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final barW = size.width * 0.3;

    paint.color = Colors.blue.withOpacity(0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * (1 - tmdb / 10), barW, size.height * (tmdb / 10)),
        const Radius.circular(4),
      ),
      paint,
    );

    paint.color = Colors.deepPurpleAccent.withOpacity(0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.6, size.height * (1 - user / 10), barW, size.height * (user / 10)),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RatingPainter old) => old.tmdb != tmdb || old.user != user;
}
```

**DoD:** Due barre visibili, proporzionate al rating, senza crash.

---

### Task 4.3 — DashboardScreen: Cronologia e Filtri

**File:** `lib/screens/dashboard_screen.dart`

Struttura target:

```dart
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(financeProvider);
    final stats = ref.watch(appStatsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Stat cards (già implementate in StatsScreen → unificare)
          SliverToBoxAdapter(child: _StatCards(stats: stats)),
          // Cronologia
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _FinanceListTile(
                entry: ledger[i],
                onDelete: () => ref.read(financeProvider.notifier).removeEntry(ledger[i].id),
              ),
              childCount: ledger.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilters(context, ref),
        child: const Icon(Icons.filter_list),
      ),
    );
  }
}
```

Filtri implementati come `state` locale (StatefulWidget o `ref.watch` di un provider filtri):
- Per cinema: `ledger.where((e) => e.cinema == selected)`
- Per periodo: `ledger.where((e) => e.dateTime.isAfter(from))`

**DoD:** Cronologia lista scrollabile, eliminazione funziona, filtri base presenti.

---

### Task 4.4 — SocialNotesScreen

**File:** `lib/screens/social_notes_screen.dart`

Sezioni:
1. Header stats: rating medio + film votati
2. Lista film votati (ordinati per rating)
3. Lista cinema visitati con appunti editabili

```dart
class SocialNotesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewsProvider);
    final cinemaList = ref.watch(cinemaNotesProvider);

    return ListView(
      children: [
        // Header stats
        _buildHeader(reviews),
        const Divider(),
        // Film votati
        ...reviews
            .where((r) => r.hasRating)
            .sorted((a, b) => b.userRating.compareTo(a.userRating))
            .map((r) => ListTile(
              title: Text(r.movieTitle),
              trailing: Text('${r.userRating}/10'),
              subtitle: r.hasReviewText ? Text(r.reviewText) : null,
            )),
        const Divider(),
        // Cinema
        ...cinemaList.map((c) => ListTile(
          title: Text(c.cinemaName),
          subtitle: Text('${c.visitCount} visite | ${c.formattedAvgPrice}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editNote(context, ref, c),
          ),
        )),
      ],
    );
  }
}
```

**DoD:** Review visibili e ordinate. Appunti cinema editabili.

---

## <a id="fase5"></a>Fase 5 — Testing e Polish

**Durata:** 3-4 giorni | **Prerequisito:** Fase 4

**Obiettivo:** Test coverage > 60%, app stabile su device reale.

### Task 5.1 — Unit Test Notifier

**Target:** `test/providers/`

```dart
// finance_notifier_test.dart
test('addVisione aggiunge entry', () async {
  await notifier.addVisione('550', 'Fight Club', 'Cineworld', 9.50);
  expect(notifier.state.length, 1);
  expect(notifier.state[0].priceEur, 9.50);
});

test('removeEntry elimina entry', () async {
  await notifier.addVisione('550', 'Fight Club', 'Cineworld', 9.50);
  final id = notifier.state[0].id;
  await notifier.removeEntry(id);
  expect(notifier.state, isEmpty);
});

test('totalSpent calcola correttamente', () async {
  await notifier.addVisione('1', 'Film A', 'Cinema', 9.00);
  await notifier.addVisione('2', 'Film B', 'Cinema', 11.00);
  expect(notifier.totalSpent, 20.00);
});
```

**Target coverage:** > 70% per Notifier.

---

### Task 5.2 — Widget Test Screen

**Target:** `test/widget/`

```dart
testWidgets('DiscoveryScreen mostra loading indicator', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        movieListProvider.overrideWith((ref, arg) => Future.delayed(
          const Duration(seconds: 10),
          () => [],
        )),
      ],
      child: const MaterialApp(home: DiscoveryScreen()),
    ),
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

**Target coverage:** > 60% per screen critiche.

---

### Task 5.3 — Performance e Polish

- [ ] Profilo in `flutter run --profile` → target 60 FPS durante scroll
- [ ] Verifica dark mode su device reale
- [ ] Hero animation fluida tra MovieCard e MovieDetailScreen
- [ ] Shimmer loading su poster (opzionale con `shimmer` package)
- [ ] Nessun `print()` rimasto nel codice di produzione
- [ ] Nessuna API key hardcoded visibile in log

---

### Checklist Pre-Release

- [ ] `flutter analyze` → 0 errori, 0 warning critici
- [ ] `flutter build apk --release` → build OK
- [ ] Test su device fisico Android
- [ ] Tutti i flussi principali funzionano end-to-end:
  - Discovery → Dettaglio → Registra Visione
  - Dashboard → elimina entry
  - Social → modifica review
- [ ] Gestione offline: messaggio chiaro + retry
- [ ] TMDB key non nel repository git
