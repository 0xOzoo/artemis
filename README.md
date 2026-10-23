<div align="center">

# 🏹 Artemis

**Ton Claude Code, dans ta poche. Il tourne chez toi, il t'écrit sur Telegram et Discord, et il se souvient de tout.**

*Un abonnement Claude · une machine Linux · 3 minutes.*

</div>

---

Tu envoies une photo de ticket de caisse, un vocal, un numéro de colis, une question de code. Une vraie session **Claude Code** tourne en permanence sur ta machine (Raspberry Pi, serveur, vieux PC), lit tes fichiers, agit, et te répond **là où tu es** : Telegram, Discord, ou les deux dans la même conversation.

## Pourquoi c'est différent

- 🧠 **Un second cerveau qui reste.** Ses souvenirs sont des notes Markdown dans un coffre **Obsidian** que tu peux ouvrir et corriger. Tu le corriges une fois, il ne refait pas l'erreur. Il ne charge que l'`INDEX.md` puis les notes utiles, donc il économise ton contexte.
- 💬 **Où tu veux.** Telegram et Discord dans **une seule session** : même mémoire, mêmes skills, mêmes agents.
- 🎯 **Sonnet au quotidien, Opus quand ça compte.** Les questions difficiles partent sur un sous-agent Opus, la réponse revient dans ta conversation. `/opus` et `/sonnet` pour forcer.
- 📦 **Skills et agents inclus.** Suivi de colis avec alertes, menus et courses depuis ton stock, vocaux et vidéos transcrits (Whisper). Ajoute les tiens en déposant un dossier.
- 🔒 **Chez toi, à toi.** Pas de serveur tiers : ton abonnement Claude, tes fichiers. Liste blanche figée au démarrage, jetons en `chmod 600`, rien d'envoyé ailleurs.
- 🛡️ **Indestructible.** Session `tmux` relancée par `systemd` : plantage, redémarrage, coupure, il revient.

## Installation : 3 commandes

**Avant** : un abonnement **Claude** (Pro ou Max, pas de clé API), Linux avec systemd, et un bot Telegram (`@BotFather` → `/newbot`, garde le jeton).

```bash
git clone https://github.com/0xOzoo/artemis ~/artemis && cd ~/artemis
curl -fsSL https://claude.ai/install.sh | bash && claude      # connexion, accepter le dossier, /exit
./setup.sh --starter
```

`setup.sh` fait le reste, en te posant 2 questions :

1. **Le jeton du bot** : il le vérifie auprès de Telegram.
2. **Un message à ton bot** : il lit ton identifiant dans ce message et t'autorise tout seul. Plus d'appairage, plus de code à recopier.

Ensuite il installe les dépendances (en **demandant avant chaque étape**, sans `sudo` sauf `apt`), branche le coffre Obsidian et lance le service. Écris à ton bot : Artemis répond.

> Relançable à volonté : `setup.sh` et `install.sh` sont idempotents et n'écrasent jamais une note du coffre.
> Options : `--yes` (tout accepter), `--voice` (vocaux et vidéos), `--starter=cuisine` (un module du coffre).

**Discord en plus ?** `setup.sh` te le propose : il vérifie le jeton **et** que « Message Content Intent » est activé (l'erreur n°1), puis t'affiche le lien d'invitation. Détail dans [Discord](#discord-option).

## Le coffre Obsidian

Par défaut `~/cerveau` (`VAULT_DIR` dans `.env`). Ouvre-le dans Obsidian si tu veux le lire ; Artemis y accède seul.

- `INDEX.md` : une ligne par note, qui dit *quand* l'ouvrir
- `CLAUDE.md` : règles d'écriture (en-tête, une note = une ligne dans l'INDEX)
- `lecons/`, `workflow/` : remplis par Artemis quand tu le corriges

**Modules** (`vault-starter/`) : un module = un dossier à garder ou non.

| Module | Contenu | Skill associée |
|---|---|---|
| `cuisine` | profil et stock, recettes, menus et courses | `courses`, `recette-tiktok` |

Notes vides, sauf des exemples marqués `(exemple fictif)`. Dis simplement à Artemis « je n'aime pas le poisson » ou « il me reste 1 kg de riz » : il met les notes à jour.

- Charger un module : `./install.sh --starter=cuisine`
- Le retirer : supprime son dossier du coffre, sa ligne dans `INDEX.md` et sa skill dans `plugin/skills/`
- En créer un : `vault-starter/<nom>/` avec tes notes et un `_index.md`

## Suivi de colis

Envoie un numéro de suivi : Artemis détecte le transporteur (Colis Privé, Colissimo, Chronopost, UPS, DPD, Mondial Relay) et donne le statut. « Surveille-le » l'ajoute à la liste.

- **Colis Privé** : sans clé. **Les autres** : clé gratuite sur [ship24.com](https://www.ship24.com), à mettre dans `.env` (`SHIP24_API_KEY=`)
- Avec la clé, `./install.sh` active un timer (toutes les 30 min) qui t'alerte à chaque changement de statut. Destinataire : `TELEGRAM_CHAT_ID`, sinon le premier compte appairé
- Journal : `journalctl --user -u artemis-colis`

## Rappels

« Rappelle-moi lundi 18h30 de sortir les poubelles » : Artemis calcule la date exacte, te la confirme et l'ajoute (`rappel/rappel.py`, skill `rappel`).

- Toujours actif, sans clé : `./install.sh` installe un timer (chaque minute) qui t'envoie le rappel sur Telegram, au même destinataire que l'alerte colis
- Lister / annuler : demande-le, ou `python3 rappel/rappel.py list` puis `rm <n>`
- Journal : `journalctl --user -u artemis-rappel`

## Recettes TikTok

Envoie un lien TikTok de cuisine : Artemis lit la légende (sans navigateur), la convertit en fiche au format du module `cuisine` et l'ajoute à `cuisine/recettes.md` avec sa ligne d'index (skill `recette-tiktok`). Si rien n'est lisible, il te le dit au lieu d'inventer.

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
4. **Le plus simple** : `./setup.sh` (il demande le jeton et ton ID, vérifie l'intent, affiche le lien d'invitation). À la main : dans `.env`, `DISCORD_BOT_TOKEN=<jeton>` et `DISCORD_ALLOWED_USERS=<ton ID>` (plusieurs : séparés par des virgules ; **obligatoire**), puis `./install.sh && systemctl --user restart artemis`.
5. Écris au bot en MP.

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
| Qui a accès | `TELEGRAM_ALLOWED_USERS` et `DISCORD_ALLOWED_USERS` dans `.env` |

## Dépannage

| Problème | Solution |
|---|---|
| Discord : `Used disallowed intents` | Developer Portal → Bot → active **Message Content Intent**, puis `systemctl --user restart artemis` |
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
