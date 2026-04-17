# Plan de nettoyage de `Core/MultiBotInit.lua`

Document de cadrage pour alléger durablement `Core/MultiBotInit.lua` pendant la migration ACE3 de MultiBot.

> Objectif : transformer `Core/MultiBotInit.lua` en fichier de bootstrap/composition minimale, en déplaçant les responsabilités UI métier dans `UI/` et les helpers transversaux dans des modules partagés dédiés.

---

## Principes directeurs

### 1. Une vraie migration ACE3, pas un emballage de legacy
- **Interdit** : créer une fenêtre AceGUI qui contient simplement une ancienne frame legacy.
- **Attendu** : recréer le contenu de la frame dans une vraie fenêtre AceGUI, avec une structure moderne, tout en conservant la logique fonctionnelle existante.
- **Conséquence** : chaque écran migré doit vivre dans son propre fichier `UI/`.

### 2. `Core/MultiBotInit.lua` ne doit plus être un fourre-tout UI
À terme, `Core/MultiBotInit.lua` doit se limiter à :
- l’initialisation des briques globales strictement nécessaires ;
- la composition minimale du layout principal ;
- l’appel vers les modules `UI/` spécialisés ;
- éventuellement quelques helpers **vraiment transversaux** tant qu’ils n’ont pas encore été déplacés.

### 3. Séparer systématiquement trois types de responsabilités
- **Bootstrap Core** : initialisation globale, flags, points d’entrée.
- **UI métier** : Attack, Flee, Beast, Creator, Main, RTSC, GroupActions, etc.
- **UI partagée** : helpers AceGUI, persistance de position, popup host, tooltips cachés, styles communs.

---

## Constat actuel

Le fichier `Core/MultiBotInit.lua` contient encore un mélange de :
- helpers transversaux (`TimerAfter`) ;
- fonctions UI déjà encapsulées (`BuildAttackUI`, `BuildFleeUI`, `BuildFormationUI`, `BuildFilterUI`, `BuildRosterUI`, `BuildGmUI`, `ShowDeleteSVPrompt`) ;
- gros blocs UI encore écrits en top-level (`Beast`, `Creator`, `Main`, `GroupActions`, `RTSC`, etc.) ;
- infrastructure partagée utilisée par les écrans Quests/GameObjects modernes (`GetLocalizedQuestName`, résolution AceGUI, close/hide, ESC, persistance de position, popup host).

La tranche **Quests/GameObjects** est déjà bien avancée côté extraction structurelle :
- les écrans ont leur fichier dédié dans `UI/` ;
- le menu Quests est déjà extrait ;
- un module partagé `UI/MultiBotQuestUIShared.lua` existe déjà.

En revanche, le **socle partagé Quests/Ace3** vit encore dans `Core/MultiBotInit.lua`, ce qui maintient un couplage inutile entre les nouvelles frames Ace3 et `Init`.

---

## Cible d’architecture

### Rôle cible de `Core/MultiBotInit.lua`
À la fin du nettoyage, `Core/MultiBotInit.lua` doit idéalement :
- créer le conteneur principal (`MultiBar`) et ses zones racines si cela reste le bon point d’entrée ;
- déléguer la construction des sous-zones à des modules `UI/` ;
- initialiser le menu Quests via son module dédié ;
- ne plus contenir de gros blocs métier ni de helpers UI partagés complexes.

### Répartition cible des responsabilités

#### Core
- `Core/MultiBotInit.lua`
  - bootstrap minimal ;
  - layout racine ;
  - appels d’initialisation vers les modules UI.

#### UI métier
- `UI/MultiBotAttackUI.lua`
- `UI/MultiBotFleeUI.lua`
- `UI/MultiBotFormationUI.lua`
- `UI/MultiBotBeastUI.lua`
- `UI/MultiBotCreatorUI.lua`
- `UI/MultiBotUnitsUI.lua` *(ou découpage plus fin si nécessaire)*
- `UI/MultiBotUnitsFilterUI.lua`
- `UI/MultiBotUnitsRosterUI.lua`
- `UI/MultiBotMainUI.lua`
- `UI/MultiBotGroupActionsUI.lua`
- `UI/MultiBotGmUI.lua`
- `UI/MultiBotRTSCUI.lua`
- `UI/MultiBotMinimap.lua`

#### UI partagée
- `UI/MultiBotAceUI.lua` *(nom suggéré)*
  - résolution AceGUI ;
  - host de popup ;
  - close => hide ;
  - fermeture ESC ;
  - persistance de position ;
  - éventuels helpers communs de prompt/fenêtres.
- `UI/MultiBotQuestUIShared.lua`
  - styles, rendu de lignes, liens de quêtes, tri, agrégation, etc.

