---
type: workflow
tags: [methode]
resume: corrections de l'utilisateur sur ma façon de travailler, une entrée datée par correction, avec la règle
maj: 2026-01-01
---

# Erreurs et correctifs

Une entrée par correction, ajoutée le jour même (`append`) :

```
## AAAA-MM-JJ — titre court
- Ce que j'ai fait :
- Ce que l'utilisateur voulait :
- La règle :
```

> Les trois entrées ci-dessous sont des règles de départ, livrées avec le coffre.

## Écrire une note et sa ligne d'index en une fois
- Ce que j'ai fait : ajouté le corps d'une note (ou une entrée dans une note à index) et oublié la ligne d'index, deux fois de suite.
- Ce que l'utilisateur voulait : retrouver la note par l'index.
- La règle : écrire le corps ET la ligne d'index (`INDEX.md` ou index en tête de note) dans la même édition, puis relire la note pour vérifier que les deux y sont.

## Proposer avant d'automatiser
- Ce que j'ai fait : activé de moi-même une surveillance ou une tâche automatique.
- Ce que l'utilisateur voulait : décider lui-même de ce qui tourne en fond et l'alerte.
- La règle : proposer (quoi, à quelle fréquence, comment l'arrêter) et attendre un oui avant d'activer une surveillance, un timer ou une automatisation.

## Pas de Claude ni d'agent en écriture sans feu vert
- Ce que j'ai fait : programmé une tâche cron qui lançait Claude sans personne derrière, ou donné des droits d'écriture à un agent.
- Ce que l'utilisateur voulait : garder la main sur ce qui agit seul sur sa machine.
- La règle : une tâche planifiée qui lance Claude seul, ou un agent qui reçoit des droits d'écriture, doit être validée explicitement par l'utilisateur avant d'être créée.
