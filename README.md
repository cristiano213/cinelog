# CineLog

App Flutter di tracking personale di film con backend Supabase e componente social.

**Stato**: in sviluppo (Modulo 0 — Consolidamento, in pivot dalla v1 single-user locale).

## Prerequisiti

- Flutter SDK ^3.11.5
- Dart ^3.x
- Account Supabase (per i Moduli 1+)
- Account TMDB (per API key gratuita)
- Account Google Cloud Platform (per Modulo 3 - Places API)

## Setup

1. Clona il repo
2. Copia `.env.example` in `.env` e compila con le tue chiavi:
   ```
   TMDB_API_KEY=...
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   GOOGLE_PLACES_API_KEY=...     # opzionale, serve dal Modulo 3
   ```
3. `flutter pub get`
4. `flutter run`

## Documentazione

La documentazione completa è in `docs/`. Inizia da:
- `docs/T1_STATO_PROGETTO.md` — dove siamo
- `docs/T2_VISIONE_FUNZIONALE.md` — cosa fa l'app
- `docs/T2_ARCHITETTURA.md` — come è strutturata
- `docs/T2_CONVENZIONI.md` — come si lavora

## Struttura

```
cinelog/
├── lib/             # Codice Flutter
├── docs/            # Documentazione vivente (T1/T2)
│   └── archive/     # Doc storica (Tier 3)
├── .env             # Segreti (NON committato)
└── .env.example     # Template segreti (committato)
```

## Licenza

TODO — da definire prima di pubblicazione.
