# CineLog — Problemi Aperti e Punti di Attenzione

**Tier 1 — Documento vivo.**
**Aggiornato:** Maggio 2026 (creato a fine Modulo 0.1, analisi codice)
**Scope:** Lista completa dei bug, smell architetturali e punti di attenzione emersi dall'analisi del codebase v1. Bussola operativa per i moduli successivi.
**Audience:** chiunque debba pianificare interventi sul codice.

> **Convenzione**: ogni problema ha un ID numerico stabile. Quando un fix lo chiude, il problema viene marcato `[CHIUSO - Modulo N]` ma NON rimosso dal documento. L'ID è la "memoria di lungo termine" del progetto.

---

## Legenda priorità

- 🔴 **Grave** — sicurezza, bug logico, problema che blocca il pivot al backend
- 🟡 **Medio** — bug o limitazione che non blocca ma va sistemato nel modulo opportuno
- 🟢 **Minore** — smell, polish, lint, refactoring opportunistico

## Indice rapido per priorità

**Gravi aperti (🔴)**: #1, #2, #3, #4, #5, #6, #19, #20

**Medi aperti (🟡)**: #21

**Minori aperti (🟢)**: #7, #8, #9, #10, #11, #12, #13, #14, #15, #16, #17, #18

---

## Problemi

### #1 🔴 — API key TMDB hardcoded in `constants.dart`
- **File**: `lib/core/constants.dart`
- **Sintomo**: `static const String apiKey = '2952ea50fc43f4fa0f41f0fed731f44f';` esposto nel sorgente.
- **Causa**: scelta iniziale di pre-backend. Convenzione di sicurezza assente.
- **Rischio**: chiunque legga il repo (o la sua history Git) ottiene la key. Anche se per TMDB non causa danni economici diretti, è violazione di una regola d'oro.
- **Fix proposto**: spostare in `.env` non committato, leggere via `flutter_dotenv`. Rigenerare la key sulla dashboard TMDB (la corrente è da considerare compromessa).
- **Modulo di chiusura**: 0.A (sicurezza e pulizia repo)

---

### #2 🔴 — Cinema come stringa libera ovunque
- **File coinvolti**: `models/finance_entry.dart`, `models/cinema_note.dart`, `providers/finance_provider.dart`, `providers/cinema_notes_provider.dart`, `providers/stats_provider.dart`, `widgets/register_cinema_visit_dialog.dart`
- **Sintomo**: l'utente digita "UCI Terni" oggi e "Uci Terni" domani. L'app li tratta come cinema diversi. Conseguenze: stats bugate (cinema preferito errato), cinema_notes non si aggancia, prezzo medio per cinema impossibile da calcolare.
- **Causa**: nessuna entità canonica di "cinema". Esiste `models/cinema.dart` ma è codice morto, mai importato.
- **Rischio**: corruzione semantica dei dati storici dell'utente.
- **Fix proposto**: entità `cinemas` su Supabase popolata da Google Places. `finance_entries.cinema_id` come FK. CinemaPicker UI con autocomplete. Migrazione storica dei dati esistenti (best effort: fuzzy match per nome).
- **Modulo di chiusura**: 3 (cinema canonici da Google Places)

---

### #3 🔴 — Validazione dati assente
- **File coinvolti**: tutti i modelli + dialog + provider
- **Sintomo**:
  - `priceEur` accetta -1000, 0.001, 999999. Solo il dialog fa `price > 0`, niente upper bound.
  - `userRating` int senza CHECK 0-10: si possono salvare valori arbitrari.
  - `reviewText` zero limiti di lunghezza.
  - `cinema` stringa senza length check.
- **Causa**: validazione solo UI, niente schema-level. Principio "il frontend non protegge nulla" violato.
- **Rischio**: dati corrotti se la UI viene bypassata. Con backend, sicuramente bypassabile (chiunque può fare POST manuale via Postman).
- **Fix proposto**: CHECK constraint su tutti i campi sensibili nel DB (range numerici + length text). Mantenere validazione UI come UX. Vedi `T2_SCHEMA_DATI` §6/7/8/9.
- **Modulo di chiusura**: 2 (finance, primo caso) → 4 (gli altri)

---

