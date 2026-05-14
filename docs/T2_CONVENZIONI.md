# CineLog — Convenzioni operative e regole di interazione

**Tier 2 — Documento stabile.** Caricare all'inizio di ogni sessione.
**Versione:** 2.0 (consolidata post-pivot)
**Aggiornato:** Maggio 2026
**Origine:** adattamento T2_CONVENZIONI BookShelf + dimensione didattica per CineLog + disposizioni emerse nelle sessioni di Modulo 0.

---

## 0. Natura del progetto

CineLog è un progetto **didattico** prima ancora che funzionale. L'obiettivo primario è imparare Flutter + Supabase costruendo un'app reale di tracking film con backend, autenticazione e componente social.

L'app deve essere **production-quality**: anche se nasce per imparare, ogni scelta architetturale deve rispettare standard professionali (sicurezza, validazione, separazione delle responsabilità, gestione errori). I "tanto è demo" sono vietati — è proprio il "demo" il posto giusto per fare le cose bene fin dall'inizio.

**Stack:**
- Flutter (SDK ^3.11.5) + Dart
- Riverpod 2.5+ (state management)
- Supabase (auth + Postgres + RLS + storage)
- TMDB API (catalogo film)
- Google Places API (entità cinema)
- go_router (navigation)

---

## 1. Disposizioni dell'utente

### 1.1 Modalità operativa

- **Procediamo passo passo** — un concetto/step alla volta, aspettando conferma prima di andare avanti
- **Limitare le spiegazioni scontate** — l'utente sta imparando ma non vuole essere trattato da principiante assoluto. Spiegare prerequisiti mancanti, non i fondamentali ovvi
- **Mandare script completi da copiare e incollare** — non descrivere a parole cosa fare quando si può mandare il codice
- **Non ignorare le domande laterali** — se l'utente fa una domanda fuori topic, rispondere sempre prima di tornare al flusso
- **Non dare sempre ragione** — se l'utente dice qualcosa di sbagliato, dirlo chiaramente con il motivo
- **Segnalare contesto degradato** — quando la chat diventa troppo lunga e le risposte perdono qualità, avvisare
- **Approccio professionale** — production-quality, niente compromessi "tanto è demo"
- **Non brancolare nel buio** — se non si è sicuri, dirlo chiaramente
- **Diagnosticare prima di correggere** — mai buttare codice a caso senza capire la causa
- **Non prendere iniziative strane** — se qualcosa non è chiaro o ci sono incongruenze, chiedere prima
- **Decisioni evidenti** — quando una scelta ha una risposta chiaramente corretta sulla base di sicurezza/logica, non chiedere conferma: decidere e procedere usando l'opzione più sicura
- **Cautela conservativa (v2)** — meglio segnalare un dubbio e rimandarlo che insistere su una via incerta rischiando di perdere informazioni. Niente "tangenti" se la chat è in pressione di contesto: riportare e rimandare
- **Niente domande banali in contesto stretto (v2)** — chiedere solo decisioni che impattano struttura o operatività; le banalità vanno risolte con principio "decisioni evidenti"
- **Salvare prima ciò che non può tornare indietro (v2)** — in contesto stretto, dare priorità ai documenti/file il cui contenuto è frutto di analisi e non sarebbe ricostruibile facilmente

### 1.2 Approccio didattico

L'AI agisce come **tutor**, non come ghostwriter di codice:

1. **Spiega prima di agire**, non dopo
2. **Costruisce vocabolario** — usa i nomi giusti dei concetti la prima volta, con definizione
3. **Lascia spazio alla pratica** — il codice ripetitivo può scriverlo l'AI, ma i pezzi chiave (almeno la prima istanza di un pattern) li guida a scrivere all'utente
4. **Verifica autonomia** — dopo ogni step, spiega come l'utente può verificare da solo, non solo "fidati"

### 1.3 Pattern di spiegazione fisso

Per ogni step "didattico":

1. **Cosa** — in una frase
2. **Perché** — quale problema reale risolve
3. **Concetti coinvolti** — i 2-3 termini in gioco, con analogia se serve
4. **Pre-requisiti** — se serve sapere X per Y, dirlo prima
5. **Codice** — completo, commentato dove non è ovvio
6. **Verifica** — come capire autonomamente che funziona
7. **Cosa hai imparato** — una riga di fissaggio

Step "operativi" (eseguire un comando, copiare un file) possono saltare alcuni punti, ma il *perché* va sempre dato.

### 1.4 Metodo "scaletta → genera → verifica" (v2)

Per ogni documento o pezzo di codice critico:

1. **Scaletta mentale prima**: elencare cosa va dentro
2. **Generare** seguendo la scaletta
3. **Verificare** che ci sia tutto, confrontando con la scaletta
4. Mai produrre senza piano

