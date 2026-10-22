#!/usr/bin/env bash
# Assistant d'installation : pose 2-3 questions, écrit .env, vérifie les jetons, lit ton ID Telegram
# dans ton premier message au bot (pas d'appairage), puis lance install.sh.
# Usage : ./setup.sh [options d'install.sh : --yes --voice --starter]
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
command -v curl >/dev/null && command -v python3 >/dev/null || { echo "Installe d'abord curl et python3." >&2; exit 1; }

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }
ask() { local r; read -rp "$(printf '\033[1;34m[?]\033[0m %s ' "$1")" r; printf '%s' "$r"; }
jget() { python3 -c 'import sys,json;d=json.load(sys.stdin)
for k in sys.argv[1].split("."): d=d[int(k)] if k.isdigit() else d.get(k) if isinstance(d,dict) else None
print("" if d is None else d)' "$1" 2>/dev/null || true; }

[ -f .env ] || cp .env.example .env
chmod 600 .env
get_env() { grep -m1 "^$1=" .env | cut -d= -f2- | tr -d '"' || true; }
set_env() { { grep -v "^$1=" .env || true; printf '%s=%s\n' "$1" "$2"; } > .env.new && mv .env.new .env && chmod 600 .env; }

# --- Telegram ----------------------------------------------------------------
TOKEN="$(get_env TELEGRAM_BOT_TOKEN)"
if [ -z "$TOKEN" ]; then
  echo "Dans Telegram : @BotFather → /newbot → nom, puis identifiant finissant par « bot »."
  TOKEN="$(ask 'Colle le jeton du bot :')"
fi
ME="$(curl -fsS "https://api.telegram.org/bot$TOKEN/getMe" 2>/dev/null || true)"
BOT="$(printf '%s' "$ME" | jget result.username)"
[ -n "$BOT" ] || die "Jeton refusé par Telegram. Vérifie-le chez @BotFather (/mybots → API Token)."
set_env TELEGRAM_BOT_TOKEN "$TOKEN"
say "Bot Telegram : @$BOT"

USERS="$(get_env TELEGRAM_ALLOWED_USERS)"
if [ -z "$USERS" ]; then
  echo "Écris maintenant n'importe quoi à @$BOT dans Telegram (2 min max)…"
  for _ in 1 2 3 4 5; do
    UPD="$(curl -fsS "https://api.telegram.org/bot$TOKEN/getUpdates?timeout=25&allowed_updates=%5B%22message%22%5D" 2>/dev/null || true)"
    USERS="$(printf '%s' "$UPD" | jget result.0.message.from.id)"
    [ -n "$USERS" ] && break
  done
  [ -n "$USERS" ] || die "Aucun message reçu. Si Artemis tourne déjà avec ce bot, arrête-le (systemctl --user stop artemis) ; sinon relance ./setup.sh."
fi
set_env TELEGRAM_ALLOWED_USERS "$USERS"
say "Compte autorisé : $USERS (le seul qui pilote Artemis)"

# --- Discord (facultatif) ----------------------------------------------------
DTOKEN="$(get_env DISCORD_BOT_TOKEN)"
if [ -z "$DTOKEN" ] && [[ "$(ask 'Ajouter Discord aussi ? [o/N]')" =~ ^[oOyY] ]]; then
  echo "discord.com/developers/applications → New Application → Bot → Reset Token."
  echo "Sur la même page, active « Message Content Intent » et enregistre."
  DTOKEN="$(ask 'Colle le jeton Discord :')"
fi
if [ -n "$DTOKEN" ]; then
  DME="$(curl -fsS -H "Authorization: Bot $DTOKEN" https://discord.com/api/v10/users/@me 2>/dev/null || true)"
  DNAME="$(printf '%s' "$DME" | jget username)"
  [ -n "$DNAME" ] || die "Jeton Discord refusé (Bot → Reset Token, puis colle le nouveau)."
  DID="$(printf '%s' "$DME" | jget id)"
  FLAGS="$(curl -fsS -H "Authorization: Bot $DTOKEN" https://discord.com/api/v10/applications/@me 2>/dev/null | jget flags)"
  # bits 18 (activé) et 19 (activé, bot < 100 serveurs) = Message Content Intent
  if [ -n "$FLAGS" ] && (( (FLAGS & (1 << 18)) == 0 && (FLAGS & (1 << 19)) == 0 )); then
    die "« Message Content Intent » est désactivé : Developer Portal → ton app → Bot → Privileged Gateway Intents, puis relance ./setup.sh"
  fi
  DUSERS="$(get_env DISCORD_ALLOWED_USERS)"
  [ -n "$DUSERS" ] || DUSERS="$(ask 'Ton ID Discord (Paramètres → Avancés → Mode développeur, clic droit sur ton nom → Copier l'"'"'identifiant) :')"
  set_env DISCORD_BOT_TOKEN "$DTOKEN"
  set_env DISCORD_ALLOWED_USERS "$DUSERS"
  say "Bot Discord : $DNAME"
  echo "Ajoute-le à un serveur où tu es (Discord l'exige pour les messages privés) :"
  echo "  https://discord.com/oauth2/authorize?client_id=$DID&scope=bot&permissions=101440"
  ask 'Entrée quand c'"'"'est fait…' >/dev/null
fi

# --- Installation ------------------------------------------------------------
say "Installation…"
exec ./install.sh "$@"