### #4 🔴 — `ref.invalidate(cinemaNotesProvider)` resetta lo stato invece di rinfrescarlo
- **File**: `lib/providers/finance_provider.dart`, metodo `updateEntry`
- **Sintomo**: dopo aggiornamento di una finance_entry, le cinema_notes vengono azzerate finché non si fa `loadFromDisk` di nuovo (riavvio app o navigazione).
- **Causa**: `cinemaNotesProvider.build()` ritorna `[]`. `ref.invalidate` ricostruisce il provider quindi torna a `[]`. È un bug subdolo: funziona finché non si testa seriamente.
- **Rischio**: in produzione l'utente "perderebbe" le note finché non riavvia.
- **Fix proposto**: rimuovere la riga `ref.invalidate(cinemaNotesProvider)` da `updateEntry`. Stessa logica già rimossa in `addVisione` con commento esplicito ("appStatsProvider si aggiornerà DA SOLO perché fa ref.watch"). Da estendere coerentemente.
- **Modulo di chiusura**: 0.B (quality baseline) — fix immediato perché ha rischio zero ed è bug puro

---

### #5 🔴 — `MovieDetailScreen` non carica i dettagli del film
- **File**: `lib/screens/movie_detail_screen.dart`
- **Sintomo**:
  - Durata mostrata sempre "N/A" anche se TMDB ce l'ha.
  - Lista generi vuota (non viene visualizzata).
  - Cast non visibile.
- **Causa**: il `Movie` arriva da `/movie/now_playing` o `/discover/movie`, endpoint che **non** restituiscono `runtime`, `genres`, `cast`. La chiamata `movieRepository.getMovieDetails(movieId)` esiste ma non viene mai invocata.
- **Rischio**: feature pubblicata ma di fatto monca.
- **Fix proposto**: la screen accetta `Movie` come bootstrap + chiama `getMovieDetails(movie.id)` in un `FutureProvider.family`. Mostra dati base mentre carica i dettagli. Pattern: il `Movie` passato è solo un seme, i dati completi vengono da una richiesta dedicata.
- **Modulo di chiusura**: 4 (rifinitura MovieDetailScreen quando aggiungiamo review)

---

### #6 🔴 — Inizializzazione bloccante incompatibile col backend
- **File**: `lib/main.dart`, `lib/providers/app_initialization_provider.dart`
- **Sintomo**: `_InitializedApp` aspetta che tutti i provider (`finance`, `reviews`, `wishlist`, `cinemaNotes`) abbiano caricato i loro dati prima di mostrare UI. Oggi ~50ms (SharedPreferences locale). Domani con Supabase: 4 round-trip di rete = 2-3s di schermata di caricamento prima ancora del login.
- **Causa**: pattern "load all then render" pensato per persistenza locale, inadatto a remoto.
- **Rischio**: UX disastrosa al primo avvio backend.
- **Fix proposto**:
  1. `main()` diventa `async`, fa `WidgetsFlutterBinding.ensureInitialized()`, `dotenv.load()`, `Supabase.initialize()`.
  2. `authStateProvider` ascolta `Supabase.instance.client.auth.onAuthStateChange`.
  3. Routing tramite `go_router` con redirect basato su `authStateProvider`.
  4. Caricamento dei dati utente avviene **on-demand** nelle rispettive schermate (`financeProvider` carica i dati quando si apre Stats, non al boot).
- **Modulo di chiusura**: 1 (Supabase setup + auth)

---

### #7 🟢 — `print()` ovunque
- **File coinvolti**: `repositories/local_storage_service.dart`, `repositories/movie_repository.dart` (17 occorrenze tra i due)
- **Sintomo**: log di errore via `print`, non strippato in release build.
- **Fix proposto**: `debugPrint` (built-in Flutter, no-op in release) o package `logger` per livelli (info/warn/error).
- **Modulo di chiusura**: 0.B (quality baseline)

---

### #8 🟢 — `withOpacity` deprecato
- **File coinvolti**: `screens/movie_detail_screen.dart` (e potenzialmente altri)
- **Sintomo**: warning di lint Flutter 3.27+. Sostituito da `withValues(alpha: ...)`.
- **Fix proposto**: search & replace globale. Coesiste già col nuovo pattern (es. `stats_screen` usa `withValues`).
- **Modulo di chiusura**: 0.B

---

### #9 🟢 — Hero tag inconsistente
- **File coinvolti**: `widgets/movie_card.dart` (ha Hero), `screens/movie_detail_screen.dart` (ha Hero), `screens/discovery_screen.dart` `_MoviePosterCard` (NO Hero)
- **Sintomo**: animazione Hero parte dalla `SearchScreen` (usa `MovieCard`) ma non dal carousel Discovery.
- **Causa**: rimossa per evitare duplicate-tag exception.
- **Fix proposto**: tag univoci per contesto (`'movie-hero-discovery-${movie.id}'`, `'movie-hero-search-${movie.id}'`).
- **Modulo di chiusura**: opportunisticamente quando si rifinisce Discovery, non urgente

---

