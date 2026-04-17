# Ace3 Quick Frames Migration Tracker (Milestone 8)

Document de suivi dédié à la migration complète des mini frames **Quick Hunter** et **Quick Shaman** vers de vraies interfaces Ace3/AceGUI.

> Scope: documenter l’audit initial, suivre l’extraction des implémentations legacy anciennement imbriquées dans `Core/MultiBotInit.lua`, confirmer leur reconstruction dans des fichiers dédiés sous `UI/`, et tracer la suppression des shells legacy (`MultiBot.addFrame`, contours, groupes maison) tout en conservant la parité fonctionnelle.

---

## 1) Source-of-truth actuel / historique de migration

### Fichiers concernés par l’audit et la migration
- `Core/MultiBotInit.lua`
- `Core/MultiBot.lua`
- `UI/MultiBotHunterQuickFrame.lua`
- `UI/MultiBotShamanQuickFrame.lua`
- `Strategies/MultiBotHunter.lua`
- `Strategies/MultiBotShaman.lua`
- `docs/ace3-ui-frame-inventory.md`
- `docs/ace3-expansion-checklist.md`

### Points d’entrée legacy audités
- `MultiBot.InitHunterQuick()` construisait toute la mini frame Hunter directement dans `Core/MultiBotInit.lua` avant son extraction vers `UI/MultiBotHunterQuickFrame.lua`.
- `MultiBot.InitShamanQuick()` construisait toute la mini frame Shaman directement dans `Core/MultiBotInit.lua` avant son extraction vers `UI/MultiBotShamanQuickFrame.lua`.
- Les deux quick bars restaurent leur position via `MultiBot.GetQuickFramePosition(...)` / `MultiBot.SetQuickFramePosition(...)`.
- La quick frame Hunter persiste en plus la stance du pet par bot via `MultiBot.GetHunterPetStance(...)` / `MultiBot.SetHunterPetStance(...)`.
- La quick frame Shaman persiste les totems choisis par bot/élément via `MultiBot.GetShamanTotemsForBot(...)`, `MultiBot.SetShamanTotemChoice(...)`, et `MultiBot.ClearShamanTotemChoice(...)`.

---

## 2) Audit fonctionnel — Quick Hunter

### Ce que la frame fait aujourd’hui
- [x] S’affiche uniquement lorsqu’au moins un **bot hunter** est détecté dans le groupe/raid.
- [x] Construit une colonne par hunter bot trié alphabétiquement.
- [x] Permet d’ouvrir un menu vertical par bot depuis un bouton principal `class_hunter`.
- [x] Expose un bloc **pet stances** avec 7 actions : `aggressive`, `passive`, `defensive`, `stance`, `attack`, `follow`, `stay`.
- [x] Sauvegarde/restaure visuellement la stance active (`aggressive/passive/defensive`) par hunter.
- [x] Désactive le bloc des stances quand le pet du hunter n’existe pas ou est mort.
- [x] Expose un bloc **pet utils** avec les actions : `Name`, `Id`, `Family`, `Rename`, `Abandon`.
- [x] Réutilise déjà des popups AceGUI pour le prompt, la recherche de créature, la preview modèle et le sélecteur de famille.
- [x] Sauvegarde/restaure la position globale de la quick frame.

### Observations d’architecture
- [x] La logique de présence des bots, la construction de la vue et les handlers de chat sont mélangés dans une seule grosse fonction.
- [x] La frame racine et toutes les sous-zones reposent encore sur le wrapper legacy `MultiBot.addFrame(...)` / `row.addFrame(...)` / `addButton(...)`.
- [x] Les dimensions/offsets sont codés en dur sur une grille de `36px`.
- [x] Le code gère déjà un mini-contrôleur implicite (`entries`, `Rebuild`, `CollectHunterBots`, `UpdatePetPresence`) mais sans séparation formelle modèle/vue/contrôleur.

### Risques spécifiques Hunter
- [x] Régression sur l’apparition conditionnelle selon la composition du groupe. **Validation OK en jeu.**
- [x] Régression sur la persistance des stances par nom de bot. **Validation OK en jeu.**
- [x] Régression sur le drag & drop / restauration de position. **Validation OK en jeu.**
- [x] Régression sur les popups déjà migrés (search/family/prompt) si on modifie mal les points d’appel. **Validation OK en jeu.**
- [x] Régression sur la désactivation du menu des stances quand aucun pet n’est disponible. **Validation OK en jeu.**

---

## 3) Audit fonctionnel — Quick Shaman