#### Helpers transversaux hors UI métier
- `TimerAfter`
  - à conserver dans un espace partagé transversal ;
  - à **ne pas** ranger dans un module UI métier.

---

## Priorité recommandée

### Phase 1 — Finaliser proprement la tranche Quests / GameObjects
C’est la priorité, car elle correspond directement au **Milestone 8**.

#### À sortir de `Core/MultiBotInit.lua` en premier
Créer un module partagé de type `UI/MultiBotAceUI.lua` pour accueillir :
- `ensureHiddenTooltip`
- `GetLocalizedQuestName`
- `getUniversalPromptAceGUI`
- `resolveAceGUI`
- `setAceWindowCloseToHide`
- `registerAceWindowEscapeClose`
- `bindAceWindowPosition`
- `createAceQuestPopupHost`

#### Résultat attendu
- Les frames Quests/GameObjects modernes deviennent dépendantes d’un module partagé UI, pas de `Init`.
- `Core/MultiBotInit.lua` ne garde plus pour Quests que :
  - les flags globaux strictement nécessaires ;
  - la création de `tRight` ;
  - l’appel à `MultiBot.InitializeQuestsMenu(tRight)`.

#### Règle de migration
Aucune frame Quests/GameObjects ne doit réintroduire une ancienne frame legacy encapsulée dans AceGUI.

---

### Phase 2 — Extraire les modules déjà bien encapsulés
Ce sont les sorties les moins risquées, car le code est déjà structuré en fonctions nommées.

#### Ordre recommandé
1. `MultiBot.BuildAttackUI` → `UI/MultiBotAttackUI.lua`
2. `MultiBot.BuildFleeUI` → `UI/MultiBotFleeUI.lua`
3. `MultiBot.BuildFilterUI` → `UI/MultiBotUnitsFilterUI.lua`
4. `MultiBot.BuildRosterUI` → `UI/MultiBotUnitsRosterUI.lua`
5. `MultiBot.BuildGmUI` + `MultiBot.ShowDeleteSVPrompt` → `UI/MultiBotGmUI.lua`
6. `MultiBot.Minimap_Create` + `MultiBot.Minimap_Refresh` → `UI/MultiBotMinimap.lua`

#### Pourquoi cet ordre ?
- faible risque de régression structurelle ;
- gain rapide en lisibilité ;
- réduction immédiate de la taille de `Init.lua`.

---

### Phase 3 — Extraire les gros blocs top-level encore bruts
Ces blocs sont prioritaires d’un point de vue architecture, même s’ils demandent plus de travail qu’un simple copier/déplacer.

#### Blocs à traiter
- **Beast**
  - bouton principal ;
  - frame dédiée ;
  - boutons Release / Revive / Heal / Feed / Call.
- **Creator**
  - `GENDER_BUTTONS`
  - `CLASS_BUTTONS`
  - `AddClassButton`
  - frame Creator ;
  - boutons Inspect / Init.
- **GroupActions**
  - Drink / Release / Revive / Summon.
- **Main**
  - Coords / Masters / RTSC / Raidus / Creator / Beast / Expand / Release / Stats / Reward / Reset / Actions.
- **RTSC**
  - frame ;
  - selector ;
  - save/go slots ;
  - rôles ;
  - groupes ;
  - browse.
- **Units hors Filter/Roster**
  - bouton principal ;
  - bannière Alliance/Horde ;
  - browse/pagination ;
  - PvP stats ;
  - AllBotsCommands ;
  - Invite.
- **Stats bootstrap**
  - initialisation de `MultiBot.stats` et des panneaux `party1..party4`.

#### Règle d’implémentation
Quand un bloc top-level est extrait, il faut de préférence :
- l’encapsuler dans une API explicite (`Initialize...`, `Build...`, `Create...`) ;
- limiter les écritures implicites dans des globales ;
- centraliser les tables de configuration en haut du module ;
- utiliser un style Lua plus moderne et plus déclaratif quand c’est possible.

---

## Points de vigilance

### 1. `BuildFormationUI`
C’est une bonne candidate à sortir, mais pas forcément la plus urgente tant que les blocs `Beast` et `Creator` voisins restent inline. Son extraction seule allégerait peu la cohérence d’ensemble.

### 2. `TimerAfter`
Ne pas le déplacer dans un fichier UI métier. Si une extraction est faite, la cible doit être un helper partagé de niveau Core/commun.

### 3. Helpers Ace/tooltip/popup host
Ils doivent sortir de `Init`, mais **pas** aller dans un fichier métier comme `AttackUI` ou `RTSCUI`. Ce sont des briques partagées.

