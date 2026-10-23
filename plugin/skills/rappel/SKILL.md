---
name: rappel
description: Programmer, lister ou supprimer un rappel envoyé sur Telegram à une date et une heure précises. Utiliser quand l'utilisateur dit « rappelle-moi… », « pense à me dire… », demande ses rappels ou veut en annuler un. Mots-clés : rappel, rappelle-moi, n'oublie pas, alarme, plus tard, demain, lundi.
---

# Rappels

Script dans `$ARTEMIS_DIR/rappel/` (variable exportée par `artemis.sh`). Lancer depuis ce dossier :

- **Programmer** (« rappelle-moi lundi 18h30 de sortir les poubelles ») : `cd "$ARTEMIS_DIR/rappel" && python3 rappel.py add "AAAA-MM-JJ HH:MM" "texte"`.
  - Convertir toute date relative (« demain », « lundi », « dans 2 h », « ce soir ») en date absolue à partir de `date '+%Y-%m-%d %H:%M %A'`, jamais de tête. « Lundi » = le prochain lundi (pas aujourd'hui s'il est passé). Sans heure : la demander, ou proposer 9:00 et le dire.
  - Texte du rappel : l'action seule, à l'infinitif ou telle que dite (« sortir les poubelles »), sans « rappelle-moi ».
  - Répondre par `reply` en confirmant la date calculée en toutes lettres : « Rappel lundi 26/10 à 18:30 : sortir les poubelles ». Une date dans le passé : ne pas l'ajouter, redemander.
- **Lister** : `python3 rappel.py list` (numéro, date, texte, triés par date). **Supprimer** : `python3 rappel.py rm <numéro>` après un `list`, car les numéros changent à chaque ajout.
- Le timer `artemis-rappel` (`systemctl --user is-active artemis-rappel.timer`) envoie chaque rappel échu sur Telegram à la minute près, puis le retire. Inactif : le dire, rien ne partira (`./install.sh` le réactive).
- Précision : la minute. Pas de rappel récurrent : pour « tous les lundis », programmer le prochain et le dire.
