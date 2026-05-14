# CineLog — Diff Recenti (cronologia inversa)

**Tier 1 — Documento vivo, append-only.**
**Convenzione:** sessioni in cima, le più vecchie scendono. Retention: ultime 2-3 sessioni; oltre, archivio in `T3_ARCHIVIO_DIFF.md`.
**Aggiornato:** Maggio 2026

---

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