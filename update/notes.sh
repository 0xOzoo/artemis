#!/usr/bin/env bash
# Affiche les notes de la version donnée (par défaut VERSION) depuis CHANGELOG.md. Sort en erreur si absentes.
cd "$(dirname "$0")/.." || exit 1
V="${1:-v$(cat VERSION)}"
N=$(awk -v v="## ${V#v}" -v w="## $V" '$0==v||$0==w{p=1;next} /^## /{p=0} p' CHANGELOG.md | sed '/./,$!d')
[ -n "$N" ] || { echo "pas de notes pour $V dans CHANGELOG.md" >&2; exit 1; }
printf '%s\n' "$N"
