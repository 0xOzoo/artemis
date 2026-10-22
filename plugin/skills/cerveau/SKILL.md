---
name: cerveau
description: >
  Lire le second cerveau (coffre Obsidian) par le MCP obsidian, de façon sélective : INDEX d'abord, puis
  seulement les notes utiles. Utiliser quand on cherche l'état d'un projet, un incident passé, une leçon,
  une préférence de l'utilisateur, ou avant de régler un filtre / relancer un service / annoncer un
  chiffre. Mots-clés : cerveau, coffre, Obsidian, leçon, note, état du projet, INDEX.
---

Le coffre porte ce que le code ne dit pas : l'état des projets, les incidents, les préférences, et la
leçon que chaque erreur a coûtée. Tout passe par le MCP obsidian, `vault:` le nom donné dans la consigne
système (par défaut `cerveau`), chemins **relatifs** à la racine du coffre.

## L'ordre de lecture (c'est là que l'économie de contexte se fait)

1. `obsidian_read_note` sur `INDEX.md` — une ligne par note, qui dit **quand** l'ouvrir. Rien d'autre
   d'office.
2. Les notes que l'index désigne pour la tâche en cours, pas la rubrique entière.
3. Un détail précis : `obsidian_search_vault` (`mode: "content"`, `scope:` le dossier concerné, ex.
   `"lecons"`), puis lire la note trouvée. Jamais un balayage du coffre.

## Deux pièges du MCP

- **Il refuse tout chemin passant par un lien symbolique** (`SYMLINK_NOT_ALLOWED`) : ce qui est derrière
  un lien se lit avec `Read` à son chemin réel.
- Une note dit ce qui était vrai à sa date (`maj:`). Un chiffre se vérifie à la source, jamais dans une
  note.

Si le coffre est encore vide, le dire simplement et continuer. Pour écrire : skill `cerveau-ecrire`.
