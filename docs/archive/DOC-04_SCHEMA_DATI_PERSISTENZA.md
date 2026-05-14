# CineLog 2.0 — Schema Dati e Persistenza (JSON + shared_preferences)

**Versione:** 1.0  
**Data:** Maggio 2026  
**Scope:** Strutture JSON, serializzazione, strategia di backup  

---

## Indice

1. [Overview Persistenza](#overview)
2. [Struttura JSON per Ogni Modello](#json-models)
3. [Storage Keys e Naming Convention](#storage-keys)
4. [Migration Strategy](#migration)
5. [Backup & Export](#backup)
6. [Data Validation & Sanitization](#validation)
7. [Recupero da Dati Corrotti](#recovery)

---

## <a id="overview"></a>1. Overview della Persistenza

### 1.1 Architettura Storage

```
┌─────────────────────────────┐
│     App State (Riverpod)    │
│  (in RAM, volatile)         │
└──────────────┬──────────────┘
               │ save()
┌──────────────▼──────────────┐
│   LocalStorageService       │
│   (JSON serialization)      │
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│   shared_preferences        │
│   (device persistent store) │
└─────────────────────────────┘
```

### 1.2 Principi Guida

1. **Immutabilità in Memoria**: Riverpod state è immutabile
2. **Serializzazione Esplicita**: Ogni modello sa come diventare JSON
3. **Lazy Deserialization**: Carica dal disco solo quando necessario
4. **Graceful Degradation**: Se JSON corrotto → default vuoto, no crash
5. **Version-Safe**: Schema è versionato per future migration

---

## <a id="json-models"></a>2. Struttura JSON per Ogni Modello

### 2.1 Movie (Da TMDB)

**Non viene salvato** (è in cache immagini, caricato ogni volta da API).

Se necessario salvare per offline:

```json
{
  "id": "550",
  "title": "Fight Club",
  "description": "A disgruntled office worker...",
  "posterUrl": "https://image.tmdb.org/t/p/w500/...",
  "backdropUrl": "https://image.tmdb.org/t/p/original/...",
  "rating": 8.8,
  "durationMinutes": 139,
  "releaseDate": "1999-10-15T00:00:00.000Z",
  "genre": "Drama, Thriller",
  "cast": ["Brad Pitt", "Edward Norton", "Helena Bonham Carter"]
}
```

### 2.2 FinanceLedgerEntry

**Salvato in:** `shared_preferences` key `"finance_ledger"`

**Struttura Single Entry:**

```json
{
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "movieId": "550",
  "movieTitle": "Fight Club",
  "cinema": "Cineworld Kings Road",
  "priceEur": 9.50,
  "dateTime": "2026-05-08T19:30:00.000Z",
  "count": 1
}
```

**Struttura Completa (Finance Ledger):**

```json
{
  "entries": [
    {
      "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "movieId": "550",
      "movieTitle": "Fight Club",
      "cinema": "Cineworld Kings Road",
      "priceEur": 9.50,
      "dateTime": "2026-05-08T19:30:00.000Z",
      "count": 1
    },
    {
      "id": "a8e4c5d6-7f8g-9h0i-j1k2-l3m4n5o6p7q8",
      "movieId": "550",
      "movieTitle": "Fight Club",
      "cinema": "UCI Cinemas Leicester Sq",
      "priceEur": 10.00,
      "dateTime": "2026-03-20T14:00:00.000Z",
      "count": 1
    }
  ]
}
```

**Nota:** L'array è wrappato in oggetto per potervi aggiungere metadata in futuro (es. `version`, `lastUpdated`).

**Serializzazione (Dart):**

```dart
// → JSON (salva)
List<FinanceLedgerEntry> entries = [...];
final json = {
  'entries': entries.map((e) => e.toJson()).toList(),
};
final jsonString = jsonEncode(json);

// ← JSON (carica)
final json = jsonDecode(jsonString) as Map;
final entriesList = (json['entries'] as List)
  .map((e) => FinanceLedgerEntry.fromJson(e))
  .toList();
```

### 2.3 UserReview

**Salvato in:** `shared_preferences` key `"user_reviews"`

**Struttura Single Review:**

```json
{
  "movieId": "550",
  "movieTitle": "Fight Club",
  "userRating": 9,
  "reviewText": "Capolavoro assoluto. La scena finale mi ha lasciato senza fiato.",
  "timestamp": "2026-05-08T22:10:00.000Z"
}
```

**Struttura Completa:**

```json
{
  "reviews": [
    {
      "movieId": "550",
      "movieTitle": "Fight Club",
      "userRating": 9,
      "reviewText": "Capolavoro assoluto...",
      "timestamp": "2026-05-08T22:10:00.000Z"
    },
    {
      "movieId": "27205",
      "movieTitle": "Inception",
      "userRating": 8,
      "reviewText": "Intrigante e affascinante, ma talvolta confuso.",
      "timestamp": "2026-04-15T19:45:00.000Z"
    }
  ]
}
```

### 2.4 CinemaNote

**Salvato in:** `shared_preferences` key `"cinema_notes"`

**Struttura Single Note:**

```json
{
  "cinemaName": "Cineworld Kings Road",
  "note": "Sala comoda, proiezioni 3D buone, snack caro",
  "avgPriceEur": 9.50,
  "visitCount": 5,
  "lastVisit": "2026-05-08T19:30:00.000Z"
}
```

**Struttura Completa:**

```json
{
  "notes": [
    {
      "cinemaName": "Cineworld Kings Road",
      "note": "Sala comoda, proiezioni 3D buone...",
      "avgPriceEur": 9.50,
      "visitCount": 5,
      "lastVisit": "2026-05-08T19:30:00.000Z"
    },
    {
      "cinemaName": "UCI Cinemas Leicester Sq",
      "note": "Proiezioni IMAX, ma molto caro",
      "avgPriceEur": 10.50,
      "visitCount": 3,
      "lastVisit": "2026-03-20T14:00:00.000Z"
    }
  ]
}
```

### 2.5 Wishlist

**Salvato in:** `shared_preferences` key `"library_wishlist"`

**Struttura:**

```json
{
  "films": [
    {
      "id": "550",
      "title": "Fight Club",
      "posterUrl": "https://image.tmdb.org/t/p/w500/...",
      "rating": 8.8
    },
    {
      "id": "27205",
      "title": "Inception",
      "posterUrl": "https://image.tmdb.org/t/p/w500/...",
      "rating": 8.8
    }
  ]
}
```

**Nota:** Salviamo solo ID, title, posterUrl, rating. Non vogliamo un dataset massiccio (costi storage).

### 2.6 LibraryArchive

**Salvato in:** `shared_preferences` key `"library_archive"`

**Struttura:**

```json
{
  "films": [
    {
      "id": "550",
      "title": "Fight Club",
      "posterUrl": "https://image.tmdb.org/t/p/w500/...",
      "viewedDate": "2026-03-15T00:00:00.000Z",
      "context": "streaming"
    },
    {
      "id": "27205",
      "title": "Inception",
      "posterUrl": "https://image.tmdb.org/t/p/w500/...",
      "viewedDate": "2026-02-10T00:00:00.000Z",
      "context": "tv"
    }
  ]
}
```

**Context Enum:** `"streaming"`, `"tv"`, `"dvd"`, `"cinema"`, `"other"`

---

## <a id="storage-keys"></a>3. Storage Keys e Naming Convention

### 3.1 Mappa Completa

| Modello | SharedPreferences Key | Descrizione |
|---------|----------------------|-------------|
| FinanceLedger | `"finance_ledger"` | Visioni al cinema con prezzo |
| UserReview | `"user_reviews"` | Rating e testo review film |
| CinemaNote | `"cinema_notes"` | Appunti su cinema visitati |
| Wishlist | `"library_wishlist"` | Film voglio vederli |
| LibraryArchive | `"library_archive"` | Film ho visto (generico) |

### 3.2 Naming Convention

- **CamelCase minuscolo** per key
- **Prefisso semantico**: `library_*`, `finance_*`, `user_*`
- **No special characters** (spazi, slash, ecc)
- **Versione Schema (opzionale)**: `"finance_ledger_v2"`

### 3.3 Enumerazione in Dart

```dart
// lib/core/storage_keys.dart

enum StorageKey {
  financeLedger('finance_ledger'),
  userReviews('user_reviews'),
  cinemaNotes('cinema_notes'),
  wishlist('library_wishlist'),
  archive('library_archive');

  final String key;
  const StorageKey(this.key);
}

// Uso
_prefs.getString(StorageKey.financeLedger.key);
```

---

## <a id="migration"></a>4. Migration Strategy

### 4.1 Versionamento Schema

Se in futuro cambiamo struttura, usiamo versioning:

```json
{
  "version": 1,
  "entries": [...]
}
```

**Codice Migration (Dart):**

```dart
List<FinanceLedgerEntry> loadFinanceLedger() {
  final json = _prefs.getString(StorageKey.financeLedger.key);
  if (json == null || json.isEmpty) return [];

  try {
    final data = jsonDecode(json) as Map;
    final version = data['version'] ?? 1;

    if (version == 1) {
      return _migrateV1(data);
    } else if (version == 2) {
      return _migrateV2(data);
    }
    // Default: assume latest version
    return (data['entries'] as List)
      .map((e) => FinanceLedgerEntry.fromJson(e))
      .toList();
  } catch (e) {
    // Log e ritorna fallback
    debugPrint('Error loading finance ledger: $e');
    return [];
  }
}

List<FinanceLedgerEntry> _migrateV1(Map data) {
  // Se versione 1 ha struttura diversa, trasforma qui
  return (data['entries'] as List)
    .map((e) => FinanceLedgerEntry.fromJson(e))
    .toList();
}
```

### 4.2 Backwards Compatibility

- **Aggiungi campi**: default values in fromJson
- **Rimuovi campi**: ignora in fromJson (no error)
- **Rinomina campi**: aggiungi alias nel parsing

```dart
factory FinanceLedgerEntry.fromJson(Map<String, dynamic> json) {
  return FinanceLedgerEntry(
    id: json['id'] ?? json['entryId'] ?? '',  // Alias
    movieId: json['movieId'] ?? '',
    movieTitle: json['movieTitle'] ?? '',
    cinema: json['cinema'] ?? json['cinemaName'] ?? 'Unknown',  // Alias
    priceEur: (json['priceEur'] ?? json['price'] ?? 0.0).toDouble(),  // Alias
    dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
    count: json['count'] ?? 1,  // Default value
  );
}
```

---

## <a id="backup"></a>5. Backup & Export

### 5.1 Funzione Export Totale

```dart
// lib/repositories/local_storage_service.dart

Future<String> exportAllDataAsJson() async {
  final allData = {
    'version': 1,
    'exportTime': DateTime.now().toIso8601String(),
    'data': {
      'finance_ledger': jsonDecode(
        _prefs.getString(StorageKey.financeLedger.key) ?? '{}'
      ),
      'user_reviews': jsonDecode(
        _prefs.getString(StorageKey.userReviews.key) ?? '{}'
      ),
      'cinema_notes': jsonDecode(
        _prefs.getString(StorageKey.cinemaNotes.key) ?? '{}'
      ),
      'wishlist': jsonDecode(
        _prefs.getString(StorageKey.wishlist.key) ?? '{}'
      ),
      'archive': jsonDecode(
        _prefs.getString(StorageKey.archive.key) ?? '{}'
      ),
    },
  };

  return jsonEncode(allData);
}
```

**Uso (nel SettingsScreen, future):**

```dart
onPressed: () async {
  final exported = await storage.exportAllDataAsJson();
  
  // Copia negli appunti (flutter/services)
  await Clipboard.setData(ClipboardData(text: exported));
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Dati copiati negli appunti')),
  );
},
child: const Text('Esporta Dati'),
```

### 5.2 Funzione Import da JSON

```dart
Future<void> importDataFromJson(String jsonString) async {
  try {
    final data = jsonDecode(jsonString) as Map;
    final version = data['version'] ?? 1;

    if (version != 1) {
      throw Exception('Import version non supportata');
    }

    final payload = data['data'] as Map;

    // Salva ogni sezione
    if (payload.containsKey('finance_ledger')) {
      await _prefs.setString(
        StorageKey.financeLedger.key,
        jsonEncode(payload['finance_ledger']),
      );
    }

    // Simile per altri...

    debugPrint('Import completato con successo');
  } catch (e) {
    throw Exception('Errore import: $e');
  }
}
```

---

## <a id="validation"></a>6. Data Validation & Sanitization

### 6.1 Validazione in fromJson

```dart
factory FinanceLedgerEntry.fromJson(Map<String, dynamic> json) {
  // Validazione campi obbligatori
  final id = json['id'] as String?;
  if (id == null || id.isEmpty) {
    throw FormatException('FinanceLedgerEntry.id is required');
  }

  final movieId = json['movieId'] as String?;
  if (movieId == null || movieId.isEmpty) {
    throw FormatException('FinanceLedgerEntry.movieId is required');
  }

  final priceEur = (json['priceEur'] as num?)?.toDouble();
  if (priceEur == null || priceEur < 0) {
    throw FormatException('FinanceLedgerEntry.priceEur must be >= 0');
  }

  // Se tutto ok
  return FinanceLedgerEntry(
    id: id,
    movieId: movieId,
    movieTitle: (json['movieTitle'] as String?) ?? 'Unknown',
    cinema: (json['cinema'] as String?) ?? 'Unknown Cinema',
    priceEur: priceEur,
    dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ?? DateTime.now(),
    count: (json['count'] as int?) ?? 1,
  );
}
```

### 6.2 Sanitizzazione Input Utente

Quando utente inserisce cinema/note, sanitizza:

```dart
Future<void> addVisione(String cinema, double price) async {
  // Trim e limita lunghezza
  final sanitizedCinema = cinema.trim();
  if (sanitizedCinema.isEmpty) {
    throw FormatException('Cinema cannot be empty');
  }
  if (sanitizedCinema.length > 100) {
    throw FormatException('Cinema too long (max 100 chars)');
  }

  // Valida prezzo
  if (price <= 0 || price > 1000) {
    throw FormatException('Price must be between 0 and 1000');
  }

  // Se tutto ok, procedi
  // ...
}
```

### 6.3 Note Testuali (Max Length)

```dart
if (reviewText.length > 500) {
  throw FormatException('Review too long (max 500 chars)');
}

if (cinemaNote.length > 1000) {
  throw FormatException('Note too long (max 1000 chars)');
}
```

---

## <a id="recovery"></a>7. Recupero da Dati Corrotti

### 7.1 Try-Catch Graceful in Load

```dart
List<FinanceLedgerEntry> loadFinanceLedger() {
  try {
    final jsonString = _prefs.getString(StorageKey.financeLedger.key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];  // Nessun dato ancora salvato
    }

    final data = jsonDecode(jsonString) as Map;
    final entries = (data['entries'] as List?)
      ?.map((e) => FinanceLedgerEntry.fromJson(e as Map<String, dynamic>))
      ?.toList() ?? [];

    return entries;
  } on FormatException catch (e) {
    // JSON malformato
    debugPrint('⚠️ Finance ledger is corrupted: $e');
    // Fallback: ritorna lista vuota, chiedi all'utente di ripristinare backup
    return [];
  } on Exception catch (e) {
    debugPrint('❌ Unexpected error loading finance ledger: $e');
    return [];
  }
}
```

### 7.2 Notifica all'Utente

Se dati corrotti, mostra dialog:

```dart
if (loadedEntries.isEmpty && _prefs.getString(StorageKey.financeLedger.key) != null) {
  // Dati salvati ma non leggibili
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Dati Corrotti'),
      content: const Text(
        'I dati salvati non sono leggibili. '
        'Puoi ripristinarli da un backup oppure iniziare da zero.'
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(financeProvider.notifier).reset();
            Navigator.pop(ctx);
          },
          child: const Text('Ripristina da Zero'),
        ),
        TextButton(
          onPressed: () {
            _showRestoreBackupDialog(context);
            Navigator.pop(ctx);
          },
          child: const Text('Ripristina Backup'),
        ),
      ],
    ),
  );
}
```

### 7.3 Strategie di Recovery

1. **Automatico (Fallback)**: Carica una lista vuota, l'app funziona
2. **Manuale (User-Driven)**: Dialog "Ripristina da Backup"
3. **Partial (Row-Level)**: Carica entry valide, scarta invalide

```dart
List<FinanceLedgerEntry> loadFinanceLedgerPartial() {
  try {
    final jsonString = _prefs.getString(StorageKey.financeLedger.key);
    if (jsonString == null || jsonString.isEmpty) return [];

    final data = jsonDecode(jsonString) as Map;
    final entries = <FinanceLedgerEntry>[];

    for (final item in (data['entries'] as List? ?? [])) {
      try {
        entries.add(FinanceLedgerEntry.fromJson(item as Map<String, dynamic>));
      } catch (e) {
        // Scarta questa entry, continua con la prossima
        debugPrint('⚠️ Skipped corrupted entry: $e');
      }
    }

    return entries;
  } catch (e) {
    return [];
  }
}
```

---

## 8. Tabella di Sintesi

| Aspetto | Implementazione | Note |
|---------|-----------------|------|
| **Serializzazione** | JSON + fromJson/toJson | Manual (no code gen) |
| **Persistenza** | shared_preferences | Leggero, no setup |
| **Versionamento** | Schema version field | Per future migration |
| **Export** | Full JSON dump | Per backup |
| **Import** | Parsing + validation | User-friendly errors |
| **Error Handling** | Graceful fallback | No crash, dati vuoti ok |
| **Max Storage** | ~10 MB (stima) | 1000 entry × 5KB/entry |
| **Encryption** | No (assenza sicurezza richiesta) | Future: flutter_secure_storage |

---

## 9. Performance Considerations

### 9.1 Tempi di Load

```
Lettura da shared_preferences: ~1-5 ms
Parsing JSON 1000 entry: ~10-20 ms
Totale boot: ~50-100 ms (imperceptibile)
```

### 9.2 Ottimizzazioni

- **Lazy Load**: Carica ledger solo quando DashboardScreen aperto
- **Partial Refresh**: Non ricaricare tutto, solo l'entry modificata
- **In-Memory Cache**: Riverpod mantiene in RAM, no ricaricamento

```dart
// NON fare (reload intero ledger ogni volta)
ref.watch(financeProvider);  // ← Okay, è cached

// Fare (invalidate specifico)
ref.invalidate(financeProvider);  // ← Solo se dati changed
```

### 9.3 Storage Budget

Per app leggera, aim:

```
Wishlist: ~100 entry × 200 bytes = 20 KB
Archive: ~100 entry × 200 bytes = 20 KB
Finance: ~500 entry × 150 bytes = 75 KB
Reviews: ~50 entry × 300 bytes = 15 KB
Cinema Notes: ~20 entry × 200 bytes = 4 KB
────────────────────────────────────────
TOTALE: ~134 KB (dati puri, NO immagini cache)
```

---

## 10. Conclusione

Lo schema JSON è **semplice, versionato, e resiliente**:

- Facile debug (apri il file JSON)
- Facile export (condividi con utente)
- Facile migration (versioning)
- Facile recovery (fallback graziosi)

Nel prossimo documento (DOC-05), descriveremo l'integrazione TMDB API in dettaglio.

---

**Documento redatto: Maggio 2026**  
**Prossimo:** DOC-05 — Guida Integrazione TMDB API
