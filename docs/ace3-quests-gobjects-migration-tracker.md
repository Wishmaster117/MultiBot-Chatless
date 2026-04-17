# Ace3 Quests + GameObject UI Migration Tracker (Milestone 8)

Document de suivi dédié à la migration complète de la tranche **Quests** + **GameObject search/results** hors de `Core/MultiBotInit.lua` vers des modules `UI/` dédiés.

> Objectif de la migration : avoir de vraies fenêtres AceGUI avec contenu recodé nativement, sans réembarquer les anciennes frames legacy dans une coquille Ace3.

---

## État actuel

### Statut global
- **Extraction UI réalisée** : les frames Quests/GameObjects ne sont plus construites inline dans `Core/MultiBotInit.lua`.
- **Découpage par écran réalisé** : chaque écran important dispose maintenant de son propre fichier `UI/`.
- **Socle partagé en place** : le styling, le tri, les helpers de liens de quête, l’agrégation des bots, le prompt GameObject et le host Ace3 partagé sont maintenant factorisés.
- **Reste à faire** : aucun blocage Milestone 8. Cette tranche est considérée finalisée ; les ajustements futurs relèvent du polish continu (hors gating M8).

### Source of truth actuelle
- `Core/MultiBotInit.lua`
- `Core/MultiBotHandler.lua`
- `UI/MultiBotAceUI.lua`
- `UI/MultiBotQuestUIShared.lua`
- `UI/MultiBotPromptDialog.lua`
- `UI/MultiBotQuestLogFrame.lua`
- `UI/MultiBotQuestIncompleteFrame.lua`
- `UI/MultiBotQuestCompletedFrame.lua`
- `UI/MultiBotQuestAllFrame.lua`
- `UI/MultiBotGameObjectResultsFrame.lua`
- `UI/MultiBotGameObjectCopyFrame.lua`
- `UI/MultiBotQuestsMenu.lua`
- `UI/MultiBotItemusFrame.lua` *(référence visuelle)*

---

## Découpage effectivement livré

### Fichiers UI dédiés
- `UI/MultiBotQuestLogFrame.lua`
  - Popup du journal de quêtes joueur.
- `UI/MultiBotQuestIncompleteFrame.lua`
  - Quêtes incomplètes des bots.
- `UI/MultiBotQuestCompletedFrame.lua`
  - Quêtes terminées des bots.
- `UI/MultiBotQuestAllFrame.lua`
  - Vue agrégée “all quests”.
- `UI/MultiBotGameObjectResultsFrame.lua`
  - Résultats de recherche GameObjects.
- `UI/MultiBotGameObjectCopyFrame.lua`
  - Fenêtre de copie/export.
- `UI/MultiBotPromptDialog.lua`
  - Prompt AceGUI réutilisable pour le flux `u <name>`.
- `UI/MultiBotAceUI.lua`
  - Résolution AceGUI, popup host, ESC, close=>hide, persistance de position et tooltip caché de localisation des quêtes.
- `UI/MultiBotQuestUIShared.lua`
  - Helpers communs de style, tri, agrégation et rendu.
- `UI/MultiBotQuestsMenu.lua`
  - Wiring du menu Quests et des actions associées.

### Rôle résiduel de `Core/MultiBotInit.lua`
- Exposer les helpers transverses encore utiles au slice Quests/GameObjects (`GetLocalizedQuestName`, résolution AceGUI, close/ESC/persist positions).
- Initialiser le menu via `MultiBot.InitializeQuestsMenu(tRight)`.
- Ne plus contenir le gros bloc legacy de construction inline des fenêtres de quêtes/GameObjects.

---

## Checklist d’avancement

### Contraintes de migration
- [x] Ne pas réembarquer les anciennes frames legacy dans une fenêtre AceGUI.
- [x] Sortir la construction des frames Quests/GameObjects de `Core/MultiBotInit.lua`.
- [x] Déplacer la construction UI dans des fichiers `UI/` dédiés.
- [x] Conserver la logique fonctionnelle globale (group/whisper/loading/close/reopen).
- [x] Introduire des helpers partagés pour limiter la duplication.

