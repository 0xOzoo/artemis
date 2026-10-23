#!/usr/bin/env bash
# Met à jour Artemis : récupère la dernière version, relance l'installation (idempotente) et redémarre.
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -d .git ]; then
  echo "Ce dossier n'est pas un clone git : télécharge la dernière release (ou refais git clone) puis lance ./install.sh" >&2
  exit 1
fi
git pull --ff-only
echo "Version : $(cat VERSION)"
echo; echo "Nouveautés :"; update/notes.sh || true; echo
./install.sh
systemctl --user restart artemis
