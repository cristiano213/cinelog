# Shell Commands Reference — PowerShell + Git Bash

**Tier reference — File di consultazione perpetua.**
**Scope:** comandi di shell che useremo lavorando su CineLog (e in generale su qualsiasi progetto). Mix PowerShell (default su Windows) + Git Bash (shell Unix-like installata con Git for Windows).
**Convenzione:** se un comando funziona uguale in entrambe, non lo specifico. Se cambia, indico variante PS e variante Bash.

---

## Quando usare quale shell

| Tipo di lavoro | Shell consigliata | Perché |
|---|---|---|
| Comandi `git` | PowerShell o Git Bash, entrambe ok | Git installa la sua porta di Linux: funziona ovunque |
| Comandi `flutter`, `dart` | PowerShell | È quella di default di VS Code su Windows |
| Comandi Unix nativi (`grep`, `awk`, `find`, `chmod`) | Git Bash | PowerShell ha alias parziali che a volte falliscono |
| Script `.sh` | Git Bash | PowerShell non li esegue nativamente |
| Comandi cmdlet PowerShell (`Get-*`, `Set-*`) | PowerShell | Bash non li conosce |

**Apri Git Bash**: menu Start → "Git Bash". Oppure dentro VS Code, in alto a destra del terminale, freccia accanto al `+` → seleziona "Git Bash" come shell.

---

## Navigazione filesystem

### Stampare la cartella corrente
```powershell
pwd                          # PS e Bash, stessa sintassi
```

### Cambiare cartella
```powershell
cd C:\Users\serlo\Dev\cinelog    # path assoluto
cd lib\core                      # path relativo (entra in lib\core)
cd ..                            # sali di un livello
cd ~                             # vai alla home (Bash) — su PS è cd $HOME
cd -                             # torna alla cartella precedente
```

### Elenco file
```powershell
# Solo visibili
ls
dir                              # PS, equivalente a ls

# Includendo nascosti (file che iniziano con `.`)
ls -Force                        # PowerShell
ls -la                           # Git Bash

# Filtrare per pattern
ls *.dart                        # solo file .dart
ls -Recurse *.dart               # PS, ricorsivo
ls -R *.dart                     # Bash, ricorsivo
```

### Filtri avanzati PowerShell
```powershell
# File modificati nelle ultime 24h
Get-ChildItem | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }

# File più grandi di 1 MB
Get-ChildItem -Recurse | Where-Object { $_.Length -gt 1MB }

# Tutti i file nascosti in root
ls -Force | Where-Object { $_.Name -like ".*" }
```

---

## Manipolazione file

### Creare cartella
```powershell
mkdir lib/core/config            # PS e Bash
New-Item -ItemType Directory lib/core/config   # PS verboso
```

### Creare file vuoto
```powershell
New-Item -Path .env.example -ItemType File     # PowerShell
touch .env.example                              # Bash
```

> Su PowerShell `touch` non esiste nativamente. Workaround equivalente: `$null > .env.example` (crea file vuoto).

### Copiare
```powershell
Copy-Item source.txt destination.txt           # PS
cp source.txt destination.txt                  # Bash
```

### Spostare/rinominare
```powershell
Move-Item old.txt new.txt                      # PS
mv old.txt new.txt                             # Bash
```

### Cancellare (ATTENZIONE: niente cestino!)
```powershell
Remove-Item file.txt                           # PS
rm file.txt                                    # Bash

# Cancellare cartella ricorsivamente
Remove-Item -Recurse -Force folder/            # PS
rm -rf folder/                                 # Bash
```

> **`rm -rf` è il comando più pericoloso del mondo Unix.** Cancella ricorsivamente e forzatamente, senza chiedere conferma. Non esiste "annulla". Triplica i controlli prima di lanciarlo. Mai eseguire `rm -rf` con path generati da variabili senza prima fare un `echo` di prova.

### Leggere contenuto file
```powershell
Get-Content file.txt                           # PS
cat file.txt                                   # Bash, anche PS lo accetta come alias
```

### Leggere solo prime/ultime righe
```powershell
Get-Content file.txt -TotalCount 10            # PS, prime 10
Get-Content file.txt -Tail 10                  # PS, ultime 10
head -10 file.txt                              # Bash, prime 10
tail -10 file.txt                              # Bash, ultime 10
```

### Cercare testo dentro file
```powershell
# PowerShell
Select-String -Pattern "TODO" -Path lib/**/*.dart
Get-ChildItem -Path lib -Filter *.dart -Recurse | Select-String -Pattern "apiKey"

# Bash
grep -r "TODO" lib/
grep -ri "apikey" lib/                         # -i = case-insensitive
```

---

## Pager (come uscire da `less`, `more`, ecc.)

Quando un comando produce molto output, Git e altri tool usano un **pager** (`less` di default). Lo riconosci perché il prompt diventa `:` o vedi `END` in fondo allo schermo, e i tasti non sembrano funzionare normalmente.

### Tasti dentro `less`

| Tasto | Effetto |
|---|---|
| `q` | **ESCI** — quello che ti serve nel 95% dei casi |
| Spazio | pagina avanti |
| `b` | pagina indietro |
| Frecce | scroll riga per riga |
| `/parola` | cerca avanti |
| `n` | prossimo risultato di ricerca |
| `g` | inizio file |
| `G` | fine file |
| `h` | help |

