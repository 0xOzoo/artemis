#!/usr/bin/env bash
# Ajoute au plugin telegram les commandes /clear, /usage, /opus, /sonnet et la lecture des vocaux/vidéos.
# Idempotent. À relancer après chaque mise à jour du plugin (elle écrase server.ts), puis :
#   systemctl --user restart artemis
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${CLAUDE_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/claude-plugins-official/telegram"
PATCH="$DIR/telegram-patch/telegram-commands.patch"

# Version la plus récente du plugin = celle que Claude charge.
PLUGIN="$(find "$CACHE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -1)"
[ -n "$PLUGIN" ] && [ -f "$PLUGIN/server.ts" ] \
  || { echo "[x] Plugin telegram introuvable dans $CACHE (installe-le d'abord : ./install.sh)" >&2; exit 1; }
VERSION="${PLUGIN##*/}"
cd "$PLUGIN"

if grep -q 'ARTEMIS-PATCH' server.ts; then
  echo "Déjà patché : plugin telegram $VERSION"
  exit 0
fi
if ! patch -p1 --dry-run --silent < "$PATCH" >/dev/null; then
  echo "[x] Le patch ne s'applique pas au plugin telegram $VERSION (testé sur 0.0.7) : server.ts a changé." >&2
  echo "    Rien n'a été modifié. Les commandes /clear /usage /opus et les vocaux sont indisponibles ;" >&2
  echo "    le bot fonctionne sans. Il faut adapter telegram-patch/telegram-commands.patch à cette version." >&2
  exit 1
fi
cp server.ts server.ts.orig # non patché ici (marqueur absent) : c'est bien l'original
patch -p1 --silent --no-backup-if-mismatch < "$PATCH"
echo "Patché : plugin telegram $VERSION (original sauvé dans $PLUGIN/server.ts.orig)"
echo "Pour l'appliquer à la session en cours : systemctl --user restart artemis"
