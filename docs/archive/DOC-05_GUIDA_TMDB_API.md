# CineLog 2.0 — Guida Integrazione TMDB API

**Versione:** 1.0  
**Data:** Maggio 2026  
**Scope:** Setup API key, endpoints, pagination, image handling

---

## Indice

1. [Setup TMDB Account](#setup)
2. [Configurazione API Key](#apikey)
3. [Endpoint Reference](#endpoints)
4. [Pagination](#pagination)
5. [Image URLs](#images)
6. [Error Handling](#errors)
7. [Rate Limiting](#ratelimit)
8. [Testing](#testing)

---

## <a id="setup"></a>1. Setup TMDB Account

### 1.1 Registrazione

1. Vai a https://www.themoviedb.org/signup
2. Crea account con email
3. Verifica email
4. Accedi

### 1.2 Ottenere API Key

1. Vai a https://www.themoviedb.org/settings/api
2. Clicca "Create" o "Request an API Key"
3. Seleziona "Developer" (free tier disponibile)
4. Accetta termini
5. Ricevi **API Key v3 (REST API)**

Esempio API Key: `f8e1f1e5c5d5e5c5d5e5c5d5e5c5d5e5`

### 1.3 Verifica

Testa con curl:

```bash
curl "https://api.themoviedb.org/3/movie/550?api_key=YOUR_API_KEY"
```

Risposta attesa (JSON):

```json
{
  "adult": false,
  "backdrop_path": "/s3TBrjDWv9J2STSlLTeYPyDsbv6.jpg",
  "budget": 63000000,
  "genres": [
    { "id": 18, "name": "Drama" },
    { "id": 53, "name": "Thriller" }
  ],
  "homepage": "",
  "id": 550,
  "imdb_id": "tt0137523",
  "original_language": "en",
  "original_title": "Fight Club",
  "overview": "An insomniac office worker...",
  "popularity": 75.573,
  "poster_path": "/9gk7Fn9sSAsS989S3LZ1OROBqQD.jpg",
  "production_companies": [...],
  "release_date": "1999-10-15",
  "revenue": 100853753,
  "runtime": 139,
  "title": "Fight Club",
  "vote_average": 8.8,
  "vote_count": 26589
}
```

---

## <a id="apikey"></a>2. Configurazione API Key

### 2.1 Salvare in Constants (NO Hardcode)

**File:** `lib/core/constants.dart`

```dart
class TmdbConstants {
  // ⚠️ IMPORTANTE: Usa environment variable o .env file in produzione
  // Per development, puoi salvare qui, ma NON committare su Git
  static const String apiKey = 'YOUR_API_KEY_HERE';

  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';
  
  // Dimensioni poster disponibili: w92, w154, w185, w342, w500, w780, original
  static const String posterSize = 'w500';  // 500px width
  
  // Dimensioni backdrop: w300, w780, w1280, original
  static const String backdropSize = 'original';
  
  // Timeout per API call
  static const Duration apiTimeout = Duration(seconds: 10);
}
```

### 2.2 Usare Variables d'Ambiente (Production)

Crea `.env` file in root:

```
TMDB_API_KEY=f8e1f1e5c5d5e5c5d5e5c5d5e5c5d5e5
```

Aggiungi `flutter_dotenv` in pubspec.yaml:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

In main.dart:

```dart
void main() async {
  await dotenv.load();
  final apiKey = dotenv.env['TMDB_API_KEY']!;
  runApp(const CineLogApp());
}
```

### 2.3 .gitignore

**File:** `.gitignore`

```
.env
.env.*
!.env.example
```

---

## <a id="endpoints"></a>3. Endpoint Reference

### 3.1 Categorie Supportate

| Categoria | Endpoint | Descrizione |
|-----------|----------|-------------|
| Now Playing | `/movie/now_playing` | Film nelle sale adesso |
| Upcoming | `/movie/upcoming` | Uscite future |
| Top Rated | `/movie/top_rated` | Top 250 film di sempre |
| Trending | `/trending/movie/week` | Trending questa settimana |

### 3.2 Endpoint Details

#### **Get Movie List by Category**

```
GET /movie/{category}
Query Params:
  - api_key: [string] ← Obbligatorio
  - page: [int] ← Default: 1, Max: 500
  - region: [string] ← Es. "GB" per UK, optional
  - language: [string] ← Es. "it" per italiano, default: "en"
```

**Esempio Request:**

```
https://api.themoviedb.org/3/movie/now_playing?api_key=YOUR_KEY&page=1&region=IT&language=it
```

**Response (Successful):**

```json
{
  "page": 1,
  "results": [
    {
      "adult": false,
      "backdrop_path": "/...",
      "genre_ids": [28, 12, 878],
      "id": 912649,
      "original_language": "en",
      "original_title": "Dune: Part Two",
      "overview": "Paul Atreides, now haunted...",
      "popularity": 125.5,
      "poster_path": "/u3V2I4FcZ7r2r6p3TKmJMhOmJgE.jpg",
      "release_date": "2024-02-28",
      "title": "Dune: Part Two",
      "video": false,
      "vote_average": 8.5,
      "vote_count": 3245
    },
    // ... più film
  ],
  "total_pages": 523,
  "total_results": 10447,
  "dates": {
    "maximum": "2024-05-16",
    "minimum": "2024-04-19"
  }
}
```

#### **Get Movie Details (Cast, etc)**

```
GET /movie/{movie_id}
Query Params:
  - api_key: [string]
  - append_to_response: "credits,videos" ← Per aggiungere cast
  - language: [string]
```

**Esempio:**

```
https://api.themoviedb.org/3/movie/550?api_key=YOUR_KEY&append_to_response=credits
```

**Response (excerpt):**

```json
{
  "id": 550,
  "title": "Fight Club",
  "runtime": 139,
  "genres": [{"id": 18, "name": "Drama"}],
  "credits": {
    "cast": [
      {
        "adult": false,
        "character": "The Narrator",
        "credit_id": "52fe4284c3b08a8c64001a1b",
        "id": 287,
        "name": "Brad Pitt",
        "order": 0,
        "profile_path": "/cckcYc2v0yh1tc9QjRelC60SmqU.jpg"
      },
      {
        "adult": false,
        "character": "Tyler Durden",
        "credit_id": "52fe4284c3b08a8c64001a23",
        "id": 3131,
        "name": "Edward Norton",
        "order": 1,
        "profile_path": "/yJPi1j5SRmvAUwz9dBDJKzYQbAb.jpg"
      }
    ]
  }
}
```

### 3.3 Mapping a Movie Model

```dart
// lib/repositories/movie_repository.dart

Movie _movieFromTmdbJson(Map<String, dynamic> json) {
  final credits = json['credits'] as Map? ?? {};
  final cast = (credits['cast'] as List?)
    ?.cast<Map<String, dynamic>>()
    .take(5)  // Top 5 actors
    .map((c) => c['name'] as String? ?? 'Unknown')
    .toList() ?? [];

  final genres = json['genres'] as List?;
  final genreString = genres != null
    ? genres.map((g) => g['name']).join(', ')
    : 'Unknown';

  return Movie(
    id: json['id'].toString(),
    title: json['title'] ?? 'Unknown',
    description: json['overview'] ?? '',
    posterUrl: json['poster_path'] != null
      ? '${TmdbConstants.imageBaseUrl}/${TmdbConstants.posterSize}${json['poster_path']}'
      : '',
    backdropUrl: json['backdrop_path'] != null
      ? '${TmdbConstants.imageBaseUrl}/${TmdbConstants.backdropSize}${json['backdrop_path']}'
      : '',
    rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    durationMinutes: json['runtime'] as int? ?? 0,
    releaseDate: DateTime.tryParse(json['release_date'] as String? ?? '')
      ?? DateTime.now(),
    genre: genreString,
    cast: cast,
  );
}
```

---

## <a id="pagination"></a>4. Pagination

### 4.1 Request Paginato

TMDB ritorna max 20 film per pagina.

```dart
// page 1 = film 1-20
// page 2 = film 21-40
// page 3 = film 41-60

Future<List<Movie>> getMoviesByCategory(MovieCategory category, {int page = 1}) async {
  final endpoint = _getCategoryEndpoint(category);
  final url = '${TmdbConstants.baseUrl}$endpoint'
    '?api_key=${TmdbConstants.apiKey}'
    '&page=$page'
    '&language=it';

  final response = await http.get(Uri.parse(url))
    .timeout(TmdbConstants.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('TMDB API error: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as Map;
  final results = data['results'] as List? ?? [];

  return results
    .map((m) => _movieFromTmdbJson(m))
    .toList();
}
```

### 4.2 Infinite Scroll in UI

Nel Provider:

```dart
final moviePageProvider = FutureProvider.family<List<Movie>, (MovieCategory, int)>(
  (ref, args) async {
    final (category, page) = args;
    final repo = ref.watch(movieRepositoryProvider);
    return repo.getMoviesByCategory(category, page: page);
  },
);
```

Nel Widget:

```dart
class DiscoveryScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  int currentPage = 1;
  List<Movie> allMovies = [];

  void _loadNextPage() {
    final asyncMovies = ref.watch(
      moviePageProvider((MovieCategory.nowPlaying, currentPage + 1)),
    );
    asyncMovies.whenData((newMovies) {
      setState(() {
        allMovies.addAll(newMovies);
        currentPage++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // ListView che carica pagine man mano
    return ListView.builder(
      itemCount: allMovies.length + 1,
      itemBuilder: (ctx, i) {
        if (i == allMovies.length) {
          // Ultimo item = bottone "carica più"
          return Center(
            child: ElevatedButton(
              onPressed: _loadNextPage,
              child: const Text('Carica più film'),
            ),
          );
        }
        return MovieCard(movie: allMovies[i]);
      },
    );
  }
}
```

---

## <a id="images"></a>5. Image URLs

### 5.1 Costruzione URL

TMDB fornisce path relativo. Devi concatenare con base URL:

```
Poster (small):  https://image.tmdb.org/t/p/w342{posterPath}
Poster (large):  https://image.tmdb.org/t/p/w500{posterPath}
Backdrop:        https://image.tmdb.org/t/p/w780{backdropPath}
```

**Esempio:**

```
API Response posterPath: "/9gk7Fn9sSAsS989S3LZ1OROBqQD.jpg"
Completo URL: "https://image.tmdb.org/t/p/w500/9gk7Fn9sSAsS989S3LZ1OROBqQD.jpg"
```

### 5.2 Image Caching in Flutter

`Image.network` caccha automaticamente. Per controllo esplicito:

```dart
Image.network(
  'https://image.tmdb.org/t/p/w500/...',
  fit: BoxFit.cover,
  cacheHeight: 500,  // Cache con questa dimensione
  cacheWidth: 350,
  errorBuilder: (ctx, err, stack) => Container(
    color: Colors.grey[800],
    child: const Icon(Icons.broken_image, color: Colors.grey),
  ),
  loadingBuilder: (ctx, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded /
            loadingProgress.expectedTotalBytes!
          : null,
      ),
    );
  },
)
```

### 5.3 Offline Image Placeholder

Se no internet, mostra placeholder salvato:

```dart
final defaultPosterUrl = 'assets/images/placeholder_poster.jpg';

Image.network(
  moviePosterUrl.isNotEmpty ? moviePosterUrl : defaultPosterUrl,
  fit: BoxFit.cover,
  errorBuilder: (ctx, err, stack) => Image.asset(
    defaultPosterUrl,
    fit: BoxFit.cover,
  ),
)
```

---

## <a id="errors"></a>6. Error Handling

### 6.1 HTTP Status Codes

| Code | Significato | Azione |
|------|-------------|--------|
| 200 | OK | Procedi normalmente |
| 400 | Bad Request | Controlla parametri |
| 401 | Unauthorized | API key invalida o scaduta |
| 404 | Not Found | Film/endpoint non esiste |
| 429 | Too Many Requests | Rate limit superato → aspetta |
| 500+ | Server Error | Problema TMDB, riprova dopo |

### 6.2 Implementazione

```dart
Future<List<Movie>> getMoviesByCategory(MovieCategory category, {int page = 1}) async {
  try {
    final response = await http.get(Uri.parse(url))
      .timeout(const Duration(seconds: 10));

    switch (response.statusCode) {
      case 200:
        return _parseMovies(response.body);
      
      case 401:
        throw AuthException('API key non valida. Controlla constants.dart');
      
      case 404:
        throw NotFoundException('Categoria film non trovata');
      
      case 429:
        throw RateLimitException(
          'Troppe richieste. Aspetta un minuto e riprova.'
        );
      
      default:
        throw ApiException(
          'Errore TMDB: ${response.statusCode}\n'
          'Riprova tra poco'
        );
    }
  } on TimeoutException {
    throw TimeoutException('Timeout API - connessione lenta?');
  } on SocketException {
    throw NetworkException('No internet connection');
  } on Exception catch (e) {
    throw UnexpectedException('Errore sconosciuto: $e');
  }
}
```

### 6.3 Nel Widget

```dart
movieAsync.when(
  loading: () => const LoadingWidget(),
  
  error: (err, stack) {
    String message = 'Errore sconosciuto';
    
    if (err is AuthException) {
      message = '🔑 ${err.message}';
    } else if (err is RateLimitException) {
      message = '⏱️ ${err.message}';
    } else if (err is NetworkException) {
      message = '📡 ${err.message}';
    } else {
      message = err.toString();
    }
    
    return ErrorWidget(
      message: message,
      onRetry: () => ref.refresh(movieListProvider(category)),
    );
  },
  
  data: (movies) => MovieListWidget(movies: movies),
)
```

---

## <a id="ratelimit"></a>7. Rate Limiting

### 7.1 Limiti TMDB

- Free tier: 40 request/10 secondi
- Paid tier: no limite

### 7.2 Implementazione Throttle

```dart
import 'package:throttle_debounce/throttle_debounce.dart';

class MovieRepository {
  final _throttledGet = Throttle(
    const Duration(seconds: 1),
    onExecute: () => _actualGetMovies(),
  );

  Future<List<Movie>> getMovies() => _throttledGet.call();

  Future<List<Movie>> _actualGetMovies() async {
    // Vera chiamata API
  }
}
```

### 7.3 Caching Aggressivo

```dart
// Salva le risposte, non richiamare se < 5 minuti
class MovieRepository {
  static final _cache = <String, (DateTime, List<Movie>)>{};

  Future<List<Movie>> getMoviesByCategory(MovieCategory cat, {int page = 1}) async {
    final key = '${cat.name}_p$page';
    
    // Check cache
    if (_cache.containsKey(key)) {
      final (timestamp, movies) = _cache[key]!;
      if (DateTime.now().difference(timestamp).inMinutes < 5) {
        return movies;  // Cache hit
      }
    }

    // Cache miss: fetch da API
    final movies = await _fetchFromTmdb(cat, page);
    _cache[key] = (DateTime.now(), movies);
    return movies;
  }
}
```

---

## <a id="testing"></a>8. Testing TMDB Integration

### 8.1 Mock HTTP Responses

```dart
// test/repositories/movie_repository_test.dart

import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('MovieRepository TMDB Integration', () {
    late MovieRepository repo;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      repo = MovieRepository(httpClient: mockClient);
    });

    test('getMoviesByCategory returns movies', () async {
      final mockResponse = '''
      {
        "results": [
          {
            "id": 550,
            "title": "Fight Club",
            "overview": "Test",
            "poster_path": "/test.jpg",
            "backdrop_path": "/test_back.jpg",
            "vote_average": 8.8,
            "runtime": 139,
            "release_date": "1999-10-15",
            "genres": [{"id": 18, "name": "Drama"}],
            "credits": {"cast": [{"name": "Brad Pitt"}]}
          }
        ]
      }
      ''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(mockResponse, 200),
      );

      final movies = await repo.getMoviesByCategory(MovieCategory.nowPlaying);

      expect(movies, isNotEmpty);
      expect(movies[0].title, 'Fight Club');
      expect(movies[0].rating, 8.8);
    });

    test('getMoviesByCategory handles 401 error', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('Unauthorized', 401),
      );

      expect(
        () => repo.getMoviesByCategory(MovieCategory.nowPlaying),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

### 8.2 Integration Test (Reale)

```dart
// test/integration/tmdb_integration_test.dart

void main() {
  group('TMDB Real API Integration (requires internet)', () {
    late MovieRepository repo;

    setUp(() {
      repo = MovieRepository();
    });

    test('fetches now_playing movies', () async {
      final movies = await repo.getMoviesByCategory(MovieCategory.nowPlaying);

      expect(movies, isNotEmpty);
      expect(movies[0].id, isNotEmpty);
      expect(movies[0].title, isNotEmpty);
      expect(movies[0].posterUrl, isNotEmpty);
    });

    test('pagination works', () async {
      final page1 = await repo.getMoviesByCategory(
        MovieCategory.nowPlaying,
        page: 1,
      );
      final page2 = await repo.getMoviesByCategory(
        MovieCategory.nowPlaying,
        page: 2,
      );

      expect(page1[0].id != page2[0].id, isTrue);
    });

    test('handles missing images gracefully', () async {
      final movies = await repo.getMoviesByCategory(MovieCategory.topRated);
      
      for (final movie in movies) {
        // posterUrl può essere vuoto, ok
        expect(movie.title, isNotEmpty);
      }
    });
  });
}
```

---

## 9. Checklist Pre-Release

- [ ] API key configurata in `constants.dart`
- [ ] MovieRepository implementato e testato
- [ ] Pagination funzionante
- [ ] Image caching attivo
- [ ] Error handling per tutti gli status code
- [ ] Rate limiting implementato
- [ ] Test unit con mock passano
- [ ] Test integration (facoltativo) passano
- [ ] Cache key strategy verificato
- [ ] Documentazione TMDB API letta

---

**Documento redatto: Maggio 2026**  
**Prossimo:** DOC-06 — Note Tecniche su Riverpod e Logica
