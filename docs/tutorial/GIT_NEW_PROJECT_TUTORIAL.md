# Git — Tutorial completo: da zero al primo push su GitHub

**Tier reference / tutorial.**
**Scope:** procedura passo-passo per inizializzare un progetto nuovo con Git, prepararlo per GitHub, fare il primo commit pulito e pushare. Pensato come "ricetta" da seguire dall'inizio alla fine ogni volta che parti un progetto da zero.
**Audience:** te stesso, fra un mese, su un nuovo progetto.

> Per la **reference dei singoli comandi** vedi `GIT_WORKFLOW_REFERENCE.md`. Qui invece c'è il **flusso completo**, con tutto in ordine.

---

## Pre-requisiti

Prima di partire:

- ✅ Git installato (`git --version` deve rispondere)
- ✅ Git configurato globalmente: `user.name`, `user.email`, `init.defaultBranch=main`, `core.autocrlf=true` (su Windows)
- ✅ Account GitHub esistente
- ✅ Privacy email GitHub attiva (no-reply email configurata come `user.email`)
- ✅ Progetto fisicamente esistente in una cartella (es. `flutter create myapp` già eseguito), **fuori da cartelle sincronizzate** tipo OneDrive, Dropbox, iCloud
- ✅ Terminale aperto **nella cartella del progetto**

Se uno di questi punti non è soddisfatto, fermati e completalo prima. Niente shortcuts.

---

## Fase 1 — Verifica pre-inizializzazione

### 1.1 Controlla dove sei

```powershell
pwd
```

Atteso: il path della cartella del progetto. Niente `Desktop`, niente `OneDrive`, niente `Documents`.

Esempio corretto: `C:\Users\<utente>\Dev\<nome-progetto>`

### 1.2 Controlla che Git non sia già inizializzato

```powershell
Test-Path .git
```

Atteso: `False`. Se ti dice `True`, il repo esiste già — controlla con `git log` se ha senso e procedi a `git status` invece di fare `git init`.

### 1.3 Elenca cosa c'è in cartella

```powershell
ls
ls -Force        # PowerShell: include file nascosti
```

Verifica visivamente: ci sono i file del tuo progetto? `package.json` / `pubspec.yaml` / `Cargo.toml` / `requirements.txt` / qualunque file specifico del linguaggio? Bene.

---

## Fase 2 — Inizializzazione Git locale

### 2.1 `git init`

```powershell
git init
```

Output atteso: `Initialized empty Git repository in <path>/.git/`.

Da questo momento esiste un repo locale.

### 2.2 Verifica stato iniziale

```powershell
git status
```

Atteso:
- `On branch main` (perché abbiamo configurato `init.defaultBranch=main` globalmente)
- `No commits yet`
- `Untracked files:` seguito da elenco di tutti i file del progetto

Tutti i file appaiono come "untracked": è normale, niente è ancora tracciato.

---

## Fase 3 — Setup `.gitignore`

**MAI saltare questa fase.** Un secret committato per errore vive per sempre nella history.

### 3.1 Se esiste già un `.gitignore`

Tipico se hai usato `flutter create`, `create-react-app`, `cargo new`: viene generato un `.gitignore` di default. **Controllalo e integralo**, non darlo per scontato.

```powershell
Get-Content .gitignore
```

Verifica che ci siano (in qualche forma):
- `.env`, `.env.local`, `.env.*.local` — **CRITICO**
- `node_modules/` / `.dart_tool/` / `target/` / `__pycache__/` (artifacts della tua tecnologia)
- `build/`, `dist/`, `out/` (output di build)
- File IDE: `.idea/`, `.vscode/` (a scelta, valuta caso per caso)
- File OS: `.DS_Store`, `Thumbs.db`
- Keystore / certificati: `*.keystore`, `*.jks`, `*.pem`, `*.key`
- File di config sensibili: `google-services.json`, `GoogleService-Info.plist` (Android/iOS)
- Coverage: `coverage/`, `.coverage`
- Backup editor: `*.bak`, `*~`, `*.swp`

### 3.2 Se NON esiste

Creane uno usando un template adatto al tuo stack. Per Flutter, già visto in CineLog. Per altri stack:

- Node.js / React: https://github.com/github/gitignore/blob/main/Node.gitignore
- Python: https://github.com/github/gitignore/blob/main/Python.gitignore
- Rust: https://github.com/github/gitignore/blob/main/Rust.gitignore
- Generale OS-only: https://github.com/github/gitignore/tree/main/Global

Aggiungi sempre **manualmente** le righe per `.env*` se mancano dai template.

### 3.3 Verifica che il `.gitignore` funzioni

Per ogni file/cartella critico, controlla che Git lo ignorerebbe se ci fosse:

