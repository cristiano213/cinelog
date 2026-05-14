# Git Workflow Reference — CineLog

**Tier reference — File di consultazione perpetua.**
**Scope:** Git applicato a CineLog, dal `git init` al `git tag`. Convenzioni, comandi quotidiani, casi tipici. Da leggere a inizio modulo o quando un'operazione non è familiare.
**Audience:** te stesso fra 3 mesi.

> Per concetti generali (i 4 stati del codice, Conventional Commits, ecc.) c'è una sezione introduttiva qui sotto. Per la pratica vera, salta al §3.

---

## 1. Concetti chiave (rapidi)

### I 4 stati del codice

```
[Working directory] → [Staging area] → [Repo locale] → [Repo remoto]
        |                  |                |                 |
   editi i file       git add          git commit         git push
```

- **Working directory**: la cartella `cinelog/` sul disco.
- **Staging area** ("index"): zona di carico merci, contiene i file pronti per il prossimo commit.
- **Repo locale**: la cartella `.git/` nascosta, contiene tutta la storia.
- **Repo remoto**: `origin`, ospitato su https://github.com/cristiano213/cinelog

### Branch
Linea di sviluppo parallela. Tutti i commit appartengono a un branch.
- `main` = branch stabile, deve sempre buildare
- `module-N-nome` = branch di sviluppo per modulo (es. `module-0-cleanup`)

### HEAD
Puntatore al commit corrente del branch corrente. Quando fai `git commit`, HEAD avanza al nuovo commit.

### Conventional Commits
Convenzione per messaggi di commit. Da `T2_CONVENZIONI §7.2`.

```
<tipo>: <descrizione breve in inglese, presente imperativo>

feat:      nuova feature
fix:       bug fix
chore:     pulizia, setup, configurazione
docs:      solo documentazione
refactor:  refactor senza cambio comportamento
test:      aggiunta/modifica test
style:     formattazione, indentazione (no logic)
perf:      ottimizzazione performance
```

Regole:
- Subject ≤ 72 caratteri
- Inglese, imperativo presente (`add`, non `added` né `adding`)
- Niente punto finale
- Body opzionale separato da riga vuota dal subject
- Nessuna emoji nei messaggi

Esempi buoni:
```
feat: add login screen with email validation
fix: prevent ref.invalidate from clearing cinema notes
chore: secure env config and rotate TMDB key
docs: update T1 status after module 0.A baseline
refactor: extract auth state to dedicated provider
```

---

## 2. Setup una tantum (già fatto per CineLog)

```powershell
# Identità (mai cambiare senza pensare due volte)
git config --global user.name "cristiano213"
git config --global user.email "215478156+cristiano213@users.noreply.github.com"

# Branch principale = main, non master
git config --global init.defaultBranch main

# Fine riga Windows
git config --global core.autocrlf true

# Verifica
git config --list --global
```

> Quando GitHub aggiorna la sua no-reply email (es. cambi username), aggiorna anche `user.email` qui.

---

## 3. Workflow quotidiano

### 3.1 Iniziare a lavorare su un modulo

```powershell
# Sei su main, allineato col remoto
git status                              # deve dire "clean"
git pull                                # ricevi eventuali update remoti (se altri lavorano)

# Crei il branch del modulo
git checkout -b module-0-cleanup        # crea + entra nel branch
# oppure (Git moderno):
git switch -c module-0-cleanup
```

### 3.2 Loop di sviluppo

Durante una sessione di lavoro:

```powershell
# Modifichi file in VS Code...

git status                              # vedi cosa è cambiato (usa SEMPRE prima di add)

# Aggiungi al staging
git add <file>                          # un file specifico
git add lib/core/env_config.dart        # esempio
git add lib/                            # tutta la cartella
git add .                               # tutto quello che è cambiato

# Verifica cosa è in staging
git status
git diff --cached                       # vedi le righe esatte che committerai (premi `q` per uscire dal pager)

# Commit
git commit -m "feat: read TMDB key from .env via EnvConfig"

# Per messaggio multi-paragrafo, usa più `-m`:
git commit -m "feat: short subject" -m "Longer body explaining what and why." -m "Closes #1 (TMDB hardcoded)."

# Verifica
git log --oneline -5                    # ultimi 5 commit
```

### 3.3 Push del branch

```powershell
# Prima volta che pushi il branch (registra upstream)
git push -u origin module-0-cleanup

# Da quel momento basta
git push
```

### 3.4 Chiusura modulo (PR + merge + tag)

