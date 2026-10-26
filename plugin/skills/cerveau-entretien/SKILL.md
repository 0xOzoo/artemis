---
name: cerveau-entretien
description: Entretenir le coffre Obsidian « cerveau » : ingérer une source en notes reliées, répondre à une question puis ranger la réponse, et faire un audit (notes orphelines, absentes de l'INDEX, liens cassés, contradictions, notes périmées). Utiliser quand l'utilisateur dit « range le cerveau », « audit du coffre », « ajoute cette source au cerveau », ou après un gros ajout. Mots-clés : audit, lint, orphelines, INDEX, entretien, ingérer.
---

# Entretien du cerveau

Adapté de `llm-wiki` (pattern de Karpathy, via Hermes Agent, licence MIT, 2026-10-26). Le coffre existe déjà (`INDEX.md`, `lecons/`, `workflow/`, `perso/`...) : ce skill n'en crée pas un second, il tient le premier propre. Écriture via `cerveau-ecrire` (MCP obsidian), jamais en balayant tout le coffre.

## 1. Ingérer une source
1. Lire d'abord `INDEX.md` pour voir si le sujet a déjà une note ; mettre à jour plutôt que dupliquer.
2. Écrire/compléter une note avec en-tête `type/tags/resume/maj` et au moins 2 liens `[[...]]` vers des notes existantes.
3. Ajouter **une ligne dans `INDEX.md`** (sinon la note est perdue).
4. Si la source contredit une note : le signaler dans les deux notes avec la date, ne pas écraser en silence.
5. Garder la source brute immuable (lien/URL, pas de réécriture).

## 2. Répondre puis ranger
Après une réponse de fond qui a coûté de la recherche et resservira : la déposer en note (ou en section datée) plutôt que la laisser dans le chat.

## 3. Audit (à la demande, jamais en tâche de fond)
Lister, avec chemins, **sans rien modifier** avant accord :
- notes absentes de `INDEX.md` et lignes d'`INDEX.md` dont la note n'existe plus ;
- notes sans lien entrant ni sortant (orphelines), liens `[[...]]` cassés ;
- en-têtes incomplets, `maj:` très ancien sur des états qui bougent (desk, stock) ;
- contradictions entre notes (seuils, chiffres, règles) et doublons.
Proposer les corrections en liste courte ; appliquer seulement celles que l'utilisateur valide.

## Pièges
Balayer tout le coffre (coûte du contexte : `obsidian_search_vault` ciblé suffit) ; créer une note sans la ligne d'INDEX ; réécrire l'historique d'une note datée (ajouter une section, ne pas effacer).