```powershell
git check-ignore -v .env
git check-ignore -v node_modules
git check-ignore -v build
```

Atteso per ognuno: una riga tipo `.gitignore:NN:pattern    nome-file`. Se invece il comando esce senza output, il file NON è ignorato — fix il `.gitignore`.

---

## Fase 4 — Scan di sicurezza pre-commit

**Anche questa MAI saltare.** Cerca secret hardcoded prima del primo commit. Se ne trovi, sterilizza.

### 4.1 Scan manuale veloce

```powershell
Get-ChildItem -Recurse -File | Where-Object { 
  $_.FullName -notmatch "\\\.git\\|\\node_modules\\|\\\.dart_tool\\|\\build\\|\\target\\" 
} | Select-String -Pattern "api[_-]?key|secret|password|bearer|token" -CaseSensitive:$false
```

Adatta i path-da-saltare al tuo stack (`node_modules`, `.dart_tool`, `target`, `.venv`, ecc.).

### 4.2 Scan con AI agent (raccomandato)

Apri Claude Code (CLI o estensione VS Code) e incolla un prompt come quello usato in CineLog:

> *You are auditing this project for a pre-commit security scan. Scan all source files. Find: hardcoded API keys, tokens, JWTs, passwords, private URLs, PII. Report each finding with file:line, severity, snippet (REDACT real secret values), and reason. Do not modify any file. Read-only audit.*

Decide tu cosa fare di ogni finding, mai delegare la decisione all'agent.

### 4.3 Sterilizza i secret trovati

Per ogni secret hardcoded:

**Pattern fail-fast** (raccomandato): sostituisci il secret con un placeholder che lancia eccezione a runtime, così se qualcuno lo usa prima di completare la migrazione a `.env`, **crasha subito** con messaggio chiaro.

Dart esempio:
```dart
static String get apiKey => throw UnimplementedError(
  'apiKey is a placeholder. Migrate to EnvConfig.<keyName>.'
);
```

JavaScript esempio:
```javascript
get apiKey() {
  throw new Error('apiKey is a placeholder. Migrate to process.env.API_KEY.');
}
```

Python esempio:
```python
@property
def api_key(self):
    raise NotImplementedError('api_key is a placeholder. Migrate to env var.')
```

### 4.4 Crea `.env.example`

Template del `.env` da committare. Tutti i nomi delle variabili, valori placeholder.

```env
# Project environment template
#
# 1. Copy this file to `.env`
# 2. Fill in real values
# 3. NEVER commit `.env`

API_KEY_NAME=your_value_here
```

Lo committeremo. Il `.env` reale lo creeremo dopo, fuori dal repo.

### 4.5 Rotazione preventiva dei secret esposti

Se hai trovato secret hardcoded, **revocali sulle rispettive dashboard** e generane di nuovi. **Anche se il repo non è ancora pubblico.** I secret esposti per qualche minuto sono già da considerare compromessi (cache, backup, qualcuno che li vede sul tuo schermo).

I nuovi li metterai nel `.env` reale (mai committato).

---

## Fase 5 — Preparazione README e licenza

### 5.1 README.md

Crea o aggiorna `README.md` con almeno:
- Nome progetto, una riga di descrizione
- Stato (es. "Work in Progress — Module N")
- Prerequisiti (versioni SDK, account terzi)
- Setup (clona repo, copia `.env.example` in `.env`, installa dipendenze, run)
- Struttura cartelle (basica)
- Licenza (anche solo "TODO" inizialmente)

### 5.2 Licenza (opzionale ma raccomandata)

Per progetti pubblici è importante. Le scelte tipiche:
- **MIT**: permissiva, chiunque può usare/modificare anche commercialmente, deve solo dare credito
- **Apache 2.0**: come MIT + protezione brevetti, più legalese
- **GPL-3.0**: copyleft, chi usa il tuo codice deve aprire anche il suo
- **Proprietary / All Rights Reserved**: per ora privato, decisione futura

GitHub ti permette di scegliere una licenza al momento della creazione del repo o aggiungerla dopo con un file `LICENSE`. Senza licenza esplicita, di default il codice è "all rights reserved" anche se è pubblico (cioè la gente può leggerlo ma non riusarlo legalmente).

---

## Fase 6 — Primo commit baseline

### 6.1 Verifica stato pre-add

```powershell
git status
```

Lista degli untracked. Niente di sospetto?

### 6.2 Stage tutto

```powershell
git add .
```

Vedrai warning tipo "LF will be replaced by CRLF" su file di testo — normale, gestione fine riga di Git su Windows.

### 6.3 Verifica cosa è in staging

```powershell
git status
```

Sotto "Changes to be committed" devono apparire **tutti e solo** i file che vuoi committare. **Scorri l'elenco lentamente** e cerca:

