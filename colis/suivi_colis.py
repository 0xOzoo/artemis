#!/usr/bin/env python3
"""Suivi de colis : python3 suivi_colis.py <numéro> -> transporteur, statut, historique."""
import json
import os
import re
import sys
import urllib.request
from html import unescape
from pathlib import Path

DEPOT = Path(__file__).resolve().parent.parent


def config(nom, defaut=""):
    """Variable d'environnement, sinon ligne NOM=valeur du .env du dépôt (le cron ne voit pas l'env d'Artemis)."""
    if os.environ.get(nom):
        return os.environ[nom]
    try:
        for ligne in (DEPOT / ".env").read_text().splitlines():
            if ligne.startswith(nom + "="):
                return os.path.expandvars(ligne.split("=", 1)[1].strip().strip("\"'")) or defaut
    except FileNotFoundError:
        pass
    return defaut

URL = "https://www.colisprive.com/moncolis/pages/detailColis.aspx?numColis="


# (nom, motif, lien de suivi officiel) ; shortcut: Colis Privé est lu en direct, les autres bloquent les robots donc passent par Ship24
TRANSPORTEURS = [
    ("Colis Privé", r"DG\d{15}", None),
    ("UPS", r"1Z[0-9A-Z]{16}", "https://www.ups.com/track?tracknum="),
    ("Chronopost", r"[A-Z]{2}\d{9}FR|X[A-Z]\d{9,}", "https://www.chronopost.fr/tracking-no-cms/suivi-page?listeNumerosLT="),
    ("Colissimo", r"[0-9][A-Z]\d{11}|[A-Z]{2}\d{9}[A-Z]{2}", "https://www.laposte.fr/outils/suivre-vos-envois?code="),
    ("DPD", r"\d{14}", "https://trace.dpd.fr/fr/trace/"),
    ("Mondial Relay", r"\d{8}|\d{10}|\d{12}", "https://www.mondialrelay.fr/suivi-de-colis/?numeroExpedition="),
]


def transporteur(numero):
    for nom, motif, lien in TRANSPORTEURS:
        if re.fullmatch(motif, numero):
            return nom, lien
    return None, None


def suivi(numero):
    req = urllib.request.Request(URL + numero, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=20) as r:
        html = r.read().decode("utf-8", "ignore")
    html = re.sub(r"<(script|style).*?</\1>", "", html, flags=re.S)
    txt = unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", html[html.find("<body"):])))
    m = re.search(r"Statut (.*?) Adresse du destinataire", txt)
    if not m:  # shortcut: parsing du texte de la page, à revoir si Colis Privé change son HTML
        raise ValueError("numéro inconnu ou page changée")
    histo = re.findall(r"(\d\d/\d\d/\d{4}) (.*?)(?= \d\d/\d\d/\d{4} |\s*Modifier ma livraison|$)",
                       txt[txt.find("Date Statut du colis"):])
    return m.group(1), histo


def ship24(numero):
    """Tous transporteurs via Ship24 ; clé SHIP24_API_KEY dans .env (jamais affichée)."""
    cle = config("SHIP24_API_KEY")
    if not cle:
        raise RuntimeError("SHIP24_API_KEY absente du .env : seul Colis Privé est suivi sans clé")
    req = urllib.request.Request(
        "https://api.ship24.com/public/v1/trackers/track",
        data=json.dumps({"trackingNumber": numero}).encode(),
        headers={"Authorization": f"Bearer {cle}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        t = json.load(r)["data"]["trackings"][0]
    ev = sorted(t["events"], key=lambda e: e["datetime"], reverse=True)
    transp = ev[0]["courierCode"] if ev else "inconnu"
    return transp, t["shipment"]["statusMilestone"], [(e["datetime"][:10], e["status"]) for e in ev]


def etat(numero):
    """Forme commune pour le briefing et l'alerte : transporteur, statut, historique, livré ?, livraison du jour ?"""
    numero = numero.strip().upper().replace(" ", "")
    nom, _ = transporteur(numero)
    if nom == "Colis Privé":
        statut, histo = suivi(numero)
        bas = statut.lower()
        # shortcut: mots-clés devinés (seul le 1er statut « pris en charge » est observé), à confirmer sur « en livraison » / « livré »
        livre = "livré" in bas and "sera livré" not in bas
        jour = not livre and bool(re.search(r"en cours de livraison|sera livré|livraison.*aujourd", bas))
    else:
        nom, jalon, histo = ship24(numero)
        statut = histo[0][1] if histo else jalon
        livre, jour = jalon == "delivered", jalon == "out_for_delivery"
    return {"numero": numero, "transporteur": nom, "statut": statut, "histo": histo, "livre": livre, "aujourdhui": jour}


if __name__ == "__main__":
    numero = sys.argv[1].strip().upper().replace(" ", "")
    nom, lien = transporteur(numero)
    if nom == "Colis Privé":
        statut, histo = suivi(numero)
    else:
        nom, statut, histo = ship24(numero)
        if not histo:
            sys.exit(f"Aucun événement pour {numero} (numéro trop récent ou inconnu)"
                     + (f" ; voir {lien}{numero}" if lien else ""))
    print(f"Transporteur : {nom}\n{statut}")
    for d, s in histo:
        print(f"{d}  {s}")
