# CineLog — Stato del Progetto

**Tier 1 — Documento vivo.**
**Aggiornato:** Maggio 2026 — fine sessione Modulo 0.A pre-coding (Git init, baseline commit, push GitHub).
**Scope:** Dove siamo, cosa stiamo per fare, blockers attivi.
**Audience:** Riferimento all'inizio di ogni sessione di lavoro.

> Questo documento si aggiorna **a fine di ogni sessione**. La sezione "Sessione corrente" diventa "Sessione precedente" nella sessione successiva, e si crea una nuova "Sessione corrente".

---

## 1. Snapshot ad alto livello

- **Versione progetto**: 2.0 (post-pivot social/backend)
- **Modulo corrente**: 0.A — Sicurezza e setup `.env`
- **Sub-stato**: pre-coding chiuso (Git inizializzato, baseline commit, push GitHub). Prossimo: setup tecnico `flutter_dotenv` + `EnvConfig` + refactor `TmdbConstants` + `main()` async.
- **Build status**: ⚠️ il codebase v1 attualmente **NON funziona a runtime** perché `TmdbConstants.apiKey` è stato sterilizzato a placeholder che lancia `UnimplementedError`. È stato voluto e temporaneo: il refactor a `EnvConfig.tmdbApiKey` lo rimette online nei prossimi step del 0.A.
- **Backend**: ❌ non ancora setuppato (Modulo 1)
- **Auth**: ❌ non ancora implementata (Modulo 1)
- **Repo Git**: ✅ inizializzato, primo commit fatto, push su GitHub completato
- **GitHub URL**: https://github.com/cristiano213/cinelog (pubblico)
- **Problemi aperti**: 21 (#1 e #19 in progress nel 0.A, gli altri invariati)

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

### Sessione corrente (Modulo 0.A pre-coding)
- ✅ Tutorial Git completo (concetti + comandi base + Conventional Commits)
- ✅ Installazione e config Git su Windows: `user.name`, `user.email` (GitHub no-reply), `init.defaultBranch=main`, `core.autocrlf=true`
- ✅ Email privacy GitHub: attivata "Keep my email addresses private" + "Block command line pushes that expose my email"
- ✅ Progetto spostato fuori da OneDrive: nuova path `C:\Users\serlo\Dev\cinelog\`
- ✅ Aggiornato `.gitignore` con: `.env`, `.env.local`, `.env.*.local`, `.metadata`, segreti firma Android (`*.keystore`, `*.jks`, `google-services.json`), file iOS/macOS, `*.iml`, `.idea/`, ecc.
- ✅ Scan di sicurezza pre-commit eseguita con Claude Code: 1 CRITICAL (TMDB key hardcoded), 1 HIGH (key leak via print URL), 3 MEDIUM (avoid_print + 10 print + .env.example mancante), 1 LOW (.metadata mancante in gitignore). I findings rimandati a 0.A successivi e 0.B sono mappati a problemi #1, #7 (e altri).
- ✅ Rotazione API key TMDB sulla dashboard (vecchia compromessa, nuova mai esposta)
- ✅ Sterilizzazione `lib/core/constants.dart`: `apiKey` è ora un getter che lancia `UnimplementedError` (fail-fast). La key reale entrerà via `EnvConfig` nei prossimi step.
- ✅ Creato `.env.example` in root con template tre variabili (TMDB, Supabase, Google Places)
- ✅ `git init` + baseline commit (hash `309aae9`): 177 file, 17085 righe, chore con riferimento a #1 e #19
- ✅ Repo GitHub creato: https://github.com/cristiano213/cinelog (pubblico, no README/license preimpostati)
- ✅ `git remote add origin` + `git push -u origin main` riusciti, branch tracking impostato

---

## 3. Prossimi passi immediati

Da affrontare nella **prossima sessione**, in chat nuova con contesto fresco.

### 3.1 Setup Claude Code da CLI
Prima di toccare codice, installazione e primo test di Claude Code in modalità terminale (non solo estensione VS Code).
- `npm install -g @anthropic-ai/claude-code` (richiede Node.js installato)
- `claude` per login interattivo
- Primo test su CineLog: lettura di un file e generazione di un piano
- Documentazione comandi base CC in `docs/CLAUDE_CODE_REFERENCE.md` (da generare in sessione)

### 3.2 Modulo 0.A — completamento (setup tecnico .env)
Branch `module-0-cleanup` (da creare).
1. `flutter pub add flutter_dotenv` (aggiunge dipendenza a pubspec.yaml)
2. Dichiarazione `.env` come asset in `pubspec.yaml`
3. Creazione `.env` reale in root con la NUOVA chiave TMDB (gli altri due placeholder lasciati)
4. Creazione `lib/core/config/env_config.dart` con pattern fail-fast (getter `tmdbApiKey`, `supabaseUrl`, `supabaseAnonKey`, `googlePlacesApiKey`)
5. Refactor `lib/core/constants.dart`: `apiKey` legge da `EnvConfig.tmdbApiKey` (rimuove `UnimplementedError`)
6. Refactor `lib/main.dart`: `void main() async`, `WidgetsFlutterBinding.ensureInitialized()`, `await dotenv.load(fileName: '.env')`, poi `runApp(...)`. Risolve #19.
7. Test: `flutter run` su un device. Verifica che Discovery carichi film da TMDB. **L'app deve tornare a funzionare** dopo essere stata rotta dal commit baseline.
8. Commit `feat: load TMDB key from .env via EnvConfig` (o simile), push del branch
9. PR su GitHub da `module-0-cleanup` a `main`, auto-review del diff, merge
10. Tag `v0.A-cleanup` a fine modulo, push del tag
11. Chiude #1 e #19 in `T1_PROBLEMI_APERTI`

Tempo stimato: 1 sessione (45-60 min).

### 3.3 Modulo 0.B — Quality baseline (sessione successiva)
1. `analysis_options.yaml` con regole stringenti
2. `debugPrint` al posto di `print` ovunque
3. `withValues(alpha)` al posto di `withOpacity`
4. Fix bug sicuri: rimuovere `ref.invalidate(cinemaNotesProvider)` da `finance_provider.updateEntry`; `monthKey` zero-padded
5. Chiude #4, #7, #8, #10

Tempo stimato: 1 sessione.

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