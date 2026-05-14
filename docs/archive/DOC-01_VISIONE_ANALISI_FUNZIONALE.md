# CineLog 2.0 — Visione di Progetto e Analisi Funzionale

**Versione:** 1.0  
**Data:** Maggio 2026  
**Status:** Specifiche Definitive (Didattica + Produzione Light)  
**Maintainer:** Sviluppo Flutter  

---

## Indice
1. [Manifesto e Filosofia](#manifesto)
2. [Panoramica Generale](#panoramica)
3. [Tre Pilastri Architetturali](#pilastri)
4. [Le 4 Schermate Principali](#schermate)
5. [Flussi d'Uso Dettagliati](#flussi)
6. [Modello dei Dati (Alto Livello)](#modello)
7. [Considerazioni di Design](#considerazioni)

---

## <a id="manifesto"></a>1. Manifesto e Filosofia

### 1.1 La Visione

**CineLog 2.0** nasce da una semplice idea: trasformare il modo in cui gli appassionati di cinema (o semplici curiosi) **ricordano, analizzano e discutono** i film che guardano al cinema.

Non è un'app di social network globale. Non è una piattaforma di condivisione pubblica. È **il tuo ecosistema personale del cinema**.

**Parola chiave:** Organizzazione consapevole + Analisi finanziaria + Riflessione personale.

### 1.2 Obiettivi Centrali

1. **Organizzazione Consapevole**
   - Mantenere una libreria personale di film desiderati e visti
   - Distinguere tra film "al cinema" e film guardati in altri contesti (streaming, casa)
   - Permettere di ritrovare facilmente ciò che stai cercando

2. **Consapevolezza Finanziaria**
   - Tracciare quanto spendi al cinema
   - Analizzare trend di spesa (quanto al mese? Dove spendo di più?)
   - Calcolare costi medi per aiutare nelle decisioni future

3. **Riflessione Personale**
   - Registrare la tua opinione su ogni film (rating + nota)
   - Confrontare il tuo gusto con i voti globali di TMDB
   - Tenere appunti sui cinema visitati
   - Identificare pattern: quali generi preferisci davvero?

4. **Scoperta Cosciente**
   - Esplorare nuovi film da fonti affidabili (TMDB API)
   - Filtrare per genere, rating minimo, categoria (in arrivo / ora al cinema / classici)
   - Aggiungere film alla tua "lista desideri" senza impegno finanziario

---

## <a id="panoramica"></a>2. Panoramica Generale dell'App

### 2.1 Stack Tecnologico

```
┌─────────────────────────────────────┐
│     Flutter 3.11.5 + Material 3    │
├─────────────────────────────────────┤
│   Riverpod (State Management)       │
│   • Notifier<T> per logica          │
│   • FutureProvider per API async    │
│   • AsyncValue per loading/error    │
├─────────────────────────────────────┤
│   Persistenza Locale                │
│   • shared_preferences              │
│   • Serializzazione JSON con Dart   │
├─────────────────────────────────────┤
│   API Esterna                       │
│   • TMDB (The Movie Database) REST  │
├─────────────────────────────────────┤
│   UI & Navigation                   │
│   • go_router (navigazione)         │
│   • BottomNavigationBar (tab)       │
│   • CustomPaint (grafici)           │
│   • Dialog, BottomSheet, SliveAppBar│
└─────────────────────────────────────┘
```

### 2.2 Il Ciclo di Vita Ideale dell'Utente

```
1. PRIMA APERTURA
   ├─ App si avvia
   ├─ Carica Discovery da TMDB
   └─ Crea le 3 scatole JSON locali (vuote)

2. ESPLORAZIONE
   ├─ Sfoglia film in Discovery
   ├─ Aggiunge film alla Wishlist
   └─ Legge dettagli (trama, cast, voto TMDB)

3. VISIONE AL CINEMA
   ├─ Cliccando "REGISTRA VISIONE"
   ├─ Dialog chiede: Prezzo + Nome Cinema
   ├─ Salva in Finance Ledger (+ aggiunge nota opzionale)
   └─ Film appare sia in Library che in Dashboard

4. RIFLESSIONE
   ├─ Torna al Dettaglio del film
   ├─ Scrive review personale (testo + rating 1-10)
   ├─ Vede comparazione (voto suo vs TMDB)
   └─ Salva appunti sul cinema

5. ANALISI
   ├─ Va in Dashboard
   ├─ Vede stats: quanto ha speso, generi preferiti
   ├─ Filtra per tipo (al cinema, wishlist, ecc)
   ├─ Vede i propri rating ordinati
   └─ Osserva i cinema più visitati
```

### 2.3 I Tre Caschi di Ferro dell'Architettura

L'app è costruita attorno a **tre responsabilità nette e indipendenti**:

#### **DISCOVERY (Pilastro API)**
- Fonte: TMDB
- Ruolo: Portale di scoperta infinito
- Dati: Film + poster + trama + cast + rating globale
- Persistenza: Nessuna (cache immagini locali)
- Non modifichiamo qui: i voti sono di TMDB

#### **LIBRARY (Pilastro Organizzazione)**
- Fonte: Utente tramite Discovery
- Ruolo: Raccolta personale "neutra" (non finanziaria)
- Dati: Wishlist (IDs) + Archivio Visti (film generici)
- Persistenza: shared_preferences JSON
- Logica: Nessuna finanza, solo memorizzazione

#### **DASHBOARD/FINANCE (Pilastro Economia)**
- Fonte: Utente tramite "Registra Visione" nel Dettaglio
- Ruolo: Ledger finanziario + Analisi
- Dati: Visione = {filmId, cinema, prezzo, data, count}
- Persistenza: shared_preferences JSON (ledger immutabile in lettura)
- Logica: Calcoli statistici, filtri, eliminazione (undo)

#### **SOCIAL/NOTES (Pilastro Riflessione)**
- Fonte: Utente durante uso
- Ruolo: Hub personale di reviews e appunti
- Dati: {filmId → rating, testo review}, {cinemaName → appunti}
- Persistenza: shared_preferences JSON
- Logica: Comparazione voti, aggregazioni locali

---

## <a id="pilastri"></a>3. I Tre Pilastri Architetturali in Dettaglio

### 3.1 DISCOVERY: Il Portale Infinito (TMDB)

**Responsabilità:**
- Carica pagine di film da TMDB (now playing, upcoming, top rated)
- Crea "categorie" di esplorazione
- Mostra poster, rating globale, trama sintetica
- Permette il tap per accedere al Dettaglio

**Flusso Dati:**
```
┌────────────────────────┐
│  TMDB API              │
│  GET /movie/now_playing│
│  GET /movie/upcoming   │
│  GET /movie/top_rated  │
└────────────┬───────────┘
             │ JSON
             ▼
┌──────────────────────────┐
│  MovieFutureProvider     │
│  (async da notifier)     │
└────────────┬──────────────┘
             │ AsyncValue<List<Movie>>
             ▼
┌──────────────────────────┐
│  DiscoveryScreen         │
│  (ConsumeWidget)         │
│  .when(loading/error/data)
└──────────────────────────┘
```

**Infinit Scroll:**
- User scrolla al fondo
- FutureProvider carica pagina successiva
- Film append alla lista (senza reload)

**Categorizzazione:**
```
Now Playing    → Film nelle sale ORA
Upcoming       → Uscite nei prossimi mesi
Top Rated      → I film più votati di sempre (Cult)
Trending       → Film in trend questa settimana
```

**Non c'è persistenza.** Se chiudi l'app e la riapri, Discovery ricarica tutto da TMDB. (Il caching delle immagini è automatico da Image.network di Flutter.)

### 3.2 LIBRARY: La Raccolta Personale

**Responsabilità:**
- Gestire Wishlist: film che "voglio vederli"
- Gestire Archivio Visti: film che "ho visto" (senza prezzo)
- Permettere di navigare tra i due
- Sincronizzazione da Discovery (bottone "Aggiungi")

**Struttura Dati:**

```dart
// Cosa viene salvato in shared_preferences

// library_wishlist.json
{
  "films": [
    {"id": "550", "title": "Fight Club", "posterUrl": "..."},
    {"id": "27205", "title": "Inception", "posterUrl": "..."}
  ]
}

// library_archive.json
{
  "films": [
    {
      "id": "550",
      "title": "Fight Club",
      "posterUrl": "...",
      "viewedDate": "2026-03-15",  // Quando l'ho visto (opzionale)
      "context": "streaming"  // Casa, streaming, TV, ecc
    }
  ]
}
```

**Flusso: Aggiungi a Wishlist**

```
User in Discovery → Tap "AGGIUNGI"
  ├─ Dialog: "Voglio vederlo" / "L'ho visto"
  │
  ├─ Se "Voglio vederlo"
  │  ├─ Film → Wishlist
  │  └─ [ID salvato in library_wishlist.json]
  │
  └─ Se "L'ho visto"
     ├─ Film → Archivio
     └─ [ID + metadata salvato in library_archive.json]
```

**REGOLA CRITICA:** Library e Finance sono **indipendenti**. 
- Un film può stare in Library (Archivio) senza prezzo.
- Un film può avere una Visione in Finance (prezzo + cinema) senza essere in Library.
- Possono coesistere.

### 3.3 DASHBOARD/FINANCE: Il Ledger Finanziario

**Responsabilità:**
- Registrare ogni visione al cinema (prezzo + cinema)
- Calcolare statistiche: spesa totale, media, trend
- Permettere filtraggio e analisi
- Eliminazione di errori (undo)

**Struttura Dati:**

```dart
// finance_ledger.json
{
  "entries": [
    {
      "id": "uuid_unico",
      "movieId": "550",
      "movieTitle": "Fight Club",
      "cinema": "Cineworld Kings Road",
      "priceEur": 9.50,
      "dateTime": "2026-05-08T19:30:00Z",
      "count": 1  // Se lo stesso film vedi 2 volte (count = 2)
    },
    {
      "id": "uuid_unico_2",
      "movieId": "550",
      "movieTitle": "Fight Club",
      "cinema": "UCI Cinemas Leicester Sq",
      "priceEur": 10.00,
      "dateTime": "2026-03-20T14:00:00Z",
      "count": 1
    }
  ]
}
```

**Flusso: Registra Visione**

```
User in MovieDetailScreen → Tap "REGISTRA VISIONE"
  ├─ Dialog appare:
  │  ├─ Campo Prezzo (default: 8.50€, modificabile)
  │  ├─ Campo Cinema (text input, o suggerito da cronologia)
  │  └─ Conferma
  │
  ├─ Preço validato (> 0)
  ├─ Cinema non vuoto
  │
  └─ ✅ Salva in finance_ledger.json
     ├─ Crea nuovo UUID
     ├─ Timestamp ora
     └─ Count = 1 (primo acquisto di questo film)
```

**Eliminazione & Modifica:**
- Dashboard mostra lista cronologica di tutte le visioni
- Swipe left → Delete (conferma popup)
- Tap su voce → Popup modifica (prezzo, cinema)

**Statistiche Automatiche:**

```
Somma film visti:      COUNT di tutte le entries
Spesa totale:          SUM(priceEur)
Spesa media:           totalSpent / totalCount
Cinema visitati:       DISTINCT cinema
Genere preferito:      MAX frequenza genere
Mese top-spender:      MAX spesa per mese (grafici)
```

### 3.4 SOCIAL/NOTES: Il Personal Hub

**Responsabilità:**
- Permettere all'utente di votare ogni film (1-10)
- Permettere di scrivere una review (testo libero, max 500 char)
- Confrontare il voto personale con TMDB
- Salvare appunti sui cinema

**Struttura Dati:**

```dart
// user_reviews.json
{
  "reviews": [
    {
      "movieId": "550",
      "movieTitle": "Fight Club",
      "userRating": 9,
      "reviewText": "Capolavoro. Finale devastante.",
      "timestamp": "2026-05-08T22:00:00Z"
    }
  ]
}

// cinema_notes.json
{
  "notes": [
    {
      "cinemaName": "Cineworld Kings Road",
      "note": "Sala comoda, proiezioni 3D buone",
      "avgPriceEur": 9.50,
      "visitCount": 5,
      "lastVisit": "2026-05-08T19:30:00Z"
    }
  ]
}
```

**Flusso: Aggiungi Review**

```
User in MovieDetailScreen → Vede sezione "La Tua Opinione"
  ├─ Rating Bar (1-10 stelle, draggable)
  ├─ TextField (opzionale): scrivi review
  ├─ Tap "Salva Review"
  │
  └─ ✅ Salva in user_reviews.json
     ├─ Se esiste già review dello stesso film → Update
     └─ Altrimenti → Insert nuovo
```

**Comparazione Voti:**

Nel Dettaglio film si vede:

```
┌─────────────────────────────────────┐
│ TMDB Rating: 8.8 ⭐⭐⭐⭐⭐        │
│ Your Rating: 9.0 ⭐⭐⭐⭐⭐        │
│                                     │
│ [Grafico comparativo]               │
│ Tu 20% più alto di TMDB             │
└─────────────────────────────────────┘
```

(Il grafico è fatto con `CustomPaint` per massima didattica.)

---

## <a id="schermate"></a>4. Le 4 Schermate Principali

### 4.1 DISCOVERY SCREEN

**Responsabilità:**
- Mostrare film pagina per pagina (infinite scroll)
- Permettere tap su film → Dettaglio
- Mostrare categorie (tab o filter)

**Layout:**

```
┌──────────────────────────────────────┐
│ CineLog          [🔍 Search]         │
├──────────────────────────────────────┤
│ [Now Playing] [Upcoming] [Cult]      │
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────┐  ┌──────────────┐ │
│  │  Film 1      │  │  Film 2      │ │
│  │  Poster      │  │  Poster      │ │
│  │  Rating ⭐  │  │  Rating ⭐  │ │
│  └──────────────┘  └──────────────┘ │
│                                      │
│  ┌──────────────┐  ┌──────────────┐ │
│  │  Film 3      │  │  Film 4      │ │
│  │  Poster      │  │  Poster      │ │
│  │  Rating ⭐  │  │  Rating ⭐  │ │
│  └──────────────┘  └──────────────┘ │
│                                      │
│  [Loading 5 film in più...]          │
└──────────────────────────────────────┘
```

**Comportamento:**
- Scroll infinito: raggiunto il fondo → carica prossima pagina
- Tap su film → Navigator.push(MovieDetailScreen)
- Ogni categoria carica da endpoint TMDB diverso

### 4.2 MOVIE DETAIL SCREEN

**Responsabilità:**
- Mostrare tutte le info del film (trama, cast, rating TMDB)
- Permettere azioni: Aggiungi a Wishlist / Registra Visione
- Mostrare la tua review e rating
- Permettere modifica review

**Layout (Sliver):**

```
┌──────────────────────────────────────┐
│ [← Back]                        [+]  │
├──────────────────────────────────────┤
│                                      │
│         [Poster Espanso]             │
│         (Hero animation)             │
│                                      │
│         Fight Club                   │
│         ⭐ 8.8 | ⏱️ 2h 19m | 🎬 1999 │
│                                      │
├──────────────────────────────────────┤
│ SINOSSI                              │
│ Un impiegato insoddisfatto forma ... │
│                                      │
├──────────────────────────────────────┤
│ CAST                                 │
│ [Brad Pitt] [Edward Norton] ...      │
│                                      │
├──────────────────────────────────────┤
│ LA TUA OPINIONE                      │
│                                      │
│ Rating: [⭐⭐⭐⭐⭐] (9/10)          │
│ Vs TMDB: 8.8 → Tu +0.2 (più alto)  │
│                                      │
│ [Grafico comparativo con CustomPaint]│
│                                      │
│ Note personale:                      │
│ "Capolavoro assoluto, finale che ... │
│                                      │
│ [Modifica] [Salva]                   │
│                                      │
├──────────────────────────────────────┤
│ AZIONI                               │
│ [Aggiungi a Wishlist] [Registra al Cine]│
│                                      │
└──────────────────────────────────────┘
```

**Interazioni Chiave:**

1. **Aggiungi a Wishlist** → Dialog: "Voglio vederlo / L'ho visto"
2. **Registra al Cinema** → Dialog: Prezzo + Cinema → Ledger
3. **Rating Bar** → Draggabile, update in tempo reale
4. **Salva Review** → Persistent in user_reviews.json

### 4.3 DASHBOARD/STATS SCREEN

**Responsabilità:**
- Mostrare statistiche: spesa totale, media, trend
- Elencare tutte le visioni in cronologia
- Permettere filtraggio (per cinema, genere, periodo)
- Permettere eliminazione di errori

**Layout:**

```
┌──────────────────────────────────────┐
│ Dashboard FinanceFlow                │
├──────────────────────────────────────┤
│                                      │
│ ┌────────────────────────────────┐  │
│ │ SPESA TOTALE                   │  │
│ │ €105.50                        │  │
│ │ 📊 (grafico trend mensile)     │  │
│ └────────────────────────────────┘  │
│                                      │
│ ┌──────────────┐ ┌──────────────┐   │
│ │ FILM VISTI   │ │ MEDIA PREZZO │   │
│ │ 12           │ │ €8.79        │   │
│ └──────────────┘ └──────────────┘   │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ FILTRI                           │ │
│ │ [All] [Cinema] [Wishlist] [Cult] │ │
│ └──────────────────────────────────┘ │
│                                      │
│ CRONOLOGIA VISIONI                   │
│ ─────────────────────────────────────│
│ Fight Club          Cineworld  €9.50 │
│ 8 Mag 2026 19:30    [⋮ delete]      │
│                                      │
│ Inception           UCI Cinemas €10  │
│ 20 Mar 2026 14:00   [⋮ delete]      │
│                                      │
│ ... (scroll infinito)                │
│                                      │
└──────────────────────────────────────┘
```

**Statistiche Calcolate:**

```
Spesa totale:       SUM(price) da ledger
Media prezzo:       totalSpent / countFilms
Film più caro:      MAX(price)
Cinema top:         MOST FREQUENT cinema
Genere preferito:   MOST COMMON genre in viewed
Trend mese:         Spesa aggregata per mese (charts)
```

**Filtraggio:**
- All: Mostra tutto
- Cinema: Seleziona da lista dropdown
- Genere: Seleziona da checkboxes
- Periodo: Slider date da-a

### 4.4 SOCIAL/NOTES SCREEN

**Responsabilità:**
- Mostrare le tue review (film votati)
- Aggregare statistiche personali (film rating, cinema notes)
- Permettere gestione appunti

**Layout:**

```
┌──────────────────────────────────────┐
│ Le Mie Review                        │
├──────────────────────────────────────┤
│                                      │
│ LA TRAMA DEI TUOI VOTI               │
│ Rating medio: 8.2/10                 │
│ Film votati: 8                       │
│                                      │
│ [Grafico: Distribution 1-10]         │
│                                      │
├──────────────────────────────────────┤
│ FILM CHE HAI VOTATO                  │
│                                      │
│ 1. Fight Club          9.0 ⭐        │
│    "Capolavoro assoluto"             │
│                                      │
│ 2. Inception           8.5 ⭐        │
│    "Intrigante e visivo"             │
│                                      │
│ 3. The Matrix          8.0 ⭐        │
│    "Rivoluzionario per l'epoca"      │
│                                      │
├──────────────────────────────────────┤
│ CINEMA CHE VISITI                    │
│                                      │
│ Cineworld Kings Rd:                  │
│ 5 volte | Media €9.50 | Nota: ...   │
│ [Modifica nota]                      │
│                                      │
│ UCI Cinemas Leicester Sq:            │
│ 3 volte | Media €10.00 | Nota: ...  │
│ [Modifica nota]                      │
│                                      │
└──────────────────────────────────────┘
```

**Funzionalità:**

1. **Top Rated By You**: Lista film ordinati per rating personale
2. **Cinema Summary**: Frequenza + appunti + prezzo medio
3. **Rating Distribution**: CustomPaint histogram (rating vs count)
4. **Comparazione vs TMDB**: "Sei più critico o più indulgente del pubblico?"

---

## <a id="flussi"></a>5. Flussi d'Uso Dettagliati

### 5.1 Flusso: Primo Accesso

```
┌─ App launch
├─ ProviderScope initialized
├─ shared_preferences.getInstance()
│  ├─ Se nuova app: crea 3 scatole vuote
│  │  ├─ library_wishlist.json = {}
│  │  ├─ library_archive.json = {}
│  │  ├─ finance_ledger.json = {}
│  │  ├─ user_reviews.json = {}
│  │  └─ cinema_notes.json = {}
│  │
│  └─ Se app preesistente: carica dati
│
├─ MovieFutureProvider carica da TMDB
│  └─ GET /movie/now_playing (pagina 1)
│
├─ DiscoveryScreen render con lista film
└─ User vede griglia film con posteruri
```

### 5.2 Flusso: Aggiungi Film a Wishlist

```
┌─ User in DiscoveryScreen
├─ Tap su film poster
├─ Navigator.push → MovieDetailScreen
│  ├─ Film details fetch (da TMDB cache o nuovo call)
│  └─ Layout renderizza
│
├─ User tap "AGGIUNGI A WISHLIST"
├─ Dialog popup:
│  ├─ [Voglio vederlo] ← Selected default
│  └─ [L'ho visto (casa/streaming)]
│
├─ Utente clicca "Voglio vederlo"
├─ App legge library_wishlist.json corrente
├─ Aggiunge film ID alla lista
├─ Serializza e salva in shared_preferences
│
└─ Snackbar: "Aggiunto a Wishlist"
```

### 5.3 Flusso: Registra Visione al Cinema

```
┌─ User in MovieDetailScreen
├─ Tap "REGISTRA VISIONE AL CINEMA"
├─ Dialog popup:
│  ├─ Prezzo € [8.50] ← default, modificabile
│  ├─ Cinema "Scrivi nome" ← dropdown con cronologia
│  └─ [Conferma] [Annulla]
│
├─ User modifica prezzo a 9.50€, sceglie "Cineworld Kings"
├─ Tap "Conferma"
│
├─ Validazione:
│  ├─ Prezzo > 0? ✓
│  ├─ Cinema non vuoto? ✓
│
├─ App legge finance_ledger.json
├─ Crea nuova entry:
│  {
│    "id": "uuid_random",
│    "movieId": "550",
│    "movieTitle": "Fight Club",
│    "cinema": "Cineworld Kings Rd",
│    "priceEur": 9.50,
│    "dateTime": "2026-05-08T19:30:00Z",
│    "count": 1
│  }
├─ Append a ledger → salva in shared_preferences
│
│  [SIMULTANEAMENTE]
├─ Film aggiunto ad archive di Library (se non già presente)
│
└─ Snackbar: "Visione registrata: €9.50 presso Cineworld Kings Rd"
```

### 5.4 Flusso: Aggiungi Review + Rating

```
┌─ User in MovieDetailScreen
├─ Vede sezione "La Tua Opinione"
├─ Rating Bar attuale: nessun rating (0/10)
│
├─ Drag rating bar → seleziona 9/10
├─ TextField: scrivi "Capolavoro, finale devastante"
│
├─ Tap "Salva Review"
├─ Validazione:
│  ├─ Rating è 0? → warning, chiedi conferma
│  ├─ Review testo è > 500 char? → warning
│
├─ App legge user_reviews.json
├─ Check: esiste review per questo movie?
│  ├─ SÌ → Update entry esistente
│  └─ NO → Crea nuova entry
│
├─ Serializza:
│  {
│    "movieId": "550",
│    "movieTitle": "Fight Club",
│    "userRating": 9,
│    "reviewText": "Capolavoro, finale devastante.",
│    "timestamp": "2026-05-08T22:10:00Z"
│  }
│
├─ Salva in shared_preferences
├─ UI rebuild: comparazione vs TMDB aggiornata
│
└─ Snackbar: "Review salvata"
```

### 5.5 Flusso: Analizza Stats in Dashboard

```
┌─ User in tab "Dashboard"
├─ DashboardScreen carica dati locali:
│  ├─ Legge finance_ledger.json
│  ├─ Legge cinema_notes.json
│  └─ Legge user_reviews.json (per rating distribution)
│
├─ Calcola statistiche:
│  ├─ totalSpent = SUM(priceEur)
│  ├─ avgPrice = totalSpent / count
│  ├─ cinemaList = DISTINCT(cinema)
│  ├─ ratingAvg = AVG(userRating)
│  └─ trend = [mese1_spesa, mese2_spesa, ...]
│
├─ Render cards statistiche
├─ Render cronologia visioni (scroll infinito)
│
├─ User clicca su "FILTRI"
├─ BottomSheet apre con opzioni:
│  ├─ Filter by Cinema: [Cineworld] [UCI] [...]
│  ├─ Filter by Genre: [Action] [Drama] [...]
│  └─ Filter by Period: [Questo mese] [Ultimi 3 mesi] [...]
│
├─ User seleziona "Cineworld" + "Ultimi 3 mesi"
├─ Cronologia ricaclcolata (filter applied)
│
├─ User tap su voce "Fight Club - €9.50"
├─ BottomSheet edit:
│  ├─ Modifica prezzo: €9.50 → €10.00
│  ├─ Modifica cinema: "Cineworld" → "UCI"
│  └─ [Salva] [Elimina]
│
└─ Tap elimina → Confirm dialog → Entry rimossa, ledger salvata
```

---

## <a id="modello"></a>6. Modello dei Dati (Alto Livello)

### 6.1 Modello: Movie (Da TMDB)

```dart
class Movie {
  final String id;              // TMDB ID
  final String title;
  final String description;     // Sinossi
  final String posterUrl;       // URL immagine
  final String backdropUrl;     // URL backdrop
  final double rating;          // TMDB rating (0-10)
  final int durationMinutes;
  final DateTime releaseDate;
  final String? genre;          // es. "Action, Sci-Fi"
  final List<String>? cast;     // Nome attori
  
  // Computed
  String get formattedDuration => "${durationMinutes ~/ 60}h ${durationMinutes % 60}m";
}
```

### 6.2 Modello: FinanceLedgerEntry

```dart
class FinanceLedgerEntry {
  final String id;              // UUID unico
  final String movieId;
  final String movieTitle;
  final String cinema;          // Nome cinema
  final double priceEur;
  final DateTime dateTime;      // Quando visto
  final int count;              // Numero volte visto (default 1)
  
  // Computed
  String get formattedPrice => "€${priceEur.toStringAsFixed(2)}";
  String get monthKey => "${dateTime.year}-${dateTime.month}";  // Per aggregazioni
}
```

### 6.3 Modello: UserReview

```dart
class UserReview {
  final String movieId;
  final String movieTitle;
  final int userRating;         // 0-10
  final String reviewText;      // Max 500 char
  final DateTime timestamp;
  
  // Computed
  bool get hasRating => userRating > 0;
  bool get isPositive => userRating >= 7;
}
```

### 6.4 Modello: CinemaNote

```dart
class CinemaNote {
  final String cinemaName;
  final String note;            // Appunti liberi
  final double avgPriceEur;     // Media prezzi qui
  final int visitCount;         // Quante volte visitato
  final DateTime lastVisit;
  
  // Computed
  String get frequencyLabel => "$visitCount volte";
}
```

---

## <a id="considerazioni"></a>7. Considerazioni di Design

### 7.1 Scelte Architetturali Fondamentali

#### **Separazione Library vs Finance**

**Perché sono separate?**

1. **Use Case Divergente**: 
   - Library: "Voglio organizzare i film che mi interessano"
   - Finance: "Voglio tracciare le spese al cinema"

2. **Non Tutti gli Utenti Usano Finance**:
   - Uno potrebbe usare solo Library (wishlist personale)
   - Uno potrebbe usare solo Finance (se fa spese aziendali)
   - Non forziarli a fare entrambi

3. **Persistenza Indipendente**:
   - Se cancello la Library, Finance resta intatto
   - Se cancello Finance, Library resta intatto
   - Meno rischio di corruzione dati

4. **Logica Pulita**:
   - Notifier separati = codice più manutenibile
   - Provider separati = cache separata
   - Nessun accoppiamento

#### **No Database, Solo JSON**

**Perché shared_preferences + JSON?**

1. **Semplicità**: Zero configurazione, zero dipendenze esterne
2. **Didattica**: Imparare serializzazione, schema design
3. **Performance**: JSON è leggero per dati < 1MB
4. **Portabilità**: Facile export/debug

**Limiti Noti:**
- Non adatto a dataset massivi (es. 100k film)
- Non supporta query avanzate (es. join)
- Non è relazionale

**Soluzione Futura (Fase 4):**
Se l'app cresce, migrare a **Isar** (DB locale NoSQL per Flutter, molto più potente, stessa persistenza locale).

#### **Infinite Scroll su Discovery**

**Perché non caricare tutto subito?**

1. **UX**: Non vuoi scrollare 500 film
2. **Performance**: Caricamenti graduali
3. **Didattica**: Imparare pagination API, FutureProvider, AsyncValue

### 7.2 Decisioni UI/UX

#### **Bottom Navigation vs Drawer**

Usare BottomNavigationBar perché:
- ✅ Touchable su mobile
- ✅ Sempre visibile
- ✅ Facile switchare tra 4 tab
- ❌ Non supporta sub-navigation (ma non ci serve)

#### **Dialog per Input (Prezzo, Cinema)**

Perché dialog e non una schermata intera?

1. **Non è una "schermata principale"**: è un micro-task
2. **Ritorno veloce**: post-input torno automaticamente al detail
3. **Contesto**: vedo ancora il film dietro il dialog (blur)

#### **CustomPaint per Grafici**

Perché non usare `fl_chart` o `charts_flutter`?

1. **Didattica**: Imparare `CustomPaint` da zero
2. **Libertà**: Nessun dependency aggiunto
3. **Semplicità**: Grafici semplici (linea, bar, hist) → CustomPaint basta

(Se servissero grafici complessi, allora sì, usare un package.)

### 7.3 Sicurezza & Privacy

**Non c'è backend, quindi:**
- ✅ Dati NON vanno online
- ✅ Zero tracking
- ✅ Zero login (no autenticazione)
- ❌ Nessuna cloud backup
- ❌ Se perdi il phone, perdi i dati

**GDPR Compliance**: ✅ Dati locali, nessuna raccolta personale

### 7.4 Performance Target

| Metrica | Target |
|---------|--------|
| Time to Interactive (TTI) | < 2 secondi (primo load) |
| FPS durante scroll | 60 FPS (no jank) |
| API call latency | < 3 secondi (timeout) |
| Storage utilizzato | < 50 MB (comprese immagini cache) |

---

## 8. Conclusione

**CineLog 2.0** è la sintesi di tre intenzioni:

1. **Pratica**: Un'app che risolve un vero problema (tracciare i film)
2. **Didattica**: Un'opportunità per imparare Flutter in profondità
3. **Consapevolezza**: Aiutare gli utenti a riflettere sui loro consumi culturali

Nei prossimi documenti entreremo nel dettaglio tecnico di come realizzare questa visione con Riverpod, shared_preferences e TMDB API.

---

**Documento redatto: Maggio 2026**  
**Prossimo:** DOC-02 — Architettura Tecnica e Provider Riverpod
