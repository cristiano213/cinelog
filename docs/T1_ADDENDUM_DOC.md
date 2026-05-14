# CineLog — Addendum alla documentazione T1/T2 (review finale)

**Tier 1 — Vivo.**
**Versione:** 1.0 — Maggio 2026, fine sessione Modulo 0.2
**Scope:** Chiarimenti e integrazioni emersi dalla review finale dei documenti T1/T2 generati nella stessa sessione. Va letto **insieme** ai documenti principali, non li sostituisce.

> **Perché esiste questo file:** durante la generazione massiva dei documenti T1/T2 alcuni dettagli sono rimasti impliciti o non perfettamente coerenti tra documenti. Questo addendum li esplicita senza rigenerare i file principali. Alla prossima revisione consolidata della documentazione (probabilmente fine Modulo 1), il contenuto di questo addendum verrà inglobato nei file di destinazione e questo file potrà essere archiviato.

---

## 1. Chiarimenti sui sotto-moduli del Modulo 0

Il Modulo 0 è suddiviso in tre sotto-moduli. Per memoria storica:

| Sotto-modulo | Titolo | Stato |
|---|---|---|
| **0.1** | Analisi del codebase v1 | ✅ chiuso (sessione precedente) |
| **0.2** | Ricostruzione documentazione (T1/T2/T3) | ✅ chiuso (sessione corrente) |
| **0.A** | Sicurezza e setup `.env` | ⏸️ da iniziare (prossima sessione fresca) |
| **0.B** | Quality baseline (lint, debugPrint, fix bug sicuri) | ⏸️ da fare dopo 0.A |

> Il sotto-modulo 0.C "documentazione" del piano iniziale è di fatto il 0.2 attuale, è stato rinumerato per coerenza cronologica. Il piano iniziale citava 0.A→0.B→0.C; la numerazione finale è 0.1→0.2→0.A→0.B. Non c'è alcun 0.C residuo.

---

## 2. Decisione esplicita: livello "social" target

Nella discussione iniziale erano state proposte tre opzioni di scope per il modulo social futuro:

- **A**: solo multi-utente isolato (no social)
- **B**: social light con `follows` + visibility per riga
- **C**: social granulare con visibility "private | followers | public"

**Decisione presa**: lo schema dati **v1 prevede l'opzione A++**, cioè:
- Tutte le tabelle utente hanno `visibility` con CHECK `('private', 'public')`
- Nessuna tabella `follows` viene creata nel Modulo 1
- La tabella `follows` viene introdotta come parte del Modulo 5 social
- L'evoluzione verso valore `'followers'` nel CHECK di visibility è documentata in `T2_SCHEMA_DATI` §16.1 come "v2.1"

**Rationale**: schema future-compatibile senza costi oggi, evoluzione senza migration dolorose.

---

## 3. Regole d'oro non scritte (che assumiamo come default)

Queste sono "scontate per un professionista" e per questo non sempre esplicitate nei doc, ma per il corso vanno dette chiaramente:

### 3.1 Denaro: mai `float`/`double`, sempre `numeric`/`decimal`
- Lato DB Postgres: `numeric(P,S)` (nel nostro caso `numeric(6,2)`)
- Lato Dart: meglio usare un tipo dedicato (es. package `decimal`) per calcoli importanti
- Per CineLog: tolleriamo `double` lato Dart per semplicità (somme di 2 decimali con errore floating point trascurabile su totali < 10.000 €). Da rivedere se mai diventa contabilità seria.

### 3.2 Date e fusi orari
- Nel DB: sempre `timestamptz`, sempre **UTC**
- Lato Dart: convertire al fuso utente **solo in UI**, mai nel modello
- Mai memorizzare "data come stringa" — sempre come `DateTime` o `timestamptz`

### 3.3 ID
- UUID v4 (nativo Postgres `gen_random_uuid()`)
- Mai esporre ID autoincrement (`bigserial`) verso il client — leak di informazione su volumi e ordine

### 3.4 Stringhe vuote vs NULL
- Per CineLog: **`DEFAULT ''` su text**, mai NULL (ereditato da T2_CONVENZIONI BookShelf)
- Vantaggio: query più semplici (`WHERE field <> ''` invece di `WHERE field IS NOT NULL AND field <> ''`)
- Eccezione: campi opzionali "veri" che devono distinguere "non impostato" da "impostato a vuoto" — caso raro

---

## 4. Prerequisiti operativi mancanti nella roadmap

Aggiunte alla lista in `T1_STATO_PROGETTO.md` §6 "Blockers":

### Da preparare entro il Modulo 0.A
- ✅ Hai già un account TMDB (la key esposta nel codice ne è la prova)
- ⚠️ **Accesso al repository Git** del progetto: serve sapere dove vive il codice
  - GitHub? GitLab? Bitbucket?
  - Se non esiste ancora repo remoto: crearne uno prima di committare le modifiche del Modulo 0.A
  - Se esiste già: verificare che la API key TMDB non sia nello storico (e in caso revocarla/rigenerarla)

