# MultiBot ACE3 — Main Bar Layout Migration Tracker

## Objectif global
Rendre la barre principale configurable et sûre à manipuler, avec une approche incrémentale en **2 phases**.

---

## Phase 1 — Plan ajusté (simple, rapide, propre)

### 1) Lock par défaut + déplacement sécurisé
- Par défaut : **tous les boutons sont verrouillés**.
- Déplacement autorisé uniquement si :
  - touche **Ctrl** enfoncée ;
  - **clic droit** maintenu sur le bouton Main (déplacement de la barre).
- Bénéfice : éviter les déplacements accidentels.

✅ Implémenté (lock persistant + Ctrl + clic droit).

#### Pourquoi c’est simple à intégrer
- La base drag existe déjà (barre principale en drag + infra drag générique).

---

### 2) Modèle de sauvegarde unique (pas de variantes)
- Un seul objet : `mainLayout` (positions des boutons principaux).
- Format minimal par bouton : `{ x, y, visible }`.
- Aucune notion PvE/PvP/rôle/spec.

#### Base existante réutilisable
- Le système de persistance layout est déjà disponible :
  - `GetSavedLayoutValue`
  - `SetSavedLayoutValue`

✅ Implémenté pour :
- position de la barre ;
- layouts de swap boutons (par contexte).

---

### 3) Boutons `Save` / `Export` / `Import` / `Reset`
- **Save** : écrit les positions courantes dans la sauvegarde.
- **Export** : sérialise en string compacte (copiable).
- **Import** : colle la string et applique immédiatement.
- **Reset** : revient aux positions par défaut.

#### Cohérence existante
- Les positions par défaut existent déjà dans `resetDefaultWindowPositions`.

✅ Implémenté :
- export/import fonctionnels via bibliothèque globale + payload ;
- reset des clés layout (`MultiBarPoint` + `ButtonLayout:*`) avec remise en position par défaut de la barre principale ;
- actions exposées en Options (legacy + Ace3) et via slash (`/mblreset`).


---

### 4) Réorganisation des boutons de la Main Bar (nouvelle fonctionnalité)
#### Objectif
Permettre de **déplacer/réordonner les boutons de la barre principale** pour adapter l’ergonomie :
- exemple : inverser `Attack` et `Control` (ou tout autre bouton principal).

#### Interaction utilisateur
- Entrer en mode réorganisation via **Shift + clic droit** sur un bouton de la Main Bar.
- Sélection source puis cible via **Shift + clic droit** pour échanger leurs positions (swap).
- Afficher un feedback visuel minimal :
  - slot source/survol;
  - aperçu de permutation;
  - confirmation à la fin du drop.

#### Persistance
- Sauvegarder l’ordre des boutons dans la sauvegarde de layout par profil.
- Format actuel : mapping sérialisé `buttonId -> x,y` par contexte (`ButtonLayout:<context>`).
- Compatibilité : fallback automatique sur l’ordre par défaut si une clé manque.

#### Contraintes
- Ne pas casser les callbacks existants (`doLeft`, `doRight`, états toggle, disable).
- Préserver les tooltips et icônes.
- Garder le comportement de déplacement de la **barre elle-même** séparé (Ctrl + clic droit selon lock).

✅ Implémenté partiellement :
- swap actif sur les groupes de boutons configurés ;
- état visuel source/survol + message d’aperçu léger avant validation ;
- les frames de menus verticaux liées suivent leur bouton principal ;
- bouton **Main** reste fixe ;
- bouton **Units** laissé fixe (pas de swap) pour stabilité.

---

### 5) Import A -> B (cas d’usage principal)
- Sur perso A : `Export` → copier la string.
- Sur perso B : `Import` → coller la string → `Apply` → `Save`.
- Optionnel : checksum/version pour valider la compatibilité de la string.
- Le payload doit inclure :
  - position de la barre;
  - ordre personnalisé des boutons;
  - visibilité/flags nécessaires au rendu.

✅ Implémenté :
- export d’un payload versionné (`MBLAYOUT1`) incluant lock déplacement + position barre + layouts `ButtonLayout:*` ;
- import avec application immédiate (barre principale + layouts de swap déjà enregistrés) ;
- sauvegarde **globale** des layouts exportés indexés par `NomJoueur-Royaume` ;
- stockage global dans `MultiBotGlobalSave.savedLayoutsByPlayer` (scope compte, pas par personnage) ;
- import via **liste déroulante** des layouts sauvegardés (Options legacy + Ace3) ;
- actions exposées dans Options (legacy + Ace3) et slash commands (`/mblx`, `/mbll`, `/mblio <owner>`, `/mbli <payload>`, `/mblp [owner]`, `/mbldel <owner>`, `/mblreset`).

---

### 6) UX minimale mais propre
- Message visuel :
  - `Locked` par défaut ;
  - `Hold Ctrl + Right Click to move bar`.
  - `Hold Shift + Right Click to move buttons`.
- Pendant drag : afficher les coordonnées.
- Fin de drag : autosave (ou save manuel, selon choix final).

✅ Implémenté (messages lock/swap + aperçu + hint explicite si drag refusé + autosave layout).

---

### 7) Checkbox `Verrouiller déplacement barre`
#### Objectif
Ajouter dans le panneau Options une case simple :
- **Cochée** → barre principale verrouillée ;
- **Décochée** → barre déplaçable.

#### Pourquoi c’est rapide
- Le panneau options a déjà des `CheckBox` (legacy + ACE3).
- Le drag de la barre principale existe déjà (actuellement right-drag).
- Il suffit d’ajouter une condition de lock avant d’autoriser le déplacement.
- Le booléen peut être persisté comme les autres options UI.

#### Comportement UX proposé
- Valeur par défaut : `verrouillé = true`.
- Tooltip : `Décoche pour autoriser le déplacement de la barre principale`.
- Position : à côté des toggles UI existants dans le panneau Options.

---

## Phase 2 — Slots supplémentaires pour boutons custom

### Objectif
Ajouter des **emplacements vides** sur la barre principale pour y attacher des boutons custom.

### Approche propre
- Définir un nombre de slots configurables (`N`).
- Chaque slot = bouton standard MultiBot (même API `newButton`, `setPoint`, etc.).
- Slots stockés/chargés via la persistance layout existante.
- Le binding d’action du slot sera traité dans une phase dédiée :
  - menu de choix action,
  - macro command,
  - etc.

### Pourquoi plus tard
Cette partie touche :
- UX,
- modèle de données,
- assignation d’actions.

=> Mieux de la sortir du correctif lock/unlock pour garder la Phase 1 légère et livrable rapidement.

---

## Statut
- [x] Phase 1 — Finalisée
  - [x] lock déplacement barre (Ctrl + clic droit)
  - [x] checkbox options lock/unlock
  - [x] persistance layout de déplacement
  - [x] swap boutons Shift + clic droit (avec suivi des menus verticaux liés)
  - [x] export/import des layouts entre personnages
- [ ] Phase 2 — Non démarrée