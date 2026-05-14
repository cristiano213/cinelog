# CineLog — Architettura Tecnica

**Tier 2 — Documento stabile.**
**Versione:** 2.0 (post-pivot social/backend)
**Aggiornato:** Maggio 2026
**Scope:** Architettura *target* dell'app Flutter + Supabase. Pattern, layer, convenzioni di codice. Cosa va dove e perché.
**Audience:** chiunque tocchi il codice Flutter.

> **Nota:** questo documento descrive la struttura *target*, non quella attuale del codebase. Il codice v1 verrà evoluto verso questa struttura durante i moduli del corso. Le divergenze tra codice attuale e questo documento sono mappate in `T1_PROBLEMI_APERTI.md`.

---

## Indice

1. [Stack riassuntivo](#stack)
2. [Layer architetturali](#layer)
3. [Struttura cartelle](#cartelle)
4. [Pattern Riverpod](#riverpod)
5. [Pattern Repository](#repository)
6. [Auth e routing](#auth)
7. [Caricamento dati: on-demand vs eager](#caricamento)
8. [Gestione segreti e configurazione](#segreti)
9. [Gestione errori e UI feedback](#errori)
10. [Tema e stile](#tema)
11. [Testing](#testing)
12. [Anti-pattern da evitare](#antipattern)

---

## <a id="stack"></a>1. Stack riassuntivo

| Layer | Tecnologia | Versione | Ruolo |
|---|---|---|---|
| UI | Flutter + Material 3 | ^3.11.5 | Dichiarativa, reattiva |
| State | flutter_riverpod | ^2.5.1 | DI + reactive state |
| Routing | go_router | ^14.0.0 (target) | Navigation + auth guards |
| Auth + DB | supabase_flutter | ^2.5.0 (target) | Client Supabase |
| Config | flutter_dotenv | ^5.1.0 (target) | Segreti da `.env` |
| HTTP | http | ^1.2.1 | Chiamate REST esterne (TMDB, Places) |
| Maps | google_maps_flutter | ^2.6.0 (target) | Mappa cinema |
| Images | cached_network_image | ^3.3.1 | Cache immagini TMDB |
| Misc | intl, uuid, google_fonts, font_awesome_flutter | varie | Già presenti |

---

## <a id="layer"></a>2. Layer architetturali

```
┌─────────────────────────────────────────────────────────────┐
│  UI Layer (screens/, widgets/)                              │
│  - ConsumerWidget, ConsumerStatefulWidget                   │
│  - Solo render + delega di azioni ai provider               │
│  - Mai chiamate dirette ai servizi esterni                  │
└────────────────────────────┬────────────────────────────────┘
                             │ ref.watch / ref.read
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  State Layer (providers/)                                   │
│  - Notifier, AsyncNotifier, FutureProvider, Provider        │
│  - Espone state immutabile + metodi di mutazione            │
│  - Chiama repository, non servizi diretti                   │
└────────────────────────────┬────────────────────────────────┘
                             │ chiama metodi
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  Repository Layer (repositories/)                           │
│  - Astrae sorgenti dati (Supabase, TMDB, Places, cache)     │
│  - Trasforma DTO esterni in modelli Dart                    │
│  - Lancia exception tipizzate, non gestisce UI              │
└────────────────────────────┬────────────────────────────────┘
                             │ usa
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  Service Layer (services/, core/)                           │
│  - Wrapper di basso livello (SupabaseClient, http client)   │
│  - Cache, retry, timeout                                    │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │  External (Supabase, │
                  │  TMDB, Google Places)│
                  └──────────────────────┘
```

**Regole di flusso**:
- I dati salgono dal basso verso l'alto.
- I comandi (mutazioni) scendono dall'alto verso il basso.
- Un layer non salta layer sottostanti (UI non chiama mai un repository direttamente).
- Un layer non conosce quello sopra (un repository non importa nulla da `providers/`).

---

## <a id="cartelle"></a>3. Struttura cartelle

Struttura target a Modulo 4 completato:

```
lib/
├── main.dart                     # Entry point. async, init dotenv + Supabase.
├── app.dart                      # MaterialApp + router config (opzionale split)
│
├── core/                         # Costanti, config, helper puri (no logica di dominio)
│   ├── config/
│   │   ├── env_config.dart       # Lettura .env, lancio eccezione se mancante
│   │   └── supabase_config.dart  # Wrapper inizializzazione Supabase
│   ├── constants/
│   │   ├── tmdb_constants.dart   # Endpoint, sizes, timeout
│   │   └── app_constants.dart    # Costanti app-wide (limiti, default)
│   ├── theme/
│   │   ├── app_theme.dart        # ThemeData unico
│   │   └── app_colors.dart       # Palette semantica
│   └── utils/
│       ├── date_format.dart      # Helper formatazione
│       └── result.dart           # Tipo Result<T, E> opzionale per error handling
│
├── models/                       # Classi dati immutabili
│   ├── profile.dart
│   ├── cinema.dart               # Versione aggiornata, allineata a tabella cinemas
│   ├── movie.dart                # Esistente, parsing TMDB
│   ├── finance_entry.dart
│   ├── review.dart
│   ├── user_movie_list_item.dart
│   ├── cinema_note.dart
│   └── follow.dart
│
├── repositories/                 # Data access, astrazione sorgenti
│   ├── auth_repository.dart      # Login, signup, logout, sessione corrente
│   ├── profile_repository.dart   # CRUD profili
│   ├── movie_repository.dart     # TMDB (esistente, mantenuto)
│   ├── places_repository.dart    # Google Places (nuovo)
│   ├── cinema_repository.dart    # cinemas table + RPC upsert
│   ├── finance_repository.dart   # finance_entries
│   ├── reviews_repository.dart
│   ├── lists_repository.dart     # user_movie_lists (wishlist + archive unificati)
│   ├── cinema_notes_repository.dart
│   └── follows_repository.dart
│
├── providers/                    # Riverpod
│   ├── auth/
│   │   └── auth_state_provider.dart  # Stream da Supabase, fonte di verità sessione
│   ├── profile/
│   │   ├── my_profile_provider.dart
│   │   └── user_profile_provider.dart  # Profilo altrui (family su user_id)
│   ├── discovery/                # Esistenti, mantenuti
│   │   ├── movie_provider.dart
│   │   └── discovery_provider.dart
│   ├── finance/
│   │   ├── finance_entries_provider.dart
│   │   └── finance_stats_provider.dart
│   ├── reviews/
│   │   ├── my_reviews_provider.dart
│   │   └── movie_review_provider.dart  # family su movie_id
│   ├── lists/
│   │   ├── wishlist_provider.dart
│   │   └── archive_provider.dart
│   ├── cinema/
│   │   ├── cinema_picker_provider.dart
│   │   └── nearby_cinemas_provider.dart
│   └── social/
│       ├── follows_provider.dart
│       └── public_feed_provider.dart
│
├── routing/
│   ├── app_router.dart           # GoRouter config + redirect/guard
│   └── route_names.dart          # Costanti nomi rotte
│
├── screens/                      # Pagine
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── email_verification_screen.dart
│   │   └── reset_password_screen.dart
│   ├── onboarding/
│   │   └── onboarding_screen.dart    # Setup username/display_name post-signup
│   ├── discovery/
│   │   ├── discovery_screen.dart
│   │   ├── search_screen.dart
│   │   └── movie_detail_screen.dart
│   ├── library/
│   │   └── library_screen.dart       # Wishlist + Archive con tabs
│   ├── stats/
│   │   └── stats_screen.dart
│   ├── cinemas/
│   │   ├── cinemas_map_screen.dart
│   │   └── cinema_detail_sheet.dart
│   ├── profile/
│   │   ├── my_profile_screen.dart
│   │   ├── settings_screen.dart      # Visibilità default per categoria
│   │   └── user_profile_screen.dart  # Altrui (family su user_id)
│   └── main_navigation_screen.dart   # Shell con BottomNavBar (5 tab)
│
└── widgets/                      # Componenti riutilizzabili
    ├── common/
    │   ├── error_view.dart
    │   ├── loading_indicator.dart
    │   ├── empty_state.dart
    │   └── visibility_toggle.dart    # Riusabile per review/list/note
    ├── movie/
    │   ├── movie_card.dart
    │   └── movie_poster.dart
    ├── finance/
    │   └── register_cinema_visit_dialog.dart  # Aggiornato con CinemaPicker
    └── cinema/
        └── cinema_picker_sheet.dart  # Bottom sheet selezione cinema
```

**Principi**:
- **Una responsabilità per cartella**. `screens/discovery/` contiene solo screen del flusso discovery.
- **Sotto-cartelle per dominio**, non per tipo tecnico. Si raggruppano i file che cambiano insieme.
- **Naming consistente**: file finiscono in `_screen.dart`, `_provider.dart`, `_repository.dart` quando ha senso.
- Modelli senza suffisso (`profile.dart`, non `profile_model.dart`).

---

## <a id="riverpod"></a>4. Pattern Riverpod

### 4.1 Tipi di provider, quando usarli

| Tipo | Quando | Esempio |
|---|---|---|
| `Provider<T>` | Singleton, dipendenza, valore derivato sincrono | `Provider((ref) => MovieRepository())` |
| `FutureProvider<T>` | Chiamata async one-shot | Caricamento dettagli film |
| `FutureProvider.family<T, P>` | Async parametrizzato | `getMovieDetails(movieId)` |
| `StreamProvider<T>` | Stream esterno | Auth state changes Supabase |
| `NotifierProvider<N, T>` | Stato sincrono con metodi mutazione | Filtri UI |
| `AsyncNotifierProvider<N, T>` | Stato async + metodi (CRUD) | Lista finance dell'utente |
| `AsyncNotifierProvider.family<N, T, P>` | Idem ma parametrizzato | Review di un film specifico |

### 4.2 Struttura tipica `AsyncNotifier`

Per ogni tabella utente Supabase il pattern è:

```dart
class FinanceEntriesNotifier extends AsyncNotifier<List<FinanceEntry>> {
  @override
  FutureOr<List<FinanceEntry>> build() async {
    final repo = ref.watch(financeRepositoryProvider);
    return repo.fetchMyEntries();
  }

  Future<void> addEntry(NewEntryInput input) async {
    final repo = ref.read(financeRepositoryProvider);
    // Optimistic update opzionale: aggiorna state subito, rollback su errore
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.insert(input);
      return repo.fetchMyEntries();
    });
  }

  Future<void> updateEntry(String id, EntryPatch patch) async { ... }
  Future<void> deleteEntry(String id) async { ... }
}

final financeEntriesProvider =
    AsyncNotifierProvider<FinanceEntriesNotifier, List<FinanceEntry>>(
  FinanceEntriesNotifier.new,
);
```

**Cose importanti**:
- `build()` viene chiamato la prima volta che un widget watcha. **Niente più caricamento eager al boot**.
- `state = await AsyncValue.guard(...)` gestisce automaticamente try/catch e produce `AsyncError` se qualcosa fallisce.
- I metodi di mutazione fanno **refetch completo** dopo la modifica (semplice e corretto). Optimistic update si valuta in fase polish.

### 4.3 Provider "computed" (osservano altri)

`statsProvider` è derivato da `financeEntriesProvider` + `reviewsProvider`. Pattern:

```dart
final statsProvider = Provider<AppStats>((ref) {
  final entries = ref.watch(financeEntriesProvider).valueOrNull ?? [];
  final reviews = ref.watch(reviewsProvider).valueOrNull ?? [];
  return AppStats.compute(entries, reviews);
});
```

**Mai chiamare repository direttamente** in un provider computed. Usa altri provider.

### 4.4 Regole d'oro

1. **Niente `ref.invalidate` su Notifier che parte vuoto** (problema #4 in `T1_PROBLEMI_APERTI`). Se vuoi rinfrescare i dati, chiama un metodo `refresh()` esplicito del Notifier che faccia refetch.
2. **`ref.watch` nei build, `ref.read` nelle azioni** (handler onPressed, callback).
3. **I provider sono top-level constants**, mai dentro classi/widget.
4. **Dipendenze tramite `ref.watch`**, mai chiamare il singleton direttamente.
5. **Naming**: `xxxProvider` per il provider, `XxxNotifier` per la classe.

---

## <a id="repository"></a>5. Pattern Repository

### 5.1 Responsabilità

Un repository:
- Conosce **una** sorgente di dati (Supabase, TMDB, Places, cache locale).
- Ritorna **modelli Dart**, non Map<String, dynamic> grezze.
- Lancia **eccezioni tipizzate** in caso di errore.
- Non sa nulla di UI, navigation, snackbar.

### 5.2 Esempio: `FinanceRepository`

```dart
class FinanceRepository {
  final SupabaseClient _client;
  FinanceRepository(this._client);

  Future<List<FinanceEntry>> fetchMyEntries() async {
    try {
      final rows = await _client
          .from('finance_entries')
          .select()
          .order('watched_at', ascending: false);
      return rows.map((r) => FinanceEntry.fromSupabase(r)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException.fromPostgrest(e);
    }
  }

  Future<void> insert(NewEntryInput input) async {
    try {
      await _client.from('finance_entries').insert(input.toSupabase());
    } on PostgrestException catch (e) {
      throw RepositoryException.fromPostgrest(e);
    }
  }
}

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(Supabase.instance.client);
});
```

### 5.3 Mapping modelli

Ogni modello con persistenza ha **due famiglie di costruttori/serializzatori**:

| Famiglia | Quando |
|---|---|
| `fromSupabase(Map) / toSupabase()` | Per la tabella Supabase. Convenzioni snake_case. |
| `fromTmdbJson(Map)` | Solo `Movie`, per parsing TMDB. |
| `copyWith(...)` | Sempre, per immutabilità. |
| `fromJson / toJson` legacy | Solo durante migrazione, poi rimosso. |

### 5.4 Eccezioni tipizzate

Classe base:

```dart
sealed class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);

  factory RepositoryException.fromPostgrest(PostgrestException e) {
    // Mappa codici noti su tipi specifici
    switch (e.code) {
      case 'PGRST301': return AuthRequiredException();
      case '23505': return DuplicateException(e.message);
      case '23514': return ValidationException(e.message);
      default: return UnknownDbException(e.message);
    }
  }
}

class AuthRequiredException extends RepositoryException {
  AuthRequiredException() : super('Autenticazione richiesta');
}
class DuplicateException extends RepositoryException {
  DuplicateException(super.message);
}
class ValidationException extends RepositoryException {
  ValidationException(super.message);
}
class UnknownDbException extends RepositoryException {
  UnknownDbException(super.message);
}
```

Vantaggio: il provider può fare `catch (e) { ... }` distinguendo i casi (mostra "credenziali scadute, rilogga" vs "errore generico").

---

## <a id="auth"></a>6. Auth e routing

### 6.1 `authStateProvider`

Stream che riflette lo stato della sessione Supabase. Fonte di verità unica per "sono loggato?".

```dart
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Helper sincrono per il router
final currentSessionProvider = Provider<Session?>((ref) {
  final state = ref.watch(authStateProvider).valueOrNull;
  return state?.session ?? Supabase.instance.client.auth.currentSession;
});
```

### 6.2 Router con redirect

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      // Non loggato → /auth/login
      if (!isAuth && !isAuthRoute) return '/auth/login';
      // Loggato e ancora su /auth → /
      if (isAuth && isAuthRoute) return '/';
      // Loggato ma senza username completo → /onboarding
      // (logica controllata dal provider profilo, qui semplificato)
      return null;
    },
    routes: [
      // ... rotte
    ],
  );
});
```

**Chiave**: il redirect è **una sola decisione, in un solo posto**. Le singole screen non implementano "se non sei loggato vai al login": è il router che decide.

### 6.3 Onboarding obbligatorio

Dopo signup, l'utente ha un record `profiles` con `username=''` (default). Il redirect lo forza su `/onboarding` finché non compila username e display name. Solo allora può accedere al resto dell'app.

---

## <a id="caricamento"></a>7. Caricamento dati: on-demand vs eager

### 7.1 Regola

**On-demand è il default. Eager solo se assolutamente necessario.**

### 7.2 Cosa è eager
Solo l'**inizializzazione dei servizi globali**:
- Carica `.env`
- Inizializza `Supabase.initialize`
- Carica `authStateProvider` (è un Stream, parte subito)

### 7.3 Cosa è on-demand
**Tutti i dati utente**:
- `financeEntriesProvider` carica quando la screen Stats viene aperta
- `wishlistProvider` carica quando la tab Library è aperta
- `myReviewsProvider` carica quando l'utente visita il proprio profilo

### 7.4 Pattern in `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const ProviderScope(child: CineLogApp()));
}
```

Niente `initializeAppProvider` che carica tutto. La schermata di startup mostra al massimo lo splash mentre `authStateProvider` decide se andare al login o alla home.

---

## <a id="segreti"></a>8. Gestione segreti e configurazione

### 8.1 File `.env`

Mai committato. Esempio:

```
TMDB_API_KEY=xxx
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
GOOGLE_PLACES_API_KEY=xxx
```

### 8.2 File `.env.example`

Committato, placeholder:

```
TMDB_API_KEY=your_tmdb_key_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
GOOGLE_PLACES_API_KEY=your_google_places_key_here
```

### 8.3 Lettura via `EnvConfig`

Wrapper che centralizza la lettura e lancia eccezione se manca:

```dart
class EnvConfig {
  static String get tmdbApiKey => _required('TMDB_API_KEY');
  static String get supabaseUrl => _required('SUPABASE_URL');
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');
  static String get googlePlacesApiKey => _required('GOOGLE_PLACES_API_KEY');

  static String _required(String key) {
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) {
      throw StateError('Missing env var: $key');
    }
    return v;
  }
}
```

### 8.4 Note di sicurezza

- **TMDB key**: per progetto personale resta nel client. Per produzione vera si fa un **proxy server** (Edge Function Supabase) che riceve la richiesta dal client, aggiunge la key, chiama TMDB. Pattern valutato nel Modulo 5 come esercizio facoltativo.
- **Supabase anon key**: pubblica per design. La sicurezza viene da RLS, non dal nascondere la key.
- **Google Places key**: identica al TMDB. Se il volume cresce, restrizione per app bundle ID + proxy server.
- **Mai loggare**: token, password, key, sessione completa.

---

## <a id="errori"></a>9. Gestione errori e UI feedback

### 9.1 Tassonomia

| Tipo errore | Esempio | Come gestire |
|---|---|---|
| Validazione utente | "prezzo deve essere > 0" | Snackbar + non chiudere il form |
| Rete | timeout TMDB | Banner "connessione assente, riprova" |
| Auth | sessione scaduta | Redirect a /auth/login + snackbar |
| RLS deny | "violates row-level security" | "non hai permessi" (raro, indica bug) |
| Unknown | qualunque eccezione non mappata | "qualcosa è andato storto" + log dettagliato |

### 9.2 Pattern UI

In una screen con AsyncValue:

```dart
final asyncFinance = ref.watch(financeEntriesProvider);

return asyncFinance.when(
  loading: () => const LoadingIndicator(),
  error: (err, stack) => ErrorView(
    error: err,
    onRetry: () => ref.invalidate(financeEntriesProvider),
  ),
  data: (entries) => entries.isEmpty
      ? const EmptyState(message: 'Nessuna visione registrata')
      : ListView(...),
);
```

Mai mostrare lo stack trace all'utente. Mostralo solo in debug build.

### 9.3 Logging

- Usare `debugPrint` (no-op in release) per log normali.
- Per errori, package `logger` con livelli.
- Mai `print()`.
- Mai loggare token/password/payload completi che possano contenere PII.

---

## <a id="tema"></a>10. Tema e stile

### 10.1 ThemeData centralizzato

```dart
class AppTheme {
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPurple,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.poppinsTextTheme(/* ... */),
      // ... altri override
    );
  }
}
```

### 10.2 Colori semantici, non Material crudi

```dart
class AppColors {
  static const brandPurple = Color(0xFF673AB7);
  static const successGreen = Color(0xFF4CAF50);
  static const warningAmber = Color(0xFFFFB300);
  static const errorRed = Color(0xFFE53935);
}
```

Negli screen: `Theme.of(context).colorScheme.primary`, non `Colors.deepPurpleAccent`.

### 10.3 Regola

Nuovo codice scritto da Modulo 1 in poi: **niente `Colors.X` hardcoded nei widget**, eccetto colori semantici neutri (es. `Colors.amber` per stelle voto). Il codice esistente sarà migrato nel Modulo 6 (polish).

---

## <a id="testing"></a>11. Testing

Strategia di alto livello. Dettaglio in `T2_NOTE_TECNICHE.md` (a generazione successiva).

### 11.1 Cosa testare in priorità

1. **Logica nei Notifier** (unit test): calcoli, transizioni di stato.
2. **Repository** (test integrazione con DB locale Supabase o mock).
3. **RLS** (test SQL diretti: §15 di `T2_SCHEMA_DATI`).
4. **Widget critici**: form di registrazione visione, login, signup.

### 11.2 Cosa NON testare

- Singoli widget di presentazione (perdita di tempo).
- Animazioni.
- Codice generato.

### 11.3 Tooling

- `flutter_test` (default).
- `mocktail` per mock.
- `riverpod_test` (utility per test provider).

---

## <a id="antipattern"></a>12. Anti-pattern da evitare

Una checklist negativa. Se ti accorgi di farne uno, fermati.

### Riverpod
- ❌ `ref.invalidate` su Notifier che parte vuoto.
- ❌ Provider dentro classi o build method.
- ❌ `ref.read` in build (usa `watch`).
- ❌ Chiamare repository direttamente dalla UI senza passare per un provider.
- ❌ Caricare dati nel `build()` di un widget con `Future.microtask` o simili.

### Architettura
- ❌ UI che importa `repositories/`.
- ❌ Repository che importa `providers/` (dipendenza circolare).
- ❌ Modello con metodi che chiamano API (sono dumb data class).
- ❌ Logica di business nel widget (sposta in Notifier).
- ❌ Eager loading di tutto al boot.

### Sicurezza
- ❌ Validazione solo client-side per campi critici.
- ❌ Segreti hardcoded.
- ❌ `print` di token o payload sensibili.
- ❌ Trust di dati ricevuti senza validazione (anche da Supabase, se vengono da query con join utenti).

### Stile
- ❌ `Colors.X` hardcoded fuori da `core/theme/`.
- ❌ `withOpacity` (deprecato, usa `withValues`).
- ❌ `print` (usa `debugPrint`).
- ❌ Stringhe in italiano sparse nel codice (centralizza per i18n futuro).

### Database
- ❌ Validazione DB-side rilassata "tanto c'è il client".
- ❌ `for all` nelle policy RLS.
- ❌ `auth.uid()` diretto in WHERE (usa `(select auth.uid())`).
- ❌ Cancellazione cinema o dati che possano essere referenziati.

---

## Riferimenti

- Visione funzionale: `T2_VISIONE_FUNZIONALE.md`
- Schema dati completo: `T2_SCHEMA_DATI.md`
- API esterne (TMDB, Places): `T2_API_ESTERNE.md` (a generazione successiva)
- Pattern Riverpod approfonditi: `T2_NOTE_TECNICHE.md` (a generazione successiva)
- Stato corrente del progetto: `T1_STATO_PROGETTO.md`
- Problemi aperti mappati: `T1_PROBLEMI_APERTI.md`
- Convenzioni operative: `T2_CONVENZIONI.md`