```powershell
# Allinea con main se main è avanzato (raro per progetti solo)
git checkout main
git pull
git checkout module-0-cleanup
git merge main                          # incorpora eventuali update di main

# Vai su https://github.com/cristiano213/cinelog
# → "Pull requests" → "New pull request"
# → base: main ← compare: module-0-cleanup
# → "Create pull request"
# → AUTO-REVIEW: leggi il diff completo come se fosse di un altro

# Quando ok: "Merge pull request" → "Confirm merge"

# Torna in locale e allinea
git checkout main
git pull                                # tira giù il merge appena fatto
git branch -d module-0-cleanup          # cancella branch locale (sicuro: è stato mergiato)

# Tag fine modulo
git tag -a v0.A-cleanup -m "Module 0.A: env secrets and cleanup complete"
git push --tags                         # invia il tag al remoto
```

---

## 4. Comandi di consultazione

### Vedere la storia
```powershell
git log                                 # storia completa (usa `q` per uscire)
git log --oneline                       # compatto, una riga per commit
git log --oneline --graph --all         # ASCII art di tutti i branch
git log -5                              # ultimi 5
git log --author="cristiano213"         # solo i tuoi
git log --since="2 weeks ago"           # ultimi 14 giorni
git log -- lib/core/constants.dart      # solo commit che toccano un file
```

### Vedere differenze
```powershell
git diff                                # working dir vs ultimo commit
git diff --cached                       # staging vs ultimo commit
git diff main..module-0-cleanup         # differenze tra due branch
git diff <hash1>..<hash2>               # differenze tra due commit
git diff HEAD~1 HEAD                    # differenza tra penultimo e ultimo commit
```

### Vedere chi ha modificato cosa (blame)
```powershell
git blame lib/core/constants.dart       # autore + commit per ogni riga
```

### Cercare nella storia
```powershell
git log --grep="api key"                # commit con "api key" nel messaggio
git log -S "TmdbConstants.apiKey"       # commit che hanno aggiunto/tolto questa stringa
```

---

## 5. Annullare cose

### Annullare modifiche non staged (working directory)
```powershell
git restore <file>                      # ripristina file dall'ultimo commit
git restore .                           # ripristina tutto (ATTENZIONE: perdi modifiche)
```

### Rimuovere file dallo staging (senza perdere modifiche)
```powershell
git restore --staged <file>             # toglie dal staging, modifiche restano in working dir
```

### Modificare l'ultimo commit (se NON ancora pushato)
```powershell
# Cambiare messaggio
git commit --amend -m "nuovo messaggio"

# Aggiungere file dimenticati
git add <file_dimenticato>
git commit --amend --no-edit            # mantiene il messaggio precedente
```

> **MAI** `--amend` su un commit già pushato. Riscrive la storia, e chi ha clonato deve riconciliare a forza.

### Tornare a un commit precedente
```powershell
# Visualizza il commit (solo lettura, "detached HEAD")
git checkout <hash>

# Torna al branch
git checkout main

# Resetta il branch all'indietro (DISTRUTTIVO se pushato)
git reset --hard <hash>                 # cancella tutti i commit dopo <hash>
git reset --soft <hash>                 # mantiene le modifiche nel working dir
```

### Revertire un commit (sicuro, anche se pushato)
```powershell
git revert <hash>                       # crea un NUOVO commit che annulla <hash>
```

Differenza chiave: `reset` riscrive la storia, `revert` aggiunge un commit "anti". Su branch pushati e condivisi, sempre `revert`.

---

## 6. Casi tipici di CineLog

### "Ho modificato `lib/main.dart` e voglio committare solo questo file"
```powershell
git status                              # vedi cosa è cambiato
git diff lib/main.dart                  # ispeziona il diff
git add lib/main.dart
git commit -m "fix: make main() async for dotenv.load"
git push
```

### "Ho lavorato su 3 file ma voglio committarli separatamente"
```powershell
git add lib/core/env_config.dart
git commit -m "feat: add EnvConfig with fail-fast getters"

git add lib/core/constants.dart
git commit -m "refactor: read TMDB key from EnvConfig"

git add lib/main.dart
git commit -m "fix: make main() async for dotenv.load"

git push
```
Commit atomici = storia leggibile.

### "Ho fatto modifiche sbagliate, voglio buttare via tutto"
```powershell
git status                              # vedi cosa hai modificato
git restore .                           # butta via tutto il working dir
# ATTENZIONE: irreversibile. Solo se sei sicuro.
```

### "Ho dimenticato di creare il branch, ho committato su main"
```powershell
git log --oneline -3                    # identifica gli hash dei commit "sbagliati"
git branch module-0-cleanup             # crea il branch puntando al tuo stato attuale
git reset --hard origin/main            # main torna allo stato del remoto
git checkout module-0-cleanup           # passi al nuovo branch con i tuoi commit
```
Funziona se NON hai ancora pushato su main.