- ❌ `.env` (NON deve esserci, è gitignored)
- ❌ `node_modules/` / `.dart_tool/` / `target/` (NON devono esserci)
- ❌ `build/`, `dist/` (NON devono esserci)
- ❌ File con credenziali (`*.keystore`, `*.jks`, ecc.)
- ❌ `.DS_Store`, `Thumbs.db`
- ✅ `.env.example` (DEVE esserci, è il template)
- ✅ `.gitignore`
- ✅ `README.md`
- ✅ Tutto il codice sorgente

Se vedi qualcosa di sbagliato nello staging, esci con:
```powershell
git restore --staged <file>
```

E aggiusta `.gitignore` se necessario.

### 6.4 Ultima sbirciata al contenuto staged

```powershell
git diff --cached
```

Mostra il diff completo. Premi spazio per scorrere, **`q`** per uscire dal pager.

Voglio vedere che il codice che sta per essere committato è effettivamente sterilizzato. Cerca con `/<parola>` (dentro `less`) frasi sospette: nome di servizi (`Stripe`, `AWS`, `Supabase`), parole chiave (`apiKey`, `secret`, `password`), pattern di token (sequenze lunghe alfanumeriche).

### 6.5 Commit

```powershell
git commit -m "chore: initial commit"
```

Per messaggi più ricchi (consigliato), usa multi-`-m`:

```powershell
git commit -m "chore: initial commit of <ProjectName>" -m "Baseline of <ProjectName>: <stack tecnologico>. Includes sterilized secrets (placeholder pattern), .env.example template, .gitignore hardened." -m "Pre-flight checklist completed: gitignore verified, secret scan passed, secrets rotated."
```

Output atteso:
```
[main (root-commit) <hash>] chore: initial commit of <ProjectName>
 <N> files changed, <M> insertions(+)
 create mode 100644 <file1>
 ...
```

Il `(root-commit)` indica "primo commit della storia". Lo vedrai solo questa volta.

### 6.6 Verifica history

```powershell
git log --oneline
```

Una riga: il tuo primo commit. Hash + subject.

```powershell
git status
```

`nothing to commit, working tree clean` — working dir allineato.

---

## Fase 7 — Creazione repo GitHub

### 7.1 Da GitHub web

Vai su https://github.com/new

Compila:
- **Repository name**: lo stesso nome della cartella locale (raccomandato)
- **Description**: una riga
- **Public / Private**: scelta tua. Pubblico è raccomandato per portfolio/educational; privato per business o se contiene IP/info riservate.
- **Initialize with README**: ⛔ **NON SPUNTARE** — abbiamo già il nostro
- **Add .gitignore**: ⛔ **NON SPUNTARE** — abbiamo già il nostro
- **Add license**: ⛔ **NON SPUNTARE** — la aggiungeremo via PR se serve

Click **"Create repository"**.

GitHub mostra una pagina "Quick setup". **Non chiuderla**: ti serve l'URL del repo (tipo `https://github.com/<user>/<repo>.git`).

### 7.2 Collega repo locale al remoto

Nel terminale:

```powershell
git remote add origin https://github.com/<tuo-user>/<repo>.git
```

Sostituisci `<tuo-user>` e `<repo>` con i valori reali.

Verifica:

```powershell
git remote -v
```

Atteso: due righe identiche, una per `(fetch)` e una per `(push)`.

### 7.3 Conferma il nome del branch

```powershell
git branch -M main
```

Se eri già su `main` è un no-op. Garanzia.

---

## Fase 8 — Primo push

### 8.1 Push con tracking

```powershell
git push -u origin main
```

Il `-u` (`--set-upstream`) collega il tuo `main` locale al `main` remoto. Da quel momento basta `git push` o `git pull` senza specificare nient'altro.

### 8.2 Autenticazione

La **prima volta** che pushi su GitHub da una macchina nuova:

- **Windows + Git Credential Manager**: si apre una finestra "Sign in to GitHub", logghi nel browser, autorizzi il device. Token salvato in Windows Credential Vault. Mai più chiesto.
- **Linux/Mac**: idem, ma il prompt apre il browser direttamente.
- **CI/CD**: usi Personal Access Token come password, oppure SSH key.

Se hai 2FA attiva (e dovresti), accetti la notifica sul telefono.

### 8.3 Output atteso

