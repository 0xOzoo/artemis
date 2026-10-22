# Règles du cerveau

Ce dossier est de la documentation, pas du code. Obsidian le lit tel quel (*Ouvrir un dossier comme coffre*), et Claude y accède par le **MCP obsidian** (chemins relatifs à la racine du coffre).

## Lecture — c'est là que l'économie de contexte se fait
1. Charger **[[INDEX]]** et rien d'autre.
2. N'ouvrir que les notes dont l'INDEX dit qu'elles servent à la tâche. Une note = une idée, ≤ 80 lignes.
3. Besoin d'un détail précis : `obsidian_search_vault` (`mode: "content"`, `scope:` le dossier concerné) puis lire la note trouvée, jamais le dossier entier.
4. Ne pas recopier ici ce qui vit déjà dans un fichier d'un projet : mettre son chemin. Un lien symbolique est illisible par le MCP (`SYMLINK_NOT_ALLOWED`).

## Écriture
Nouvelle note quand un savoir a coûté cher à obtenir et resservira : une leçon, un état de projet, un fait d'infra, une préférence.

Par le MCP : `obsidian_create_note` pour une note neuve (il n'écrase jamais), `obsidian_read_note` → `obsidian_edit_note` avec `if_match` pour compléter (`append` pour une entrée datée, `replace` seulement en repartant du contenu qu'on vient de lire).

En-tête :
```
---
type: lecon | projet | workflow | infra | perso
tags: [sujet]
resume: une ligne qui suffit à décider si on ouvre la note
maj: AAAA-MM-JJ
---
```
Pour une leçon, trois sections courtes : **Ce qui s'est passé** (chiffres et date), **La règle**, **Où ça a mordu**.

Chaque nouvelle note ajoute **une ligne dans [[INDEX]]**, sous la bonne rubrique, formulée en « quand l'ouvrir ». Une note non indexée est une note perdue.

Dates en absolu (`AAAA-MM-JJ`), jamais « hier ». Liens `[[...]]` même vers une note pas encore écrite : ça marque le trou. Jamais de secret (jeton, clé, mot de passe) dans une note.

Correction de l'utilisateur sur ma façon de travailler → entrée dans [[workflow/erreurs-et-correctifs]] le jour même, avec la règle à appliquer.
