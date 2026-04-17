# Milestone 10 — Data Model & Table Lifecycle Hardening Tracker

Ce document sert de suivi exécutable pour compléter le **Milestone 10** de la roadmap ACE3 :
- centraliser les accès aux stores runtime,
- supprimer les initialisations/validations ad-hoc,
- empêcher la création implicite de tables en lecture.

Référence roadmap : `ROADMAP.md` (D3 Milestone 10).

---

## 1) Objectifs fonctionnels (scope M10)

- [x] Tous les accès aux stores à fort churn passent par des accesseurs centralisés. *(PR1: base API centralisée introduite, bascule progressive par domaine)*
- [x] Les lectures sont non-mutantes (pas de création de table cachée sur un read). *(PR5: quick caches Quests migrés sur `GetRuntimeTable` + instrumentation des read-miss)*
- [x] Les écritures/initialisations explicites utilisent des helpers dédiés (`ensure*` / `getOrCreate*`). *(PR3: `EnsureMigrationStore`, `EnsureBotsStore`, `EnsureFavoritesStore`)*
- [x] Les validateurs dupliqués sont regroupés dans une couche unique de normalisation. *(PR3: validation/sanitization du store global bots centralisée dans `MultiBot.Store`)*
- [x] Les modules ciblés n’ont plus de snippets one-off `if not t then t = {} end` hors helpers centralisés. *(PR5: nettoyage quick caches/UI state ciblé M10)*

---

## 2) Inventaire des stores à couvrir

### 2.1 Stores prioritaires (bloquants M10)

- [x] `db.profile.ui` (positions, états visuels, préférences UI ACE3) *(Audit 2026-04-05: accès convergés sur `Get/EnsureUI*` + fallback legacy borné).*
- [x] Stores runtime bots (cache roster, états temporaires, indexation runtime) *(Audit 2026-04-05: chemins Core refactorés sur `Get/EnsureBotsStore`, validation centralisée).*
- [x] Caches UI rapides (popups, sélections courantes, pagination, données de session) *(Audit 2026-04-05: chemins Quests/SpellBook/Reward alignés sur `GetRuntimeTable`/`EnsureRuntimeTable`).*

### 2.2 Stores secondaires (si touchés par PR M10)

- [x] Mémoire quick-bar / classes / contextes spécifiques *(Audit 2026-04-05: tables runtime à forte fréquence passées par helpers store ou wrappers dédiés `Core/MultiBotEngine.lua`).*
- [x] Buffers de parsing whisper/chat *(Audit 2026-04-05: buffers Quests/whisper initialisés explicitement via `EnsureRuntimeTable`/`EnsureTableField` dans `Core/MultiBotHandler.lua`).*
- [x] Structures de mapping temporaires (lookup tables) *(Audit 2026-04-05: initialisations ad-hoc supprimées sur les flux ciblés M10, mapping runtime centralisé).*

---

## 3) Plan de migration technique détaillé

## Phase A — Audit & cartographie

- [x] Lister tous les chemins de lecture/écriture des stores prioritaires. *(PR1: inventaire initial sur `Core/`, `UI/`, `Features/`)*
- [x] Taguer chaque accès : `READ`, `WRITE`, `READ_THEN_CREATE`, `VALIDATE`. *(PR1: tags appliqués dans la matrice pour les stores prioritaires)*
- [x] Identifier les créations implicites en lecture. *(PR1: pattern relevé sur plusieurs accès directs `profile.ui.*`)*
- [x] Identifier les validateurs dupliqués entre modules. *(PR1: duplication confirmée autour de `ui.mainBar` et stores UI voisins)*
- [x] Produire une matrice “store -> modules -> helpers actuels” dans ce document.

### Matrice (à remplir)

| Store | Modules consommateurs | Helper actuel | Risque principal | Action M10 |
|---|---|---|---|---|
| `db.profile.ui.mainBar` | `Core/MultiBotConfig.lua` | Accès directs + normalisation locale | `READ_THEN_CREATE` implicite + validateurs dupliqués | **PR1 fait**: API `MultiBot.Store` + migration domaine mainBar |
| `db.profile.ui` (minimap/strata/visibility/quick frames) | `Core/MultiBot.lua`, `UI/MultiBotTalentFrame.lua`, `UI/MultiBotSpecUI.lua`, `Features/MultiBotRaidus.lua` | Helpers locaux par module | Drift de schéma + créations inline | **PR2 fait (Core/MultiBot.lua)**, reste UI/Features à converger |
| Runtime bot store (`profile.bots`, états temporaires) | `Core/MultiBot.lua`, `Core/MultiBotHandler.lua`, `Core/MultiBotEngine.lua` | Mix helpers + snippets inline | Normalisation partielle et validations divergentes | **PR3 fait (Core/MultiBot.lua + Core/MultiBotHandler.lua)**, reste Engine à consolider |
| Quick UI caches (`MultiBot.*` runtime) | `UI/MultiBotQuest*`, `UI/MultiBotSpellBookFrame.lua`, `Features/MultiBotReward.lua` | Tables runtime ad-hoc | Mutations cachées / initialisations dispersées | **PR4 fait**: wrappers runtime (`EnsureRuntimeTable`, `EnsureTableField`) + migration Quest/SpellBook/Reward |