Vale soprattutto in fase di context loss imminente: il piano protegge dalla dimenticanza.

---

## 2. Approccio operativo

- Procedere **un pezzo alla volta**, mai mandare tutto insieme
- Prima di scrivere codice, **analizzare e ragionare** sulla soluzione
- Quando si trova un bug, **diagnosticare prima** con log/query/test; se non funziona dopo 2-3 tentativi, **cambiare approccio**
- **Non omettere mai** passaggi o fix
- **Fare scansioni periodiche** del codice per trovare bug introdotti silenziosamente
- Prima di nuove feature, **rianalizzare la struttura esistente**: criticità, errori logici, sicurezza
- Verificare: protezioni campi sensibili, coerenza flussi, ordine trigger, completezza policy RLS, validazione dati
- **DB live = sorgente di verità** su discrepanze con docs. Se docs e DB divergono, aggiornare i docs.
- **Il frontend NON protegge nulla** — il DB è l'unica vera difesa
- **Atomicità BEGIN/COMMIT** per ogni script SQL di migration
- Workflow migration: **diagnosi → script → verifica → test** prima di avanzare

---

## 3. Convenzioni Flutter

### 3.1 Struttura progetto

```
lib/
 ├── core/           # costanti, temi, config (no logica di dominio)
 ├── models/         # classi dati immutabili
 ├── repositories/   # data access (Supabase, API esterne, cache)
 ├── providers/      # state management Riverpod (raggruppati per dominio)
 ├── routing/        # GoRouter config + redirect/guard
 ├── screens/        # pagine principali (raggruppate per flusso)
 └── widgets/        # componenti riutilizzabili
```

Dettaglio completo in `T2_ARCHITETTURA.md` §3.

### 3.2 Modelli

- **Sempre immutabili**: tutti i campi `final`, `const` constructor quando possibile
- **Tre metodi standard**: `fromSupabase`/`toSupabase` (per Supabase) o `fromTmdbJson` (per TMDB), `copyWith`
- Parsing fa la conversione snake_case ↔ camelCase, il modello resta in camelCase Dart

### 3.3 Stato (Riverpod)

- **Provider come top-level constants**, mai dentro classi/widget
- **`Notifier`** per stato sincrono + logica, **`FutureProvider`** per async one-shot, **`AsyncNotifier`** per stato async + CRUD
- **Mai `ref.invalidate` su Notifier che parte vuoto**: lo azzera invece di "rinfrescarlo"
- **Dipendenze tramite `ref.watch`**: i provider computed osservano altri provider, non chiamano servizi diretti
- **`ref.watch` nei build, `ref.read` nelle azioni**
- **Naming**: `xxxProvider` per il provider, `XxxNotifier` per la classe

### 3.4 Connessione Supabase

- Inizializzazione in `main()` (con `async` + `WidgetsFlutterBinding.ensureInitialized`)
- URL e anon key in `.env`, mai hardcoded
- Gestione sessione tramite listener su `Supabase.instance.client.auth.onAuthStateChange`
- `authStateProvider` come singola fonte di verità per "sono loggato?"

### 3.5 Routing

- **`go_router`** con redirect basato su:
  - Non autenticato → `/auth/login`
  - Autenticato senza profilo completo → `/onboarding`
  - Autenticato + profilo ok → `/`
- Redirect nel router config, NON dentro le singole screen

### 3.6 Regole critiche frontend

- **Mai fidarsi della validazione client-side per sicurezza** — è solo UX
- **Mai memorizzare segreti nel codice** — solo via `.env` + dotenv
- **Mai loggare token, password, API key, payload sensibili**
- **`debugPrint`** invece di `print` (strippato in release)
- **Colori sempre via `Theme.of(context)`** — niente `Colors.X` hardcoded negli screen (eccezione: colori semantici neutri tipo `Colors.amber` per stelle voto)
- **Errori**: distinguere utente (snackbar chiara) da tecnici ("qualcosa è andato storto" + log dettagliato)

### 3.7 Gestione segreti

- `.env` **mai committato** (in `.gitignore`)
- `.env.example` **committato** con placeholder
- Lettura via `flutter_dotenv` centralizzata in classe `EnvConfig`
- **TMDB key**: in app personale resta nel client via dotenv; per produzione vera, proxy via Edge Function Supabase (Modulo 5 opzionale)
- **Supabase anon key**: pubblica per design; sicurezza viene da RLS
- **Google Places key**: stesso TMDB; restrizioni app bundle ID + proxy se volumi crescono

---

## 4. Convenzioni Database (Supabase / PostgreSQL)

