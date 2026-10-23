---
name: recette-tiktok
description: Ajouter au coffre une recette reçue sous forme de lien TikTok (ou de vidéo, de vocal). Utiliser quand l'utilisateur envoie un lien TikTok de cuisine ou dit « ajoute cette recette ». Mots-clés : tiktok, recette, vidéo, ajoute cette recette, recettes.md.
---

# Recette TikTok vers le coffre

Notes du module `cuisine` : `cuisine/recettes.md` et `cuisine/profil-et-stock.md` (chemins relatifs au coffre). Absentes : proposer `./install.sh --starter=cuisine`.

1. **Extraire** sans navigateur :
   - Lien court (`vm.tiktok.com/…`, `vt.tiktok.com/…`) : suivre la redirection pour obtenir l'URL complète : `curl -sL -o /dev/null -w '%{url_effective}' "<lien>"`.
   - Lire la légende : `curl -sL -A 'Mozilla/5.0' "<url>"` puis le champ `"desc":"…"` de la page (JSON embarqué, souvent avec la liste des ingrédients). Ex. : `python3 -c 'import re,sys,json; m=re.search(r"\"desc\":(\"(?:[^\"\\]|\\.)*\")", sys.stdin.read()); print(json.loads(m.group(1)) if m else "RIEN")'` (page passée sur l'entrée standard).
   - `desc` sans quantités ni étapes : la page embarque souvent des **sous-titres automatiques** (`"subtitleInfos":[{"LanguageCodeName":"fra-FR","Url":"…","Format":"webvtt"}]`). Télécharger l'`Url` (WebVTT, `curl -sL -A 'Mozilla/5.0'`), ignorer les lignes de temps : on obtient la narration, donc les étapes. Les quantités y sont rarement dites : les marquer `~`.
   - Vidéo ou vocal envoyé en pièce jointe : transcription Whisper si installée (`--voice`).
   - **Rien de lisible** (page vide, `desc` vide ou sans ingrédients, blocage, vidéo sans légende ni Whisper) : le dire et demander les ingrédients ou une capture, au lieu d'inventer les quantités.
2. **Convertir** au format de `recettes.md` (1 repas, 1 personne) : titre `###` numéroté, `statut : proposée AAAA-MM-JJ · temps · prix : ?`, ingrédients `- <quantité> <unité> <produit>`, étapes courtes avec temps. Quantité devinée : la marquer `~`. Ingrédient interdit d'après `profil-et-stock.md` : le signaler et proposer une substitution.
3. **Écrire la fiche ET la ligne de l'index en tête de note dans la même édition** : `obsidian_read_note`, puis `obsidian_edit_note` avec `if_match`, puis `maj:`. Relire la note après l'édition : le titre doit figurer dans la fiche et dans l'index.
4. Répondre en liste courte : nom, temps, ingrédients absents du stock (`profil-et-stock.md`).