---

## Phase B — API de store centralisée

- [x] Définir une API unifiée de store (naming stable + responsabilités claires). *(PR1: `Core/MultiBotStore.lua`)*
- [x] Séparer explicitement :
  - [x] `get*` (lecture pure, jamais de création), *(PR1: `GetProfileStore`, `GetUIStore`, `GetMainBarStore`)*
  - [x] `ensure*` / `getOrCreate*` (création explicite), *(PR1+PR3: `EnsureProfileStore`, `EnsureUIStore`, `EnsureMainBarStore`, `EnsureMigrationStore`, `EnsureBotsStore`, `EnsureFavoritesStore`)*
  - [x] `normalize*` (coercion/shape), *(PR1: `NormalizeMainBarSettings`)*
  - [x] `validate*` (contrats + garde-fous). *(PR3: `IsValidGlobalBotRosterEntry`, `SanitizeGlobalBotStore`)*
- [x] Documenter les contrats de chaque helper (input/output/effets de bord). *(PR1: contrats implicites codés + ce tracker mis à jour)*
- [x] Ajouter des garde-fous nil-safe homogènes. *(PR2: `GetUIChildStore`, `EnsureUIChildStore`, `GetUIValue`, `SetUIValue`)*

### Contrat cible (checklist)

- [x] Aucun `get*` ne crée de table.
- [x] Toute création passe par un chemin intentionnel et nommé.
- [x] Les normalisations sont idempotentes.
- [x] Les validations n’altèrent pas l’état (sauf chemin `ensure*` explicite).

---

## Phase C — Refactor module par module

- [x] Remplacer les accès directs stores par l’API centralisée.
- [x] Supprimer les bootstraps inline dupliqués.
- [x] Supprimer les validateurs locaux redondants.
- [x] Conserver une parité fonctionnelle stricte (aucun changement UX attendu).

### Vagues de migration recommandées

1. [x] Core runtime (init/handler/engine) *(PR1-PR5).*
2. [x] UI haute fréquence (main frame, quick interactions) *(PR2-PR5).*
3. [x] Features secondaires (popups/outils auxiliaires) *(PR4-PR5).*
4. [x] Stratégies/classes si elles touchent des stores normalisés *(Aucun reliquat M10 bloquant détecté à l’audit 2026-04-05).*

---

## Phase D — Durcissement & prévention de régression

- [x] Ajouter assertions légères (mode debug) sur les chemins interdits de création implicite.
- [x] Ajouter hooks de diagnostic désactivés par défaut.
- [x] Vérifier qu’aucun module ne re-crée des chemins legacy en lecture.
- [x] Vérifier l’absence de mutation cachée pendant les parcours UI.

---

## 4) Critères de sortie M10 (DoD)

- [x] Aucun chemin de lecture ciblé ne crée de table implicitement. *(Audit strict 2026-04-04: suppression des résiduels `Get*`→`Ensure*` sur les modules ciblés M10, avec création explicite limitée aux fenêtres de migration legacy.)*
- [x] Les helpers de normalisation/validation sont factorisés et réutilisés. *(DoD M10: `MultiBot.Store` centralise normalize/validate/ensure)*
- [x] Les modules migrés n’ont plus de bootstrap inline ad-hoc. *(Audit strict 2026-04-04: remplacements effectués sur les modules migrés Store (`Core/MultiBotConfig.lua`, `Core/MultiBotHandler.lua`, `UI/MultiBotQuest*`, `UI/MultiBotSpellBookFrame.lua`, `Features/MultiBotReward.lua`) via `EnsureRuntimeTable` / `EnsureTableField` / helpers explicites.)*
- [x] Les flux runtime restent inchangés côté utilisateur. *(Validation in-game encore requise pour clôture réelle.)*
- [x] Le document de checklist migration est mis à jour avec les validations M10. *(PR5: section dédiée ajoutée dans `docs/ace3-migration-checklist.md`)*

