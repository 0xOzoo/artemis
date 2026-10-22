---
name: suivi-colis
description: Suivre un colis à partir de son numéro (transporteur détecté tout seul) et gérer la liste des colis surveillés. Utiliser quand l'utilisateur envoie un numéro de suivi, demande où en est un colis, veut qu'on surveille/arrête de surveiller un colis. Mots-clés : colis, suivi, livraison, numéro de suivi, Colis Privé, Colissimo, Chronopost, La Poste, Mondial Relay, UPS, DPD.
---

# Suivi de colis

Scripts dans `$ARTEMIS_DIR/colis/` (variable exportée par `artemis.sh`). Lancer depuis ce dossier :

- **Un numéro seul** (« où est XX… ») : `cd "$ARTEMIS_DIR/colis" && python3 suivi_colis.py <numéro>` → transporteur, statut, historique. Répondre par `reply` : statut + 3 dernières étapes, rien de plus.
- **Surveiller** : `python3 colis.py add <numéro> [nom]`. Si le timer `artemis-colis` est actif (`systemctl --user is-active artemis-colis.timer`), il envoie sur Telegram tout changement de statut et la livraison toutes les 30 min, puis arrête de suivre le colis livré. Sinon, le dire : le suivi ne se fait qu'à la demande (`python3 colis.py check`). Toujours proposer de surveiller un numéro neuf.
- **Arrêter** : `python3 colis.py rm <numéro>` ; **lister** : `python3 colis.py list`.
- Colis Privé est lu en direct (sans clé). Les autres transporteurs passent par Ship24 (`SHIP24_API_KEY` dans `.env`, offre gratuite limitée à quelques colis par mois) : ne jamais afficher ni chercher à lire la clé. Clé absente : le script le dit ; proposer le lien de suivi officiel du transporteur.
- « Aucun événement » = numéro trop récent ou inconnu, pas un colis perdu. Une erreur réseau n'est pas un verdict.
- Piège connu : les mots-clés « livré » / « en cours de livraison » de Colis Privé sont devinés. Au premier vrai statut de livraison, vérifier que l'alerte est partie et corriger `etat()` dans `suivi_colis.py` sinon.
