#!/usr/bin/env python3
"""Rappels à date fixe : python3 rappel.py add "AAAA-MM-JJ HH:MM" "texte" | list | rm <n> | check
`check` (timer systemd artemis-rappel, chaque minute) envoie sur Telegram les rappels échus puis les retire."""
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "colis"))
from suivi_colis import DEPOT, config  # noqa: E402
from colis import envoyer  # noqa: E402  même envoi Telegram (jeton et destinataire) que l'alerte colis

FICHIER = os.path.expanduser(config("RAPPEL_FILE", str(DEPOT / "rappel" / "rappels.json")))
FMT = "%Y-%m-%d %H:%M"


def charger():
    try:
        with open(FICHIER) as f:
            return json.load(f)
    except FileNotFoundError:
        return []


def sauver(liste):
    os.makedirs(os.path.dirname(FICHIER), exist_ok=True)
    tmp = FICHIER + ".tmp"
    with open(tmp, "w") as f:
        json.dump(liste, f, ensure_ascii=False, indent=1)
    os.replace(tmp, FICHIER)


def echus(liste, maintenant):
    return [r for r in liste if datetime.datetime.strptime(r["quand"], FMT) <= maintenant]


if __name__ == "__main__":
    cmd, *a = sys.argv[1:] or ["list"]
    liste = charger()
    if cmd == "add":
        datetime.datetime.strptime(a[0], FMT)  # refuse un format invalide avant de stocker
        liste.append({"quand": a[0], "texte": " ".join(a[1:])})
        liste.sort(key=lambda r: r["quand"])
        sauver(liste)
        print(f"rappel : {a[0]} {' '.join(a[1:])}")
    elif cmd == "rm":
        liste.pop(int(a[0]))
        sauver(liste)
    elif cmd == "check":
        for r in echus(liste, datetime.datetime.now()):
            envoyer("⏰ " + r["texte"])  # si l'envoi échoue, le rappel reste et repart à la minute suivante
            liste.remove(r)
            sauver(liste)  # après chaque envoi : un plantage plus loin ne renvoie pas le même rappel
    else:
        for i, r in enumerate(liste):
            print(i, r["quand"], r["texte"])