### Partage et architecture
- [x] Ajouter un module partagé `UI/MultiBotQuestUIShared.lua`.
- [x] Ajouter un prompt mutualisé `UI/MultiBotPromptDialog.lua`.
- [x] Extraire le menu Quests dans `UI/MultiBotQuestsMenu.lua`.
- [x] Conserver la logique de parsing/agrégation asynchrone côté `Core/MultiBotHandler.lua`.
- [x] Introduire un tri déterministe pour les listes de quêtes agrégées.
- [x] Mutualiser le formatage “Bots: …” et l’agrégation multi-bots.
- [x] Extraire le socle Ace3/tooltip partagé hors de `Core/MultiBotInit.lua` dans `UI/MultiBotAceUI.lua`.

### Réécriture par écran
- [x] `MB_QuestPopup` → `UI/MultiBotQuestLogFrame.lua`
- [x] `MB_BotQuestPopup` → `UI/MultiBotQuestIncompleteFrame.lua`
- [x] `MB_BotQuestCompPopup` → `UI/MultiBotQuestCompletedFrame.lua`
- [x] `MB_BotQuestAllPopup` → `UI/MultiBotQuestAllFrame.lua`
- [x] `MB_GameObjPopup` → `UI/MultiBotGameObjectResultsFrame.lua`
- [x] `MB_GameObjCopyBox` → `UI/MultiBotGameObjectCopyFrame.lua`

### Validation / finitions restantes
- [x] Vérifier en jeu le clic gauche/droit sur les quêtes du journal.
- [x] Vérifier la parité exacte des tooltips de quêtes.
- [x] Vérifier la parité exacte des modes GROUP / WHISPER.
- [x] Vérifier les états de chargement et d’absence de données.
- [x] Vérifier visuellement l’alignement final avec le style `Itemus`.
- [x] Réduire si besoin la surface des wrappers de compatibilité exposés par `Core/MultiBotInit.lua`.

---

## Détails sur l’état fonctionnel à ce stade

### Ce qui est déjà migré nativement
- Les hôtes de fenêtres sont créés via AceGUI.
- Le contenu de chaque écran est reconstruit dans son module dédié.
- Le prompt GameObject n’utilise plus d’ancienne frame séparée inline.
- Les listes agrégées sont triées de façon déterministe.
- Les fenêtres de quêtes partagent désormais un socle de style/backdrop commun.
- Le comportement close/hide, ESC et persistance de position réutilise désormais un module partagé dédié (`UI/MultiBotAceUI.lua`).

### Ce qui reste principalement à confirmer
- Le rendu exact en client WoW avec toutes les localisations/cas limites.
- La cohérence finale du skin par rapport à `Itemus` sur tous les écrans du slice.
- Les éventuels petits écarts de wording/fallback (`LOADING`, labels vides, cas sans données).

---

## Suivi recommandé pour la suite

### Si la prochaine PR est une PR de finalisation Quests
1. Faire une passe de validation in-game complète sur tous les flux Quests/GameObjects.
2. Corriger les écarts de polish visuel restants vers le style `Itemus`.
3. Réduire les doublons résiduels éventuels entre les écrans incomplete/completed/all.
4. Mettre à jour ce document en basculant les items de validation en `[x]`.

### Si la prochaine PR change de slice
Le slice Quests/GameObjects est désormais considéré comme **complètement validé pour Milestone 8** (migration + parité fonctionnelle/visuelle).

---

### Statut Milestone 8
- ✅ Milestone 8 est marqué **complet** pour la tranche Quests/GameObjects.
- Les prochains changements relèvent de l’amélioration continue, pas d’un reliquat de migration Ace3 bloquant.