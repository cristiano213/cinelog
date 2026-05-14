# CineLog — Schema Dati e Persistenza (Supabase / PostgreSQL)

**Tier 2 — Documento stabile.**
**Versione:** 2.0 (post-pivot social/backend)
**Aggiornato:** Maggio 2026
**Scope:** Schema completo del database: tabelle, RLS, trigger, funzioni RPC. SQL eseguibile.
**Audience:** Chiunque debba toccare il DB o capire dove "vivono" i dati.

> **Cambiamenti rispetto alla v1 (shared_preferences locale):**
> La persistenza passa da JSON locale a Postgres su Supabase. Tutti i dati utente sono ora user-scoped via FK + RLS. Cinema diventa entità canonica condivisa. Wishlist e Archive sono unificati in `user_movie_lists`.

> **AVVERTENZE LEGGI PRIMA DI ESEGUIRE QUALSIASI SQL**
> 1. Niente di quanto segue va eseguito senza prima averlo letto e capito.
> 2. Ogni script va eseguito in **transazione** (`BEGIN ... COMMIT`), così se qualcosa fallisce non resta lo schema a metà.
> 3. Lo schema verrà costruito **incrementalmente nei moduli** del corso, non tutto in una botta. Questo documento è il **riferimento finale**, non un ordine di esecuzione del Modulo 1.
> 4. Il DB live è la sorgente di verità. Se questo documento e il DB divergono, **fa fede il DB**: aggiornare il documento.

---

## Indice

