# Artemis

**Claude Code dans Telegram (et Discord en option).** Une session Claude Code tourne en permanence sur ta machine Linux (Raspberry Pi, serveur, PC) et tu lui écris depuis Telegram. Elle lit tes photos et documents, et garde sa mémoire dans un **coffre Obsidian** (des notes Markdown).

- Session dans `tmux`, relancée par un service **systemd utilisateur** (plantage, redémarrage)
- Plugin Telegram officiel (appairage, liste blanche) + commandes `/clear` `/usage` `/opus` `/sonnet`
- Suivi de colis avec alertes Telegram (clé Ship24 gratuite)
- Second cerveau Obsidian livré vide, avec modules facultatifs (cuisine…)
- Vocaux et vidéos en option (Whisper)

## Prérequis

- Linux avec systemd, ARM64 ou x86_64, `sudo`
- Un abonnement **Claude** (Pro ou Max), sans clé API
- Un compte **Telegram**

`install.sh` installe le reste en **demandant avant chaque étape** (`--yes` pour tout accepter) : `tmux curl unzip patch python3` via apt (seul usage de `sudo`), puis Node 22, bun et Claude Code dans ton dossier personnel.

## Installation (10 min)

**1. Créer le bot.** Dans Telegram, ouvre **@BotFather** → `/newbot` → nom, puis identifiant finissant par `bot`. Garde le **jeton** (`123456789:AAH...`) : qui l'a contrôle le bot.

**2. Récupérer Artemis.**
```bash
git clone https://github.com/0xOzoo/artemis ~/artemis && cd ~/artemis
```
Ou télécharge l'archive dans les [Releases](https://github.com/0xOzoo/artemis/releases).

**3. Connecter Claude.** `curl -fsSL https://claude.ai/install.sh | bash` si besoin, puis :
```bash
cd ~ && claude     # connexion, accepter le dossier, puis /exit
```

**4. Configurer.**
```bash
cp .env.example .env && nano .env     # TELEGRAM_BOT_TOKEN=<ton jeton>
```

**5. Installer.**
```bash
./install.sh --starter     # + modules du coffre ; ajoute --voice (vocaux) ou --yes (sans questions)
```
Idempotent : relançable à volonté, n'écrase jamais une note du coffre.

**6. Appairer ton compte.** Écris au bot : il répond par un code. Puis :
```bash
tmux attach -t artemis
```
Tape `/telegram:access pair <code>` puis `/telegram:access policy allowlist`. Détache-toi avec **Ctrl-b puis d** (pas Ctrl-c). Réécris au bot : Artemis répond.

## Le coffre Obsidian

Par défaut `~/cerveau` (`VAULT_DIR` dans `.env`). Ouvre-le dans Obsidian si tu veux le lire ; Artemis y accède seul.

- `INDEX.md` : une ligne par note, qui dit *quand* l'ouvrir
- `CLAUDE.md` : règles d'écriture (en-tête, une note = une ligne dans l'INDEX)
- `lecons/`, `workflow/` : remplis par Artemis quand tu le corriges

**Modules** (`vault-starter/`) : un module = un dossier à garder ou non.

| Module | Contenu | Skill associée |
|---|---|---|
| `cuisine` | profil et stock, recettes, menus et courses | `courses` |

Notes vides, sauf des exemples marqués `(exemple fictif)`. Dis simplement à Artemis « je n'aime pas le poisson » ou « il me reste 1 kg de riz » : il met les notes à jour.

- Charger un module : `./install.sh --starter=cuisine`
- Le retirer : supprime son dossier du coffre, sa ligne dans `INDEX.md` et sa skill dans `plugin/skills/`
- En créer un : `vault-starter/<nom>/` avec tes notes et un `_index.md`

## Suivi de colis

Envoie un numéro de suivi : Artemis détecte le transporteur (Colis Privé, Colissimo, Chronopost, UPS, DPD, Mondial Relay) et donne le statut. « Surveille-le » l'ajoute à la liste.

