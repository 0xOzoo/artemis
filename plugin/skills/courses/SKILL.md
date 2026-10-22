---
name: courses
description: Menus, recettes et listes de courses de l'utilisateur, calculés à partir du coffre Obsidian (recettes validées, stock, goûts, budget). Utiliser quand il parle de courses, de repas, de recettes, de ce qu'il a dans ses placards, ou valide/refuse un plat. Mots-clés : courses, menu, recette, repas, stock, frigo, budget.
---

# Courses et menus

Notes du coffre (MCP obsidian, `vault:` celui de la consigne système) : `cuisine/profil-et-stock.md`, `cuisine/recettes.md`, `cuisine/menus-et-courses.md` (module « cuisine » du starter). Lire d'abord le profil (goûts, interdits, rythme, stock, réservé), puis seulement ce qui sert. Si ces notes n'existent pas, proposer de les créer sur ce modèle. Ignorer les lignes marquées `(exemple fictif)`.

- **Proposer** : plats simples et variés, jamais un produit interdit, respecter le rythme des repas et les produits réservés du profil.
- **Il valide ou refuse un plat** : le mettre/mettre à jour dans `recettes.md` (statut, ingrédients pour 1 repas, 1 personne, format `- <quantité> <unité> <produit>`, prix si connu). Un refus est noté aussi.
- **Il dit ce qu'il a / ce qui est fini** : corriger `profil-et-stock.md`.
- **Liste de courses** : suivre la méthode de `menus-et-courses.md` (sommer les recettes du menu, soustraire le stock, arrondir au conditionnement, ne rien ajouter de refusé, additionner les prix si le budget est connu). Budget inconnu : le demander avant de chiffrer.
- Écrire dans le coffre : `obsidian_read_note` puis `obsidian_edit_note` avec `if_match`. Répondre sur Telegram en liste courte.
