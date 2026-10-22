#!/usr/bin/env bash
# Installe Artemis (Claude Code piloté depuis Telegram). Idempotent : se relance sans rien casser.
# Usage : ./install.sh [--yes] [--voice] [--starter[=cuisine]]
#   --yes            accepte d'avance chaque installation de dépendance (sinon une question par dépendance)
#   --voice          installe aussi la lecture des vocaux/vidéos (ffmpeg + Whisper, ~1 Go, lent sur petite machine)
#   --starter        copie aussi tous les modules du starter (vault-starter/*) dans le coffre
#   --starter=a,b    seulement ces modules
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="" YES="" VOICE=""
for arg in "$@"; do
  case "$arg" in
    --starter) STARTER="all" ;;
    --starter=*) STARTER="${arg#--starter=}" ;;
    --yes|-y) YES=1 ;;
    --voice) VOICE=1 ;;
    -h|--help) sed -n 2,7p "$0"; exit 0 ;;
    *) echo "Option inconnue : $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }
# Demande avant chaque installation ; sans terminal (et sans --yes) la réponse est non.
ask()  {
  [ -n "$YES" ] && return 0
  local r; { : </dev/tty; } 2>/dev/null || return 1
  read -rp "$(printf '\033[1;34m[?]\033[0m %s [o/N] ' "$*")" r </dev/tty || return 1
  [[ "$r" =~ ^[oOyY] ]]
}
need() { ask "$1" || die "Refusé : $1. Installe-le toi-même ou relance avec --yes."; }

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.local/share/fnm/aliases/default/bin:$PATH"

# --- 1. Configuration -------------------------------------------------------
if [ ! -f "$DIR/.env" ]; then
  cp "$DIR/.env.example" "$DIR/.env"
  chmod 600 "$DIR/.env"
  die "Fichier .env créé. Remplis TELEGRAM_BOT_TOKEN dedans (nano $DIR/.env), puis relance ./install.sh"
fi
chmod 600 "$DIR/.env"
set -a
# shellcheck source=/dev/null
. "$DIR/.env"
set +a
: "${VAULT_NAME:=cerveau}" "${VAULT_DIR:=$HOME/cerveau}" "${TMUX_SESSION:=artemis}"
[[ "${TELEGRAM_BOT_TOKEN:-}" =~ ^[0-9]{5,15}:[A-Za-z0-9_-]{30,}$ ]] \
  || die "TELEGRAM_BOT_TOKEN absent ou mal formé dans .env (attendu : 123456789:ABC..., donné par @BotFather)"
[[ "$VAULT_NAME" =~ ^[A-Za-z0-9_-]+$ ]] || die "VAULT_NAME : lettres, chiffres, - et _ seulement"
[[ "$TMUX_SESSION" =~ ^[A-Za-z0-9_-]+$ ]] || die "TMUX_SESSION : lettres, chiffres, - et _ seulement"

