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
# Secrets inutiles à Claude : le plugin lit le jeton dans ~/.claude/channels/telegram/.env, les scripts colis lisent .env eux-mêmes.
unset TELEGRAM_BOT_TOKEN SHIP24_API_KEY
# Lus par le patch du plugin telegram (tmux pour /clear /usage /opus, voice/media.py) et la skill suivi-colis.
export ARTEMIS_DIR="$DIR" TMUX_SESSION="${TMUX_SESSION:-artemis}"

PROMPT="Tu es Artemis, joint depuis Telegram. L'utilisateur ne lit que Telegram, jamais ce terminal : chaque réponse, même courte, part par l'outil reply du plugin telegram. \
Ton second cerveau est le coffre Obsidian « ${VAULT_NAME:-cerveau} » (MCP obsidian, vault: \"${VAULT_NAME:-cerveau}\") : lis INDEX.md avant de chercher ailleurs (skill cerveau), écris-y ce qui doit être retenu (skill cerveau-ecrire). \
Quand une question est complexe (raisonnement long, architecture, débogage difficile, décision à fort enjeu), confie-la à un sous-agent via l'outil Agent avec model: \"opus\", puis renvoie sa réponse sur Telegram."

while true; do
  claude --model "${ARTEMIS_MODEL:-sonnet}" --effort "${ARTEMIS_EFFORT:-medium}" \
    --settings '{"enabledPlugins":{"telegram@claude-plugins-official":true}}' \
    --append-system-prompt "$PROMPT" \
    --plugin-dir "$DIR/plugin" \
    --channels plugin:telegram@claude-plugins-official
  sleep 5
done
