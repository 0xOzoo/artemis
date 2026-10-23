#!/usr/bin/env python3
"""Prévient sur Telegram quand une release plus récente que VERSION existe (une fois par version).
Timer systemd artemis-update (hebdo). `python3 check.py --dry-run` imprime au lieu d'envoyer."""
import json
import os
import re
import sys
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "colis"))
from suivi_colis import DEPOT, config  # noqa: E402
from colis import envoyer  # noqa: E402

DEPOT_GH = config("ARTEMIS_REPO", "0xOzoo/artemis")
VUE = DEPOT / "update" / "derniere-annoncee.txt"  # shortcut: un seul fichier d'état, en dehors de git (.gitignore)


def version(texte):
    return tuple(int(n) for n in re.findall(r"\d+", texte)[:3])


def plus_recente(locale, distante):
    return version(distante) > version(locale)


def derniere_release():
    req = urllib.request.Request(f"https://api.github.com/repos/{DEPOT_GH}/releases/latest",
                                 headers={"User-Agent": "artemis-update"})
    r = json.load(urllib.request.urlopen(req, timeout=20))
    return r["tag_name"], (r.get("body") or "").strip()


if __name__ == "__main__":
    locale = (DEPOT / "VERSION").read_text().strip()
    distante, notes = derniere_release()
    deja = VUE.read_text().strip() if VUE.exists() else ""
    if plus_recente(locale, distante) and deja != distante:
        msg = (f"🆕 Artemis {distante} est disponible (tu as {locale}).\n"
               f"{notes[:800]}\n\n"
               f"Pour mettre à jour : ./update.sh dans le dossier d'Artemis.")
        if "--dry-run" in sys.argv:
            print(msg)
        else:
            envoyer(msg)
            VUE.write_text(distante)  # écrit après l'envoi : un échec réessaie à la prochaine passe
    else:
        print(f"à jour ({locale}, dernière release {distante})")
