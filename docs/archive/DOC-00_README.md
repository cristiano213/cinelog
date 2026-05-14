# CineLog — Documentazione

**Aggiornato:** Maggio 2026 | **Stack:** Flutter 3.11 + Riverpod 2.5 + TMDB API

---

## Indice

| File | Contenuto | Leggi quando |
|------|-----------|--------------|
| [DEVELOPMENT_TRACKER.md](DEVELOPMENT_TRACKER.md) | Stato attuale, prossimi step, pattern veloci | Inizi una sessione di lavoro |
| [DOC-01_VISIONE_ANALISI_FUNZIONALE.md](DOC-01_VISIONE_ANALISI_FUNZIONALE.md) | Schermate, flussi utente, decisioni di design | Vuoi capire cosa fa l'app |
| [DOC-02_ARCHITETTURA_TECNICA.md](DOC-02_ARCHITETTURA_TECNICA.md) | Struttura cartelle, modelli, provider, flussi di dato | Devi toccare il codice |
| [DOC-03_ROADMAP_SVILUPPO.md](DOC-03_ROADMAP_SVILUPPO.md) | Fasi 3-5: TMDB, UI avanzate, testing | Pianifichi il prossimo lavoro |
| [DOC-04_SCHEMA_DATI_PERSISTENZA.md](DOC-04_SCHEMA_DATI_PERSISTENZA.md) | Schema JSON, chiavi storage, migration | Lavori sulla persistenza |
| [DOC-05_GUIDA_TMDB_API.md](DOC-05_GUIDA_TMDB_API.md) | Setup API key, endpoint, pagination, error codes | Lavori sull'API TMDB |
| [DOC-06_NOTE_TECNICHE_RIVERPOD.md](DOC-06_NOTE_TECNICHE_RIVERPOD.md) | AsyncValue, Notifier, invalidation, patterns | Hai dubbi su state management |

---

## Stato Progetto

| Fase | Obiettivo | Stato |
|------|-----------|-------|
| Fase 1 | Struttura base + modelli | ✅ Completata |
| Fase 2 | Persistenza locale | ✅ Completata |
| Fase 3 | TMDB API integration + paginazione | ⚠️ In progress |
| Fase 4 | UI avanzate (filtri, grafici, review) | ⏳ Pianificata |
| Fase 5 | Testing + polish | ⏳ Pianificata |

→ Task correnti e blockers: [DEVELOPMENT_TRACKER.md](DEVELOPMENT_TRACKER.md)

---

## Configurazione obbligatoria

`lib/core/constants.dart` → inserire TMDB API key:

```dart
static const String apiKey = 'LA_TUA_KEY_QUI';
```

Ottieni la key su: https://www.themoviedb.org/settings/api

---

## Comandi rapidi

```bash
flutter pub get       # Installa dipendenze
flutter run           # Avvia app
flutter analyze       # Lint
dart format lib/      # Format codice
flutter test          # Esegui test
flutter build apk --release
```