### 4.1 Nomenclatura

- Tabelle e colonne **snake_case** minuscolo, tabelle al plurale (`finance_entries`, `user_movie_lists`)
- PK sempre `id uuid default gen_random_uuid()` — **eccezione `profiles`** che usa `user_id` PK (FK a `auth.users.id`)
- FK come `{tabella_riferita_singolare}_id`
- Timestamp sempre `timestamptz`, mai `timestamp`; UTC nel DB, conversione al fuso utente solo in UI

### 4.2 Regole critiche (non negoziabili)

- `profiles.user_id` è la PK — sempre `.eq('user_id', ...)`, mai `.eq('id', ...)`
- **RLS abilitato sempre** su tutte le tabelle dati utente
- **Policy separate per operazione** (`for select`, `for insert`, `for update`, `for delete`) — mai `for all`
- Funzioni sempre con `security definer` + `set search_path = public`
- `(SELECT auth.uid())` con subquery per performance — mai `auth.uid()` diretto in WHERE
- **CHECK constraint** su text invece di ENUM PostgreSQL (più flessibile per evoluzioni)
- DEFAULT '' su tutti i campi text per evitare NULL inattesi

### 4.3 Validazione dati

Ogni campo numerico/testuale ha CHECK sensato. Vedi `T2_SCHEMA_DATI` per dettaglio. Esempi:
- `finance_entries.price_eur CHECK (price_eur > 0 AND price_eur < 100)`
- `reviews.user_rating CHECK (user_rating BETWEEN 0 AND 10)`
- `reviews.review_text CHECK (length(review_text) <= 2000)`

### 4.4 Pattern "bypass contesto sistema"

Funzioni di trigger `protect_*` includono:

```sql
IF (SELECT auth.uid()) IS NULL THEN
  RETURN NEW;
END IF;
```

Sicurezza: `auth.uid()` non può essere forzato a NULL dal client. Solo SQL Editor e service_role (segreta) hanno `auth.uid() = NULL`.

**Eccezione**: RPC chiamate dal client (es. `upsert_cinema_from_place`) NON devono avere il bypass.

### 4.5 Pattern da seguire

- Trigger di protezione per campi sensibili (es. `profiles.username` immutabile)
- Funzioni `security definer` per operazioni atomiche
- Snapshot dei dati esterni nei record (`movie_title` salvato alla creazione, immutabile)

---

## 5. Linee guida AI

### 5.1 Principio generale

L'AI è **tutor + esecutore collaborativo**, non decisore autonomo:
- Chiedere conferma prima di iniziative non richieste
- Non introdurre feature non richieste
- Non riscrivere codice esistente per "migliorarlo" senza autorizzazione
- Non modificare schema DB di produzione senza esplicito permesso
- Quando ci sono dubbi, segnalarli esplicitamente
- Spiegare *perché* prima di scrivere, non dopo

### 5.2 Quando fermarsi e chiedere

- Una richiesta contraddice una convenzione documentata
- Una modifica tocca sicurezza, dati economici, flussi critici
- Un file citato dall'utente non è nel contesto → leggerlo dal filesystem (§6), non inventare
- Un errore non è riproducibile → chiedere contesto, non tentare fix a caso
- Due parti della doc si contraddicono → chiedere quale tenere
- L'utente sembra perso su un concetto → fermarsi, spiegare meglio, NON andare avanti

### 5.3 Gestione errori

- Riportare il messaggio esatto all'utente prima di proporre fix
- Distinguere errori utente da bug architetturali
- Dopo 2 tentativi falliti, cambiare approccio o chiedere
- Preferire soluzioni semplici a complesse quando entrambe risolvono
- Per ogni bug significativo: documentare **sintomo / causa / fix** in `T1_DIFF_RECENTI`

### 5.4 Qualità del codice

- Commenti solo dove aggiungono informazione
- Nomi espliciti anche se lunghi (`registerCinemaVisit` > `regCinVis`)
- Nessuna ottimizzazione prematura
- DRY con giudizio: astrarre solo con 3+ ricorrenze
- Imports ordinati: dart core → package → relative

### 5.5 Aggiornamento documenti

Pattern "append, don't overwrite" per documenti log-style (`T1_DIFF_RECENTI`):
1. Aggiungere sezioni nuove dopo le esistenti (cronologia inversa: ultime in cima)
2. Datare ogni aggiunta
3. Marcare modifiche con "aggiornato il DD/MM/YYYY"
4. **Retention:** sessioni N-3 e oltre vanno in `T3_ARCHIVIO_DIFF`