### #10 🟢 — `monthKey` non zero-padded
- **File**: `lib/models/finance_entry.dart`
- **Sintomo**: `'${dateTime.year}-${dateTime.month}'` produce `"2026-3"` e `"2026-12"`. Ordering alfabetico sbagliato (`"2026-10" < "2026-3"`).
- **Impatto reale**: rompe grafici trend mensile quando l'utente arriva a 10+ mesi di dati.
- **Fix proposto**: `'${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}'`.
- **Modulo di chiusura**: 0.B

---

### #11 🟢 — Colori hardcoded ovunque
- **File coinvolti**: tutti gli screen e i widget
- **Sintomo**: `Colors.black`, `Colors.deepPurpleAccent`, `Colors.grey[900]` ripetuti decine di volte. Il `ColorScheme.fromSeed` in `main.dart` è ignorato.
- **Rischio**: per cambiare accent o aggiungere theme switch serve refactoring tedioso.
- **Fix proposto**: spostare in `ThemeData` Material 3 centralizzato, usare `Theme.of(context).colorScheme.X` negli screen.
- **Modulo di chiusura**: 6 (polish), non urgente

---

### #12 🟢 — Duplicazione `Wishlist` / `LibraryArchive`
- **File**: `lib/models/wishlist.dart`, `lib/models/library_archive.dart`
- **Sintomo**: due classi praticamente identiche con stessa logica `contains`/`addMovie`/`removeMovie`.
- **Fix proposto**: sparisce naturalmente sul backend (vedi `T2_SCHEMA_DATI` §8 — `user_movie_lists` con `list_type` discriminatore). Per ora non toccare.
- **Modulo di chiusura**: 4 (migrazione liste a Supabase)

---

