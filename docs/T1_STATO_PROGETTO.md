# CineLog — Stato del Progetto

**Tier 1 — Documento vivo.**
**Aggiornato:** Maggio 2026 — fine Modulo 0.1 (analisi codebase v1 completata, documentazione ricostruita)
**Scope:** Dove siamo, cosa stiamo per fare, blockers attivi.
**Audience:** Riferimento all'inizio di ogni sessione di lavoro.

> Questo documento si aggiorna **a fine di ogni sessione**. La sezione "Sessione corrente" diventa "Sessione precedente" nella sessione successiva, e si crea una nuova "Sessione corrente".

---

## 1. Snapshot ad alto livello

- **Versione progetto**: 2.0 (post-pivot social/backend)
- **Modulo corrente**: 0 — Consolidamento
- **Sub-modulo**: 0.2 → 0.3 (documentazione ricostruita, prossimo passo: bonifica codice)
- **Build status**: ✅ il codebase v1 compila e gira (single-user, locale)
- **Backend**: ❌ non ancora setuppato (Modulo 1)
- **Auth**: ❌ non ancora implementata (Modulo 1)
- **Problemi aperti**: 21 (8 gravi, 1 medio, 12 minori) — vedi `T1_PROBLEMI_APERTI.md`

---

## 2. Cosa è stato fatto

### Sessioni precedenti (consolidate)
- Costruzione app v1 single-user con persistenza locale (`shared_preferences`)
- 4 schermate principali: Discovery, Stats, Search, MovieDetail
- 5 categorie di dati: finance ledger, reviews, cinema notes, wishlist, library archive
- TMDB integration con cache e paginazione
- Riverpod come state management ovunque

### Sessione corrente (Modulo 0.1 + 0.2)
- ✅ Analisi completa del codebase (27 file Dart + pubspec)
- ✅ Mappatura 21 punti di attenzione (`T1_PROBLEMI_APERTI`)
- ✅ Decisione strategica: pivot a multi-utente + Supabase + componente social
- ✅ Documentazione ricostruita secondo schema tier T1/T2/T3:
  - `T2_VISIONE_FUNZIONALE.md` (rifatto, post-pivot)
  - `T2_SCHEMA_DATI.md` (rifatto da JSON → SQL Postgres)
  - `T2_ARCHITETTURA.md` (rifatto, target Flutter+Supabase)
  - `T1_PROBLEMI_APERTI.md` (nuovo)
  - `T1_STATO_PROGETTO.md` (questo file)
  - `T2_CONVENZIONI.md` (versione aggiornata in arrivo)
  - Prompt master per Claude Code (per generazione `T2_NOTE_TECNICHE`, `T2_API_ESTERNE` e scheletri vuoti T3)

---

## 3. Prossimi passi immediati

Da affrontare nella **prossima sessione**, in chat nuova con contesto fresco.

### 3.1 Pacchetto Claude Code (subito)
Eseguire il prompt master per:
- Generare `T2_NOTE_TECNICHE.md` (pattern Riverpod usati nel codebase)
- Generare `T2_API_ESTERNE.md` (TMDB endpoints attualmente usati + sezione Google Places vuota da popolare in Modulo 3)
- Creare scheletri vuoti: `T1_DIFF_RECENTI`, `T3_GLOSSARIO_TECNICO`, `T3_ARCHIVIO_DIFF`
- Spostare i vecchi `DOC-*.md` in `docs/archive/` come `T3_ROADMAP_STORICA.md`

### 3.2 Modulo 0.A — Sicurezza e setup
Priorità massima dopo doc.
1. Verifica `.gitignore` + scan storia Git per API key TMDB
2. Rigenerazione API key TMDB su dashboard
3. Setup `flutter_dotenv` + struttura `.env` / `.env.example`
4. Refactor `TmdbConstants` per leggere da env
5. README progetto (prerequisiti, setup, run)
6. Branch `module-0-cleanup`, commit `chore: secure env config`

Tempo stimato: 1 sessione (45-60 min).

### 3.3 Modulo 0.B — Quality baseline
1. `analysis_options.yaml` con regole stringenti
2. `debugPrint` ovunque al posto di `print`
3. `withValues(alpha)` al posto di `withOpacity`
4. `main()` async + `WidgetsFlutterBinding.ensureInitialized()`
5. Fix bug sicuri:
   - Rimuovere `ref.invalidate(cinemaNotesProvider)` da `finance_provider.updateEntry`
   - `monthKey` zero-padded
6. Niente refactoring strutturale qui — solo polish e bug logici

Tempo stimato: 1 sessione.

---

## 4. Roadmap moduli completa

Sequenza target, con stato e tempo stimato.