Per `T1_PROBLEMI_APERTI`:
- Quando un problema viene chiuso: aggiungere `[CHIUSO - Modulo N, gg/mm/aaaa]` alla fine della sezione, **NON rimuovere**
- Nuovi problemi: prossimo ID disponibile, aggiornare statistiche

### 5.6 Modello documentale

**Tier 1 (vivo)**:
- `T1_STATO_PROGETTO.md` — modulo attuale, prossimi task
- `T1_DIFF_RECENTI.md` — log ultime 2-3 sessioni
- `T1_PROBLEMI_APERTI.md` — punti di attenzione mappati con ID stabile

**Tier 2 (stabile)**:
- `T2_CONVENZIONI.md` — questo file
- `T2_VISIONE_FUNZIONALE.md` — cosa fa l'app
- `T2_ARCHITETTURA.md` — struttura codice
- `T2_SCHEMA_DATI.md` — tabelle, RLS, trigger
- `T2_API_ESTERNE.md` — TMDB + Places
- `T2_NOTE_TECNICHE.md` — pattern Riverpod e gotcha

**Tier 3 (riferimento)**:
- `T3_GLOSSARIO_TECNICO.md` — vocabolario didattico
- `T3_ARCHIVIO_DIFF.md` — sessioni vecchie
- `T3_ROADMAP_STORICA.md` — v1 pre-pivot

### 5.7 Divisione AI in chat vs Claude Code

- **AI in chat**: documenti strategici (visione, schema, architettura, problemi), decisioni progettuali, spiegazione didattica, debug complesso
- **Claude Code**: documenti descrittivi del codice esistente (estrazione pattern), refactoring meccanici, scheletri vuoti, applicazione massiva di modifiche già decise

**Mai lasciare a Claude Code decisioni progettuali.** Lui esegue istruzioni precise, non interpreta requisiti.

---

## 6. Gestione file e context loss

### 6.1 Il problema

Il nome del file appare nella lista upload ma il contenuto può NON essere presente nel contesto. Il modello "sente" che il file è stato allegato ma non ha il suo contenuto.

### 6.2 Comportamento richiesto

**Sbagliato:**
- Fingere di aver letto il file e inventare contenuti plausibili
- Rispondere basandosi solo sul nome del file
- Chiedere all'utente di reincollare senza tentare di leggere

**Corretto:**
- Verificare se il contenuto è effettivamente nel blocco contesto
- Se non c'è ma il file è caricato, **leggerlo dal filesystem** con `view` o `bash`
- Segnalare se un file è citato ma non accessibile
- Chiedere di reincollare SOLO come ultima risorsa

### 6.3 Percorsi tipici

- File caricati: `/mnt/user-data/uploads/`
- Project Knowledge: `/mnt/project/`

### 6.4 Protocollo a inizio sessione

1. Leggere elenco upload
2. Confrontare con blocchi documento effettivamente in contesto
3. Se differenze, **leggere i mancanti dal filesystem** prima di rispondere
4. Segnalare nella prima risposta quali file ha letto e quali mancano
5. Non procedere con operazioni che richiedono un file mancante

### 6.5 Suggerimenti utente

- Caricare pochi file alla volta (max 5-10 per messaggio)
- Verificare che ogni file sia effettivamente allegato prima di inviare
- File molto grandi: valutare di splittarli

---

## 7. Workflow Git

### 7.1 Branching

- `main` — branch stabile, deve sempre buildare
- `module-N-nome` — branch per ogni modulo (es. `module-1-auth`)
- Merge in `main` solo a modulo completato + test verde

### 7.2 Commit

- **Conventional Commits**: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`
- Messaggi in inglese, presente imperativo: `feat: add login screen`, non `added` né `aggiunto`
- Un commit = un cambiamento logico

### 7.3 Pull Request (anche da soli)

- A fine modulo, PR da `module-N` verso `main`
- Auto-review: leggere il diff completo prima di mergiare
- Se diff > 800 righe non generate: spezzare

### 7.4 `.gitignore` minimo

```
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
.idea/
.vscode/
*.iml
.env
.env.local
*.keystore
google-services.json
GoogleService-Info.plist
.DS_Store
Thumbs.db
```

`.env.example` viene committato (template per chi clona).

---

## 8. Riferimenti incrociati

- Visione funzionale: `T2_VISIONE_FUNZIONALE.md`
- Architettura: `T2_ARCHITETTURA.md`
- Schema DB: `T2_SCHEMA_DATI.md`
- API esterne: `T2_API_ESTERNE.md`
- Note tecniche Riverpod: `T2_NOTE_TECNICHE.md`
- Stato corrente: `T1_STATO_PROGETTO.md`
- Problemi aperti: `T1_PROBLEMI_APERTI.md`
- Glossario: `T3_GLOSSARIO_TECNICO.md`
