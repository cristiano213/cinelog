# CineLog — Problemi Aperti e Punti di Attenzione

**Tier 1 — Documento vivo.**
**Aggiornato:** Maggio 2026 (fine sessione 0.A pre-coding: #1 e #19 segnati "in progress" - non ancora chiusi)
**Scope:** Lista completa dei bug, smell architetturali e punti di attenzione emersi dall'analisi del codebase v1. Bussola operativa per i moduli successivi.
**Audience:** chiunque debba pianificare interventi sul codice.

> **Convenzione**: ogni problema ha un ID numerico stabile. Quando un fix lo chiude, il problema viene marcato `[CHIUSO - Modulo N]` ma NON rimosso dal documento. L'ID è la "memoria di lungo termine" del progetto.

---

## Legenda priorità

- 🔴 **Grave** — sicurezza, bug logico, problema che blocca il pivot al backend
- 🟡 **Medio** — bug o limitazione che non blocca ma va sistemato nel modulo opportuno
- 🟢 **Minore** — smell, polish, lint, refactoring opportunistico

## Indice rapido per priorità

**Gravi aperti (🔴)**: #1 🟡in progress, #2, #3, #4, #5, #6, #19 🟡in progress, #20

**Medi aperti (🟡)**: #21

**Minori aperti (🟢)**: #7, #8, #9, #10, #11, #12, #13, #14, #15, #16, #17, #18

---

## Problemi

### #1 🔴 — API key TMDB hardcoded in `constants.dart`
- **File**: `lib/core/constants.dart`
- **Sintomo**: `static const String apiKey = '2952ea50fc43f4fa0f41f0fed731f44f';` esposto nel sorgente.
- **Causa**: scelta iniziale di pre-backend. Convenzione di sicurezza assente.
- **Rischio**: chiunque legga il repo (o la sua history Git) ottiene la key.
- **Fix proposto**: spostare in `.env` non committato, leggere via `flutter_dotenv`. Rigenerare la key sulla dashboard TMDB.
- **Modulo di chiusura**: 0.A (sicurezza e pulizia repo)
- **🟡 STATO 14/05/2026 (sessione 0.A pre-coding)**: 
  - ✅ Vecchia key revocata su dashboard TMDB, nuova generata, mai esposta in repo
  - ✅ `constants.dart` sterilizzato: `apiKey` ora getter che lancia `UnimplementedError` (placeholder fail-fast)
  - ✅ `.env` aggiunto a `.gitignore`, `.env.example` creato come template committato
  - ⏳ Setup `flutter_dotenv` + `EnvConfig` + refactor di `constants.dart` → prossimo step del 0.A
  - **Da chiudere completamente quando**: il refactor `EnvConfig.tmdbApiKey` è in repo, il `.env` reale contiene la nuova key, `flutter run` torna a funzionare.

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
- **Rischio**: dati corrotti se la UI viene bypassata. Con backend, sicuramente bypassabile.
- **Fix proposto**: CHECK constraint su tutti i campi sensibili nel DB (range numerici + length text). Mantenere validazione UI come UX. Vedi `T2_SCHEMA_DATI` §6/7/8/9.
- **Modulo di chiusura**: 2 (finance, primo caso) → 4 (gli altri)

---

### #4 🔴 — `ref.invalidate(cinemaNotesProvider)` resetta lo stato invece di rinfrescarlo
- **File**: `lib/providers/finance_provider.dart`, metodo `updateEntry`
- **Sintomo**: dopo aggiornamento di una finance_entry, le cinema_notes vengono azzerate finché non si fa `loadFromDisk` di nuovo (riavvio app o navigazione).
- **Causa**: `cinemaNotesProvider.build()` ritorna `[]`. `ref.invalidate` ricostruisce il provider quindi torna a `[]`.
- **Rischio**: in produzione l'utente "perderebbe" le note finché non riavvia.
- **Fix proposto**: rimuovere la riga `ref.invalidate(cinemaNotesProvider)` da `updateEntry`. Stessa logica già rimossa in `addVisione`.
- **Modulo di chiusura**: 0.B (quality baseline)

---

### #5 🔴 — `MovieDetailScreen` non carica i dettagli del film
- **File**: `lib/screens/movie_detail_screen.dart`
- **Sintomo**: Durata sempre "N/A", generi vuoti, cast non visibile.
- **Causa**: il `Movie` arriva da endpoint che non restituiscono `runtime`, `genres`, `cast`. `movieRepository.getMovieDetails(movieId)` esiste ma non viene mai invocata.
- **Rischio**: feature pubblicata ma di fatto monca.
- **Fix proposto**: screen accetta `Movie` come bootstrap + chiama `getMovieDetails(movie.id)` in un `FutureProvider.family`.
- **Modulo di chiusura**: 4

---

### #6 🔴 — Inizializzazione bloccante incompatibile col backend
- **File**: `lib/main.dart`, `lib/providers/app_initialization_provider.dart`
- **Sintomo**: `_InitializedApp` aspetta che tutti i provider abbiano caricato i loro dati prima di mostrare UI. Oggi 50ms locale. Con Supabase: 2-3s di caricamento bloccante.
- **Fix proposto**: `main()` async, `dotenv.load()`, `Supabase.initialize()`. `authStateProvider` ascolta `onAuthStateChange`. Routing via go_router. Dati on-demand nelle schermate.
- **Modulo di chiusura**: 1 (Supabase setup + auth)

---

### #7 🟢 — `print()` ovunque
- **File coinvolti**: `repositories/local_storage_service.dart`, `repositories/movie_repository.dart` (17 occorrenze)
- **Sintomo**: log di errore via `print`, non strippato in release.
- **Fix proposto**: `debugPrint` o package `logger`.
- **Modulo di chiusura**: 0.B
- **Note dalla scan 14/05/2026**: il finding H-1 della scan Claude Code è un caso particolarmente delicato di questo problema — `print('Error fetching movies from $url: $e')` in `movie_repository.dart:84` stampa un URL contenente la API key. Fix automatico una volta che #7 è risolto (debugPrint è no-op in release, ma resta un caveat: anche in debug build, evitare di stampare URL con chiavi).

---

### #8 🟢 — `withOpacity` deprecato
- **File**: `screens/movie_detail_screen.dart` (e potenzialmente altri)
- **Fix proposto**: search & replace globale a `withValues(alpha: ...)`.
- **Modulo di chiusura**: 0.B

---

### #9 🟢 — Hero tag inconsistente
- **File**: `widgets/movie_card.dart`, `screens/movie_detail_screen.dart`, `screens/discovery_screen.dart`
- **Fix proposto**: tag univoci per contesto (`'movie-hero-discovery-${movie.id}'`, ecc.).
- **Modulo di chiusura**: opportunistico

---

### #10 🟢 — `monthKey` non zero-padded
- **File**: `lib/models/finance_entry.dart`
- **Sintomo**: `'${dateTime.year}-${dateTime.month}'` produce `"2026-3"` e `"2026-12"`. Ordering alfabetico sbagliato.
- **Fix proposto**: `'${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}'`.
- **Modulo di chiusura**: 0.B

---

### #11 🟢 — Colori hardcoded ovunque
- **File coinvolti**: tutti gli screen e i widget
- **Sintomo**: `Colors.black`, `Colors.deepPurpleAccent`, ecc. ripetuti. `ColorScheme.fromSeed` ignorato.
- **Fix proposto**: spostare in `ThemeData` Material 3 centralizzato.
- **Modulo di chiusura**: 6 (polish)

---

### #12 🟢 — Duplicazione `Wishlist` / `LibraryArchive`
- **File**: `models/wishlist.dart`, `models/library_archive.dart`
- **Fix proposto**: sparisce naturalmente sul backend (`user_movie_lists` con `list_type` discriminatore).
- **Modulo di chiusura**: 4

---

### #13 🟢 — `storage.init()` chiamato ad ogni operazione
- **File**: tutti i provider con persistenza locale
- **Fix proposto**: sparirà con migrazione a Supabase.
- **Modulo di chiusura**: 2

---

### #14 🟢 — Errori "swallowed" senza UI feedback
- **File**: `local_storage_service.dart`, `movie_repository.dart`, provider vari
- **Sintomo**: `try/catch` che logga via `print` e procede silente.
- **Fix proposto**: distinguere errori "recuperabili silenti" da "da mostrare all'utente" via `AsyncValue.error` o snackbar.
- **Modulo di chiusura**: 2

---

### #15 🟢 — `main_navigation_screen` usa `setState` invece di Riverpod
- **File**: `lib/screens/main_navigation_screen.dart`
- **Fix proposto**: `selectedTabProvider` con Riverpod.
- **Modulo di chiusura**: 1 (insieme a go_router)

---

### #16 🟢 — `language=it` hardcoded
- **File**: `lib/repositories/movie_repository.dart`
- **Fix proposto**: costante o provider `localeProvider`.
- **Modulo di chiusura**: futuro (v3)

---

### #17 🟢 — `Cinema` model fantasma
- **File**: `lib/models/cinema.dart`
- **Fix proposto**: eliminare l'attuale, sostituire con versione allineata allo schema `cinemas` di Supabase.
- **Modulo di chiusura**: 3

---

### #18 🟢 — Lookup review con try/catch su `firstWhere`
- **File**: `lib/providers/reviews_provider.dart`
- **Fix proposto**: usare `firstWhereOrNull` dal package `collection`.
- **Modulo di chiusura**: 0.B opportunistico, o 4

---

### #19 🔴 — `main()` non async, manca `WidgetsFlutterBinding.ensureInitialized()`
- **File**: `lib/main.dart`
- **Sintomo**: oggi funziona perché non si inizializzano servizi async prima di `runApp`.
- **Rischio**: si rompe nel momento esatto in cui aggiungiamo `dotenv.load()` o `Supabase.initialize()`.
- **Fix proposto**: `void main() async { WidgetsFlutterBinding.ensureInitialized(); await dotenv.load(...); await Supabase.initialize(...); runApp(...); }`
- **Modulo di chiusura**: 0.A (parte del setup `.env`)
- **🟡 STATO 14/05/2026**: ancora aperto, da risolvere insieme a #1 nel resto del 0.A.

---

### #20 🔴 — Inizializzazione blocca tutta la UI
- **File**: `lib/main.dart`, `lib/providers/app_initialization_provider.dart`
- Stessa root cause di #6.
- **Fix proposto**: rimuovere `initializeAppProvider` o usarlo solo per servizi globali. Dati utente lazy-loaded.
- **Modulo di chiusura**: 1

---

### #21 🟡 — `ColorScheme.fromSeed` definito ma ignorato
- **File**: `lib/main.dart` + tutti gli screen
- **Causa**: stessa di #11.
- **Fix proposto**: convergere su `Theme.of(context).colorScheme`.
- **Modulo di chiusura**: 6

---

## Checklist riassuntiva

| ID | Priorità | Titolo | Modulo chiusura | Status |
|---|---|---|---|---|
| 1 | 🔴 | API key TMDB hardcoded | 0.A | 🟡 in progress |
| 2 | 🔴 | Cinema come stringa libera | 3 | aperto |
| 3 | 🔴 | Validazione assente | 2 + 4 | aperto |
| 4 | 🔴 | ref.invalidate cinemaNotesProvider | 0.B | aperto |
| 5 | 🔴 | MovieDetailScreen senza getMovieDetails | 4 | aperto |
| 6 | 🔴 | Init bloccante incompatibile col backend | 1 | aperto |
| 7 | 🟢 | `print()` ovunque | 0.B | aperto |
| 8 | 🟢 | `withOpacity` deprecato | 0.B | aperto |
| 9 | 🟢 | Hero tag inconsistente | opportunistico | aperto |
| 10 | 🟢 | monthKey non zero-padded | 0.B | aperto |
| 11 | 🟢 | Colori hardcoded | 6 | aperto |
| 12 | 🟢 | Duplicazione Wishlist/Archive | 4 | aperto |
| 13 | 🟢 | `storage.init()` ripetuto | 2 | aperto |
| 14 | 🟢 | Errori swallowed | 2 | aperto |
| 15 | 🟢 | `main_navigation_screen` stateful | 1 | aperto |
| 16 | 🟢 | `language=it` hardcoded | futuro | aperto |
| 17 | 🟢 | Cinema model fantasma | 3 | aperto |
| 18 | 🟢 | Lookup review try/catch | opportunistico | aperto |
| 19 | 🔴 | main() non async | 0.A | 🟡 in progress |
| 20 | 🔴 | Init blocca UI | 1 | aperto |
| 21 | 🟡 | ColorScheme ignorato | 6 | aperto |

## Statistiche

- **Totale problemi**: 21
- **Chiusi**: 0
- **In progress**: 2 (#1, #19 — nel 0.A)
- **Aperti gravi**: 8
- **Aperti medi**: 1
- **Aperti minori**: 12

## Distribuzione per modulo di chiusura

- Modulo 0.A (sicurezza/setup): #1, #19 (entrambi in progress)
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
- Stato intermedio "in progress" (🟡) introdotto in sessione 0.A pre-coding (14/05/2026): un problema può essere in progress se il fix è iniziato ma non completato.