| Modulo | Titolo | Stato | Tempo |
|---|---|---|---|
| 0 | Consolidamento (analisi + doc + bonifica) | 🟡 in corso (0.1, 0.2 fatti, 0.3 next) | 3-4 sessioni totali |
| 1 | Supabase setup + autenticazione | ⏸️ da fare | 3-4 sessioni |
| 2 | Migrazione `finance_entries` (template per il resto) | ⏸️ | 2-3 sessioni |
| 3 | Cinema canonici via Google Places | ⏸️ | 3-4 sessioni |
| 4 | Migrazione reviews + wishlist/archive | ⏸️ | 2-3 sessioni |
| 5 | Social (definito quando ci arriviamo) | ⏸️ scope da decidere | ? |
| 6 | Testing + polish | ⏸️ | 2-3 sessioni |

**Totale stimato**: 15-22 sessioni. È un numero realistico se ogni sessione dura 60-90 min e include spiegazione + codice + verifica.

---

## 5. Decisioni strategiche prese (riassunto da sessioni precedenti)

Per memoria, in caso di context loss:

1. **Stack scelto**: Flutter ^3.11.5 + Riverpod 2.5+ + Supabase + go_router. TMDB + Google Places come API esterne.
2. **Approccio**: didattico-professionale ibrido — production-quality + spiegazioni passo-passo + vocabolario tecnico costruito strada facendo.
3. **Visibilità dati**: finanze sempre private, altri dati con `visibility` default da impostazioni profilo, sovrascrivibili per riga.
4. **Online-first**: niente offline-first con sync, è troppo complesso per lo scope.
5. **Cinema**: entità canonica da Google Places, no più stringa libera.
6. **Prezzi cinema**: inseriti dall'utente con suggerimento basato su storico utente o media aggregata.
7. **Username**: unico, immutabile dopo l'onboarding.
8. **Email verification**: obbligatoria.
9. **No social login v1**: solo email/password.
10. **No notifiche push v1, no DM, no commenti su review altrui v1**.
11. **Workflow Git**: branch per modulo, PR auto-review, conventional commits.
12. **Documentazione**: tier T1 (vivo) / T2 (stabile) / T3 (riferimento). Documenti `DOC-*` v1 archiviati come T3.
13. **Lavoro AI**: ibrido — Claude in chat per documenti strategici e decisioni, Claude Code per documenti descrittivi di codice e refactoring meccanici. Mai lasciare a Claude Code decisioni progettuali.

---

## 6. Blockers attivi

Niente blocker hard al momento.

Soft blockers / cose da fare prima del Modulo 1:
- ⚠️ Doc T2_NOTE_TECNICHE e T2_API_ESTERNE da generare con Claude Code (sub-task di 0.2)
- ⚠️ Rigenerazione API key TMDB (sub-task di 0.A)
- ⚠️ Account Supabase da creare se non esiste già (parte del Modulo 1)
- ⚠️ Account Google Cloud Platform + carta per Google Places API (necessario solo a Modulo 3, ma è da preparare con anticipo per evitare attese)

---

## 7. Note operative per la prossima sessione

### Cosa caricare nel contesto della prossima chat

**Sempre (Tier 2)**:
- `T2_CONVENZIONI.md`
- `T2_VISIONE_FUNZIONALE.md`
- `T2_ARCHITETTURA.md`
- `T2_SCHEMA_DATI.md`
- `T2_NOTE_TECNICHE.md` (dopo che esiste)
- `T2_API_ESTERNE.md` (dopo che esiste)

**Sempre (Tier 1)**:
- `T1_STATO_PROGETTO.md` (questo file)
- `T1_PROBLEMI_APERTI.md`
- `T1_DIFF_RECENTI.md`

**Solo se serve (Tier 3)**:
- `T3_GLOSSARIO_TECNICO.md`
- `T3_ARCHIVIO_DIFF.md` o `T3_ROADMAP_STORICA.md`

### Cosa caricare dal codebase

Per il Modulo 0.A (sicurezza) servono solo:
- `lib/main.dart`
- `lib/core/constants.dart`
- `pubspec.yaml`
- `.gitignore` (mostrare contenuto)

### Primo messaggio della prossima chat

Il primo messaggio dovrebbe essere qualcosa tipo:

> "Carico T2 + T1 + main.dart + constants.dart + pubspec.yaml + .gitignore. Stiamo partendo dal Modulo 0.A. Procedi col primo step (verifica .gitignore + scan storia Git per la API key)."

Così l'AI parte con tutto il contesto consolidato senza dover rileggere chat di 200 messaggi.

---

## Riferimenti

- Visione: `T2_VISIONE_FUNZIONALE.md`
- Schema dati: `T2_SCHEMA_DATI.md`
- Architettura: `T2_ARCHITETTURA.md`
- Convenzioni: `T2_CONVENZIONI.md`
- Problemi: `T1_PROBLEMI_APERTI.md`
- Diff recenti: `T1_DIFF_RECENTI.md`