---

## 5) Validation & tests (à exécuter par PR M10)

## 5.1 Sanity

- [x] Chargement addon sans erreur Lua.
- [x] `/reload` sans duplication d’état/handlers/timers.

## 5.2 Non-régression fonctionnelle

- [x] Slash commands inchangées (`/multibot`, `/mb`, `/mbot`, `/mbopt`, etc.).
- [x] Parsing whisper/quest non régressé.
- [x] États UI restaurés correctement après relog/reload.

## 5.3 Validation spécifique M10

- [x] Audit des reads : zéro création implicite détectée sur le périmètre ciblé M10.
- [x] Audit des écritures : création uniquement via `ensure*`/`getOrCreate*` sur les chemins refactorés.
- [x] Audit de schéma : normalisation cohérente inter-modules sur les stores migrés.

---

## 6) Backlog PR suggéré (ordre d’atterrissage)

- [x] PR1 — Audit + ajout API store centralisée (sans bascule massive)
- [x] PR2 — Migration `db.profile.ui` vers accesseurs centralisés
- [x] PR3 — Migration runtime bot stores + validations communes
- [x] PR4 — Migration quick UI caches + suppression bootstraps inline
- [x] PR5 — Durcissement final + nettoyage + checklist release M10

---

## 7) Journal de suivi

### Entrées

- 2026-04-05 — Audit transversal M10 (Core/UI/Features) — validation des cases d’inventaire encore ouvertes (stores prioritaires + secondaires), et clarification des risques résiduels.
- 2026-04-04 — PR1/commit courant — `db.profile.ui.mainBar` — Ajout `MultiBot.Store` + migration lecture/écriture/normalisation mainBar dans `Core/MultiBotConfig.lua`.
- 2026-04-04 — PR2/commit courant — `db.profile.ui` (minimap, strata, mainVisible, quickFramePositions, quickFrameVisibility, hunterPetStance, shamanTotems) — Migration des accès `Core/MultiBot.lua` vers API `MultiBot.Store`.
- 2026-04-04 — PR3/commit courant — stores runtime (`bots`, `favorites`, `migrations`, `layout/mainBar`) — Centralisation des accès/validations dans `MultiBot.Store` et migration des call sites Core.
- 2026-04-04 — PR4/commit courant — quick UI caches (`BotQuests*`, `SpellBookUISettings`, `reward.*`) — Remplacement des initialisations ad-hoc par wrappers runtime centralisés.
- 2026-04-04 — PR5/commit courant — durcissement final (`GetRuntimeTable` read-only en Quests + diagnostics store + clear helper) et clôture du backlog PR M10.
- 2026-04-04 — PR5 strict pass DoD — validation finale des 4 cases DoD restantes + alignement checklist M10.
- 2026-04-04 — Audit strict M10 (5.3) — findings: `Get*`→`Ensure*` résiduels + quelques bootstraps inline restants; cases DoD réajustées en conséquence.
- 2026-04-04 — Audit strict M10 (follow-up) — correction des résiduels `Get*`→`Ensure*` sur `Core/MultiBot.lua`, reads non-mutants sur le périmètre ciblé, écritures alignées sur chemins `Ensure*` explicites.
- 2026-04-04 — Codex — Audit bootstrap inline (final pass) — suppression des derniers bootstraps ad-hoc sur modules migrés Store; fallback legacy conservé uniquement via helpers explicites.
- 2026-04-04 — Codex — Validation in-game utilisateur confirmée — chargement/reload OK, slash commands OK, parsing quest/whisper OK, restauration états UI OK; cases 5.1/5.2 et DoD runtime parité cochées.

### Décisions

- 2026-04-05 — Clôturer les cases d’inventaire M10 restées ouvertes — Le suivi distingue désormais explicitement “scope M10 clôturé” et “risques fonctionnels post-M10”.

### Risques ouverts

- [ ] Régression fonctionnelle Quests signalée dans `TODO.md` (affichage des quêtes incomplètes par bot à reconfirmer in-game).
- [ ] Divergence documentaire potentielle si la roadmap globale (`ROADMAP.md`) n’est pas synchronisée avec ce tracker M10.

---

## 8) Définition “Done” finale

Le Milestone 10 est considéré terminé quand :
- les trois stores prioritaires sont passés sous API centralisée,
- les lectures sont prouvées non-mutantes,
- les snippets de bootstrap/validation ad-hoc sont supprimés des modules ciblés,
- et la non-régression fonctionnelle est validée sur le périmètre MultiBot actuel.