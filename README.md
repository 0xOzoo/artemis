# Artemis — Claude Code dans Telegram

Artemis fait tourner une session **Claude Code** en permanence sur ta machine Linux (Raspberry Pi, Orange Pi, serveur, PC) et te la rend joignable depuis **Telegram**. Tu lui écris, il répond, il lit tes photos et documents, et il garde sa mémoire dans un **coffre Obsidian** (un dossier de notes Markdown).

- Session Claude Code dans `tmux`, relancée par un service **systemd utilisateur** (survit aux plantages et aux redémarrages).
- Plugin officiel `telegram@claude-plugins-official` : appairage, liste blanche, boutons pour les demandes de permission. Complété par un patch (`patch-telegram.sh`) : commandes `/clear`, `/usage`, `/opus`, `/sonnet` et, en option, lecture des vocaux.
- Suivi de colis par numéro, avec alerte Telegram facultative (clé Ship24 gratuite).
- Plugin local `plugin/` : les skills d'Artemis (`cerveau`, `cerveau-ecrire`, `courses`, `suivi-colis`), chargées **seulement** par Artemis.
- MCP `obsidian` branché sur ton coffre, livré vide avec ses règles (`INDEX.md`, `CLAUDE.md`) et des modules facultatifs.

## Prérequis

- Linux avec systemd (Debian, Ubuntu, Armbian, Raspberry Pi OS…), ARM64 ou x86_64, accès `sudo`.
- Un **abonnement Claude** (Pro ou Max) : Artemis utilise ton compte Claude, pas une clé API.
- Un compte **Telegram**.

`install.sh` installe le reste s'il manque, **en demandant avant chaque installation** (`--yes` pour tout accepter d'avance) :
- `tmux`, `curl`, `unzip`, `patch`, `python3` par `apt` (seule étape avec `sudo`) ;
- Node 22 (par fnm, dans `~/.local/share/fnm`), `bun` (dans `~/.bun`) et Claude Code (dans `~/.local/bin`) : dans ton dossier, **sans sudo**.

## Installation (moins de 10 minutes)

### 1. Créer le bot Telegram (2 min)
1. Dans Telegram, ouvre **@BotFather**, envoie `/newbot`.
2. Donne un nom (ex. « Artemis ») puis un identifiant finissant par `bot` (ex. `artemis_de_paul_bot`).
3. BotFather renvoie un **jeton** de la forme `123456789:AAH...`. Garde-le pour toi : quiconque l'a contrôle le bot.

### 2. Récupérer le dépôt
```bash
git clone <url-du-depot> ~/artemis
cd ~/artemis
```

### 3. Connecter Claude Code à ton compte (2 min)
Si `claude` n'est pas encore installé : `curl -fsSL https://claude.ai/install.sh | bash`, puis ouvre un nouveau terminal.
```bash
cd ~ && claude
```
Choisis le thème, connecte-toi avec ton compte Claude, **accepte de faire confiance au dossier** (Artemis tourne dans `~`), puis `/exit`.

### 4. Configurer
```bash
cp .env.example .env
nano .env          # colle le jeton dans TELEGRAM_BOT_TOKEN=
```
Les autres variables (modèle, effort, emplacement du coffre, nom de la session tmux) ont des valeurs par défaut raisonnables.

### 5. Installer
```bash
./install.sh               # coffre de base seulement, une question avant chaque dépendance
./install.sh --starter     # + les modules du starter (cuisine)
./install.sh --voice       # + lecture des vocaux (voir plus bas, lourd)
./install.sh --yes         # sans questions (combinable avec les autres options)
```
Le script est **idempotent** : relance-le autant de fois que tu veux, il ne réinstalle que ce qui manque et **n'écrase jamais** une note existante du coffre.

### 6. Appairer ton compte Telegram (1 min)
1. Écris n'importe quoi à ton bot : il répond par un **code**.
2. Sur la machine :
   ```bash
   tmux attach -t artemis
   ```
   tape `/telegram:access pair <code>`, puis `/telegram:access policy allowlist` (plus personne d'autre ne peut s'appairer), et détache-toi avec **Ctrl-b** puis **d** (ne fais pas Ctrl-c : ça couperait la session).
3. Écris à ton bot : Artemis répond.

## Le coffre Obsidian (second cerveau)

Par défaut `~/cerveau` (`VAULT_DIR` dans `.env`). Ouvre-le dans Obsidian avec *Ouvrir un dossier comme coffre* si tu veux le lire ou l'éditer à la main (facultatif : Artemis y accède seul, par le MCP).

