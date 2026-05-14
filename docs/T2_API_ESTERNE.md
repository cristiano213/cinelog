# CineLog — API Esterne (TMDB + Google Places)

**Tier:** 2 — Riferimento tecnico stabile  
**Versione:** 1.0  
**Aggiornato:** Maggio 2026  
**Scope:** Integrazione TMDB (attiva) e Google Places (scaffolding — Modulo 3).

---

## Indice

1. [TMDB API](#1-tmdb-api)
2. [Google Places API](#2-google-places-api)
3. [Strategia di cache e rate limiting](#3-strategia-di-cache-e-rate-limiting)
4. [Gestione errori comuni](#4-gestione-errori-comuni)
5. [Costi e quote](#5-costi-e-quote)

---

## 1. TMDB API

### 1.1 Base URL e config

Tutte le costanti sono centralizzate in `lib/core/constants.dart`:

```dart
// lib/core/constants.dart — class TmdbConstants
class TmdbConstants {
  // API key hardcoded — da spostare in .env (Modulo 0.A)
  static const String apiKey = '2952ea50fc43f4fa0f41f0fed731f44f';

  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  static const String posterSize = 'w500';    // usato per poster grandi
  static const String backdropSize = 'w780';  // usato per backdrop

  static const Duration apiTimeout = Duration(seconds: 10);
}
```

La `posterSize` della costante è `w500`, ma il getter `smallPosterUrl` in `Movie` usa `w185` costruito a mano (non dalla costante). Vedere sezione 1.4.

### 1.2 Endpoint usati nel progetto

Tutti gli endpoint sono costruiti e chiamati in `lib/repositories/movie_repository.dart`.

#### `/movie/now_playing`, `/movie/upcoming`, `/movie/top_rated`, `/trending/movie/week`

Usati da `getMoviesByCategory`. La categoria viene mappata all'endpoint in `_getEndpoint()`:

```dart
// lib/repositories/movie_repository.dart — MovieRepository._getEndpoint()
String _getEndpoint(MovieCategory category) {
  switch (category) {
    case MovieCategory.nowPlaying: return '/movie/now_playing';
    case MovieCategory.upcoming:   return '/movie/upcoming';
    case MovieCategory.topRated:   return '/movie/top_rated';
    case MovieCategory.trending:   return '/trending/movie/week';
  }
}
```

URL finale costruita in `getMoviesByCategory`:

```
${TmdbConstants.baseUrl}$endpoint?api_key=...&page=$page&language=it
```

Parametri: `api_key` (obbligatorio), `page` (default 1), `language=it` (hardcoded).  
Ritorna: `List<Movie>` (senza `runtime`, `genres`, `cast` — solo da detail endpoint).  
Chiamato da: `movieListProvider` (schermata principale) e `discoveryProvider` (infinite scroll).

#### `/discover/movie`

Usato da `getMoviesByGenre` e `getMoviesByGenres`:

```
${TmdbConstants.baseUrl}/discover/movie?api_key=...&with_genres=$genreId&page=$page&language=it&sort_by=popularity.desc
```

Parametri extra: `with_genres` (id singolo o lista separata da virgola), `sort_by=popularity.desc`.  
Ritorna: `List<Movie>`.  
Chiamato da: `genreMoviesProvider`.

#### `/search/movie`

Usato da `searchMovies`:

```
${TmdbConstants.baseUrl}/search/movie?api_key=...&query=$encodedQuery&page=$page&language=it
```

Parametri: `query` (URL-encoded), `page`.  
Ritorna: `List<Movie>`.  
Chiamato da: `lib/screens/search_screen.dart` (via repository diretto o provider dedicato — TODO: da verificare).

#### `/movie/{id}?append_to_response=credits`

Usato da `getMovieDetails`. Unico endpoint che ritorna `runtime`, `genres` e `cast`:

```
${TmdbConstants.baseUrl}/movie/$movieId?api_key=...&append_to_response=credits&language=it
```

Ritorna: `Movie` singolo con tutti i campi popolati.  
Chiamato da: `lib/screens/movie_detail_screen.dart`.

### 1.3 Parsing — `Movie.fromTmdbJson`

Il parsing TMDB è centralizzato in `lib/models/movie.dart`:

```dart
// lib/models/movie.dart — Movie.fromTmdbJson()
factory Movie.fromTmdbJson(Map<String, dynamic> json) {
  return Movie(
    id: json['id'].toString(),
    title: json['title'] ?? '',
    overview: json['overview'] ?? '',
    posterPath: json['poster_path'] ?? '',
    backdropPath: json['backdrop_path'] ?? '',
    voteAverage: (json['vote_average'] ?? 0).toDouble(),
    runtimeMinutes: json['runtime'] ?? 0,           // solo da /movie/{id}
    releaseDate: json['release_date'] != null
        ? DateTime.tryParse(json['release_date'])
        : null,
    genres: json['genres'] != null                  // solo da /movie/{id}
        ? List<String>.from(
            (json['genres'] as List).map((g) => g['name'].toString()))
        : [],
    cast: json['credits']?['cast'] != null          // solo da /movie/{id} con append_to_response=credits
        ? List<String>.from(
            (json['credits']['cast'] as List).map((c) => c['name'].toString()))
        : [],
  );
}
```

Campi estratti:

| Campo JSON TMDB       | Campo `Movie`        | Disponibile in endpoint lista? |
|-----------------------|----------------------|-------------------------------|
| `id`                  | `id` (String)        | si                            |
| `title`               | `title`              | si                            |
| `overview`            | `overview`           | si                            |
| `poster_path`         | `posterPath`         | si                            |
| `backdrop_path`       | `backdropPath`       | si                            |
| `vote_average`        | `voteAverage`        | si                            |
| `release_date`        | `releaseDate`        | si                            |
| `runtime`             | `runtimeMinutes`     | **no** (solo detail)          |
| `genres[].name`       | `genres`             | **no** (solo detail)          |
| `credits.cast[].name` | `cast`               | **no** (solo detail)          |

Conseguenza: un `Movie` caricato da lista ha `runtimeMinutes = 0`, `genres = []`, `cast = []`. La schermata di dettaglio deve chiamare `getMovieDetails` per popolare questi campi.

### 1.4 Image URLs

TMDB fornisce solo il path relativo dell'immagine. L'URL completa è costruita concatenando base URL + size + path.

I getter sono definiti direttamente in `Movie`, non usano le costanti di `TmdbConstants`:

```dart
// lib/models/movie.dart — getter in class Movie

String get fullPosterUrl {
  if (posterPath.isEmpty) return '';
  return 'https://image.tmdb.org/t/p/w500$posterPath';
}

String get smallPosterUrl {
  if (posterPath.isEmpty) return '';
  return 'https://image.tmdb.org/t/p/w185$posterPath';
}

String get fullBackdropUrl {
  if (backdropPath.isEmpty) return '';
  return 'https://image.tmdb.org/t/p/w780$backdropPath';
}
```

Sizes usate: poster grande `w500`, poster piccolo `w185`, backdrop `w780`. Se `posterPath` è stringa vuota (film senza immagine), i getter ritornano stringa vuota — la UI deve gestire il fallback.

### 1.5 Localizzazione

Tutte le chiamate API includono `language=it` hardcoded nel parametro query. Questo impatta:
- titoli (localizzati se disponibile la traduzione italiana)
- overview (localizzato se disponibile)
- nessun impatto su dati numerici (rating, runtime)

Il parametro `language` è costruito inline nelle URL, non è una costante. Non esiste ancora un meccanismo per cambiare lingua a runtime.

---

## 2. Google Places API

> **Sezione SCAFFOLD: l'integrazione verrà implementata nel Modulo 3.**
> I dettagli di configurazione, costi e implementazione sono placeholder da completare in quella sessione.

### 2.1 Scopo nell'app

Identificazione canonica dei cinema. Il problema attuale (v1): il nome del cinema è una stringa libera inserita dall'utente — lo stesso cinema può essere salvato come "UCI Cinemas", "UCI Bicocca", "uci bicocca", generando dati spezzettati nelle statistiche.

La soluzione prevista: ogni cinema reale avrà un `place_id` univoco (identificatore Google). L'associazione `place_id → nome canonico` viene salvata nel database Supabase e condivisa tra tutti gli utenti. Due utenti che visitano lo stesso cinema avranno lo stesso `place_id`.

### 2.2 API target

Google Places API (New), endpoint principali:
- `places:searchNearby` — cerca cinema vicini alla posizione GPS dell'utente
- `places:searchText` — cerca per testo (es. "UCI Bicocca Milano")

Documentazione: https://developers.google.com/maps/documentation/places/web-service/overview

### 2.3 Integrazione prevista

```
UI: CinemaPickerSheet
  → PlacesRepository.searchNearby() / searchText()
    → Google Places API (New)
      → risultati mostrati in lista con autocomplete
        → utente seleziona cinema
          → Supabase RPC upsert_cinema_from_place(place_id, display_name, ...)
            → tabella `cinemas` aggiornata/inserita
              → visita registrata con cinema_id (FK)
```

Componenti da creare nel Modulo 3:
- `lib/repositories/places_repository.dart` (`PlacesRepository`)
- Widget `CinemaPickerSheet` con autocomplete e lista cinema vicini
- RPC Supabase `upsert_cinema_from_place(...)` (vedi `T2_SCHEMA_DATI.md` §11.4 — TODO: da produrre)

### 2.4 Setup richiesto

TODO da completare al Modulo 3:
- Creazione progetto Google Cloud Platform
- Abilitazione Places API (New) nel progetto GCP
- Generazione API key con restrizioni (Android app bundle + iOS bundle ID)
- Configurazione budget cap su Google Cloud (alert a soglia definita)
- Inserimento key in `.env` come `GOOGLE_PLACES_API_KEY`
- Aggiunta a `.env.example` come placeholder

### 2.5 Costi

TODO da verificare al Modulo 3:
- Free tier mensile: $200 di crediti GCP al mese
- SKU Places New: costo variabile in base ai campi richiesti nella field mask
- Stima d'uso: bassa (ricerca cinema avviene solo al momento del check-in)

---

## 3. Strategia di cache e rate limiting

### 3.1 Cache TMDB attuale

`MovieRepository` implementa una cache in memoria statica con TTL di 5 minuti:

```dart
// lib/repositories/movie_repository.dart — MovieRepository

static final _cache = <String, (DateTime, List<Movie>)>{};
static const Duration _cacheTtl = Duration(minutes: 5);

Future<List<Movie>> _fetchMovies(String url, String cacheKey) async {
  // ... chiamata HTTP ...
  _cache[cacheKey] = (DateTime.now(), movies);
  return movies;
}
```

La chiave cache è costruita come `${category.name}_p$page` per le categorie, `search_${query}_p$page` per le ricerche, `genre_${genreId}_p$page` per i generi. Il check avviene in `getMoviesByCategory` prima di eseguire la chiamata HTTP:

```dart
// lib/repositories/movie_repository.dart — MovieRepository.getMoviesByCategory()
if (_cache.containsKey(cacheKey)) {
  final (timestamp, movies) = _cache[cacheKey]!;
  if (DateTime.now().difference(timestamp).inMinutes < _cacheTtl.inMinutes) {
    return movies;  // cache hit
  }
}
```

### 3.2 Limitazioni note

- La cache è applicata solo alle chiamate che passano per `_fetchMovies` (endpoint lista). `getMovieDetails` non è cachato: ogni apertura della schermata di dettaglio esegue una chiamata HTTP.
- La cache è statica (`static final`) a livello di classe: sopravvive per tutta la sessione app ma si azzera al riavvio.
- Non c'è limite esplicito alla dimensione della cache: cresce illimitatamente in sessioni lunghe.
- La cache TMDB è inaccessibile dall'esterno della classe (nessun provider espone `clearCache()` alla UI, anche se il metodo esiste).

### 3.3 Strategia futura

La cache TMDB non è prioritaria per Supabase. Eventuali miglioramenti da valutare in futuro:
- Persistenza su disco con `hive` o `path_provider` per cache tra sessioni (non urgente)
- Limite dimensione cache (LRU o purge per TTL scaduto)
- Caching di `getMovieDetails` per evitare chiamate ripetute sulla stessa schermata

---

## 4. Gestione errori comuni

### 4.1 TMDB — pattern attuale

Il metodo privato `_fetchMovies` gestisce gli errori con `print` + `rethrow`:

```dart
// lib/repositories/movie_repository.dart — MovieRepository._fetchMovies()
try {
  final response = await http.get(Uri.parse(url)).timeout(TmdbConstants.apiTimeout);

  if (response.statusCode != 200) {
    throw Exception('TMDB error: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as Map;
  final results = data['results'] as List? ?? [];
  final movies = results.map((m) => Movie.fromTmdbJson(m as Map<String, dynamic>)).toList();

  _cache[cacheKey] = (DateTime.now(), movies);
  return movies;
} catch (e) {
  print('Error fetching movies from $url: $e');
  rethrow;
}
```

Il `rethrow` propaga l'eccezione al `FutureProvider` o `AsyncNotifier` chiamante, che la trasforma in `AsyncValue.error`. La UI riceve lo stato di errore e lo mostra tramite `.when(error: ...)`.

Codici HTTP gestiti:

| Codice | Causa                           | Comportamento attuale             |
|--------|---------------------------------|-----------------------------------|
| 200    | OK                              | parsing normale                   |
| != 200 | qualsiasi errore TMDB           | `throw Exception('TMDB error: $code')` |
| —      | timeout (> 10s)                 | `TimeoutException` da `http`     |
| —      | no connessione                  | `SocketException` da `http`       |

Non ci sono eccezioni custom (`AuthException`, `RateLimitException`, ecc.): tutti gli errori vengono avvolti in `Exception` generica. La distinzione per status code non è implementata.

### 4.2 Google Places (futuro)

Da documentare al Modulo 3.

---

## 5. Costi e quote

### 5.1 TMDB

- **Licenza:** gratuita per uso non commerciale. Richiede attribution nella UI se l'app viene pubblicata ("This product uses the TMDB API but is not endorsed or certified by TMDB").
- **API key:** ottenibile gratuitamente su https://www.themoviedb.org/settings/api
- **Quote:** non documentate come hard limit; il soft limit documentato è ~40 req/10sec. Per un'app single-user il consumo normale è di pochi request al minuto.
- **Stato attuale:** la API key è hardcoded in `lib/core/constants.dart` (problema da risolvere nel Modulo 0.A con `flutter_dotenv`).

### 5.2 Google Places

TODO da verificare al Modulo 3 quando si attiva l'account GCP.
- Free tier: $200/mese di crediti GCP
- SKU Places New: tariffe per field mask (campi richiesti)
- Stima: costo trascurabile per uso single-user in fase di sviluppo