- **Colis Privé** : sans clé. **Les autres** : clé gratuite sur [ship24.com](https://www.ship24.com), à mettre dans `.env` (`SHIP24_API_KEY=`)
- Avec la clé, `./install.sh` active un timer (toutes les 30 min) qui t'alerte à chaque changement de statut. Destinataire : `TELEGRAM_CHAT_ID`, sinon le premier compte appairé
- Journal : `journalctl --user -u artemis-colis`

## Commandes Telegram

| Commande | Effet |
|---|---|
| `/clear` | vide le contexte et efface toute la conversation (messages de moins de 48 h : limite Telegram) |
| `/usage` | consommation et limites de Claude Code |
| `/opus`, `/sonnet` | change de modèle, conversation gardée |

Installées par `patch-telegram.sh` (écrit pour le plugin 0.0.7). **Une mise à jour du plugin l'écrase** : relance `./patch-telegram.sh && systemctl --user restart artemis`. Si le plugin a trop changé, le script s'arrête sans rien modifier et le bot marche sans ces commandes.

## Discord (option)

Artemis répond aussi en message privé à un bot Discord (plugin officiel `discord`), dans la même session que Telegram.

1. [Discord Developer Portal](https://discord.com/developers/applications) → **New Application** → **Bot** : active **Message Content Intent**, désactive **Public Bot**, puis **Reset Token** et copie le jeton.
2. **OAuth2 → URL Generator** : scope `bot`, permissions *View Channels, Send Messages, Read Message History, Attach Files, Add Reactions*. Ouvre l'URL et ajoute le bot à un serveur où tu es (Discord exige un serveur commun pour les MP).
3. Ton ID : Paramètres → Avancés → **Mode développeur**, puis clic droit sur ton nom → **Copier l'identifiant**.
4. Dans `.env` : `DISCORD_BOT_TOKEN=<jeton>` et `DISCORD_ALLOWED_USERS=<ton ID>` (plusieurs : séparés par des virgules ; **obligatoire**, l'installation refuse sans).
5. `./install.sh && systemctl --user restart artemis`, puis écris au bot en MP.

Pas d'appairage : la liste de `.env` est la seule source, recopiée dans `~/.claude/channels/discord/access.json` et figée au démarrage (`DISCORD_ACCESS_MODE=static`). Les autres comptes sont ignorés sans réponse. Ajouter ou retirer quelqu'un : modifie `.env`, relance `./install.sh` et redémarre. Retirer Discord : vide `DISCORD_BOT_TOKEN`, redémarre.

## Vocaux et vidéos (option)

`./install.sh --voice` transcrit les vocaux et vidéos avec Whisper. Lourd : ~1 Go, lent sur petite carte ARM. Modèle réglable avec `WHISPER_MODEL` (`tiny` à `medium`). Sans cette option, Artemis répond qu'il ne lit pas les vocaux. Retrait : `rm -rf .venv`.

## Personnaliser

- Modèle et effort : `ARTEMIS_MODEL`, `ARTEMIS_EFFORT` dans `.env`
- Consigne d'Artemis : variable `PROMPT` dans `artemis.sh`
- Skills et agents : `plugin/skills/<nom>/SKILL.md`, `plugin/agents/<nom>.md`
- Après un changement : `systemctl --user restart artemis` (repart d'une conversation neuve, le coffre reste)

## Commandes utiles

| Quoi | Commande |
|---|---|
| Voir la session | `tmux attach -t artemis` (sortir : Ctrl-b puis d) |
| Redémarrer / arrêter | `systemctl --user restart artemis` / `stop artemis` |
| État | `systemctl --user status artemis` |
| Qui a accès | `/telegram:access` dans la session |

## Dépannage

| Problème | Solution |
|---|---|
| Le bot ne répond pas | `tmux attach -t artemis` : la session doit afficher l'invite de Claude, pas un écran de connexion ou de confiance. Sinon règle-le là |
| Pas de serveur Telegram (`pgrep -af 'telegram/'` vide) | `claude mcp list` ; si `bun` est introuvable : `ln -s ~/.bun/bin/bun ~/.local/bin/bun` puis redémarre |
| Serveur « à authentifier » | retire `plugin:telegram:telegram` de `~/.claude/mcp-needs-auth-cache.json`, redémarre |
| Le bot se tait quand j'ouvre `claude` ailleurs | un seul lecteur par bot : garde le plugin telegram **désactivé globalement** et n'utilise pas le jeton ailleurs |
| MCP obsidian absent | il exige Node ≥ 22 dans le PATH du service : relance `./install.sh` |
| Artemis s'arrête à la déconnexion | `sudo loginctl enable-linger $USER` |
| `/clear` ou `/usage` ne répondent plus | `./patch-telegram.sh && systemctl --user restart artemis` |
| Vocal non compris | installe avec `--voice`, vérifie le patch ; limite Telegram : 20 Mo |
| Pas d'alerte colis | `SHIP24_API_KEY` remplie, `./install.sh` relancé, puis `journalctl --user -u artemis-colis` |

## Sécurité

- `.env` (jetons, clé Ship24) est en `chmod 600` et ignoré par git. Ne committe ni lui, ni `access.json`, ni `~/.claude/channels/{telegram,discord}/.env`
- Jeton Discord compromis : **Reset Token** dans le Developer Portal, nouveau jeton dans `.env`, `./install.sh` puis `systemctl --user restart artemis`
- Toute personne de la liste blanche pilote Claude Code **sur ta machine**, avec tes fichiers : n'y mets que toi. Lis les demandes de permission avant d'accepter
- Jeton compromis : `/revoke` chez @BotFather, nouveau jeton dans `.env`, `./install.sh` puis `systemctl --user restart artemis`

## Tests et licence

`tests/test-install.sh` : installation dans un HOME jetable, hors ligne, avec `claude` et systemd simulés. Licence MIT (`LICENSE`).
