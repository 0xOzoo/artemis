#!/usr/bin/env bash
# Teste install.sh hors ligne, dans un HOME jetable, avec claude/systemctl/tmux/... simulés.
# Ne touche ni au vrai ~/.claude, ni à systemd, ni au réseau.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME/.local/bin" "$HOME/.claude"
echo '{}' > "$HOME/.claude/.credentials.json"
cp -r "$REPO" "$T/repo"; rm -rf "$T/repo/.env" "$T/repo/.venv"
B="$HOME/.local/bin"
# shellcheck disable=SC2016 # $* et $HOME doivent s'étendre dans les stubs, pas ici
for c in systemctl loginctl tmux bun node unzip curl ffmpeg; do printf '#!/bin/sh\necho "%s $*" >> "$HOME/calls.log"\n' "$c" > "$B/$c"; done
cat > "$B/claude" <<'EOF'
#!/bin/sh
echo "claude $*" >> "$HOME/calls.log"
[ "$1 $2" = "mcp get" ] && exit 1
exit 0
EOF
# python3 simulé pour --voice : « -m venv » crée un pip qui pose un marqueur ; le python du venv réussit ensuite.
cat > "$B/python3" <<'EOF'
#!/bin/sh
echo "python3 $*" >> "$HOME/calls.log"
[ "$1" = -m ] || exit 0
mkdir -p "$3/bin"
printf '#!/bin/sh\necho "pip $*" >> "$HOME/calls.log"; touch "%s/ok"\n' "$3" > "$3/bin/pip"
printf '#!/bin/sh\n[ -f "%s/ok" ]\n' "$3" > "$3/bin/python"
chmod +x "$3/bin/pip" "$3/bin/python"
EOF
chmod +x "$B"/*
export PATH="$B:/usr/bin:/bin"

# Faux plugin telegram : server.ts reconstruit à partir du contexte du patch (lignes « » et « - »).
PLUG="$HOME/.claude/plugins/cache/claude-plugins-official/telegram/0.0.7"
mkdir -p "$PLUG"
grep -E '^[ -]' "$REPO/telegram-patch/telegram-commands.patch" | grep -v '^--- ' | cut -c2- > "$PLUG/server.ts"
cp "$PLUG/server.ts" "$T/server.ts.pristine"

fail() { echo "ÉCHEC : $*"; exit 1; }

# 1. sans .env : il le crée et s'arrête
! "$T/repo/install.sh" 2>/dev/null || fail "aurait dû s'arrêter sans .env"
[ -f "$T/repo/.env" ] || fail ".env non créé"

# 2. jeton mal formé : refusé
sed -i 's|^TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=nimporte-quoi|' "$T/repo/.env"
! "$T/repo/install.sh" 2>/dev/null || fail "jeton invalide accepté"

# 3. installation complète, deux fois (idempotence)
sed -i 's|^TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=123456789:AAtesttesttesttesttesttesttesttest12|' "$T/repo/.env"
"$T/repo/install.sh" --starter >/dev/null
echo "note perso" >> "$HOME/cerveau/cuisine/recettes.md"
"$T/repo/install.sh" --starter=cuisine >/dev/null

U="$HOME/.config/systemd/user/artemis.service"
! grep -q @ "$U" || fail "variables non remplacées dans le service"
grep -q "$T/repo/artemis.sh" "$U" || fail "chemin d'installation absent du service"
[ "$(stat -c %a "$HOME/.claude/channels/telegram/.env")" = 600 ] || fail "droits du jeton"
grep -qx 'TELEGRAM_BOT_TOKEN=123456789:AAtesttesttesttesttesttesttesttest12' "$HOME/.claude/channels/telegram/.env" || fail "jeton"
[ "$(grep -c '^## Cuisine' "$HOME/cerveau/INDEX.md")" = 1 ] || fail "section Cuisine dupliquée"
grep -q "note perso" "$HOME/cerveau/cuisine/recettes.md" || fail "note de l'utilisateur écrasée"
[ ! -e "$HOME/cerveau/cuisine/_index.md" ] || fail "_index.md copié dans le coffre"
grep -q "plugin disable telegram@claude-plugins-official" "$HOME/calls.log" || fail "plugin non désactivé globalement"
grep -q "mcp add -s user obsidian" "$HOME/calls.log" || fail "MCP obsidian non ajouté"

# 3b. patch du plugin telegram : appliqué une fois, original sauvé
[ "$(grep -c ARTEMIS-PATCH "$PLUG/server.ts")" = 1 ] || fail "patch telegram non appliqué (ou deux fois)"
cmp -s "$PLUG/server.ts.orig" "$T/server.ts.pristine" || fail "original du plugin non sauvé"
grep -q "bot.command('clear'" "$PLUG/server.ts" || fail "commande /clear absente"
"$T/repo/patch-telegram.sh" | grep -q "Déjà patché" || fail "patch non idempotent"
# plugin mis à jour avec un server.ts incompatible : échec explicite, fichier intact, l'installation continue
NEW="$(dirname "$PLUG")/0.0.8"
mkdir -p "$NEW"; echo "// autre version" > "$NEW/server.ts"
! "$T/repo/patch-telegram.sh" 2>"$T/err" || fail "patch appliqué sur une version incompatible"
grep -q "0.0.8" "$T/err" || fail "version du plugin non signalée"
[ "$(cat "$NEW/server.ts")" = "// autre version" ] || fail "plugin incompatible modifié"
"$T/repo/install.sh" 2>"$T/err" >/dev/null || fail "installation bloquée par le patch"
grep -q "Patch du plugin telegram non appliqué" "$T/err" || fail "échec du patch silencieux"
rm -rf "$NEW"

# 3c. alerte colis : timer seulement si SHIP24_API_KEY est remplie, retiré si elle est vidée
CU="$HOME/.config/systemd/user/artemis-colis"
[ ! -e "$CU.timer" ] || fail "timer colis installé sans clé"
sed -i 's|^SHIP24_API_KEY=.*|SHIP24_API_KEY=cle-de-test|' "$T/repo/.env"
"$T/repo/install.sh" >/dev/null
[ -f "$CU.timer" ] && grep -q "WorkingDirectory=$T/repo/colis" "$CU.service" || fail "timer colis absent ou mal rempli"
grep -q "enable --now artemis-colis.timer" "$HOME/calls.log" || fail "timer colis non activé"
sed -i 's|^SHIP24_API_KEY=.*|SHIP24_API_KEY=|' "$T/repo/.env"
"$T/repo/install.sh" >/dev/null
[ ! -e "$CU.timer" ] || fail "timer colis gardé sans clé"
# scripts colis, hors ligne : détection du transporteur, clé absente signalée, liste vide
( cd "$T/repo/colis" && export COLIS_FILE="$T/colis.json" && /usr/bin/python3 -c '
import suivi_colis as s
assert s.transporteur("DG" + "0" * 15)[0] == "Colis Privé"
assert s.transporteur("1Z" + "A" * 16)[0] == "UPS"
assert s.transporteur("XX")[0] is None
try:
    s.ship24("1Z" + "A" * 16)
    raise SystemExit("clé absente non signalée")
except RuntimeError as e:
    assert "SHIP24_API_KEY" in str(e)
' && [ -z "$(/usr/bin/python3 colis.py list)" ] ) || fail "scripts colis"

# 3c bis. rappels : timer toujours installé ; add trie et refuse un format invalide, rm retire, rien d'échu = aucun envoi
RU="$HOME/.config/systemd/user/artemis-rappel"
grep -q "WorkingDirectory=$T/repo/rappel" "$RU.service" && [ -f "$RU.timer" ] || fail "timer rappel absent ou mal rempli"
grep -q "enable --now artemis-rappel.timer" "$HOME/calls.log" || fail "timer rappel non activé"
( cd "$T/repo/rappel" && export RAPPEL_FILE="$T/rappels.json" && R="/usr/bin/python3 rappel.py" \
  && $R add "2999-01-02 09:00" "deux" >/dev/null && $R add "2999-01-01 08:00" "un" >/dev/null \
  && ! $R add "lundi 18h" "x" 2>/dev/null \
  && [ "$($R list | head -1)" = "0 2999-01-01 08:00 un" ] \
  && $R check && $R rm 0 && [ "$($R list)" = "0 2999-01-02 09:00 deux" ] ) || fail "script rappel"

# 3c ter. mise à jour : timer installé ; comparaison de versions ; update.sh refuse un dossier sans git
UU="$HOME/.config/systemd/user/artemis-update"
grep -q "WorkingDirectory=$T/repo/update" "$UU.service" && [ -f "$UU.timer" ] || fail "timer update absent ou mal rempli"
grep -q "enable --now artemis-update.timer" "$HOME/calls.log" || fail "timer update non activé"
( cd "$T/repo/update" && /usr/bin/python3 -c '
import check
assert check.plus_recente("0.1.2", "v0.1.3") and check.plus_recente("0.9.0", "v0.10.0")
assert not check.plus_recente("0.1.2", "v0.1.2") and not check.plus_recente("0.2.0", "v0.1.9")
' ) || fail "comparaison de versions"

# 3c quater. patch notes : CHANGELOG.md doit avoir une section pour la VERSION courante
( cd "$T/repo" && [ -n "$(update/notes.sh)" ] ) || fail "pas de notes pour la VERSION courante"

# 3d. vocaux : --voice installe Whisper dans .venv, une seule fois
"$T/repo/install.sh" --voice --yes >/dev/null
grep -q "pip install -q faster-whisper" "$HOME/calls.log" || fail "Whisper non installé"
"$T/repo/install.sh" --voice --yes >/dev/null
[ "$(grep -c "pip install" "$HOME/calls.log")" = 1 ] || fail "Whisper réinstallé"

# 3f. Discord : liste d'autorisation obligatoire, jeton et access.json en 600, réglages gardés, rien sans jeton
D="$HOME/.claude/channels/discord"
[ ! -e "$D" ] || fail "Discord configuré sans jeton"
mv "$B/python3" "$T/python3.stub" # vrai python3 : access.json doit vraiment être écrit
sed -i 's|^DISCORD_BOT_TOKEN=.*|DISCORD_BOT_TOKEN=MTIzNDU2Nzg5MDEyMzQ1Njc4.GabcDe.test_test-test_test-test_test-test1234|' "$T/repo/.env"
! "$T/repo/install.sh" 2>"$T/err" >/dev/null || fail "Discord accepté sans liste d'autorisation"
grep -q DISCORD_ALLOWED_USERS "$T/err" || fail "liste d'autorisation manquante non expliquée"
sed -i 's|^DISCORD_ALLOWED_USERS=.*|DISCORD_ALLOWED_USERS=pseudo|' "$T/repo/.env"
! "$T/repo/install.sh" 2>/dev/null >/dev/null || fail "ID Discord non numérique accepté"
sed -i 's|^DISCORD_ALLOWED_USERS=.*|DISCORD_ALLOWED_USERS=184695080709324800,221773638772129792|' "$T/repo/.env"
mkdir -p "$D" && echo '{"dmPolicy":"pairing","allowFrom":["999999999999999999"],"ackReaction":"🔨"}' > "$D/access.json"
"$T/repo/install.sh" >/dev/null
grep -q "plugin install discord@claude-plugins-official" "$HOME/calls.log" || fail "plugin discord non installé"
grep -q "plugin disable discord@claude-plugins-official" "$HOME/calls.log" || fail "plugin discord non désactivé globalement"
[ "$(stat -c %a "$D/.env")" = 600 ] && [ "$(stat -c %a "$D/access.json")" = 600 ] || fail "droits des fichiers Discord"
grep -qx 'DISCORD_BOT_TOKEN=MTIzNDU2Nzg5MDEyMzQ1Njc4.GabcDe.test_test-test_test-test_test-test1234' "$D/.env" || fail "jeton Discord"
/usr/bin/python3 -c '
import json, sys
a = json.load(open(sys.argv[1]))
assert a["dmPolicy"] == "allowlist", a
assert a["allowFrom"] == ["184695080709324800", "221773638772129792"], a
assert a["ackReaction"] == "🔨", a
' "$D/access.json" || fail "access.json Discord"
mv "$T/python3.stub" "$B/python3"
sed -i -e 's|^DISCORD_BOT_TOKEN=.*|DISCORD_BOT_TOKEN=|' -e 's|^DISCORD_ALLOWED_USERS=.*|DISCORD_ALLOWED_USERS=|' "$T/repo/.env"

# 3g. Telegram : liste d'autorisation de .env écrite dans access.json (pas d'appairage), refusée si mal formée
T_ACC="$HOME/.claude/channels/telegram/access.json"
mv "$B/python3" "$T/python3.stub"
sed -i 's|^TELEGRAM_ALLOWED_USERS=.*|TELEGRAM_ALLOWED_USERS=pseudo|' "$T/repo/.env"
! "$T/repo/install.sh" 2>/dev/null >/dev/null || fail "ID Telegram non numérique accepté"
sed -i 's|^TELEGRAM_ALLOWED_USERS=.*|TELEGRAM_ALLOWED_USERS=123456789|' "$T/repo/.env"
"$T/repo/install.sh" >/dev/null
/usr/bin/python3 -c '
import json, sys
a = json.load(open(sys.argv[1]))
assert a["dmPolicy"] == "allowlist" and a["allowFrom"] == ["123456789"], a
' "$T_ACC" || fail "access.json Telegram"
[ "$(stat -c %a "$T_ACC")" = 600 ] || fail "droits access.json Telegram"
mv "$T/python3.stub" "$B/python3"
sed -i 's|^TELEGRAM_ALLOWED_USERS=.*|TELEGRAM_ALLOWED_USERS=|' "$T/repo/.env"

# 3e. dépendance manquante : refusée sans terminal ni --yes, installée avec --yes (dans le HOME, sans sudo)
rm "$B/bun"
! setsid -w "$T/repo/install.sh" </dev/null 2>"$T/err" >/dev/null || fail "bun installé sans confirmation"
grep -q "Refusé" "$T/err" || fail "refus non expliqué"
! grep -q "bun.sh/install" "$HOME/calls.log" || fail "bun téléchargé sans confirmation"
"$T/repo/install.sh" --yes >/dev/null 2>&1 || true # le faux curl n'installe rien : seul l'appel compte
grep -q "bun.sh/install" "$HOME/calls.log" || fail "--yes n'installe pas bun"

# 4. module inconnu : refusé
! "$T/repo/install.sh" --starter=inexistant 2>/dev/null || fail "module inconnu accepté"
echo "OK : tous les tests passent"