**Ricorda solo `q`**. Tutto il resto è scoperta progressiva.

### Disabilitare il pager Git (opzionale)
```powershell
git config --global core.pager ""
```
Da quel momento `git diff`, `git log`, ecc. stampano tutto in linea senza pager. Adatto se preferisci scorrere col mouse e copiare output.

---

## Comandi Git essenziali (versione minima)

Per la versione completa vedi `GIT_WORKFLOW_REFERENCE.md`.

```powershell
git status                       # stato corrente
git add <file>                   # aggiungi file allo staging
git add .                        # aggiungi tutto
git commit -m "messaggio"        # commit
git log --oneline                # storia compatta
git diff                         # cosa è cambiato vs ultimo commit
git diff --cached                # cosa è in staging vs ultimo commit
git push                         # invia al remoto
git pull                         # ricevi dal remoto
```

---

## Flutter e Dart

```powershell
flutter --version                # versione SDK
flutter doctor                   # diagnostica setup
flutter pub get                  # scarica dipendenze
flutter pub add <pacchetto>      # aggiungi pacchetto + scarica
flutter pub remove <pacchetto>   # rimuovi pacchetto
flutter pub outdated             # mostra pacchetti con update disponibili
flutter clean                    # cancella build/, .dart_tool/ — utile se build si rompe
flutter analyze                  # esegue il linter
flutter test                     # esegue i test
flutter run                      # esegue l'app (chiede su quale device)
flutter run -d chrome            # esegue su Chrome (web)
flutter run -d windows           # esegue su Windows desktop
flutter build apk                # build release Android
flutter build ipa                # build release iOS (solo su macOS)
dart format lib/                 # formatta tutto il codice in lib/
```

### Diagnosticare un problema build

```powershell
flutter clean
flutter pub get
flutter run
```
Questa sequenza risolve l'80% dei problemi "non parte più, ieri funzionava". Mai sottovalutarla.

---

## Trucchi PowerShell utili

### Esecuzione di più comandi insieme
```powershell
git status; git log --oneline      # esegui in sequenza (anche se uno fallisce)
git pull && flutter pub get        # esegui il secondo SOLO se il primo va a buon fine
```

### Cronologia comandi
```powershell
# Frecce su/giù: scorri comandi precedenti
# F7: menu visuale degli ultimi comandi
# Ctrl+R: ricerca incrementale (PowerShell 7+)
Get-History                        # vedi cronologia
```

### Autocompletamento
```
Tab            # completa nome file/comando
Tab Tab        # mostra opzioni multiple (PS 7+)
```

### Variabili d'ambiente
```powershell
$env:PATH                          # vedi PATH corrente
$env:MY_VAR = "valore"             # imposta variabile (solo sessione corrente)
[Environment]::SetEnvironmentVariable("MY_VAR", "val", "User")  # permanente
```

### Pulire lo schermo
```powershell
cls                                # PS
clear                              # Bash (e anche PS, è alias)
Ctrl+L                             # scorciatoia universale
```

---

## Cose che fanno cose strane su Windows (PowerShell trap)

### `ls` con file aperti
A volte `ls` mostra `Length 0` per un file ancora in scrittura da un altro processo. Riesegui dopo qualche secondo.

### `.` come argomento di cmdlet PS
Su PowerShell `Get-ChildItem` di default mostra solo file visibili. Se vuoi vedere i file nascosti (con `.` davanti), devi passare `-Force`. Differenza notevole vs `ls -la` di Bash che li mostra subito.

### Stringa vs filename
```powershell
Get-Content .env.example           # OK
Get-Content '.env.example'         # OK (alternativa con apici)
```
Su PowerShell entrambe funzionano. Su Bash il `.` non è speciale, vanno entrambe.

### CRLF vs LF
File creati su Windows hanno `\r\n` come fine riga. File da Linux/Mac hanno `\n`. Git con `core.autocrlf=true` converte al volo. Se vedi righe "tutte attaccate" aprendo un file in Notepad → è un file LF aperto in un editor che non capisce LF. VS Code li gestisce bene, Notepad++ pure, Notepad classico no.

---

## Risorse di approfondimento

- PowerShell docs: https://learn.microsoft.com/powershell
- Bash cheatsheet: https://devhints.io/bash
- "Learn the shell" interattivo: https://linuxjourney.com/lesson/the-shell

---

## Glossario rapido

| Termine | Significato |
|---|---|
| **CLI** | Command-Line Interface — interagisci col PC scrivendo comandi |
| **GUI** | Graphical User Interface — interagisci col PC cliccando icone |
| **shell** | Programma che interpreta i comandi che digiti (PowerShell, Bash, Zsh, ecc.) |
| **terminale** | Finestra che ospita la shell |
| **prompt** | La scritta `PS C:\...>` o `$` che indica "qui aspetto un comando" |
| **stdout** | Standard output — flusso "normale" di output di un comando |
| **stderr** | Standard error — flusso separato per errori |
| **pipe** (`\|`) | Manda l'output di un comando come input del successivo |
| **redirect** (`>`, `>>`) | Manda l'output a un file (`>` sovrascrive, `>>` appende) |
| **flag** / **option** | Modificatori di un comando, es. `-Force`, `--recursive`, `-v` |
| **pager** | Programma che impagina output lunghi (`less`, `more`, ecc.) |