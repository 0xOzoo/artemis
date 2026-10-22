#!/usr/bin/env bash
# Boucle de la session Artemis, lancée dans tmux par artemis.service.
# Le plugin telegram est désactivé globalement (sinon toute session `claude` ouverte ailleurs vole le bot)
# et réactivé ici seulement, par --settings.
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
# shellcheck source=/dev/null
. "$DIR/.env"
set +a
PLUGINS='"telegram@claude-plugins-official":true' CHANNELS=(plugin:telegram@claude-plugins-official) VIA=Telegram
if [ -n "${DISCORD_BOT_TOKEN:-}" ]; then
  PLUGINS+=',"discord@claude-plugins-official":true' CHANNELS+=(plugin:discord@claude-plugins-official) VIA="Telegram ou Discord"
  # Liste d'autorisation figée au démarrage (celle écrite par install.sh) : Claude ne peut pas s'y ajouter quelqu'un.
  export DISCORD_ACCESS_MODE=static
fi
# Liste Telegram de .env (écrite par install.sh) : figée, Claude ne peut pas s'y ajouter quelqu'un.
[ -n "${TELEGRAM_ALLOWED_USERS:-}" ] && export TELEGRAM_ACCESS_MODE=static
# Secrets inutiles à Claude : les plugins lisent leur jeton dans ~/.claude/channels/<canal>/.env, les scripts colis lisent .env eux-mêmes.
unset TELEGRAM_BOT_TOKEN DISCORD_BOT_TOKEN SHIP24_API_KEY
# Lus par le patch du plugin telegram (tmux pour /clear /usage /opus, voice/media.py) et la skill suivi-colis.
export ARTEMIS_DIR="$DIR" TMUX_SESSION="${TMUX_SESSION:-artemis}"

PROMPT="Tu es Artemis, joint depuis $VIA. L'utilisateur ne lit que ce canal, jamais ce terminal : chaque réponse, même courte, part par l'outil reply du plugin du canal d'où vient le message (telegram ou discord). \
Ton second cerveau est le coffre Obsidian « ${VAULT_NAME:-cerveau} » (MCP obsidian, vault: \"${VAULT_NAME:-cerveau}\") : lis INDEX.md avant de chercher ailleurs (skill cerveau), écris-y ce qui doit être retenu (skill cerveau-ecrire). \
Quand une question est complexe (raisonnement long, architecture, débogage difficile, décision à fort enjeu), confie-la à un sous-agent via l'outil Agent avec model: \"opus\", puis renvoie sa réponse sur le même canal."

while true; do
  claude --model "${ARTEMIS_MODEL:-sonnet}" --effort "${ARTEMIS_EFFORT:-medium}" \
    --settings "{\"enabledPlugins\":{$PLUGINS}}" \
    --append-system-prompt "$PROMPT" \
    --plugin-dir "$DIR/plugin" \
    --channels "${CHANNELS[@]}"
  sleep 5
done