### 4. Découpage de `Units`
Le bloc `Units` ne doit probablement pas finir dans un seul très gros fichier. Un sous-découpage en plusieurs modules peut être préférable :
- `UnitsRoot`
- `UnitsFilter`
- `UnitsRoster`
- `UnitsBrowse` / `UnitsCommands`

Statut actuel :
- [x] `UnitsRoot` (bouton principal, frame racine, bannière, contrôle, PvP stats, AllBotsCommands, Invite, browse/pagination)
- [x] `UnitsFilter`
- [x] `UnitsRoster`
- [ ] `UnitsBrowse` / `UnitsCommands` raffinés davantage si un second module dédié apporte un vrai gain de lisibilité

### 5. Conserver la parité fonctionnelle
Chaque extraction doit préserver :
- les commandes envoyées ;
- les clics gauche/droit ;
- les sélections d’icônes ;
- les états d’affichage/masquage ;
- les comportements conditionnels liés à la cible/groupe/raid.

---

## Ordre de travail recommandé

### Ordre global conseillé
1. **Extraire le socle partagé Quests/Ace3 hors de `Init`**
2. **Extraire `GroupActions`**
3. **Extraire `BuildAttackUI`**
4. **Extraire `BuildFleeUI`**
5. **Extraire `BuildFilterUI`**
6. **Extraire `BuildRosterUI`**
7. **Extraire `Beast`**
8. **Extraire `Creator`**
9. **Extraire `BuildGmUI` + `ShowDeleteSVPrompt`**
10. **Extraire `Main`**
11. **Extraire `RTSC`**
12. **Reprendre le bloc `Units` restant**
13. **Finaliser `Minimap` si pas déjà fait avant**

### Pourquoi cet ordre ?
- il respecte le Milestone 8 en premier ;
- il supprime rapidement les dépendances Quests modernes envers `Init` ;
- il commence ensuite par des modules simples ou à forte valeur de nettoyage ;
- il reporte les plus gros noyaux de composition (`Main`, `RTSC`, `Units`) quand le terrain est déjà assaini.

---

## Définition de “done” pour le nettoyage de `MultiBotInit.lua`

Le nettoyage pourra être considéré comme réussi quand :
- `Core/MultiBotInit.lua` n’héberge plus de gros blocs UI métier top-level ;
- les écrans/fonctionnalités principales vivent chacun dans leur fichier `UI/` dédié ;
- les helpers AceGUI/tooltip/popup host sont dans un module partagé ;
- `TimerAfter` n’est plus mélangé au code UI métier ;
- les migrations ACE3 concernées sont de **vraies recodes d’écrans**, pas des wrappers de frames legacy ;
- la lisibilité du bootstrap devient claire et maintenable.

---

## Checklist de suivi

### Milestone 8 — Quests / GameObjects
- [x] Extraire les helpers Quests/Ace3 de `Core/MultiBotInit.lua`
- [x] Garder `UI/MultiBotQuestUIShared.lua` centré sur le rendu partagé, pas sur le host Ace3
- [x] Vérifier qu’aucune frame legacy n’est ré-embarquée dans une fenêtre AceGUI
- [x] Vérifier la parité visuelle et fonctionnelle en jeu

### Nettoyage structurel de `Init`
- [x] Extraire `GroupActions`
- [x] Extraire `BuildAttackUI`
- [x] Extraire `BuildFleeUI`
- [x] Extraire `BuildFormationUI`
- [x] Extraire `BuildFilterUI`
- [x] Extraire `BuildRosterUI`
- [x] Extraire `Beast`
- [x] Extraire `Creator`
- [x] Extraire `BuildGmUI`
- [x] Extraire `Minimap_Create` / `Minimap_Refresh`
- [x] Extraire `ShowDeleteSVPrompt`
- [x] Extraire `Main`
- [x] Extraire `RTSC`
- [x] Extraire le bootstrap `stats`
- [x] Sortir le bloc `Left/Mode/Stay/Follow`
- [ ] Rationaliser le bloc `Units` restant
- [x] Extraire `TimerAfter` dans `Core/MultiBotAsync.lua` et basculer les usages partagés sur `MultiBot.TimerAfter`

---

## Résumé décisionnel

### À faire tout de suite
- Extraire BuildFormationUI (le plus net).
- Extraire le bootstrap stats.
- Sortir le bloc Left/Mode/Stay/Follow pour arriver à un Init presque 100% composition.
- validation en jeu du slice Quests/GameObjects finalisée (parité fonctionnelle + visuelle) ;
- conserver la règle “pas de wrapper legacy dans une fenêtre AceGUI”.

### À faire ensuite
- **TODO (plus tard)** : Rationaliser le bloc `Units` restant (découpage Browse/Commands/refresh) ;
- reprendre les éventuels raffinements de style/structure non bloquants après validation Milestone 8.