### Ce que la frame fait aujourd’hui
- [x] S’affiche uniquement lorsqu’au moins un **bot shaman** est détecté dans le groupe/raid.
- [x] Construit une colonne par shaman bot.
- [x] Affiche un bouton principal `class_shaman` ouvrant un menu vertical par bot.
- [x] Expose 4 familles de totems : `earth`, `fire`, `water`, `air`.
- [x] Chaque famille ouvre une grille dédiée d’actions/totems sélectionnables.
- [x] Envoie les commandes chat `co +spell,?` et `co -spell,?` au bot ciblé.
- [x] Maintient une exclusivité visuelle par élément : un seul totem actif/retenti visuellement par famille.
- [x] Remplace l’icône du bouton d’élément par l’icône du totem choisi.
- [x] Sauvegarde/restaure le choix du totem par bot et par élément.
- [x] Sauvegarde/restaure la position globale de la quick frame.

### Observations d’architecture
- [x] La frame est fortement couplée au wrapper legacy et à des helpers visuels ad hoc (`SetBtnIcon`, `SetGrey`, `AddTotemToggle`).
- [x] La logique d’état (`_chosen`, `_selectedBtn`, `_gridBtns`, `_defaults`) est portée directement par les rows/boutons.
- [x] La clé d’index des entrées n’est pas homogène avec Hunter (`sanitized name` côté Shaman, nom brut côté Hunter), ce qui mérite une normalisation lors de la migration.
- [x] `CloseAllExcept()` masque aussi les autres rows, ce qui crée une UX spécifique à préserver ou à faire évoluer explicitement.
- [x] Un appel legacy parasite subsiste dans `OnDragStop` (`_MB_GetOrCreateShamanPos()`), alors que la persistance AceDB est désormais prise en charge par `MultiBot.SetQuickFramePosition(...)`.

### Risques spécifiques Shaman
- [x] Régression sur l’exclusivité visuelle d’un totem par élément. **Validation OK en jeu.**
- [x] Régression sur la restauration des icônes choisies après reload/relog. **Validation OK en jeu.**
- [x] Régression sur les commandes `co +/-<totem>,?` si le mapping données/UI diverge. **Validation OK en jeu.**
- [x] Régression sur le comportement d’expansion/fermeture des groupes Earth/Fire/Water/Air. **Validation OK en jeu.**
- [x] Régression sur l’apparition conditionnelle selon la présence de shamans bots. **Validation OK en jeu.**

---

## 4) Dette technique observée avant migration

### Problèmes communs aux deux quick frames
- [x] Les deux implémentations vivent encore dans `Core/MultiBotInit.lua`, ce qui gonfle fortement le fichier et mélange bootstrap, runtime, popups, et écrans.
- [x] Les deux écrans utilisent encore la stack UI legacy (`MultiBot.addFrame`) au lieu d’un vrai host AceGUI.
- [x] Les responsabilités suivantes ne sont pas clairement séparées : découverte des bots, état UI, rendu, persistance, et dispatch des actions.
- [x] Les handlers d’input répètent beaucoup de logique de drag/persist/close-all.
- [x] Les structures de données sont majoritairement implicites et mutées dynamiquement sur les widgets.

### Opportunités de modernisation Lua
- [x] Introduire des modules dédiés sous `UI/` (`UI/MultiBotHunterQuickFrame.lua`, `UI/MultiBotShamanQuickFrame.lua`).
- [x] Isoler des tables de configuration pures pour les actions/buttons plutôt que coder les boutons “à la main”.
- [x] Uniformiser le lifecycle avec une API du type `Ensure`, `RefreshFromGroup`, `ApplyLayout`, `PersistPosition`, `HideMenus`.
- [x] Réduire les globals implicites et privilégier `local` + helpers spécialisés.
- [x] Centraliser les primitives AceGUI/WoW natives nécessaires au drag, au close, et à la persistance.

---

## 5) Objectif de migration

### Contraintes fonctionnelles à respecter
- [x] Ne pas encapsuler les anciennes frames legacy dans une fenêtre AceGUI.
- [x] Refaire les quick frames comme de vraies fenêtres/conteneurs Ace3/AceGUI.
- [x] Conserver les mêmes commandes envoyées aux bots.
- [x] Conserver l’apparition conditionnelle selon la présence de hunters/shamans bots dans le groupe.
- [x] Conserver la persistance de position existante (`HunterQuick`, `ShamanQuick`).
- [x] Conserver la persistance des stances pet Hunter et des totems Shaman.
- [x] Conserver les popups Hunter déjà migrés sans les régresser.

### Cible de structure recommandée
- [x] `UI/MultiBotHunterQuickFrame.lua`
  - host AceGUI / container racine
  - découverte/refresh des hunters bots
  - rendu des rows/actions Hunter
  - intégration avec prompt/search/family existants