### #13 🟢 — `storage.init()` chiamato ad ogni operazione
- **File**: tutti i provider con persistenza locale
- **Sintomo**: ogni `_save()` ricalcola `await storage.init()` (= `SharedPreferences.getInstance()`).
- **Impatto reale**: bassissimo (Flutter cache l'istanza), ma indica una struttura non centralizzata.
- **Fix proposto**: sparirà con la migrazione a Supabase (i repository remoti non hanno bisogno di init ripetuti).
- **Modulo di chiusura**: 2 (insieme alla migrazione finance al DB)

---

### #14 🟢 — Errori "swallowed" senza UI feedback
- **File**: `local_storage_service.dart`, `movie_repository.dart`, provider vari
- **Sintomo**: `try/catch` che logga via `print` e procede silente. L'utente non sa mai che qualcosa è fallito.
- **Fix proposto**: distinguere errori "recuperabili silenti" (cache miss) da "da mostrare all'utente" (load fallito, save fallito). Quest'ultimi tramite `AsyncValue.error` o snackbar.
- **Modulo di chiusura**: 2 (insieme al refactoring repository per Supabase, momento naturale)

---

### #15 🟢 — `main_navigation_screen` usa `setState` invece di Riverpod
- **File**: `lib/screens/main_navigation_screen.dart`
- **Sintomo**: `_selectedIndex` come state locale. Non si può fare "vai alla tab Stats" da un altro pezzo dell'app senza propagazione manuale.
- **Fix proposto**: `selectedTabProvider` con Riverpod, `MainNavigationScreen` diventa `ConsumerWidget`.
- **Modulo di chiusura**: opportunisticamente quando rifacciamo la navigation con `go_router` (Modulo 1)

---

### #16 🟢 — `language=it` hardcoded
- **File**: `lib/repositories/movie_repository.dart`
- **Sintomo**: lingua TMDB cablata. Niente i18n possibile.
- **Fix proposto**: costante o provider `localeProvider`. Per v1 italiano va bene ma codice predisposto.
- **Modulo di chiusura**: futuro (v3), non prioritario

---

### #17 🟢 — `Cinema` model fantasma
- **File**: `lib/models/cinema.dart`
- **Sintomo**: classe `Cinema` definita con `id`, `name`, `address`, `latitude`, `longitude`, `distanceKm` — mai importata da nessun file.
- **Fix proposto**: probabilmente verrà sostituita dal modello aggiornato che mappa la tabella `cinemas` di Supabase. Eliminare l'attuale, sostituire con versione allineata allo schema.
- **Modulo di chiusura**: 3 (modulo cinema con Places)

---

### #18 🟢 — Lookup review con try/catch su `firstWhere`
- **File**: `lib/providers/reviews_provider.dart`, metodo `getReview`
- **Sintomo**: pattern `try { firstWhere } catch { return null }` — funziona ma è anti-idiomatico Dart.
- **Fix proposto**: usare `firstWhereOrNull` dal package `collection` (già usato in modo simile in cinema_notes_provider).
- **Modulo di chiusura**: 0.B opportunistico, o 4 (insieme alla migrazione reviews)

---

### #19 🔴 — `main()` non async, manca `WidgetsFlutterBinding.ensureInitialized()`
- **File**: `lib/main.dart`
- **Sintomo**: oggi funziona perché non si inizializzano servizi async prima di `runApp`.
- **Rischio**: si rompe nel momento esatto in cui aggiungiamo `dotenv.load()` o `Supabase.initialize()` (entrambi richiedono async).
- **Fix proposto**: `void main() async { WidgetsFlutterBinding.ensureInitialized(); await dotenv.load(...); await Supabase.initialize(...); runApp(...); }`
- **Modulo di chiusura**: 0.A (parte del setup `.env`)

---

### #20 🔴 — Inizializzazione blocca tutta la UI
- **File**: `lib/main.dart`, `lib/providers/app_initialization_provider.dart`
- **Stessa root cause di #6** (lo lascio separato per chiarezza: #6 è il pattern, #20 è la conseguenza UX immediata).
- **Sintomo**: nessuna schermata di app è visibile finché TUTTI i provider hanno caricato.
- **Fix proposto**: rimuovere `initializeAppProvider` o usarlo solo per servizi globali (Supabase init), non per dati utente. Dati utente lazy-loaded.
- **Modulo di chiusura**: 1 (auth setup, nuovo flusso di avvio)

---

### #21 🟡 — `ColorScheme.fromSeed` definito ma ignorato
- **File**: `lib/main.dart` + tutti gli screen
- **Sintomo**: il `MaterialApp` definisce un `ColorScheme` Material 3, ma gli screen usano colori hardcoded `Colors.*`. Il tema esiste ma non viene applicato.
- **Causa**: stessa di #11 ma vale la pena segnalarlo come problema strutturale separato (è "il tema non viene usato", non solo "i colori sono hardcoded").
- **Fix proposto**: simultaneo a #11. Convergere su `Theme.of(context).colorScheme`.
- **Modulo di chiusura**: 6 (polish)

---

## Checklist riassuntiva

| ID | Priorità | Titolo | Modulo chiusura |
|---|---|---|---|
| 1 | 🔴 | API key TMDB hardcoded | 0.A |
| 2 | 🔴 | Cinema come stringa libera | 3 |
| 3 | 🔴 | Validazione assente | 2 + 4 |
| 4 | 🔴 | ref.invalidate cinemaNotesProvider | 0.B |
| 5 | 🔴 | MovieDetailScreen senza getMovieDetails | 4 |
| 6 | 🔴 | Init bloccante incompatibile col backend | 1 |
| 7 | 🟢 | `print()` ovunque | 0.B |
| 8 | 🟢 | `withOpacity` deprecato | 0.B |
| 9 | 🟢 | Hero tag inconsistente | opportunistico |
| 10 | 🟢 | monthKey non zero-padded | 0.B |
| 11 | 🟢 | Colori hardcoded | 6 |
| 12 | 🟢 | Duplicazione Wishlist/Archive | 4 |
| 13 | 🟢 | `storage.init()` ripetuto | 2 |
| 14 | 🟢 | Errori swallowed | 2 |
| 15 | 🟢 | `main_navigation_screen` stateful | 1 |
| 16 | 🟢 | `language=it` hardcoded | futuro |
| 17 | 🟢 | Cinema model fantasma | 3 |
| 18 | 🟢 | Lookup review try/catch | opportunistico |
| 19 | 🔴 | main() non async | 0.A |
| 20 | 🔴 | Init blocca UI | 1 |
| 21 | 🟡 | ColorScheme ignorato | 6 |

## Statistiche

- **Totale problemi**: 21
- **Chiusi**: 0
- **Aperti gravi**: 8
- **Aperti medi**: 1
- **Aperti minori**: 12

## Distribuzione per modulo di chiusura

- Modulo 0.A (sicurezza/setup): #1, #19
- Modulo 0.B (quality baseline): #4, #7, #8, #10, (#18 opzionale)
- Modulo 1 (Supabase + auth): #6, #15, #20
- Modulo 2 (migration finance): #3 (prima parte), #13, #14
- Modulo 3 (cinema Places): #2, #17
- Modulo 4 (migration reviews/lists): #3 (resto), #5, #12, #18
- Modulo 6 (polish): #11, #21, #9
- Futuro: #16

---

## Note di gestione

- Quando un problema viene chiuso: aggiungere riga `**[CHIUSO - Modulo N, gg/mm/aaaa]** Note sul fix effettivo` alla fine della sua sezione. **NON rimuovere** il problema.
- Quando emerge un nuovo problema in una sessione, aggiungere con il prossimo ID disponibile (#22, #23, ...).
- Aggiornare la **Checklist riassuntiva** e le **Statistiche** ad ogni cambio.
- Quando un fix scopre un sotto-problema, creare un nuovo ID linkando al padre nella descrizione.