1. [Principi guida](#principi)
2. [ER diagram](#er)
3. [Convenzioni](#convenzioni)
4. [Tabella `profiles`](#profiles)
5. [Tabella `cinemas`](#cinemas)
6. [Tabella `finance_entries`](#finance)
7. [Tabella `reviews`](#reviews)
8. [Tabella `user_movie_lists`](#lists)
9. [Tabella `cinema_notes`](#cinema-notes)
10. [Tabella `follows`](#follows)
11. [Funzioni e RPC](#funzioni)
12. [Trigger globali](#trigger-globali)
13. [Pattern bypass contesto sistema](#bypass)
14. [Ordine di creazione e migration iniziale](#ordine)
15. [Strategia di test RLS](#test-rls)
16. [Roadmap evoluzioni](#roadmap)

---

## <a id="principi"></a>1. Principi guida

### 1.1 Sicurezza
- **RLS sempre abilitata** su tutte le tabelle dati utente. Mai disabilitata, mai bypass dal client.
- **Policy separate per operazione** (`for select`, `for insert`, `for update`, `for delete`). **Mai `for all`** (troppo permissivo e poco leggibile).
- **`security definer` + `set search_path = public`** su tutte le funzioni che bypassano RLS.
- **`(SELECT auth.uid())`** nelle policy con subquery — non `auth.uid()` diretto in WHERE (migliore caching del piano query in Postgres).
- **Il frontend non protegge nulla**: ogni vincolo critico è anche nel DB (CHECK + RLS + trigger se serve).

### 1.2 Validazione
- **CHECK constraint** su ogni campo che ha un range sensato (prezzi, voti, lunghezze testo).
- Preferire CHECK rispetto a ENUM Postgres (più flessibile per evoluzioni dello schema).
- `DEFAULT ''` su campi text per evitare NULL silenziosi.

### 1.3 Audit e immutabilità
- `created_at` e `updated_at` (dove ha senso) su tutte le tabelle utente, automatici via trigger.
- Snapshot dei dati esterni: `movie_title` viene salvato alla creazione e non aggiornato. Trade-off: il titolo resta storicamente coerente anche se TMDB lo cambia o lo rimuove.
- Username immutabile via trigger di protezione (vedi `profiles`).

### 1.4 Naming
- `snake_case` minuscolo, tabelle al **plurale** (`finance_entries`, `cinemas`, `user_movie_lists`).
- PK sempre `id uuid default gen_random_uuid()` — **eccezione `profiles`**, che usa `user_id` come PK (FK su `auth.users.id`).
- FK nominate `{tabella_riferita_singolare}_id`: `user_id`, `cinema_id`, `movie_id`.
- Timestamp sempre `timestamptz`, mai `timestamp` (preserva il fuso, UTC nel DB).

---

## <a id="er"></a>2. ER diagram

```
                                ┌──────────────────┐
                                │   auth.users     │
                                │   (Supabase)     │
                                │   - id  (uuid)   │
                                │   - email        │
                                └────────┬─────────┘
                                         │ 1:1 (PK = FK)
                                         ▼
┌───────────────────────────────────────────────────────────────┐
│                          profiles                             │
│ - user_id (PK, FK auth.users.id, CASCADE)                     │
│ - username (UNIQUE, immutabile via trigger)                   │
│ - display_name, bio, avatar_url                               │
│ - default_review_visibility   ('private' | 'public')          │
│ - default_library_visibility  ('private' | 'public')          │
│ - default_cinema_notes_visibility ('private' | 'public')      │
│ - created_at, updated_at                                      │
└────┬────────────────────────────────┬─────────────────────────┘
     │ 1:N                            │ N:N (via follows)
     │                                │
     ├──► finance_entries  (sempre privato)
     │      user_id, movie_id, movie_title, cinema_id (FK)
     │      price_eur (CHECK), count (CHECK), watched_at
     │
     ├──► reviews
     │      user_id, movie_id, movie_title
     │      user_rating (CHECK 0-10), review_text (CHECK len)
     │      visibility, UNIQUE(user_id, movie_id)
     │
     ├──► user_movie_lists  (unifica wishlist + archive)
     │      user_id, movie_id, movie_title
     │      list_type (CHECK 'wishlist'|'archive')
     │      context (CHECK '|cinema|streaming|tv|dvd|other')
     │      visibility, UNIQUE(user_id, movie_id, list_type)
     │
     ├──► cinema_notes
     │      user_id, cinema_id (FK), note (CHECK len)
     │      visibility, UNIQUE(user_id, cinema_id)
     │
     └──► follows (relazione M:N tra profiles)
            follower_id (FK), followed_id (FK)
            PK (follower_id, followed_id), CHECK no self-follow

┌─────────────────────────────────────────────────────┐
│                       cinemas                       │
│ - id (PK uuid)                                      │
│ - place_id (UNIQUE — Google Places place_id)        │
│ - name, address                                     │
│ - latitude, longitude                               │
│ - last_refreshed_at, created_at                     │
│ - leggibile da tutti autenticati                    │
│ - INSERT solo via RPC upsert_cinema_from_place()    │
└─────────────────────────────────────────────────────┘
```

---

## <a id="convenzioni"></a>3. Convenzioni di nomenclatura e tipi

### 3.1 Tipi standard

| Caso d'uso | Tipo Postgres | Note |
|---|---|---|
| Chiave primaria | `uuid default gen_random_uuid()` | Nativo Postgres 13+ |
| Riferimento esterno TMDB | `text not null default ''` | È ID stringa di TMDB |
| Prezzo in € | `numeric(6,2)` | Max 9999.99, 2 decimali |
| Voto utente | `int` con CHECK 0-10 | |
| Testo libero corto | `text not null default ''` con CHECK length | |
| Testo libero lungo (review) | `text not null default ''` con CHECK length <= 2000 | |
| Coordinate GPS | `numeric(9,6)` | 6 decimali = precisione ~10cm |
| Timestamp | `timestamptz not null default now()` | UTC nel DB |
| Enum (visibility, list_type) | `text` + CHECK in lista valori | Più flessibile di ENUM nativo |
| Stato booleano | `boolean not null default false` | |

### 3.2 Default e null

- **Mai `not null` senza `default`** su text/numeric (eccetto PK e FK obbligatorie).
- Text: `default ''`.
- Numeric: `default 0` o valore sensato.
- Timestamp: `default now()`.
- Boolean: `default false` o `default true` esplicito.

### 3.3 Vincoli aggiuntivi

- Ogni tabella utente ha `user_id` come FK su `profiles(user_id)` con `on delete cascade` (se l'utente cancella l'account, i suoi dati spariscono).
- Vincoli `UNIQUE` espliciti dove ha senso semantico (es. un utente non può avere due review per lo stesso film).

---

## <a id="profiles"></a>4. Tabella `profiles`

Estensione di `auth.users` con i dati specifici di CineLog.

### 4.1 DDL

```sql
create table public.profiles (
  user_id     uuid primary key references auth.users(id) on delete cascade,

  username           text not null default '',
  display_name       text not null default '',
  bio                text not null default '',
  avatar_url         text not null default '',

  default_review_visibility       text not null default 'public',
  default_library_visibility      text not null default 'private',
  default_cinema_notes_visibility text not null default 'private',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint profiles_username_format
    check (
      username = '' or (
        char_length(username) between 3 and 20
        and username ~ '^[a-z0-9_]+$'
      )
    ),
  constraint profiles_display_name_length
    check (char_length(display_name) <= 50),
  constraint profiles_bio_length
    check (char_length(bio) <= 200),
  constraint profiles_review_visibility
    check (default_review_visibility in ('private', 'public')),
  constraint profiles_library_visibility
    check (default_library_visibility in ('private', 'public')),
  constraint profiles_cinema_notes_visibility
    check (default_cinema_notes_visibility in ('private', 'public'))
);

create unique index profiles_username_unique
  on public.profiles (lower(username))
  where username <> '';
```

**Note**:
- `username` ha CHECK su formato (3-20 char, lowercase alfanumerico + underscore). Unicità case-insensitive via indice unico funzionale.
- `username` può essere `''` solo nello stato transitorio post-signup pre-onboarding. Dopo l'onboarding deve essere non-vuoto e univoco.
- `default_*_visibility` riflette la decisione di `T2_VISIONE_FUNZIONALE` §2.5 e §4.4.

### 4.2 RLS

```sql
alter table public.profiles enable row level security;

-- Lettura: i profili sono pubblici (chiunque autenticato può vedere tutti i profili)
-- Necessario per il social: cercare utenti, vedere chi segui, ecc.
create policy profiles_select_all
  on public.profiles
  for select
  to authenticated
  using (true);

-- Insert: viene fatto solo via trigger su auth.users (vedi §11), non dal client
create policy profiles_insert_self
  on public.profiles
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

-- Update: utente modifica solo il proprio profilo
create policy profiles_update_self
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Delete: non permesso dal client. La cancellazione dell'account si fa
-- via Supabase Auth (delete user) che fa cascade sui profili.
-- Quindi NESSUNA policy di delete = blocco totale lato client.
```

### 4.3 Trigger

```sql
-- 1. Auto-create profile alla registrazione su auth.users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (user_id)
  values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. Username immutabile dopo essere stato impostato non-vuoto
create or replace function public.protect_username_immutable()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  -- Bypass per contesto sistema (SQL Editor, service_role, cron)
  if (select auth.uid()) is null then
    return new;
  end if;

  if old.username <> '' and old.username is distinct from new.username then
    raise exception 'Username is immutable once set';
  end if;

  return new;
end;
$$;

create trigger profiles_protect_username
  before update on public.profiles
  for each row execute function public.protect_username_immutable();

-- 3. Auto-update updated_at (trigger generico, vedi §12)
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
```

### 4.4 Note operative

- Lo stato `username = ''` è "post-signup, pre-onboarding". L'app deve forzare l'onboarding prima di permettere altre azioni.
- Lookup utenti via username: `WHERE lower(username) = lower($1)`.
- Per evitare username "admin", "root", "moderator" e simili, valutare blocklist nel Modulo 5 (non v1).

---

## <a id="cinemas"></a>5. Tabella `cinemas`

Entità canonica. Un cinema reale = una riga. Niente duplicati.

### 5.1 DDL

```sql
create table public.cinemas (
  id        uuid primary key default gen_random_uuid(),

  place_id  text not null,
  name      text not null default '',
  address   text not null default '',
  latitude  numeric(9,6) not null default 0,
  longitude numeric(9,6) not null default 0,

  last_refreshed_at timestamptz not null default now(),
  created_at        timestamptz not null default now(),

  constraint cinemas_place_id_not_empty check (place_id <> ''),
  constraint cinemas_name_length check (char_length(name) <= 150),
  constraint cinemas_latitude_range check (latitude between -90 and 90),
  constraint cinemas_longitude_range check (longitude between -180 and 180)
);

create unique index cinemas_place_id_unique on public.cinemas (place_id);
create index cinemas_location_idx on public.cinemas (latitude, longitude);
```

**Note**:
- `place_id` è l'identificativo Google Places. È la **chiave di unicità semantica**: due cinema con lo stesso `place_id` sono lo stesso cinema.
- `last_refreshed_at` permette di rifetchare i dati da Google se sono stagionati (es. > 6 mesi).
- L'indice su `(latitude, longitude)` aiuta query geografiche grezze (es. "cinema entro 5km") — per ricerche serie si valuta PostGIS in fase futura.

### 5.2 RLS

```sql
alter table public.cinemas enable row level security;

-- Lettura: tutti gli autenticati leggono i cinema (è un'entità globale)
create policy cinemas_select_all
  on public.cinemas
  for select
  to authenticated
  using (true);

-- Insert: nessuna policy. Inserimento solo via RPC upsert_cinema_from_place().
-- Update: nessuna policy. Aggiornamento solo via RPC (refresh dati Google).
-- Delete: nessuna policy. I cinema non si cancellano (potrebbero essere
--        ancora referenziati in finance_entries di anni fa).
```

### 5.3 Inserimento

Mai dal client direttamente. Solo via RPC `upsert_cinema_from_place(...)` — vedi §11.

---

## <a id="finance"></a>6. Tabella `finance_entries`

Ledger personale delle visioni al cinema. **Sempre privato per design**.

### 6.1 DDL

```sql
create table public.finance_entries (
  id         uuid primary key default gen_random_uuid(),

  user_id    uuid not null references public.profiles(user_id) on delete cascade,
  movie_id   text not null default '',
  movie_title text not null default '',
  cinema_id  uuid not null references public.cinemas(id) on delete restrict,

  price_eur  numeric(6,2) not null default 0,
  count      int not null default 1,
  watched_at timestamptz not null default now(),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint finance_movie_id_not_empty check (movie_id <> ''),
  constraint finance_movie_title_length check (char_length(movie_title) <= 250),
  constraint finance_price_range check (price_eur > 0 and price_eur < 100),
  constraint finance_count_range check (count between 1 and 20)
);

create index finance_user_id_idx       on public.finance_entries (user_id);
create index finance_user_movie_idx    on public.finance_entries (user_id, movie_id);
create index finance_user_cinema_idx   on public.finance_entries (user_id, cinema_id);
create index finance_user_watched_idx  on public.finance_entries (user_id, watched_at desc);
```

**Note**:
- `cinema_id` con `on delete restrict`: un cinema non si può cancellare se ha entries collegate. Coerente con la decisione "i cinema non si cancellano".
- `movie_title` snapshot — vedi nota in §1.3.
- CHECK rigoroso: `price > 0 AND < 100`. Niente prezzi zero o astronomici.
- `count` between 1 e 20: copre il caso "ho visto lo stesso film 3 volte nella stessa giornata di festival" ma blocca abusi (es. 9999).

### 6.2 RLS

```sql
alter table public.finance_entries enable row level security;

-- ⚠️ POLITICA NON NEGOZIABILE: solo l'utente proprietario può accedere
-- Mai espandere queste policy. Finanze SEMPRE private.

create policy finance_select_own
  on public.finance_entries
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy finance_insert_own
  on public.finance_entries
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy finance_update_own
  on public.finance_entries
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy finance_delete_own
  on public.finance_entries
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);
```

### 6.3 Trigger

```sql
create trigger finance_set_updated_at
  before update on public.finance_entries
  for each row execute function public.set_updated_at();
```

### 6.4 Note operative

- Per la media prezzi aggregata "tutti gli utenti su questo cinema" (vista §6.6 della visione funzionale), serve una **funzione `security definer`** che bypassi RLS e ritorni solo l'aggregato (mai le singole righe). Vedi §11.5.

---

## <a id="reviews"></a>7. Tabella `reviews`

Voto + testo dell'utente sui film. Una review per (utente, film).

### 7.1 DDL

```sql
create table public.reviews (
  id          uuid primary key default gen_random_uuid(),

  user_id     uuid not null references public.profiles(user_id) on delete cascade,
  movie_id    text not null default '',
  movie_title text not null default '',

  user_rating int  not null default 0,
  review_text text not null default '',
  visibility  text not null default 'public',

  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  constraint reviews_movie_id_not_empty check (movie_id <> ''),
  constraint reviews_movie_title_length check (char_length(movie_title) <= 250),
  constraint reviews_rating_range       check (user_rating between 0 and 10),
  constraint reviews_text_length        check (char_length(review_text) <= 2000),
  constraint reviews_visibility         check (visibility in ('private', 'public'))
);

create unique index reviews_user_movie_unique
  on public.reviews (user_id, movie_id);

create index reviews_movie_id_idx on public.reviews (movie_id);
create index reviews_public_idx
  on public.reviews (user_id)
  where visibility = 'public';
```

**Note**:
- `user_rating = 0` significa "nessun voto, solo testo". `1` = voto minimo reale.
- `UNIQUE(user_id, movie_id)` forza la regola "una review per coppia utente-film". Le scritture vanno fatte con `INSERT ... ON CONFLICT UPDATE` (upsert).
- Indice parziale su `visibility='public'` ottimizza query "tutte le review pubbliche di un utente".

### 7.2 RLS

```sql
alter table public.reviews enable row level security;

-- Lettura: utente vede le proprie + tutte le pubbliche altrui
create policy reviews_select_visible
  on public.reviews
  for select
  to authenticated
  using (
    (select auth.uid()) = user_id
    or visibility = 'public'
  );

create policy reviews_insert_own
  on public.reviews
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy reviews_update_own
  on public.reviews
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy reviews_delete_own
  on public.reviews
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);
```

### 7.3 Trigger

```sql
create trigger reviews_set_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();
```

---

## <a id="lists"></a>8. Tabella `user_movie_lists`

Unifica wishlist (film desiderati) e archive (film visti fuori dal cinema). Discriminatore: `list_type`.

### 8.1 DDL

```sql
create table public.user_movie_lists (
  id          uuid primary key default gen_random_uuid(),

  user_id     uuid not null references public.profiles(user_id) on delete cascade,
  movie_id    text not null default '',
  movie_title text not null default '',

  list_type   text not null default 'wishlist',
  context     text not null default '',
  visibility  text not null default 'private',

  added_at    timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  constraint lists_movie_id_not_empty check (movie_id <> ''),
  constraint lists_movie_title_length check (char_length(movie_title) <= 250),
  constraint lists_list_type          check (list_type in ('wishlist', 'archive')),
  constraint lists_context            check (
    context in ('', 'cinema', 'streaming', 'tv', 'dvd', 'other')
  ),
  constraint lists_context_only_for_archive check (
    list_type = 'archive' or context = ''
  ),
  constraint lists_visibility         check (visibility in ('private', 'public'))
);

create unique index lists_user_movie_type_unique
  on public.user_movie_lists (user_id, movie_id, list_type);

create index lists_user_type_idx
  on public.user_movie_lists (user_id, list_type);

create index lists_public_idx
  on public.user_movie_lists (user_id, list_type)
  where visibility = 'public';
```

**Note**:
- `UNIQUE(user_id, movie_id, list_type)`: lo stesso film può stare sia in wishlist sia in archive contemporaneamente (caso lecito: l'ho già visto in streaming, ma vorrei rivederlo al cinema).
- `context` valorizzato **solo per** `list_type = 'archive'`. Vincolo `lists_context_only_for_archive` lo forza.
- Stringa vuota `''` come "nessun context" è equivalente a NULL ma più semplice da queryare (no `IS NULL` ovunque).

### 8.2 RLS

```sql
alter table public.user_movie_lists enable row level security;

create policy lists_select_visible
  on public.user_movie_lists
  for select
  to authenticated
  using (
    (select auth.uid()) = user_id
    or visibility = 'public'
  );

create policy lists_insert_own
  on public.user_movie_lists
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy lists_update_own
  on public.user_movie_lists
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy lists_delete_own
  on public.user_movie_lists
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);
```

### 8.3 Trigger

```sql
create trigger lists_set_updated_at
  before update on public.user_movie_lists
  for each row execute function public.set_updated_at();
```

---

## <a id="cinema-notes"></a>9. Tabella `cinema_notes`

Appunti personali sui cinema visitati.

### 9.1 DDL

```sql
create table public.cinema_notes (
  id         uuid primary key default gen_random_uuid(),

  user_id    uuid not null references public.profiles(user_id) on delete cascade,
  cinema_id  uuid not null references public.cinemas(id) on delete cascade,

  note       text not null default '',
  visibility text not null default 'private',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint cnotes_note_length check (char_length(note) <= 1000),
  constraint cnotes_visibility  check (visibility in ('private', 'public'))
);

create unique index cnotes_user_cinema_unique
  on public.cinema_notes (user_id, cinema_id);
```

**Note**:
- Una nota per coppia (utente, cinema). Upsert su INSERT ON CONFLICT.
- A differenza di `finance_entries`, qui `cinema_id` ha `on delete cascade`: se mai (in futuro) dovessimo cancellare un cinema, le note personali sparirebbero. Le finance no, perché sono storia finanziaria intoccabile.

### 9.2 RLS

```sql
alter table public.cinema_notes enable row level security;

create policy cnotes_select_visible
  on public.cinema_notes
  for select
  to authenticated
  using (
    (select auth.uid()) = user_id
    or visibility = 'public'
  );

create policy cnotes_insert_own
  on public.cinema_notes
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy cnotes_update_own
  on public.cinema_notes
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy cnotes_delete_own
  on public.cinema_notes
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);
```

### 9.3 Trigger

```sql
create trigger cnotes_set_updated_at
  before update on public.cinema_notes
  for each row execute function public.set_updated_at();
```

---

## <a id="follows"></a>10. Tabella `follows`

Relazione M:N tra profili. `follower_id` segue `followed_id`.

### 10.1 DDL

```sql
create table public.follows (
  follower_id uuid not null references public.profiles(user_id) on delete cascade,
  followed_id uuid not null references public.profiles(user_id) on delete cascade,
  created_at  timestamptz not null default now(),

  primary key (follower_id, followed_id),
  constraint follows_no_self check (follower_id <> followed_id)
);

create index follows_followed_idx on public.follows (followed_id);
```

**Note**:
- PK composta = niente duplicati di una relazione (X segue Y → una sola riga, anche se tenta di ri-inserire).
- `CHECK no_self`: nessuno segue se stesso.
- Indice su `followed_id` per query "chi mi segue?" (l'indice composto della PK già copre "chi seguo io").

### 10.2 RLS

```sql
alter table public.follows enable row level security;

-- Lettura: tutti possono vedere chi segue chi (la rete sociale è pubblica)
create policy follows_select_all
  on public.follows
  for select
  to authenticated
  using (true);

-- Insert: solo se l'utente sta creando un follow proprio
create policy follows_insert_self
  on public.follows
  for insert
  to authenticated
  with check ((select auth.uid()) = follower_id);

-- Update: nessuno. I follow non si modificano (si cancellano e ricreano).

-- Delete: solo il follower può smettere di seguire
create policy follows_delete_self
  on public.follows
  for delete
  to authenticated
  using ((select auth.uid()) = follower_id);
```

---

## <a id="funzioni"></a>11. Funzioni e RPC

### 11.1 `set_updated_at()` — trigger helper

```sql
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
```

Usato come `BEFORE UPDATE` trigger su tutte le tabelle con `updated_at`.

### 11.2 `handle_new_user()` — crea profilo al signup

Già definito in §4.3.

### 11.3 `protect_username_immutable()` — blocca cambio username

Già definito in §4.3.

### 11.4 `upsert_cinema_from_place(...)` — unica via di inserimento cinemas

```sql
create or replace function public.upsert_cinema_from_place(
  p_place_id  text,
  p_name      text,
  p_address   text,
  p_latitude  numeric,
  p_longitude numeric
)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_cinema_id uuid;
begin
  -- Validazione minima lato funzione (oltre ai CHECK della tabella)
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;
  if p_place_id is null or p_place_id = '' then
    raise exception 'place_id cannot be empty';
  end if;

  insert into public.cinemas (place_id, name, address, latitude, longitude)
  values (p_place_id, coalesce(p_name, ''), coalesce(p_address, ''),
          coalesce(p_latitude, 0), coalesce(p_longitude, 0))
  on conflict (place_id) do update
    set name              = excluded.name,
        address           = excluded.address,
        latitude          = excluded.latitude,
        longitude         = excluded.longitude,
        last_refreshed_at = now()
  returning id into v_cinema_id;

  return v_cinema_id;
end;
$$;

revoke all on function public.upsert_cinema_from_place(text, text, text, numeric, numeric) from public;
grant execute on function public.upsert_cinema_from_place(text, text, text, numeric, numeric) to authenticated;
```

**Note**:
- Chiamata dal client quando l'utente seleziona un cinema dal CinemaPicker (Google Places).
- Ritorna l'`id` del cinema (esistente o appena creato) che il client userà come `cinema_id` nei suoi insert.
- `security definer` perché la RLS su `cinemas` non permette INSERT/UPDATE.
- Bypass auth.uid() null bloccato: questa funzione richiede sempre un utente autenticato (a differenza di `protect_*` che lascia passare il contesto sistema).

### 11.5 `get_cinema_avg_price(p_cinema_id uuid)` — media prezzi aggregata

Mostra la media prezzi su un cinema **senza esporre le singole righe finance**.

```sql
create or replace function public.get_cinema_avg_price(p_cinema_id uuid)
returns numeric
language plpgsql
security definer set search_path = public
stable
as $$
declare
  v_avg numeric;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;

  select round(avg(price_eur)::numeric, 2)
    into v_avg
  from public.finance_entries
  where cinema_id = p_cinema_id;

  return coalesce(v_avg, 0);
end;
$$;

revoke all on function public.get_cinema_avg_price(uuid) from public;
grant execute on function public.get_cinema_avg_price(uuid) to authenticated;
```

**Importante**: questa funzione aggrega ma **non espone** finance_entries individuali. Il consumer riceve solo il numero medio. Coerente con §8.2 della visione funzionale.

### 11.6 Altre RPC previste in futuro

Da non implementare ora, segnalate per memoria:
- `delete_my_account()` — flusso di cancellazione account con conferma
- `get_feed_for_user(p_limit int, p_offset int)` — feed delle attività pubbliche di chi seguo (Modulo 5)

---

## <a id="trigger-globali"></a>12. Trigger globali — riepilogo

| Trigger | Tabella | Quando | Funzione |
|---|---|---|---|
| `on_auth_user_created` | `auth.users` | AFTER INSERT | `handle_new_user()` |
| `profiles_protect_username` | `profiles` | BEFORE UPDATE | `protect_username_immutable()` |
| `profiles_set_updated_at` | `profiles` | BEFORE UPDATE | `set_updated_at()` |
| `finance_set_updated_at` | `finance_entries` | BEFORE UPDATE | `set_updated_at()` |
| `reviews_set_updated_at` | `reviews` | BEFORE UPDATE | `set_updated_at()` |
| `lists_set_updated_at` | `user_movie_lists` | BEFORE UPDATE | `set_updated_at()` |
| `cnotes_set_updated_at` | `cinema_notes` | BEFORE UPDATE | `set_updated_at()` |

---

## <a id="bypass"></a>13. Pattern bypass contesto sistema

Riferimento da T2_CONVENZIONI §4.4. Tutte le funzioni `protect_*` di trigger devono iniziare con:

```sql
-- Contesto sistema (SQL Editor, service_role, cron): lascia passare
if (select auth.uid()) is null then
  return new;
end if;
```

**Perché**: in SQL Editor dashboard, durante migration via service_role, in job cron, `auth.uid()` è NULL. Senza bypass non potresti correggere dati a mano in caso di emergenza o eseguire script di manutenzione.

**Sicurezza**: `auth.uid()` **non può essere forzato a NULL dal client**. Il JWT è validato server-side da Supabase. Solo SQL Editor (credenziali admin), service_role key (segreta), e job cron hanno `auth.uid() = NULL`. Quindi il bypass è sicuro.

**Eccezione**: le funzioni RPC chiamate dal client (es. `upsert_cinema_from_place`) **NON devono avere il bypass**, anzi devono *richiedere* l'autenticazione esplicitamente.

---

## <a id="ordine"></a>14. Ordine di creazione e migration iniziale

### 14.1 Ordine

Le dipendenze impongono questo ordine:

1. Funzioni helper generiche: `set_updated_at()`
2. `profiles` (e relativi trigger + RLS)
3. `cinemas` (e RLS)
4. Funzioni dipendenti da profiles+cinemas: `upsert_cinema_from_place()`, `get_cinema_avg_price()`
5. `finance_entries` (dipende da profiles + cinemas)
6. `reviews` (dipende da profiles)
7. `user_movie_lists` (dipende da profiles)
8. `cinema_notes` (dipende da profiles + cinemas)
9. `follows` (dipende da profiles × 2)
10. Trigger su `auth.users` per `handle_new_user` (per ultimo, dopo che `profiles` esiste)

### 14.2 Migration iniziale (template)

Lo script va eseguito in una sola transazione. **Da Modulo 1 in poi lo costruiremo passo per passo**, non in un colpo. Questo è il riferimento di "come dovrà essere alla fine".

```sql
begin;

-- 1. Helper generici
-- (set_updated_at goes here)

-- 2. profiles
-- (create table + indexes + RLS + triggers + handle_new_user)

-- 3. cinemas
-- (create table + indexes + RLS)

-- 4. RPC su cinemas
-- (upsert_cinema_from_place + grants)

-- 5. finance_entries
-- (create table + indexes + RLS + triggers)

-- 6. RPC su finance
-- (get_cinema_avg_price + grants)

-- 7. reviews
-- (create table + indexes + RLS + triggers)

-- 8. user_movie_lists
-- (create table + indexes + RLS + triggers)

-- 9. cinema_notes
-- (create table + indexes + RLS + triggers)

-- 10. follows
-- (create table + indexes + RLS)

commit;
```

### 14.3 Idempotenza (best practice)

Quando possibile, usare `IF NOT EXISTS` su tabelle e indici, `CREATE OR REPLACE` su funzioni. Rende lo script ri-eseguibile in caso di interruzione.

---

## <a id="test-rls"></a>15. Strategia di test RLS

Ogni regola RLS va testata in **entrambe le direzioni** (lezione T2_CONVENZIONI §5.6):

### 15.1 Test base — ramo positivo
- Utente A inserisce una propria finance_entry → passa.
- Utente A legge le proprie reviews → vede solo le sue + le pubbliche di altri.
- Utente A aggiorna una review propria → passa.
- Utente A cancella un follow proprio → passa.

### 15.2 Test base — ramo negativo
- Utente A prova a inserire finance_entry con `user_id = B` → fallisce.
- Utente A prova a leggere finance_entry di B → 0 righe (RLS filtra silente).
- Utente A prova a cancellare review di B → 0 righe affected.
- Utente A prova ad aggiornare cinema (non ha policy update) → 0 righe affected.

### 15.3 Test edge case
- Utente A cambia username (già non-vuoto) → exception del trigger.
- Inserimento finance con prezzo = 0 → CHECK constraint fail.
- Inserimento review con rating = 11 → CHECK constraint fail.
- Inserimento follow con `follower_id = followed_id` → CHECK constraint fail.
- Insert cinema diretto (non via RPC) → 0 righe (no policy).
- Chiamata `upsert_cinema_from_place` con `auth.uid() NULL` → exception.

### 15.4 Test contesto sistema
- SQL Editor (dashboard): tutte le operazioni passano (RLS bypassato da service_role/admin).
- Trigger `protect_username_immutable` lascia passare la modifica username via SQL Editor.

---

## <a id="roadmap"></a>16. Roadmap evoluzioni schema

Riferimento per il futuro. Non implementare ora.

### v2.1 — Visibility followers
Aggiungere `'followers'` ai CHECK di visibility. RLS aggiornata per:
```sql
visibility = 'public'
or (visibility = 'followers' and exists(
  select 1 from follows
  where follower_id = (select auth.uid()) and followed_id = user_id
))
```

### v2.2 — Notifiche
Tabella `notifications (id, user_id, type, payload jsonb, read_at, created_at)`. Generata da trigger su `follows` (nuovo follower) e `reviews` (review su film che hai in wishlist).

### v2.3 — Avatar storage
Bucket Supabase Storage `avatars/`. Path `{user_id}/avatar.jpg`. RLS sul bucket: read public, write self.

### v2.4 — Soft delete account
Aggiungere `deleted_at timestamptz` su `profiles`. RLS aggiornata per nascondere profili soft-deleted dalle ricerche.

### v2.5 — Backup export utente
RPC `export_my_data()` che ritorna JSON con tutte le righe dell'utente (GDPR-friendly).

---

## Riferimenti

- Visione funzionale: `T2_VISIONE_FUNZIONALE.md`
- Architettura tecnica: `T2_ARCHITETTURA.md`
- API esterne (TMDB, Places): `T2_API_ESTERNE.md`
- Convenzioni operative: `T2_CONVENZIONI.md`
