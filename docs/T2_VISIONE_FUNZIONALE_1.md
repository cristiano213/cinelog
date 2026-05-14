# CineLog — Visione di progetto e analisi funzionale

**Tier 2 — Documento stabile.**
**Versione:** 2.0 (post-pivot social/backend)
**Aggiornato:** Maggio 2026
**Scope:** Cosa fa CineLog dal lato utente, perché esiste, quali sono i suoi limiti voluti.
**Audience:** Chiunque debba capire l'app prima di toccare il codice.

> **Cambiamenti rispetto alla v1 (locale, single-user):**
> CineLog evolve da personal tracker offline a app multi-utente con backend Supabase e componente social. La logica di app resta, cambiano il layer di persistenza, l'autenticazione, e si aggiungono profili condivisibili. La v1 è archiviata in `T3_ROADMAP_STORICA.md`.

---

## Indice

1. [Manifesto](#manifesto)
2. [Obiettivi centrali](#obiettivi)
3. [Stack tecnologico](#stack)
4. [Pilastri architetturali](#pilastri)
5. [Schermate principali](#schermate)
6. [Flussi d'uso chiave](#flussi)
7. [Modello dati ad alto livello](#modello)
8. [Decisioni di design e di scope](#decisioni)
9. [Cosa NON è CineLog](#non-e)

---

## <a id="manifesto"></a>1. Manifesto

CineLog è **il tuo ecosistema personale del cinema**, ora con la possibilità di **condividere selettivamente** le tue scoperte con altri appassionati.

Non è un social network globale né una piattaforma di review pubbliche. È uno strumento di **organizzazione personale che apre solo le finestre che decidi tu**: i tuoi voti, la tua wishlist, i film che hai visto.
Le spese rimangono private. Sempre.

**Parole chiave**: organizzazione consapevole + analisi finanziaria + riflessione personale + condivisione opzionale.

---

## <a id="obiettivi"></a>2. Obiettivi centrali

### 2.1 Organizzazione consapevole
- Mantenere una libreria personale di film desiderati (wishlist) e visti (archive)
- Distinguere tra film visti al cinema (con prezzo) e altrove (streaming, casa)
- Ritrovare rapidamente quello che si cerca

### 2.2 Consapevolezza finanziaria
- Tracciare con precisione quanto si spende al cinema (validato lato server)
- Analizzare trend di spesa per cinema, mese, genere
- Calcolare costi medi per supportare decisioni future
- **I dati finanziari sono e restano sempre privati**

### 2.3 Riflessione personale
- Registrare il proprio voto e una review testuale per ogni film visto
- Confrontare il proprio gusto con i voti globali TMDB
- Tenere appunti personali sui cinema visitati
- Identificare pattern: generi preferiti, mood, periodi

### 2.4 Scoperta cosciente
- Esplorare film da fonti affidabili (TMDB)
- Filtrare per genere, rating minimo, categoria (in arrivo, ora al cinema, classici)
- Aggiungere film alla wishlist senza impegno

### 2.5 Condivisione opzionale (nuovo)
- Ogni utente ha un profilo pubblico minimo (username, bio opzionale)
- Per ogni categoria di dato (review, wishlist, archive, cinema notes) l'utente sceglie la visibilità: privata o pubblica
- Possibilità di seguire altri utenti per vedere le loro attività pubbliche
- **Le finanze sono sempre escluse dalla condivisione**, per design

### 2.6 Localizzazione dei cinema (nuovo)
- Integrazione con Google Places per identificare i cinema in modo univoco e canonico
- Visualizzazione su mappa dei cinema vicini (location-based)
- Statistiche aggregate sui prezzi medi per cinema (intelligenza collettiva, no esposizione dati personali)

---

## <a id="stack"></a>3. Stack tecnologico

| Layer | Tecnologia | Note |
|---|---|---|
| UI | Flutter 3.11.5 + Material 3 | Dark mode di default, tema centralizzato |
| State management | Riverpod 2.5+ | Notifier, AsyncNotifier, Family providers |
| Routing | go_router | Redirect con auth guard |
| Auth + DB | Supabase | JWT, RLS, Postgres |
| Persistenza locale | Solo cache UI (limitata) | Niente più `shared_preferences` come fonte di verità |
| Catalogo film | TMDB API v3 | Endpoint pubblici, key da `.env` |
| Cinema fisici | Google Places API (New) | Place ID come riferimento canonico |
| Configurazione | flutter_dotenv | Segreti via `.env` non committato |
| Storage immagini | Supabase Storage | Avatar profilo (opzionale, Fase futura) |

---

## <a id="pilastri"></a>4. Pilastri architetturali

L'app è organizzata attorno a **cinque responsabilità nette e separate**.

### 4.1 Discovery — Pilastro API film
- **Fonte**: TMDB
- **Ruolo**: portale di scoperta infinito
- **Dati**: film + poster + trama + cast + rating globale
- **Persistenza**: nessuna, solo cache immagini lato client
- **Modificabilità**: nulla, i dati sono di TMDB

### 4.2 Library — Pilastro organizzazione
- **Fonte**: utente tramite Discovery
- **Ruolo**: raccolta personale (wishlist + archive)
- **Dati**: ID film + tipo lista (wishlist | archive) + contesto visione (cinema | streaming | tv | dvd | other)
- **Persistenza**: tabella `user_movie_lists` su Supabase, scoped sull'utente
- **Visibilità**: configurabile per utente (default privato)

### 4.3 Finance — Pilastro economia
- **Fonte**: utente tramite "Registra visione" nel detail del film
- **Ruolo**: ledger finanziario + analisi spese
- **Dati**: `{movie_id, cinema_id, price, datetime, count}` con cinema come FK
- **Persistenza**: tabella `finance_entries` su Supabase
- **Visibilità**: **sempre privata** (immutabile per design)
- **Validazione**: CHECK constraint lato DB (prezzo > 0 e < 100, count > 0)
- **Stats**: calcolate client-side osservando `finance_entries`

### 4.4 Personal Hub — Pilastro riflessione (reviews + cinema notes)
- **Fonte**: utente durante l'uso
- **Ruolo**: voti, review testuali, appunti sui cinema
- **Dati**: `reviews` (rating 0-10 + testo max 2000 char) + `cinema_notes` (testo libero sul cinema)
- **Persistenza**: tabelle `reviews` e `cinema_notes` su Supabase
- **Visibilità**: configurabile per utente (review default pubblica, cinema notes default private)

### 4.5 Profile & Social — Pilastro condivisione
- **Fonte**: registrazione utente + impostazioni
- **Ruolo**: identità pubblica + relazioni
- **Dati**: `profiles` (username, display_name, bio, visibility settings) + `follows` (relazione user → user)
- **Persistenza**: tabelle `profiles` e `follows` su Supabase
- **Visibilità**: profilo sempre con almeno username pubblico

---

## <a id="schermate"></a>5. Schermate principali

### 5.1 Schermate di autenticazione (nuove)
- **Login**: email + password
- **Signup**: email + password + username
- **Email verification**: schermata di attesa + reinvio
- **Reset password**: flusso standard via email

### 5.2 Tab principali (post-login)

1. **Discovery** — esistente, invariato nella logica
   - 6 carousel orizzontali (now playing, upcoming, top rated + 3 generi)
   - Search con filtri (infinite scroll, multi-genere AND)

2. **Library** — nuovo come tab dedicata, sostituisce parte di "Profile"
   - Wishlist (film desiderati)
   - Archive (film visti, con filtro per contesto)
   - Toggle visibilità per ognuno

3. **Stats** — esistente, ampliato
   - Stats finanziarie (totale, media, mese)
   - Cronologia visioni con filtri (per cinema, periodo)
   - Grafici trend mensile (custom paint)
   - Cinema più frequentato + media prezzi

4. **Cinemas** — nuovo
   - Mappa con cinema visitati + cinema vicini (Google Places)
   - BottomSheet con dettaglio + note personali
   - Statistiche per cinema (visite, spesa, prezzo medio)

5. **Profile** — nuovo
   - Proprio profilo (modificabile)
   - Impostazioni visibilità per categoria di dato
   - Seguiti / follower (Fase social)
   - Logout

### 5.3 Screen secondarie

- **MovieDetailScreen** — esistente, rivista:
  - Caricamento dettagli completo via `getMovieDetails` (cast, generi, durata)
  - Pulsante "Registra visione" → dialog
  - Sezione review personale (rating + testo)
  - Confronto voto utente vs TMDB (chart)
  - Aggiunta a wishlist/archive

- **CinemaPickerScreen** (dialog/sheet) — nuovo
  - Lista cinema vicini da Google Places (location-based)
  - Search per nome
  - Selezione cinema → ritorna `cinema_id` canonico

- **UserProfileScreen** (visione altrui) — Fase social
  - Profilo pubblico altro utente
  - Suoi dati pubblici (review, library, eventualmente stats parziali)
  - Pulsante follow/unfollow

---

## <a id="flussi"></a>6. Flussi d'uso chiave

### 6.1 Primo accesso (nuovo utente)
```
1. Apertura app
2. Schermata Login
3. Tap "Crea account"
4. Form signup (email, password, username)
5. Submit → email di verifica inviata
6. Schermata "controlla la tua email"
7. Click link in email → torna su app loggato
8. Onboarding minimo (display name, opzionale bio)
9. Discovery come home tab
```

### 6.2 Accesso utente già registrato
```
1. Apertura app
2. authStateProvider rileva sessione valida
3. Redirect automatico → Discovery
4. I dati utente si caricano on-demand quando l'utente apre la rispettiva tab
   (NO blocco di startup con caricamento di tutto)
```

### 6.3 Registrazione visione al cinema (rivisto)
```
1. Utente in MovieDetailScreen
2. Tap "REGISTRA VISIONE"
3. Dialog:
   ├─ Cinema: tap apre CinemaPicker
   │  ├─ Mostra cinema vicini (Google Places)
   │  ├─ Search per nome
   │  └─ Selezione → ritorna cinema_id
   ├─ Prezzo (pre-compilato con storico utente per quel cinema,
   │  o media aggregata se primo utilizzo lì)
   ├─ Data (default oggi, modificabile)
   └─ Conferma

4. Validazione client (UX):
   - prezzo > 0 e < 100
   - cinema selezionato

5. INSERT su finance_entries
   ├─ RLS verifica auth.uid() = user_id
   ├─ CHECK constraints DB validano range
   └─ Trigger eventuale aggiorna stats aggregata cinema

6. Snackbar conferma + refresh provider stats
```

### 6.4 Scrittura review (rivisto)
```
1. Utente in MovieDetailScreen, sezione "La tua review"
2. Rating bar 0-10
3. TextField (max 2000 char, contatore visibile)
4. Toggle visibilità (privata | pubblica) — default da impostazioni profilo
5. Salva
6. UPSERT su reviews con user_id + movie_id come UNIQUE
7. Confronto vs TMDB aggiornato
```

### 6.5 Seguire un utente (Fase social)
```
1. Su UserProfileScreen di un altro utente
2. Tap "Segui"
3. INSERT su follows (follower_id, followed_id)
4. RLS: chiunque autenticato può creare follow per se stesso
5. UI aggiornata
```

---

## <a id="modello"></a>7. Modello dati ad alto livello

Vista d'insieme. Dettagli completi in `T2_SCHEMA_DATI.md`.

```
┌─────────────────┐
│  auth.users     │  (gestito da Supabase Auth)
│  - id           │
│  - email        │
└────────┬────────┘
         │
         │ 1:1
         ▼
┌─────────────────────────────────────┐
│  profiles                           │
│  - user_id (PK, FK)                 │
│  - username (UNIQUE)                │
│  - display_name                     │
│  - bio                              │
│  - default_review_visibility        │
│  - default_library_visibility       │
└────────┬────────────────────────────┘
         │
         │ 1:N
         ├──→ finance_entries (sempre privato)
         │    - user_id, movie_id, cinema_id (FK), price_eur, datetime
         │
         ├──→ reviews (visibility configurabile)
         │    - user_id, movie_id, rating, text, visibility
         │
         ├──→ user_movie_lists (visibility configurabile)
         │    - user_id, movie_id, list_type, context, visibility
         │
         ├──→ cinema_notes (visibility configurabile)
         │    - user_id, cinema_id, note, visibility
         │
         └──→ follows
              - follower_id, followed_id

┌─────────────────┐
│  cinemas        │  (entità canonica, leggibile da tutti)
│  - id (UUID)    │
│  - place_id     │  (Google Places, UNIQUE)
│  - name         │
│  - address      │
│  - latitude     │
│  - longitude    │
└─────────────────┘
```

**Principi**:
- Ogni tabella utente ha `user_id` FK su `profiles`
- Ogni tabella utente ha `visibility` con CHECK constraint (privato | pubblico — futuro: + followers)
- `cinemas` è entità globale condivisa, non duplicata per utente
- `movie_id` è il TMDB ID come stringa, NO tabella locale `movies` (TMDB è la sorgente)
- RLS forza visibility a livello di riga

---

## <a id="decisioni"></a>8. Decisioni di design e di scope

### 8.1 Online-first
L'app richiede connessione per funzionare. **Niente offline-first con sync**: aggiunge complessità sproporzionata per scope didattico.
Eccezione: cache TMDB lato client per ridurre chiamate (già implementata, va mantenuta).

### 8.2 Finanze sempre private
**Decisione non negoziabile**. I dati di spesa non sono mai esposti ad altri utenti, in nessuna configurazione. Anche le stats aggregate "media prezzi per cinema" sono calcolate server-side senza esporre singole transazioni.

### 8.3 Visibilità per categoria, non per riga (v1)
Nel Modulo 5 (social), la visibilità si imposta **per categoria** nel profilo (es. "le mie review sono pubbliche"), non per singolo dato. La singola riga eredita il default ma è sovrascrivibile (campo `visibility` esiste in ogni tabella già nello schema iniziale).

### 8.4 Niente notifiche push v1
Le notifiche (nuovo follower, ecc.) sono fuori scope per la v2. Si valutano in v3 se l'app prende slancio.

### 8.5 Niente DM (direct message)
Mai. Non è scope del progetto.

### 8.6 Niente commenti su review altrui (v1)
Le review sono visibili agli altri ma non commentabili. Niente moderazione, niente flame. Si valuta per il futuro.

### 8.7 Cinema = entità canonica da Google Places
**Decisione fondante**. Mai più stringa libera. Ogni cinema ha un `place_id` Google univoco. Nuovi cinema vengono creati su DB solo via funzione `upsert_cinema_from_place(place_id)` per evitare duplicati.

### 8.8 Prezzi cinema = inseriti dall'utente con suggerimento
Nessuna API esistente fornisce prezzi reali dei biglietti (variano per giorno/sala/promozione). L'app:
- Pre-compila il prezzo con storico utente per quel cinema
- Se primo utilizzo, pre-compila con media aggregata di tutti gli utenti
- Valida range plausibile (5-25 € soft warning, 0-100 € hard limit)

### 8.9 Username unico immutabile
L'username scelto al signup non si cambia. Il `display_name` sì. Evita problemi di "chi sono io adesso" nelle reference da follow/feed.

### 8.10 Email verification obbligatoria
Niente login senza email verificata. Default Supabase.

### 8.11 Reset password con email standard
Flusso Supabase out-of-the-box. Niente OTP custom.

### 8.12 No social login v1
Solo email/password. Aggiungere Google/Apple OAuth è 2 ore di lavoro ma fuori scope didattico v2.

### 8.13 Avatar profilo opzionale
Storage Supabase. Implementato nel modulo Profile, opzionale per l'utente. Default: iniziali del display name su sfondo colorato.

---

## <a id="non-e"></a>9. Cosa NON è CineLog

Per chiudere lo scope.

- **Non è Letterboxd**. Niente liste pubbliche curate, niente "diary" pubblico, niente commenti su review altrui.
- **Non è Trakt**. Niente sync con servizi di streaming, niente "checkin in tempo reale".
- **Non è IMDb/TMDB**. Non aggiunge contenuti al catalogo, lo consuma e basta.
- **Non è un'app di booking**. Non prenota biglietti, non si integra con i sistemi cinema.
- **Non è una piattaforma di video**. Niente trailer integrati (eventualmente link esterni a YouTube/TMDB).
- **Non è un'app finanziaria seria**. Le stats sono indicative, non un budget tracker professionale.
- **Non è un social generalista**. Niente feed di stato, niente foto, niente DM, niente storie. Il social è "vedi cosa hanno consigliato i tuoi follow".
- **Non è offline-first**. Funziona solo online (eccetto cache letture recenti).
- **Non è multi-lingua v1**. Italiano fisso (TMDB con `language=it`). I18n eventualmente v3.

---

## Riferimenti

- Schema dati completo: `T2_SCHEMA_DATI.md`
- Architettura tecnica: `T2_ARCHITETTURA.md`
- API esterne: `T2_API_ESTERNE.md`
- Stato corrente: `T1_STATO_PROGETTO.md`