```
Enumerating objects: ..., done.
Counting objects: 100% (...), done.
Compressing objects: 100% (...), done.
Writing objects: 100% (...), <size> KiB | <speed>, done.
Total ... (delta ...), reused ...
To https://github.com/<user>/<repo>.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

Quel "set up to track" è la conferma del tracking.

### 8.4 Verifica finale

```powershell
git status
git log --oneline
```

Atteso:
- `Your branch is up to date with 'origin/main'.`
- Nel log, il tuo commit ha sia `HEAD -> main` che `origin/main` come riferimenti.

Apri il browser su https://github.com/<user>/<repo> — vedi i tuoi file. README renderizzato in basso. Primo push fatto.

---

## Fase 9 — Workflow di sviluppo (da qui in avanti)

A questo punto puoi iniziare il vero lavoro. Pattern raccomandato:

### 9.1 Crea un branch per ogni modulo / feature

```powershell
git checkout -b feature/<nome-feature>
# oppure per moduli:
git checkout -b module-N-<keyword>
```

### 9.2 Loop di sviluppo

1. Modifichi file in editor
2. `git status` per vedere cosa è cambiato
3. `git diff` per ispezionare modifiche specifiche
4. `git add <file>` o `git add .`
5. `git commit -m "tipo: descrizione"` (Conventional Commits, inglese, imperativo)
6. Ripeti dal punto 1 finché il modulo non è completo
7. `git push -u origin <branch>` per pushare il branch
8. Dalla web UI di GitHub apri Pull Request `<branch> → main`
9. **Auto-review del diff** — leggi tutto come se fosse di un altro
10. Merge se ok
11. Localmente: `git checkout main && git pull && git branch -d <branch>`

### 9.3 Tag a fine modulo

```powershell
git tag -a v<X.Y>-<keyword> -m "Module <X.Y>: <description>"
git push --tags
```

Esempio: `git tag -a v0.A-cleanup -m "Module 0.A: env secrets and cleanup"`.

I tag sono "bookmark" della storia. Puoi tornare allo stato di fine modulo con `git checkout v0.A-cleanup`.

---

## Checklist riassuntiva (da seguire ogni nuovo progetto)

- [ ] Progetto in cartella fuori da OneDrive/Dropbox/iCloud
- [ ] Pre-requisiti Git globali verificati
- [ ] `pwd` corretto, `Test-Path .git` = False
- [ ] `git init`
- [ ] `.gitignore` esistente o creato — verificato che `.env` sia ignorato (`git check-ignore -v .env`)
- [ ] Scan secret eseguita (manuale o AI agent)
- [ ] Secret hardcoded sterilizzati con pattern fail-fast
- [ ] Secret esposti revocati sulle dashboard
- [ ] `.env.example` committato come template
- [ ] `README.md` minimo presente
- [ ] `git add .`
- [ ] `git status` verificato: niente `.env`, `node_modules/`, `build/`, ecc. in staging; `.env.example` presente
- [ ] `git diff --cached` ispezionato per sbirciata finale
- [ ] `git commit` con Conventional Commit message in inglese
- [ ] Repo GitHub creato (no README/license/gitignore preimpostati)
- [ ] `git remote add origin <url>`
- [ ] `git branch -M main`
- [ ] `git push -u origin main`
- [ ] Verifica visiva del repo su github.com

---

## Errori comuni da evitare

| Errore | Conseguenza | Come si evita |
|---|---|---|
| `git add .` senza prima `git status` | Committi file inattesi | Sempre `status` prima di `add`, sempre `status` dopo `add` |
| Committare `.env` per errore | Secret leak permanente | `.gitignore` SEMPRE prima del primo commit |
| API key hardcoded "tanto è demo" | Secret leak permanente | Sterilizzazione + `.env` SEMPRE dal primo giorno |
| Inizializzare il repo dentro OneDrive | Conflitti sync, build lente | Cartelle progetto fuori da cloud sync |
| Email reale in `user.email` su repo pubblico | Spam, scraping | No-reply GitHub `<id>+<user>@users.noreply.github.com` |
| Spuntare "Initialize with README" su GitHub | Conflict al primo push | NON spuntare nulla quando crei repo per progetto pre-esistente |
| Committare con messaggi tipo "asd" o "fix" | History illeggibile | Conventional Commits, sempre, anche da solo |
| `git push --force` su `main` | Riscrive storia condivisa | MAI `--force` su main. Solo su branch tuoi, mai pushati a colleghi |
| `rm -rf .git` per "ricominciare" | Perdi tutta la history | Mai. Se serve resettare, `git reset --hard <hash>` o branch nuovo |

---

## Quando le cose vanno storte

Vedi `GIT_WORKFLOW_REFERENCE.md §5 (Annullare cose)` e `§9 (Emergenze comuni)`.

---

## Riferimenti

- Reference comandi: `GIT_WORKFLOW_REFERENCE.md`
- Shell + comandi base: `SHELL_COMMANDS_REFERENCE.md`
- Convenzioni progetto: `T2_CONVENZIONI.md`
- GitHub docs: https://docs.github.com