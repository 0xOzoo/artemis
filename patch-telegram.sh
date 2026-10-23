#!/usr/bin/env bash
# Ajoute au plugin telegram les commandes /clear, /usage, /opus, /sonnet et la lecture des vocaux/vidéos,
# et au plugin discord la commande /usage.
# Idempotent. À relancer après chaque mise à jour du plugin (elle écrase server.ts), puis :
#   systemctl --user restart artemis
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHES="${CLAUDE_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/claude-plugins-official"

# patch_plugin <plugin> <fichier.patch> : sur la version la plus récente du plugin = celle que Claude charge.
patch_plugin() {
  local NAME="$1" PATCH="$DIR/telegram-patch/$2" PLUGIN VERSION
  PLUGIN="$(find "$CACHES/$NAME" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -1)"
  [ -n "$PLUGIN" ] && [ -f "$PLUGIN/server.ts" ] \
    || { echo "[x] Plugin $NAME introuvable dans $CACHES/$NAME (installe-le d'abord : ./install.sh)" >&2; return 1; }
  VERSION="${PLUGIN##*/}"
  if grep -q 'ARTEMIS-PATCH' "$PLUGIN/server.ts"; then
    echo "Déjà patché : plugin $NAME $VERSION"
    return 0
  fi
  if ! (cd "$PLUGIN" && patch -p1 --dry-run --silent < "$PATCH" >/dev/null); then
    echo "[x] Le patch ne s'applique pas au plugin $NAME $VERSION : server.ts a changé." >&2
    echo "    Rien n'a été modifié ; le bot fonctionne sans ces commandes. Il faut adapter telegram-patch/$2 à cette version." >&2
    return 1
  fi
  cp "$PLUGIN/server.ts" "$PLUGIN/server.ts.orig" # non patché ici (marqueur absent) : c'est bien l'original
  (cd "$PLUGIN" && patch -p1 --silent --no-backup-if-mismatch < "$PATCH")
  echo "Patché : plugin $NAME $VERSION (original sauvé dans $PLUGIN/server.ts.orig)"
}

rc=0
patch_plugin telegram telegram-commands.patch || rc=1
# Discord est facultatif : seulement s'il est installé.
if [ -d "$CACHES/discord" ]; then patch_plugin discord discord-usage.patch || rc=1; fi
[ "$rc" = 0 ] && echo "Pour l'appliquer à la session en cours : systemctl --user restart artemis"
exit "$rc"