# --- 2. Dépendances ---------------------------------------------------------
missing=()
for c in tmux curl unzip patch python3; do command -v "$c" >/dev/null || missing+=("$c"); done
[ -n "$VOICE" ] && { command -v ffmpeg >/dev/null || missing+=(ffmpeg); python3 -c 'import ensurepip' 2>/dev/null || missing+=(python3-venv); }
if [ ${#missing[@]} -gt 0 ]; then
  command -v apt-get >/dev/null || die "Installe d'abord : ${missing[*]}"
  need "Installer ${missing[*]} avec apt (sudo) ?"
  sudo apt-get update -qq && sudo apt-get install -y "${missing[@]}"
fi

node_ok() { command -v node >/dev/null && node -e 'process.exit(+process.versions.node.split(".")[0] < 22)'; }
if ! node_ok; then
  need "Node >= 22 absent (le MCP obsidian l'exige). L'installer avec fnm dans ~/.local/share/fnm, sans sudo ?"
  [ -x "$HOME/.local/share/fnm/fnm" ] || curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
  "$HOME/.local/share/fnm/fnm" install 22
  "$HOME/.local/share/fnm/fnm" default 22
  node_ok || die "Node 22 introuvable après installation"
fi

if ! command -v bun >/dev/null; then
  need "bun absent (le plugin telegram tourne dessus). L'installer dans ~/.bun, sans sudo ?"
  curl -fsSL https://bun.sh/install | bash
fi
command -v bun >/dev/null || die "bun introuvable"

if ! command -v claude >/dev/null; then
  need "Claude Code absent. L'installer dans ~/.local/bin, sans sudo ?"
  curl -fsSL https://claude.ai/install.sh | bash
fi
command -v claude >/dev/null || die "claude introuvable"

# --- 3. Compte Claude -------------------------------------------------------
[ -s "$HOME/.claude/.credentials.json" ] || die "Claude Code n'est pas connecté. Lance : cd ~ && claude
puis connecte-toi (abonnement Claude Pro/Max), accepte de faire confiance au dossier, quitte (/exit) et relance ./install.sh"

# --- 4. Plugin telegram -----------------------------------------------------
if ! claude plugin marketplace list 2>/dev/null | grep -q claude-plugins-official; then
  say "Ajout du catalogue de plugins officiel"
  claude plugin marketplace add anthropics/claude-plugins-official
fi
if ! claude plugin list 2>/dev/null | grep -q 'telegram@claude-plugins-official'; then
  say "Installation du plugin telegram"
  claude plugin install telegram@claude-plugins-official
fi
# Désactivé partout, réactivé seulement par artemis.sh : sinon chaque session claude ouverte vole le bot.
claude plugin disable telegram@claude-plugins-official >/dev/null 2>&1 || true
# /clear, /usage, /opus, /sonnet et vocaux : patch du plugin, à relancer après chaque mise à jour de celui-ci.
"$DIR/patch-telegram.sh" \
  || warn "Patch du plugin telegram non appliqué (voir ci-dessus) : Artemis marche, sans ces commandes ni les vocaux."

STATE="${TELEGRAM_STATE_DIR:-$HOME/.claude/channels/telegram}"
mkdir -p "$STATE" && chmod 700 "$STATE"
( umask 077; printf 'TELEGRAM_BOT_TOKEN=%s\n' "$TELEGRAM_BOT_TOKEN" > "$STATE/.env" )
say "Jeton du bot enregistré dans $STATE/.env"

# --- 5. Coffre Obsidian -----------------------------------------------------
mkdir -p "$VAULT_DIR"
cp -rn "$DIR/vault-starter/base/." "$VAULT_DIR/"
if [ -n "$STARTER" ]; then
  [ "$STARTER" = all ] && STARTER="$(find "$DIR/vault-starter" -mindepth 1 -maxdepth 1 -type d ! -name base -printf '%f,')"
  IFS=, read -ra mods <<< "$STARTER"
  for m in "${mods[@]}"; do
    [ -n "$m" ] || continue
    src="$DIR/vault-starter/$m"
    [ -d "$src" ] && [ "$m" != base ] || die "Module inconnu : $m (voir vault-starter/)"
    mkdir -p "$VAULT_DIR/$m"
    find "$src" -maxdepth 1 -type f ! -name _index.md -exec cp -n {} "$VAULT_DIR/$m/" \;
    head_line="$(grep -m1 '^## ' "$src/_index.md")"
    grep -qxF "$head_line" "$VAULT_DIR/INDEX.md" || cat "$src/_index.md" >> "$VAULT_DIR/INDEX.md"
    say "Module $m copié dans le coffre"
  done
fi
say "Coffre : $VAULT_DIR (fichiers existants jamais écrasés)"

if ! claude mcp get obsidian >/dev/null 2>&1; then
  say "Ajout du MCP obsidian sur le coffre « $VAULT_NAME »"
  claude mcp add -s user obsidian -- npx -y obsidian-mcp@2.0.1 serve --vault "$VAULT_NAME=$VAULT_DIR"
fi

# --- 6. Service systemd utilisateur ----------------------------------------
chmod +x "$DIR/artemis.sh"
UNIT="$HOME/.config/systemd/user/artemis.service"
mkdir -p "$(dirname "$UNIT")"
SVC_PATH="$(dirname "$(command -v node)"):$(dirname "$(command -v bun)"):$(dirname "$(command -v claude)"):$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
sed -e "s|@PATH@|$SVC_PATH|" -e "s|@TMUX@|$(command -v tmux)|g" \
    -e "s|@SESSION@|$TMUX_SESSION|g" -e "s|@INSTALL_DIR@|$DIR|g" \
    "$DIR/systemd/artemis.service.in" > "$UNIT"
systemctl --user daemon-reload
systemctl --user enable --now artemis.service
loginctl enable-linger "$(id -un)" 2>/dev/null \
  || warn "Linger non activé : Artemis s'arrêtera à la déconnexion. Lance : sudo loginctl enable-linger $(id -un)"

# --- 7. Vocaux (facultatif, --voice) ----------------------------------------
if [ -n "$VOICE" ]; then
  if "$DIR/.venv/bin/python" -c 'import faster_whisper' 2>/dev/null; then
    say "Vocaux : Whisper déjà installé"
  else
    need "Installer Whisper (faster-whisper, ~1 Go avec le modèle) dans $DIR/.venv ?"
    python3 -m venv "$DIR/.venv"
    "$DIR/.venv/bin/pip" install -q faster-whisper
    say "Vocaux activés (le modèle « ${WHISPER_MODEL:-small} » se télécharge au premier vocal)"
  fi
elif [ ! -x "$DIR/.venv/bin/python" ]; then
  say "Vocaux non installés : Artemis signalera qu'il ne peut pas les lire (./install.sh --voice pour les activer)"
fi

# --- 8. Alerte colis (facultatif, si SHIP24_API_KEY est remplie) ------------
CU="$HOME/.config/systemd/user/artemis-colis"
if [ -n "${SHIP24_API_KEY:-}" ]; then
  sed "s|@INSTALL_DIR@|$DIR|g" "$DIR/systemd/artemis-colis.service.in" > "$CU.service"
  cp "$DIR/systemd/artemis-colis.timer" "$CU.timer"
  systemctl --user daemon-reload
  systemctl --user enable --now artemis-colis.timer
  say "Alerte colis active (toutes les 30 min)"
elif [ -f "$CU.timer" ]; then
  systemctl --user disable --now artemis-colis.timer || true
  rm -f "$CU.timer" "$CU.service"
  systemctl --user daemon-reload
  say "SHIP24_API_KEY vide : alerte colis retirée"
fi

say "Artemis tourne (session tmux « $TMUX_SESSION »)."
cat <<EOF

Étape suivante, l'appairage :
  1. Écris n'importe quoi à ton bot sur Telegram : il répond par un code.
  2. Ici : tmux attach -t $TMUX_SESSION
     tape : /telegram:access pair <code>
     puis : /telegram:access policy allowlist
     et détache-toi avec Ctrl-b puis d.
Après une modification de .env : ./install.sh puis systemctl --user restart artemis
Après une mise à jour du plugin telegram : ./patch-telegram.sh puis systemctl --user restart artemis
EOF