- [x] `UI/MultiBotShamanQuickFrame.lua`
  - host AceGUI / container racine
  - découverte/refresh des shamans bots
  - rendu des rows/actions Totems
  - restauration visuelle des totems choisis
- [x] `Core/MultiBotInit.lua`
  - ne garder que les hooks d’initialisation minimum et les appels publics nécessaires
  - supprimer les gros blocs inline une fois les modules UI branchés

---

## 6) Plan de migration recommandé

### Phase 1 — Préparation
- [x] Auditer les deux quick frames legacy.
- [x] Créer ce document de suivi.
- [x] Ajouter ces quick frames à l’inventaire M8 comme écrans non encore migrés.

### Phase 2 — Extraction structurelle
- [x] Déplacer la logique Hunter vers `UI/MultiBotHunterQuickFrame.lua` sans changer encore le comportement.
- [x] Déplacer la logique Shaman vers `UI/MultiBotShamanQuickFrame.lua` sans changer encore le comportement.
- [x] Réduire `Core/MultiBotInit.lua` à des points d’entrée fins.

### Phase 3 — Remplacement de l’UI legacy
- [x] Remplacer la racine `MultiBot.addFrame(...)` Hunter par un host AceGUI dédié.
- [x] Remplacer la racine `MultiBot.addFrame(...)` Shaman par un host AceGUI dédié.
- [x] Remplacer les groupes/boutons legacy par un layout AceGUI + frames natives WoW uniquement quand nécessaire.
- [x] Supprimer les dépendances aux bordures/contours legacy de ces deux quick frames.

### Phase 4 — Parité fonctionnelle
- [x] Valider la présence conditionnelle en groupe/raid.
- [x] Valider la persistance de position des deux quick frames.
- [x] Valider la persistance des stances Hunter.
- [x] Valider la persistance des totems Shaman.
- [x] Valider les flows Hunter prompt/search/family.
- [x] Valider l’exclusivité visuelle et l’icône d’élément côté Shaman.

---

## 7) Checklist de validation ciblée

### Hunter Quick
- [x] Un hunter bot seul fait apparaître la frame.
- [x] Plusieurs hunters bots produisent plusieurs rows stables et triées.
- [x] Le drag déplace bien la frame et la position revient après reload.
- [x] Les stances `aggressive/passive/defensive` restent exclusives visuellement.
- [x] L’absence de pet désactive correctement le sous-menu des stances.
- [x] `Name`, `Id`, `Family`, `Rename`, `Abandon` continuent d’envoyer les bonnes commandes.
- [x] Les popups search/family/prompt restent fonctionnels.

### Shaman Quick
- [x] Un shaman bot seul fait apparaître la frame.
- [x] Plusieurs shamans bots produisent plusieurs rows stables.
- [x] Le drag déplace bien la frame et la position revient après reload.
- [x] Chaque élément affiche bien le totem choisi sur son bouton principal.
- [x] La sélection d’un nouveau totem d’un même élément remplace bien l’ancien visuellement.
- [x] Désélectionner un totem rétablit l’icône par défaut du bouton d’élément.
- [x] Les choix persisted reviennent correctement après reload.

---

## 8) Décisions validées avant implémentation

- [x] **UX Shaman** : ne pas conserver le comportement legacy où une row ouverte masque complètement les autres. La cible retenue est une UX AceGUI où toutes les rows restent visibles, avec une seule row détaillée/dépliée à la fois par défaut.
- [x] **Architecture commune** : garder deux modules dédiés (`UI/MultiBotHunterQuickFrame.lua` et `UI/MultiBotShamanQuickFrame.lua`) et n’extraire que de petits utilitaires communs ciblés (position, drag, registre de rows, helpers de refresh), sans base abstraite prématurée.
- [x] **Granularité des boutons** : ne pas figer la migration sur la valeur legacy `36px`, mais conserver la même densité d’usage et la même vitesse de scan/clic, avec un léger ajustement possible si le layout AceGUI est plus lisible et plus confortable.
- [x] **Collecte des bots présents** : introduire un petit contrôleur partagé purement runtime/data pour la découverte des bots de groupe/raid par classe, afin d’éviter de dupliquer la logique de collecte Hunter/Shaman sans coupler ce contrôleur au rendu UI.

---

## 9) Clôture du slice

- [x] **Statut final** : la migration Quick Hunter / Quick Shaman est finalisée.
- [x] **Validation fonctionnelle** : tous les points de la checklist Hunter/Shaman ont été validés en jeu.
- [x] **UX additionnelle** : les quick frames disposent désormais d’une poignée de masquage/réaffichage semi-visible, persistée après reload, sans réintroduire de wrapper legacy.