### "Il `flutter run` mi ha generato file in `build/`, non li voglio in repo"
Non li hai mai visti, sono in `.gitignore`. Se mai per errore `git add` ne includesse qualcuno:
```powershell
git rm --cached build/                  # toglie da staging senza cancellare dal disco
git commit -m "chore: untrack build/ artifacts"
```

### "Mi serve recuperare un file cancellato 5 commit fa"
```powershell
git log --diff-filter=D --name-only     # mostra cancellazioni e in quali commit
git checkout <hash>^ -- path/to/file    # ripristina dal commit precedente alla cancellazione
```

### "Voglio vedere come era `lib/main.dart` al commit `309aae9`"
```powershell
git show 309aae9:lib/main.dart          # stampa il file a quel commit
```

---

## 7. Convenzioni CineLog specifiche

### Branch naming
- `module-0-cleanup`
- `module-1-supabase-auth`
- `module-2-finance-migration`
- `module-3-cinemas-places`
- ...

Sempre `module-N-keyword`.

### Commit messages (Conventional + inglese imperativo)

Esempi storici e prossimi futuri:
```
chore: baseline commit of CineLog v1 with sterilized TMDB key
docs: snapshot module 0.A pre-coding state
feat: load TMDB key from .env via EnvConfig
fix: make main() async for flutter_dotenv
chore: add flutter_dotenv dependency
test: verify EnvConfig throws on missing key
```

Mai:
- "Aggiunto login screen" (italiano, passato)
- "WIP" (no work-in-progress in main, finisci il pensiero)
- "fix" senza dettagli
- Commit messages con emoji

### Tag
- A fine modulo: `vX.Y-keyword`
- Esempi: `v0.A-cleanup`, `v0.B-quality`, `v1.0-supabase`, `v2.0-finance`

### PR auto-review
Anche se sei da solo, **apri PR e leggi il diff**:
1. Guarda il "Files changed" intero
2. Cerca: TODO/FIXME residui, console.log dimenticati, file di test che non avresti dovuto committare, secret in chiaro
3. Mergia solo se ti convince

---

## 8. Comandi che NON userai (ma è bene sapere che esistono)

| Comando | Cosa fa | Quando ti servirà |
|---|---|---|
| `git stash` | Salva temporaneamente modifiche per riprenderle dopo | Quando devi cambiare branch ma hai lavoro in corso |
| `git rebase` | Riscrive la storia di un branch | Per pulire commit prima di un merge — avanzato |
| `git cherry-pick` | Copia un singolo commit da un branch a un altro | Casi specifici di hotfix |
| `git reflog` | Mostra TUTTA la storia di HEAD, anche commit "persi" | Per recuperare dopo un reset distruttivo |
| `git bisect` | Trova il commit che ha introdotto un bug via ricerca binaria | Debug di regressioni difficili |
| `git submodule` | Includere un altro repo dentro il tuo | Mai per CineLog |
| `git filter-repo` | Riscrivere massicciamente la storia | Solo per emergenze (rimuovere secret leakati) |

Li impareremo se e quando serviranno.

---

## 9. Emergenze comuni

### "Ho pushato un secret per errore"
1. **Considera il secret compromesso**: rigeneralo subito sulla dashboard del provider
2. Rimuovi dal codice + commit + push
3. Per pulizia history serve `git filter-repo` o GitHub Support — chiedi prima

### "Ho fatto un casino, voglio tornare a com'era ieri"
```powershell
git reflog                              # vedi tutti i tuoi movimenti di HEAD
git reset --hard HEAD@{2}               # torna a 2 movimenti fa (modifica numero)
```

### "Git mi dice 'rejected' al push"
Il remoto ha commit che non hai in locale. Sequenza:
```powershell
git pull --rebase                       # tira giù e rimette i tuoi commit sopra
git push                                # riprova
```

### "Conflict di merge"
1. Git ti dice quali file hanno conflict
2. Apri il file: vedrai marker `<<<<<<<`, `=======`, `>>>>>>>`
3. Decidi cosa tenere, rimuovi i marker
4. `git add <file>` + `git commit` (il messaggio è già pre-compilato)

VS Code ha una three-way merge view che rende questo molto più facile.

---

## 10. Risorse di approfondimento

- Documentazione ufficiale: https://git-scm.com/doc
- Cheat sheet visuale: https://ndpsoftware.com/git-cheatsheet.html
- "Pro Git" libro gratis: https://git-scm.com/book/en/v2
- Tutorial interattivo: https://learngitbranching.js.org/

---

## 11. URL di CineLog

- Repo: https://github.com/cristiano213/cinelog
- Issues (future, da abilitare): https://github.com/cristiano213/cinelog/issues
- Releases (future, dopo i tag): https://github.com/cristiano213/cinelog/releases