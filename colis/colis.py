#!/usr/bin/env python3
"""Colis surveillés : python3 colis.py add <numéro> [nom] | rm <numéro> | list | check
`check` (timer systemd artemis-colis, toutes les 30 min) prévient sur Telegram à chaque changement de statut
et à la livraison, puis arrête de suivre le colis livré."""
import json
import os
import sys
import urllib.request

from suivi_colis import DEPOT, config, etat

FICHIER = os.path.expanduser(config("COLIS_FILE", str(DEPOT / "colis" / "colis.json")))
ETAT_TG = os.path.expanduser(config("TELEGRAM_STATE_DIR", "~/.claude/channels/telegram"))


def destinataire():
    """TELEGRAM_CHAT_ID du .env, sinon le premier compte appairé (access.json du plugin)."""
    chat = config("TELEGRAM_CHAT_ID")
    if chat:
        return chat
    with open(os.path.join(ETAT_TG, "access.json")) as f:
        return json.load(f)["allowFrom"][0]


def envoyer(texte):
    """Envoi avec le jeton du bot, lu dans le .env du plugin telegram (jamais affiché)."""
    with open(os.path.join(ETAT_TG, ".env")) as f:
        jeton = next(l.split("=", 1)[1].strip() for l in f if l.startswith("TELEGRAM_BOT_TOKEN="))
    chat = destinataire()
    for i in range(0, len(texte), 4000):  # limite Telegram 4096
        req = urllib.request.Request(
            f"https://api.telegram.org/bot{jeton}/sendMessage",
            data=json.dumps({"chat_id": chat, "text": texte[i:i + 4000]}).encode(),
            headers={"Content-Type": "application/json"})
        urllib.request.urlopen(req, timeout=20).read()


def charger():
    try:
        with open(FICHIER) as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def sauver(d):
    os.makedirs(os.path.dirname(FICHIER), exist_ok=True)
    tmp = FICHIER + ".tmp"
    with open(tmp, "w") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
    os.replace(tmp, FICHIER)


def etats():
    """(numéro, nom, état|None) pour chaque colis suivi ; une erreur réseau donne None, jamais un verdict."""
    for num, c in charger().items():
        try:
            yield num, c.get("nom", ""), etat(num)
        except Exception as e:  # shortcut: une erreur est loggée (journalctl), pas relancée
            print(f"{num}: {e}", file=sys.stderr)
            yield num, c.get("nom", ""), None


def check():
    d = charger()
    for num, nom, e in etats():
        if e is None or e["statut"] == d[num].get("statut"):
            continue
        d[num]["statut"] = e["statut"]
        icone = "✅" if e["livre"] else "📦"
        envoyer(f"{icone} {nom or num} ({e['transporteur']})\n{e['statut']}")
        if e["livre"]:
            del d[num]
        sauver(d)  # sauvegarde après chaque envoi : un plantage plus loin ne renvoie pas le même message


if __name__ == "__main__":
    cmd, *a = sys.argv[1:] or ["list"]
    d = charger()
    if cmd == "add":
        num = a[0].strip().upper().replace(" ", "")
        e = etat(num)  # refuse un numéro que personne ne sait suivre avant de le stocker
        d[num] = {"nom": " ".join(a[1:]), "statut": e["statut"]}
        sauver(d)
        print(f"{num} suivi ({e['transporteur']}) : {e['statut']}")
    elif cmd == "rm":
        d.pop(a[0].strip().upper().replace(" ", ""), None)
        sauver(d)
    elif cmd == "check":
        check()
    else:
        for num, c in d.items():
            print(num, c.get("nom", ""), "-", c.get("statut", ""))
