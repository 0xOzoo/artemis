---
name: cerveau-ecrire
description: >
  Écrire dans le second cerveau (coffre Obsidian) par le MCP obsidian : une leçon après un incident, l'état
  d'un projet, une préférence, une correction de méthode. Utiliser quand un savoir a coûté cher et
  resservira, quand l'utilisateur corrige ma façon de travailler, après un incident ou un gros changement,
  ou quand il dit « note ça », « garde ça », « retiens ». Mots-clés : leçon, note, coffre, état, retenir.
---

Une note par idée, ≤ 80 lignes, en français, dates en absolu (`AAAA-MM-JJ`, jamais « hier »). On écrit
quand le savoir a coûté cher et resservira — pas ce qu'un fichier dit déjà. Tout passe par le MCP
obsidian, `vault:` le nom donné dans la consigne système (par défaut `cerveau`).

## Où ça va

| Ce qu'on a appris | Où |
|---|---|
| Un piège transposable (un filtre, un seuil, un cache, une boucle) | `lecons/<slug>.md` |
| L'état d'un projet, ce qu'il ne faut pas toucher | `homelab/projets/<projet>/<projet>.md` (une note par feature à côté ; un coffre ancien garde son `projets/<projet>.md`) |
| Une correction de l'utilisateur sur ma façon de travailler | `workflow/erreurs-et-correctifs.md`, **le jour même** |
| Un fait de machine (service, cron, disque, accès) | `homelab/infra/<sujet>.md` (ou `infra/` si le coffre est ancien) |
| Une préférence ou une info personnelle que l'utilisateur veut garder | `perso/<sujet>.md` |

## Comment

- Nouvelle note : `obsidian_create_note` (il n'écrase jamais ; si le nom est pris, la note existe — la
  lire et la compléter).
- Compléter : `obsidian_read_note` pour l'`etag`, puis `obsidian_edit_note` avec `if_match`. `append`
  pour une entrée datée ; `replace` seulement en repartant du contenu qu'on vient de lire.
- En-tête obligatoire :

```
---
type: lecon | projet | workflow | infra | perso
tags: [sujet]
resume: une ligne qui suffit à décider si on ouvre la note
maj: AAAA-MM-JJ
---
```

- Une leçon = trois sections courtes : **Ce qui s'est passé** (chiffres et date), **La règle**, **Où ça a
  mordu**.
- **Une nouvelle note = une ligne dans `INDEX.md`**, sous la bonne rubrique, formulée en « quand
  l'ouvrir ». Une note non indexée est une note perdue.

## Ce qu'on n'écrit pas

Les secrets (`.env`, jetons, clés, mots de passe) — le nom de la variable suffit.
