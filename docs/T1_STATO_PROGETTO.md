# CineLog — Stato del Progetto

**Tier 1 — Documento vivo.**
**Aggiornato:** Maggio 2026 — fine sessione Modulo 0.A pre-coding (Git init, baseline commit, push GitHub).
**Scope:** Dove siamo, cosa stiamo per fare, blockers attivi.
**Audience:** Riferimento all'inizio di ogni sessione di lavoro.

> Questo documento si aggiorna **a fine di ogni sessione**. La sezione "Sessione corrente" diventa "Sessione precedente" nella sessione successiva, e si crea una nuova "Sessione corrente".

---

## 1. Snapshot ad alto livello

- **Versione progetto**: 2.0 (post-pivot social/backend)
- **Modulo corrente**: 0.B — Quality baseline (in attesa di inizio prossima sessione)
- **Sub-stato**: Modulo 0.A **chiuso e taggato `v0.A-cleanup`**. App funzionante: TMDB key letta da `.env` via `EnvConfig`, `main()` async con `WidgetsFlutterBinding.ensureInitialized()` e `dotenv.load()` prima di `runApp`.
- **Build status**: ✅ `flutter run` su Chrome verde, Discovery carica film TMDB regolarmente.
- **Backend**: ❌ non ancora setuppato (Modulo 1)
- **Auth**: ❌ non ancora implementata (Modulo 1)
- **Repo Git**: ✅ `main` allineato con `origin/main`, tag `v0.A-cleanup` pushato.
- **GitHub URL**: https://github.com/cristiano213/cinelog (pubblico)
- **Problemi aperti**: 22 (#1 e #19 **chiusi**, #22 nuovo da bug emerso in sessione)
---

## 2. Cosa è stato fatto

### Sessioni precedenti (consolidate)
- Modulo 0.1: Analisi completa codebase v1 (27 file Dart + pubspec)
- Modulo 0.2: Ricostruzione documentazione T1/T2/T3
- Costruzione app v1 single-user con persistenza locale (`shared_preferences`)
- 4 schermate principali: Discovery, Stats, Search, MovieDetail
- 5 categorie dati: finance ledger, reviews, cinema notes, wishlist, library archive
- TMDB integration con cache e paginazione
- Riverpod come state management ovunque

### Sessione corrente (Modulo 0.A tecnico — chiusura)
- ✅ Installato Claude Code via native installer Windows (`irm https://claude.ai/install.ps1 | iex`), versione 2.1.141
- ✅ Risolto problema `Path` utente non aggiornato dallo script di installazione: aggiunta manuale di `C:\Users\serlo\.local\bin` al `Path` utente tramite `[Environment]::SetEnvironmentVariable(...)` da PowerShell
- ✅ Primo avvio di Claude Code nel progetto, autenticazione browser-based ereditata da sessione VS Code precedente. Modello attivo: Sonnet 4.6 su piano Pro
- ✅ Branch `module-0-cleanup` creato e poi mergiato via PR #1 su `main`
- ✅ Aggiunta dipendenza `flutter_dotenv: ^6.0.1` (versione 6.x — divergenza dalla v5.x prevista in `T2_ARCHITETTURA` §1, da allineare in doc T2)
- ✅ `.env` registrato come asset Flutter in `pubspec.yaml`, sezione `flutter:` ripulita dai commenti template
- ✅ Creato `lib/core/config/env_config.dart` con pattern fail-fast: getter per `TMDB_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_PLACES_API_KEY`. Ogni getter lancia `StateError` esplicito con nome variabile se manca o è vuota.
- ✅ Refactor `lib/core/constants.dart`: `TmdbConstants.apiKey` ora delega a `EnvConfig.tmdbApiKey`, rimosso `UnimplementedError` placeholder
- ✅ Refactor `lib/main.dart`: `Future<void> main() async` + `WidgetsFlutterBinding.ensureInitialized()` + `await dotenv.load(fileName: '.env')` prima di `runApp`. **Chiude #19**
- ✅ Creato `.env` reale in root con TMDB key vera, gitignore verificato con `git check-ignore -v`. **Chiude #1**
- ✅ Commit `89ff62c` (`feat(config): load TMDB API key from .env via EnvConfig`), push, PR #1 con descrizione Markdown, self-review tab "Files changed", merge tramite "Create a merge commit"
- ✅ Branch remoto `module-0-cleanup` cancellato via `git push origin --delete`, branch locale via `git branch -d`
- ✅ Tag `v0.A-cleanup` annotated creato su `9dce0ac` e pushato
- ✅ Bug nuovo individuato durante test esplorativo: "cinema più frequentato" usa tie-break instabile in `stats_provider`. Registrato come **#22**, fix naturale in Modulo 3
- ✅ Riorganizzazione cartella `docs/tutorials/`: split tra `tools/` (come si fa X tecnicamente) e `method/` (come si lavora professionalmente)

---

## 3. Prossimi passi immediati

Modulo 0.A formalmente **chiuso**. La prossima sessione apre il **Modulo 0.B — Quality baseline**.

### 3.1 Strategie di efficienza concordate (sessione 15/05/2026)

Sei strategie operative concordate per la gestione di sessioni future, applicabili a tutti i progetti paralleli (Nexova, BookShelf, ArcaneDuel) oltre a CineLog:

- **A — Chat corte e frequenti**: reset contesto regolare per evitare crescita esponenziale dei costi per turno
- **B — Claude Code per task meccanici**: refactor pattern noti, generazione boilerplate, search-replace
- **C — Doc in modalità diff**: passare solo sezioni nuove/cambiate, non rigenerazione integrale
- **D — Tier 2 stabile**: toccare solo per cambi strutturali veri, non polishing
- **E — Sessione low-budget vs deep**: dichiarare modalità a inizio sessione, adattare pattern didattico
- **F — Chat fork per task lunghi**: aprire chat secondaria per task >2h, sessione principale resta corta

Da formalizzare nel Modulo 0.B in `docs/tutorials/method/SESSION_EFFICIENCY.md`.
### 3.2 Modulo 0.B — Quality baseline
1. `analysis_options.yaml` con regole stringenti (verificare quali `lint` sono attive ora, perché `flutter analyze` ha mostrato 16 info post-`flutter_lints` aggiornato)
2. **Task delegabile a Claude Code**: refactor `print` → `debugPrint` in `local_storage_service.dart` (13 occorrenze) + `movie_repository.dart` (2 occorrenze). Chiude #7
3. **Task delegabile a Claude Code**: `withOpacity` → `withValues(alpha: ...)` in `movie_detail_screen.dart`. Chiude #8
4. Rimozione `ref.invalidate(cinemaNotesProvider)` da `finance_provider.updateEntry`. Chiude #4
5. Fix `monthKey` zero-padded in `finance_entry.dart`. Chiude #10
6. Branch dedicato `module-0-B-quality`, PR, merge, tag `v0.B-quality`

Stima: 1 sessione (45-60 min) se Claude Code gestisce i task meccanici.

### 3.3 Da definire prima del Modulo 0.B
- Creare il file `docs/tutorials/method/SESSION_EFFICIENCY.md` con le strategie A-F formalizzate
- Decidere se introdurre subito il file `docs/tutorials/method/CLAUDE_CODE_USAGE.md` (workflow per delegare task)   

---

## 4. Roadmap moduli completa

| Modulo | Titolo | Stato | Tempo |
|---|---|---|---|
| 0.1 | Analisi codebase v1 | ✅ chiuso | — |
| 0.2 | Documentazione T1/T2/T3 | ✅ chiuso | — |
| 0.A | Sicurezza e setup .env | 🟡 in corso (pre-coding chiuso) | 1-2 sessioni residue |
| 0.B | Quality baseline | ⏸️ | 1 sessione |
| 1 | Supabase setup + autenticazione | ⏸️ | 3-4 sessioni |
| 2 | Migrazione finance_entries (template) | ⏸️ | 2-3 sessioni |
| 3 | Cinema canonici via Google Places | ⏸️ | 3-4 sessioni |
| 4 | Migrazione reviews + wishlist/archive | ⏸️ | 2-3 sessioni |
| 5 | Social (scope da decidere) | ⏸️ | ? |
| 6 | Testing + polish | ⏸️ | 2-3 sessioni |

---

## 5. Decisioni strategiche prese (riassunto)

1. Stack: Flutter ^3.11.5 + Riverpod 2.5+ + Supabase + go_router. TMDB + Google Places.
2. Approccio didattico-professionale. Production-quality, mai compromessi.
3. Visibilità dati: finanze private, altri default da impostazioni, override per riga.
4. Online-first (niente offline-sync v1).
5. Cinema: entità canonica da Google Places.
6. Prezzi cinema: input utente con suggerimento basato su storico.
7. Username unico, immutabile dopo onboarding.
8. Email verification obbligatoria.
9. No social login v1 (solo email/password).
10. No notifiche push v1, no DM, no commenti review altrui v1.
11. Workflow Git: branch per modulo, PR auto-review, Conventional Commits in inglese.
12. Documentazione: T1 vivo / T2 stabile / T3 riferimento.
13. Lavoro AI: chat per strategia, Claude Code per esecuzione/agentic. **OpenCode scartato**: setup complesso e API a consumo extra rispetto al piano Claude.
14. **(Nuovo, sessione 0.A pre-coding)** Email Git → GitHub no-reply (privacy email reale).
15. **(Nuovo, sessione 0.A pre-coding)** Progetto vive in `C:\Users\serlo\Dev\cinelog\`, fuori da OneDrive.
16. **(Nuovo, sessione 0.A pre-coding)** Auth Git → GitHub via HTTPS + PAT gestito da Git Credential Manager (SSH come upgrade futuro).
17. **(Nuovo, sessione 0.A pre-coding)** Pattern di sterilizzazione preventiva pre-commit: secret rimosso e sostituito da placeholder fail-fast `UnimplementedError`. La key reale arriva nel commit successivo via dotenv, mai nella history del primo commit.

---

## 6. Blockers attivi

Niente blocker hard.

Soft blockers per 0.A successivi:
- ⚠️ Decisione licenza progetto (TODO nel README, non urgente)

Da preparare entro Modulo 1:
- ⚠️ Account Supabase già esistente — confermato in sessione
- ⚠️ Progetto Supabase da creare (URL + anon key)

Da preparare entro Modulo 3:
- ⚠️ Account GCP + carta + budget alert + Places API abilitata + API key con restrizioni

---

## 7. Note operative per la prossima sessione

### Cosa caricare nel contesto della prossima chat

**Sempre (Tier 2)**:
- `T2_CONVENZIONI.md`
- `T2_VISIONE_FUNZIONALE.md` (in knowledge, può non servire subito)
- `T2_ARCHITETTURA.md`
- `T2_SCHEMA_DATI.md` (in knowledge, può non servire subito)
- `T2_NOTE_TECNICHE.md` (in knowledge)
- `T2_API_ESTERNE.md` (in knowledge)

**Sempre (Tier 1)**:
- `T1_STATO_PROGETTO.md` (questo file)
- `T1_PROBLEMI_APERTI.md`
- `T1_DIFF_RECENTI.md`

**Reference da consultare on-demand**:
- `SHELL_COMMANDS_REFERENCE.md`
- `GIT_WORKFLOW_REFERENCE.md`

### Cosa caricare dal codebase

Per il setup tecnico 0.A:
- `lib/core/constants.dart` (post-sterilizzazione)
- `lib/main.dart`
- `pubspec.yaml`
- `.env.example`
- `.gitignore` (per riferimento)

### Primo messaggio della prossima chat

Da incollare letteralmente:

> "Riprendo CineLog. Modulo 0.A, parte tecnica residua. Lo stato è in `docs/T1_STATO_PROGETTO.md` §3.2. Carico T2_CONVENZIONI, T2_ARCHITETTURA, T1_STATO_PROGETTO, T1_PROBLEMI_APERTI, T1_DIFF_RECENTI + `lib/core/constants.dart`, `lib/main.dart`, `pubspec.yaml`, `.env.example`. Prima di iniziare il setup dotenv, vogliamo installare Claude Code da CLI per usarlo nei task agentici di questo modulo e dei successivi. Procedi col primo step."

---

## Riferimenti

- Visione: `T2_VISIONE_FUNZIONALE.md`
- Schema dati: `T2_SCHEMA_DATI.md`
- Architettura: `T2_ARCHITETTURA.md`
- Convenzioni: `T2_CONVENZIONI.md`
- Note tecniche Riverpod: `T2_NOTE_TECNICHE.md`
- API esterne: `T2_API_ESTERNE.md`
- Problemi: `T1_PROBLEMI_APERTI.md`
- Diff recenti: `T1_DIFF_RECENTI.md`
- Shell reference: `SHELL_COMMANDS_REFERENCE.md`
- Git reference: `GIT_WORKFLOW_REFERENCE.md`