- `INDEX.md` : le seul fichier qu'Artemis lit d'office ; une ligne par note, qui dit **quand** l'ouvrir.
- `CLAUDE.md` : les règles de lecture/écriture (format des notes, en-tête, « une note = une ligne dans l'INDEX »).
- `lecons/`, `workflow/erreurs-et-correctifs.md` : vides, Artemis les remplit quand tu le corriges ou qu'un problème lui a coûté cher.

### Modules du starter (`vault-starter/`)
Un module = un dossier, à garder ou non :

| Module | Notes copiées | Skill qui s'en sert |
|---|---|---|
| `cuisine` | `cuisine/profil-et-stock.md`, `recettes.md`, `menus-et-courses.md` | `courses` : menus, recettes, liste de courses calculée sur le stock |

Les notes sont **vides** : les seules lignes remplies sont marquées `(exemple fictif)` pour montrer le format ; efface-les ou laisse Artemis le faire. Tu peux aussi simplement lui dire « je n'aime pas le poisson », « j'ai 1 kg de riz » : il met les notes à jour.

- **Charger un module plus tard** : `./install.sh --starter=cuisine` (copie le dossier et ajoute sa rubrique à `INDEX.md`).
- **Retirer un module** : supprime son dossier dans le coffre et sa rubrique dans `INDEX.md`. Pour qu'Artemis n'en parle plus, supprime aussi la skill dans `plugin/skills/`.
- **Créer ton module** : un dossier `vault-starter/<nom>/` avec tes notes et un `_index.md` (sa rubrique `## <Nom>` pour l'INDEX) ; éventuellement une skill `plugin/skills/<nom>/SKILL.md`.

## Suivi de colis

Envoie un numéro de suivi à Artemis : il détecte le transporteur (Colis Privé, Colissimo/La Poste, Chronopost, UPS, DPD, Mondial Relay) et répond par le statut et les dernières étapes. Dis « surveille-le » : il l'ajoute à la liste (`colis/colis.json`, hors dépôt git).

- **Colis Privé** est lu directement, sans clé. **Les autres transporteurs** passent par l'API **Ship24** : crée un compte gratuit sur <https://www.ship24.com>, récupère ta clé API dans son tableau de bord (rubrique développeurs / API), et colle la clé dans `.env` : `SHIP24_API_KEY=...`. L'offre gratuite couvre quelques colis par mois.
- **Alerte automatique** : si `SHIP24_API_KEY` est remplie, `./install.sh` installe un timer systemd utilisateur (`artemis-colis.timer`) qui vérifie les colis surveillés toutes les 30 min, envoie sur Telegram chaque changement de statut et la livraison, puis oublie le colis livré. Clé vidée puis `./install.sh` : le timer est retiré. Destinataire : `TELEGRAM_CHAT_ID` dans `.env`, sinon le premier compte appairé.
- À la main : `cd colis && python3 suivi_colis.py <numéro>`, `python3 colis.py add <numéro> [nom] | rm <numéro> | list | check`. Journal de l'alerte : `journalctl --user -u artemis-colis`.

## Commandes Telegram ajoutées

Le plugin telegram officiel ne sait pas piloter la session. `patch-telegram.sh` lui ajoute :

| Commande | Effet |
|---|---|
| `/clear` | vide le contexte de la session et efface les messages du chat depuis le dernier `/clear` (Telegram refuse au-delà de 48 h) |
| `/usage` | renvoie l'écran de consommation et de limites de Claude Code |
| `/opus`, `/sonnet` | bascule la session sur ce modèle (la conversation est gardée) |

`install.sh` l'applique. **Une mise à jour du plugin telegram écrase le patch** : relance alors
```bash
./patch-telegram.sh && systemctl --user restart artemis
```
Le script est idempotent, sauvegarde l'original (`server.ts.orig` à côté) et, si le plugin a trop changé (patch écrit pour la version 0.0.7), s'arrête **sans rien modifier** en le disant : le bot marche alors sans ces commandes, le temps d'adapter `telegram-patch/telegram-commands.patch`.

## Vocaux et vidéos (facultatif)

Claude ne lit que le texte, les images et les documents. Avec `./install.sh --voice`, les vocaux et vidéos reçus sont transcrits par **Whisper** (`faster-whisper`, sur le processeur) et les vidéos résumées en une planche de 6 images (`voice/media.py`).

- Lourd : `ffmpeg` et `python3-venv` par apt, ~1 Go dans `.venv/` et le modèle téléchargé au premier vocal. La transcription prend du temps sur une petite carte ARM.
- Modèle : `WHISPER_MODEL` dans `.env` (`tiny`, `base`, `small` par défaut, `medium` : plus juste et plus lent).
- Sans `--voice`, Artemis répond simplement qu'il ne peut pas lire le vocal. Pour retirer : `rm -rf .venv`.
- Le patch du plugin (ci-dessus) est nécessaire.

## Personnaliser

- **Modèle / effort** : `ARTEMIS_MODEL`, `ARTEMIS_EFFORT` dans `.env`, puis `systemctl --user restart artemis`.
- **Consigne d'Artemis** : variable `PROMPT` dans `artemis.sh`.
- **Skills / agents** : `plugin/skills/<nom>/SKILL.md`, `plugin/agents/<nom>.md`. Chargés au prochain redémarrage.

Un redémarrage repart d'une conversation neuve (la précédente est perdue, le coffre reste).

## Commandes utiles

| Quoi | Commande |
|---|---|
| Voir la session | `tmux attach -t artemis` (sortir : Ctrl-b puis d) |
| Redémarrer | `systemctl --user restart artemis` |
| Arrêter / désactiver | `systemctl --user stop artemis` / `systemctl --user disable --now artemis` |
| État du service | `systemctl --user status artemis` |
| Qui a accès | dans la session : `/telegram:access` |
| Après une mise à jour du plugin telegram | `./patch-telegram.sh && systemctl --user restart artemis` |
| Alerte colis | `systemctl --user list-timers artemis-colis.timer`, `journalctl --user -u artemis-colis` |

## Dépannage

**Le bot ne répond pas.**
1. `systemctl --user status artemis` puis `tmux attach -t artemis` : la session doit afficher l'invite de Claude, pas un écran de connexion ou de confiance. Si elle demande de se connecter ou de faire confiance au dossier, fais-le là, puis détache-toi.
2. Le serveur Telegram doit être un enfant de la session : `pgrep -af 'telegram/'`. Rien ? Lance `claude mcp list` : si `bun` est introuvable, `ln -s ~/.bun/bin/bun ~/.local/bin/bun` puis redémarre.
3. Le serveur peut être resté marqué « à authentifier » après un échec : retire l'entrée `plugin:telegram:telegram` de `~/.claude/mcp-needs-auth-cache.json`, puis redémarre.

**Le bot répond dans un autre terminal / se tait quand j'ouvre `claude` ailleurs.** Telegram n'accepte qu'un lecteur par bot. Le plugin telegram doit rester **désactivé globalement** (l'installateur le fait) ; ne le réactive pas avec `/plugin`. Un seul programme par jeton : n'utilise pas le même bot ailleurs.

**Le MCP obsidian n'apparaît pas.** Il exige Node ≥ 22 *dans le PATH du service*. Relance `./install.sh` après avoir changé de Node : il réécrit le PATH de `~/.config/systemd/user/artemis.service`.

**Artemis s'arrête quand je me déconnecte.** `sudo loginctl enable-linger $USER`.

**Un vocal ou une vidéo n'est pas compris.** Sans `./install.sh --voice`, c'est normal. Avec : vérifie que le patch est en place (`./patch-telegram.sh` doit dire « Déjà patché ») et redémarre. Telegram refuse au bot les fichiers de plus de 20 Mo.

**`/clear`, `/usage` ou `/opus` ne répondent plus.** Le plugin telegram a été mis à jour : `./patch-telegram.sh && systemctl --user restart artemis`.

**Pas d'alerte colis.** `SHIP24_API_KEY` remplie et `./install.sh` relancé ? Puis `journalctl --user -u artemis-colis`. Une erreur réseau est seulement journalisée ; le colis est revérifié 30 min plus tard.

## Sécurité

- `.env` (jeton, clé Ship24) est en `chmod 600` et ignoré par git ; `artemis.sh` retire jeton et clé de l'environnement de Claude. Le jeton est aussi copié dans `~/.claude/channels/telegram/.env`. Ne committe ni l'un ni l'autre, ni `access.json`.
- Toute personne de la liste blanche pilote une session Claude Code **sur ta machine**, avec tes fichiers. N'y mets que toi. Les demandes de permission d'outils arrivent sur Telegram avec des boutons : lis-les avant d'accepter.
- Jeton compromis : `/revoke` auprès de @BotFather, colle le nouveau dans `.env`, relance `./install.sh` puis `systemctl --user restart artemis`.

## Tests

```bash
tests/test-install.sh    # installe dans un HOME jetable avec claude/systemd simulés, hors ligne
```

## Licence

MIT, voir `LICENSE`.
