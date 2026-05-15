# CineLog — Diff Recenti (cronologia inversa)

**Tier 1 — Documento vivo, append-only.**
**Convenzione:** sessioni in cima, le più vecchie scendono. Retention: ultime 2-3 sessioni; oltre, archivio in `T3_ARCHIVIO_DIFF.md`.
**Aggiornato:** Maggio 2026

---

## Sessione — 15/05/2026 — Modulo 0.A tecnico (chiusura modulo)

**Durata sessione**: una giornata, con pausa pranzo.
**Branch**: `module-0-cleanup` → mergiato in `main` via PR #1.
**Commit prodotti**: 1 commit feature (`89ff62c`) + 1 merge commit (`9dce0ac`).
**Tag prodotto**: `v0.A-cleanup` su `9dce0ac`.

### Cosa è successo

**Claude Code installato e configurato**. Native PowerShell installer Anthropic (`irm https://claude.ai/install.ps1 | iex`). Versione `2.1.141`. Bug noto incontrato: lo script ha installato il binario in `C:\Users\serlo\.local\bin\` ma non ha aggiornato il `Path` utente Windows. Risolto manualmente via `[Environment]::SetEnvironmentVariable("Path", $newPath, "User")` da PowerShell. Da quel momento `claude --version` funziona da qualsiasi shell. Modello in uso: Sonnet 4.6 su piano Pro (Opus disponibile via `/model` a 2× consumo, da usare ad-hoc per task di ragionamento profondo).

**Branch `module-0-cleanup` creato** con `git switch -c module-0-cleanup`. Working tree pulito di partenza.

**Setup `flutter_dotenv`**. `flutter pub add flutter_dotenv` ha installato la versione `^6.0.1` (più recente della `^5.1.0` prevista in `T2_ARCHITETTURA` §1). Asset `.env` registrato in `pubspec.yaml` sotto la sezione `flutter:` con indentazione corretta. Sezione `flutter:` ripulita dai commenti template Flutter non più rilevanti.

**Creazione `EnvConfig`**. Nuovo file `lib/core/config/env_config.dart`. Constructor privato (`EnvConfig._()`) per impedire istanziazione. Quattro getter (`tmdbApiKey`, `supabaseUrl`, `supabaseAnonKey`, `googlePlacesApiKey`) che delegano a `_required(key)` privato. Pattern fail-fast: `StateError` esplicito con nome della variabile mancante.

**Refactor `constants.dart`**: `TmdbConstants.apiKey` ora getter che ritorna `EnvConfig.tmdbApiKey`. Rimosso `UnimplementedError` placeholder.

**Refactor `main.dart`**: `Future<void> main() async`, `WidgetsFlutterBinding.ensureInitialized()`, `await dotenv.load(fileName: '.env')` prima di `runApp`. Blocco `_InitializedApp`/`initializeAppProvider` legacy mantenuto, rimozione rinviata al Modulo 1.

**Creazione `.env` reale**. Verifica pre-emptiva `git check-ignore -v .env` superata. File creato con tre variabili (`TMDB_API_KEY` valorizzato, le altre come placeholder).

**Test runtime su Chrome**. `flutter run` parte, Discovery carica film TMDB. App di nuovo funzionante dopo la sterilizzazione baseline. Falso allarme intermedio: i film non comparivano subito al primo run, causa modifiche non salvate dall'editor (Ctrl+S dimenticato). Risolto.

**Commit + PR + merge**. Commit `89ff62c` con messaggio multi-paragrafo Conventional Commits. Push su `origin/module-0-cleanup` con tracking upstream. PR #1 creata da browser GitHub con titolo + descrizione Markdown strutturata (sommario, cambiamenti, note, riferimenti). Self-review nella tab "Files changed" (UI GitHub aggiornata: il toggle "Unified/Split" è ora dentro un dropdown nascosto da un'icona ingranaggio). Merge tramite "Create a merge commit" che preserva il commit feature singolo + crea il merge commit `9dce0ac`. Branch remoto cancellato via `git push origin --delete module-0-cleanup`, branch locale via `git branch -d`.

**Tag `v0.A-cleanup`** annotated creato su `9dce0ac`, push del tag.

**Bug nuovo individuato**: durante test esplorativo dell'app, la schermata Statistiche mostra come "cinema più frequentato" l'ultimo cinema inserito a parità di frequenza, invece di un tie-break deterministico. Registrato come problema #22 in `T1_PROBLEMI_APERTI`, fix naturale in Modulo 3 quando i cinema diventano entità canoniche via Google Places.

**Discussione strategica strutturale**: l'utente ha definito CineLog come progetto-base metodologico per altri tre progetti in parallelo (Nexova, BookShelf, ArcaneDuel) + tesina. Vincoli temporali stretti (4 mesi, budget usage settimanale al limite). Sono state concordate sei strategie di efficienza (A-F, vedi `T1_STATO_PROGETTO` §3.1) da applicare dal Modulo 0.B in poi: chat corte, Claude Code per task meccanici, docs in modalità diff, Tier 2 stabile, sessioni low-budget vs deep, chat fork per task lunghi.

**Riorganizzazione tutorial**. Cartella `docs/tutorials/` introdotta. Sotto-cartelle `tools/` (come si fa X tecnicamente: Git, shell, dotenv, ecc.) e `method/` (come si lavora professionalmente: convenzioni, workflow, organizzazione documentale). I file esistenti `SHELL_COMMANDS_REFERENCE.md`, `GIT_WORKFLOW_REFERENCE.md`, `GIT_NEW_PROJECT_TUTORIAL.md` spostati nelle nuove sottocartelle via `git mv` (storia preservata).

### Bug/comportamenti notevoli incontrati

- **Path utente Windows non aggiornato dallo script Claude Code**: bug specifico ambiente Windows, risolto come da sopra. Lezione documentata: dopo qualsiasi script di installazione che dovrebbe aggiornare `Path`, verificare con `[Environment]::GetEnvironmentVariable("Path", "User") -split ";"` prima di concludere "installato".
- **VS Code save dimenticato durante refactor**: già successo nella sessione precedente. Lezione rinforzata: dopo modifica file e prima di `flutter run` / `git diff`, sempre `Ctrl+S` esplicito o `Get-Content` di verifica.
- **Pager `less` di Git ancora insidioso**: durante `git diff --cached` PowerShell finisce nel pager. Tasto `q` per uscire (memorizzato definitivamente). Considerata disabilitazione globale con `git config --global core.pager ""`, decisione rinviata.
- **`git diff` paginato incollato due volte**: durante scroll fino in fondo + uscita pager, il contenuto è stato copiato due volte. Innocuo, ma confermato che il pager è una fonte di confusione per chi non lo conosce.
- **PR di GitHub UI cambiata da gennaio 2026**: la mia knowledge è ferma a gennaio, alcuni elementi UI sono ora diversi (es. toggle Unified/Split è dentro un dropdown). L'utente ha trovato in autonomia dopo 20 min di ricerca. Lezione: chiedere all'utente di descrivere l'UI corrente quando le mie istruzioni "click qui" non trovano corrispondenza.

### Decisioni minori prese

- **Tag style**: prefisso `v` (es. `v0.A-cleanup`), nome modulo come suffisso. Convenzione coerente con T1_ADDENDUM §5.2.
- **Strategia di merge in PR**: "Create a merge commit" come default (preserva commit individuali del branch). "Squash" rinviato a casi specifici (branch con molti commit di "save point" senza valore storico individuale).
- **Branch eliminato post-merge**: sia remoto che locale, immediatamente. Convenzione "branch monouso per modulo".

### Documenti aggiornati a fine sessione

- `T1_STATO_PROGETTO.md`: sostituzione §1, §2 sotto-sezione "Sessione corrente", §3
- `T1_DIFF_RECENTI.md`: questa sezione in cima (cronologia inversa)
- `T1_PROBLEMI_APERTI.md`: #1 e #19 marcati `[CHIUSO - Modulo 0.A, 15/05/2026]`, aggiunta sezione #22, aggiornati indice rapido + checklist + statistiche
- Riorganizzazione fisica `docs/tutorials/` in `tools/` e `method/` via `git mv`

### Non generati in questa sessione (rimandati per consapevolezza budget)

- `docs/tutorials/method/SESSION_EFFICIENCY.md` (Modulo 0.B)
- `docs/tutorials/method/CLAUDE_CODE_USAGE.md` (Modulo 0.B, dopo prima esperienza estesa con CC)
- `docs/tutorials/method/TUTORIAL_STYLE_GUIDE.md` (quando emerge necessità)
- README di indice in `tools/` e `method/` (quando aggiunto il prossimo tutorial)
- Allineamento `T2_ARCHITETTURA.md` §1 (`flutter_dotenv ^6.0.1` invece di `^5.1.0`) (prossima revisione T2)

### Stato a fine sessione

- Repo locale: pulito, allineato con `origin/main`, tag `v0.A-cleanup` localmente e su GitHub
- Repo remoto: 3 commit + 1 merge + 1 tag oltre alla baseline
- App: ✅ funzionante a runtime, TMDB key letta correttamente da `.env`
- Problemi aperti: 22 totali (2 chiusi: #1 e #19; 1 nuovo: #22)
- Prossimo: Modulo 0.B — Quality baseline, in sessione fresca con strategie A-F attive

## Sessione — 14/05/2026 — Modulo 0.A pre-coding

**Durata stimata sessione**: ~3 ore in chat.
**Branch**: `main` (baseline + docs).
**Commit prodotti**: 1 (`309aae9`) + 1 in arrivo per i docs (questo file e gli altri 4 generati a fine sessione).

### Cosa è successo

Sessione di setup pre-coding del Modulo 0.A: tutto il lavoro infrastrutturale prima di toccare la sterilizzazione secret + lo stack dotenv.

**Tutorial Git completo**: spiegati i 4 stati del codice (working directory / staging / repo locale / remoto), comandi base, Conventional Commits, GUI vs CLI. Installato Git for Windows 2.52.0, configurato `user.name`, `user.email` (GitHub no-reply per privacy), `init.defaultBranch=main`, `core.autocrlf=true`. Decisione: HTTPS + Personal Access Token gestito da Git Credential Manager (SSH come futuro upgrade).

**Tooling AI**: discussa scelta tra Claude Code, OpenCode, GitHub Copilot, modelli locali. Decisione: **Claude Code** (incluso nel piano Pro/Max), **OpenCode scartato** perché richiede API key Anthropic separata a consumo extra. Modelli locali via Ollama scartati per qualità insufficiente su agentic coding. Setup di Claude Code da CLI rimandato a inizio prossima sessione.

**Igiene repo**: progetto spostato da `C:\Users\serlo\OneDrive\Desktop\cinelog` a `C:\Users\serlo\Dev\cinelog` per evitare conflitti OneDrive ↔ Git ↔ tool di build. `flutter pub get` verificato funzionante nel nuovo path.

**Hardening `.gitignore`**: dal template Flutter default sono state aggiunte le righe per `.env`/`.env.local`/`.env.*.local`, `.metadata`, segreti firma Android (`*.keystore`, `*.jks`, `google-services.json`), config iOS/macOS (Pods, GoogleService-Info.plist), `*.iml`, `.idea/`, ecc. Verifica con `git check-ignore -v` per ogni pattern critico.

**Scan di sicurezza pre-commit**: eseguita con Claude Code (estensione VS Code) su `lib/`, `pubspec.yaml`, `README.md`, `analysis_options.yaml`, `.gitignore`. Output: 1 CRITICAL, 1 HIGH, 3 MEDIUM, 1 LOW. Findings classificati:
- **CRITICAL C-1** (TMDB key hardcoded): risolto in sessione (sterilizzazione preventiva).
- **HIGH H-1** (print con URL contenente key): rimandato a Modulo 0.B (#7 esistente).
- **MEDIUM M-1, M-2** (avoid_print lint + 10 print): Modulo 0.B (#7).
- **MEDIUM M-3** (`.env.example` referenced ma assente): risolto in sessione.
- **LOW L-1** (`.metadata` non in gitignore): risolto in sessione.

**Rotazione TMDB key**: vecchia (`2952...44f`) revocata sulla dashboard. Nuova generata e salvata fuori dal repo, NON ancora popolata nel `.env` (sarà nei prossimi step del 0.A insieme a `flutter_dotenv`).

**Sterilizzazione `constants.dart`**: convertito `static const String apiKey = '2952...'` in `static String get apiKey => throw UnimplementedError(...)`. L'app `flutter run` ora crasha all'uso di `TmdbConstants.apiKey`, comportamento atteso fino al refactor `EnvConfig`. Pattern fail-fast: meglio crash chiaro che leak silenzioso.

**Creazione `.env.example`**: template con 3 variabili (TMDB, Supabase, Google Places) + commenti + istruzioni di copia (`cp` e `Copy-Item`).

**Git init + baseline commit**: `git init`, primo `git add .`, baseline commit `309aae9` — 177 file, 17085 insertions. Messaggio Conventional Commit in inglese, body multi-paragrafo, riferimenti a #1 e #19.

**Push GitHub**: repo creato su https://github.com/cristiano213/cinelog (pubblico, no README/license preimpostati). `git remote add origin`, `git push -u origin main`, autenticazione automatica via Git Credential Manager (token GitHub esistente nel Windows Credential Vault).

### Bug/comportamenti notevoli incontrati

- **OneDrive nel path iniziale**: cause delays/lock potenziali per Git e build. Spostato. Lezione: progetti software fuori da cartelle sincronizzate.
- **PowerShell vs `grep`**: i comandi Unix non funzionano nativamente in PowerShell. Soluzione: `Select-String` / `findstr` per equivalenza, o usare Git Bash quando serve la shell Unix vera.
- **Confusione `.env.example` salvato in `lib/core/`**: VS Code ha creato il file nella sotto-cartella attiva invece che in root. Risolto spostandolo. Lezione: verificare sempre dove il file viene creato.
- **`constants.dart` non salvato al primo tentativo**: modifiche in editor non committate al disco (Ctrl+S mancato). Risolto dopo `Get-Content` di verifica. Lezione: `Get-Content` come check post-modifica prima di credere che il file sia cambiato.
- **Blocco in `less` pager**: durante un `git diff --cached` il pager è rimasto in attesa, Ctrl+V e Ctrl+C non lo hanno chiuso perché `less` intercetta i tasti come comandi propri. Risolto con `q`. Lezione documentata in `SHELL_COMMANDS_REFERENCE.md`.
- **Email Git → GitHub privacy**: configurata inizialmente con email reale, corretta in tempo (prima del primo commit) con no-reply GitHub. Lezione: l'email nei commit è permanente nella storia; in repo pubblici è meglio no-reply fin dal primo commit.

### Decisioni minori prese

- File `cinelog.iml` (generato da Android Studio/IntelliJ) gitignored via pattern `*.iml`. Non committato.
- File `.idea/` (cartella config IntelliJ) gitignored. Non committato.
- File `.vscode/` gitignored per default. Riattivabile selettivamente in futuro se serve condividere `launch.json`.
- Generati file `linux/macos/windows/flutter/generated_plugin_registrant.*`: tenuti in repo (standard Flutter). Se in futuro emergerà problema, valutare ignorare.
- README esistente (scritto in sessione 0.2) confermato valido. TODO licenza rimandato.

### Documentazione generata a fine sessione

- `T1_STATO_PROGETTO.md` aggiornato (questa sessione + prossimi passi)
- `T1_DIFF_RECENTI.md` (questo file)
- `T1_PROBLEMI_APERTI.md` aggiornato (#1 e #19 marcati "in progress nel 0.A", non chiusi)
- `SHELL_COMMANDS_REFERENCE.md` (nuovo, file maestro reference)
- `GIT_WORKFLOW_REFERENCE.md` (nuovo, file maestro reference)

### Stato a fine sessione

- Repo locale: pulito, allineato con origin.
- Repo remoto: https://github.com/cristiano213/cinelog, branch main con baseline commit.
- App: **non funziona a runtime** (per design, temporaneo). Il refactor del prossimo step la rimette online.
- Problemi aperti totali: 21 (1 e 19 in progress, gli altri invariati).
- Prossimo step: installazione Claude Code da CLI + setup `flutter_dotenv` su branch `module-0-cleanup`.

---

## Sessione precedente — fine Modulo 0.2 (consolidata in archivio)

Generazione documentazione T1/T2/T3, decisione pivot social, prompt master Claude Code preparato. Dettagli in `T3_ARCHIVIO_DIFF.md` quando creato.

---

## Sessione precedente — Modulo 0.1 (consolidata in archivio)

Analisi codebase v1, 27 file Dart mappati, 21 problemi documentati. Dettagli in `T3_ARCHIVIO_DIFF.md` quando creato.