### Da preparare entro il Modulo 1
- ⚠️ **Account Supabase** (free tier sufficiente per sviluppo)
- ⚠️ **Progetto Supabase creato** + credenziali pronte (URL + anon key)

### Da preparare entro il Modulo 3
- ⚠️ **Account Google Cloud Platform** con carta di credito associata (richiesto per attivare Places API)
- ⚠️ **Budget alert configurato su GCP** (es. $5/mese) per evitare costi imprevisti
- ⚠️ **Places API (New) abilitata** sul progetto GCP
- ⚠️ **API key con restrizioni** (Android package name + iOS bundle ID, una volta che li avremo)

---

## 5. Convenzioni Git: dettagli aggiuntivi

Cose che il `T2_CONVENZIONI` §7 dà per scontate ma vanno scritte:

### 5.1 Repository
- Un repository per il progetto (non monorepo)
- Branch `main` sempre verde
- Niente push diretto su `main` durante lo sviluppo dei moduli — solo via PR (anche da soli)

### 5.2 Tag a fine modulo
A modulo completato + merge in `main`:
```bash
git tag -a v0.A-cleanup -m "Module 0.A: env secrets and cleanup"
git push --tags
```
Vantaggio: si può tornare allo stato "fine modulo X" velocemente.

### 5.3 `.gitignore` esteso (oltre lo standard)
Lo standard Flutter è già scritto in `T2_CONVENZIONI` §7.4. Aggiunte raccomandate non già presenti:
```
# Coverage
coverage/

# Local cache di test
.flutter-plugins-dependencies
test/.test_runner.dart

# Mac/iOS specifico (Pods locali se sviluppi su Mac)
ios/Pods/
ios/.symlinks/

# Build dotenv compilato (alcune config lo generano)
.dart_tool/dartpad/
```

### 5.4 Cosa fare quando si trova un secret committato per errore
- **Non basta rimuoverlo con un commit successivo**: resta nello storico
- Procedura: rigenerare il secret immediatamente lato provider (TMDB, Supabase, Google) + considerare il vecchio compromesso
- Pulizia storia git (`git filter-repo`, `BFG Repo Cleaner`) **solo se il repo non ha ancora collaboratori esterni e il rischio è significativo**. Per progetto personale, basta la rigenerazione.

---

## 6. README.md di progetto: chi lo mantiene

Il `README.md` alla radice del progetto (creato dal prompt master Claude Code) viene **mantenuto manualmente** quando cambiano:
- Prerequisiti (versioni Flutter/Dart, librerie pesanti)
- Setup (variabili `.env` nuove)
- Comandi di run/build/test

Non si rigenera automaticamente. Resta sotto controllo umano perché è la **prima cosa che vede chi apre il repo**.

---

## 7. Punti aperti minori da gestire al primo passaggio utile

Non sono problemi del codebase (quelli sono in `T1_PROBLEMI_APERTI`), sono cose della **documentazione** stessa:

| Punto | Quando sistemarlo |
|---|---|
| Definire la licenza del progetto (README ha TODO) | Modulo 0.A o 1, decisione utente |
| Aggiornare `T2_SCHEMA_DATI` quando la prima migration viene eseguita davvero (script reali eseguiti) | Modulo 1 |
| Aggiungere link a documentazione Supabase ufficiale in `T2_CONVENZIONI` §4 (utile per imparare) | Modulo 1 |
| Decidere se `T2_API_ESTERNE` deve essere `T2_API_ESTERNE.md` o `T2_INTEGRAZIONI.md` (nome più generale per future API) | Quando si aggiunge la 3a integrazione |

---

## 8. Cose da NON dimenticare nella prossima sessione

Promemoria specifico per il primo messaggio della chat successiva:

1. **Caricare nel Project Knowledge** di Claude.ai i 7 documenti finali + questo addendum (8 file totali)
2. **Caricare nel messaggio iniziale**:
   - `lib/main.dart`
   - `lib/core/constants.dart`
   - `pubspec.yaml`
   - Output di `cat .gitignore` (copia-incolla del contenuto)
3. **Eseguire prima del messaggio**:
   - `git log --all --full-history -p -- lib/core/constants.dart | grep -i "apiKey" | head -20` (e incollare l'output)
4. **Primo messaggio**: "Carico T2 + T1 + addendum + i 3 file di codice + output gitignore + output git log. Stiamo partendo dal Modulo 0.A. Procedi col primo step."

---

## Riferimenti

- Stato corrente: `T1_STATO_PROGETTO.md`
- Problemi codice: `T1_PROBLEMI_APERTI.md`
- Schema completo: `T2_SCHEMA_DATI.md`
- Architettura target: `T2_ARCHITETTURA.md`
- Convenzioni: `T2_CONVENZIONI.md`
- Visione funzionale: `T2_VISIONE_FUNZIONALE.md`
