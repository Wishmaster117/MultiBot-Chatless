# Milestone 11 — Inventaire des boucles et timers existants

Date d'audit: 2026-04-05.
Objectif: établir la cartographie complète des mécanismes temporels avant convergence scheduler (M11).

## 1) Boucles périodiques (`OnUpdate` / compteurs elapsed)

| ID | Fichier | Mécanisme | Portée | Usage principal | Fréquence / déclenchement | Nature M11 (pré-classement) |
|---|---|---|---|---|---|---|
| P1 | `Core/MultiBotHandler.lua` | `MultiBot:SetScript("OnUpdate")` + `HandleOnUpdate` | Runtime global | Pilote des automations `stats`, `talent`, `invite`, `sort` via compteurs `elapsed/interval` | Chaque frame (gating par intervalle configurable) | **Hot path**: conserver local, harmoniser le pilotage |
| P2 | `Core/MultiBotThrottle.lua` | Frame `OnUpdate` avec token-bucket | Runtime global | Throttle de `SendChatMessage` (débit + burst) + flush file d'attente | Chaque frame | **Hot path**: conserver local (critique anti-spam) |
| P3 | `UI/MultiBotMainUI.lua` | `HookScript("OnUpdate")` sur `multiBar` | UI principal | Autohide de la barre principale (interaction souris + délai) | Polling périodique avec intervalle interne (`MAINBAR_AUTOHIDE_UPDATE_INTERVAL`) | **Candidat** centralisation partielle (si sans régression UX) |
| P4 | `Features/MultiBotRaidus.lua` | Frame `OnUpdate` dédié feedback | UI Raidus | Extinction retardée du texte de feedback drag/drop | Temporaire pendant `RAIDUS_FEEDBACK_DURATION` | **Candidat safe** vers helper timer one-shot |
| P5 | `Features/MultiBotRaidus.lua` | Driver `OnUpdate` pulse slot | UI Raidus | Animation courte de pulse lors d'un drop | Temporaire pendant `RAIDUS_DROP_ANIM_DURATION` | **À garder local** (animation visuelle) |
| P6 | `UI/MultiBotSpecUI.lua` | Frame `OnUpdate` (0.2s) | UI Spec | Chaînage `talents` puis `talents spec list` | Temporaire (désarmé après seuil) | **Candidat safe** vers `TimerAfter` |
| P7 | `UI/MultiBotMinimap.lua` | `OnUpdate` activé durant drag | UI Minimap | Mise à jour angle minimap pendant déplacement bouton | Uniquement pendant drag | **À garder local** (interaction directe) |
| P8 | `UI/MultiBotHunterQuickFrame.lua` | `OnUpdate` one-shot sur preview model | UI Hunter Quick | Initialisation différée de scale/facing/display du modèle 3D | Une frame puis auto-nil | **Candidat safe** vers helper one-shot |
| P9 | `Core/MultiBotEngine.lua` | `_clickBlockerTicker` `OnUpdate` one-shot | Runtime/UI engine | Coalescence de demandes de recalcul click-blocker | Une frame puis flush queue | **Candidat safe** vers scheduler frame-next-tick |
| P10 | `Core/MultiBotAsync.lua` | Fallback `OnUpdate` si pas de `C_Timer.After` | Utilitaire global | Implémentation de `MultiBot.TimerAfter` en environnement legacy | Temporaire, selon délai demandé | **Base utilitaire**: conserver (compatibilité) |
| P11 | `Core/MultiBot.lua` | Fallback local `C_Timer_After` dans GM detect | Runtime système | Re-lance différée `RaidPool("player")` après détection compte | One-shot (0.2s) | **Duplication à converger** vers `MultiBot.TimerAfter` |

## 2) Timers différés one-shot (`MultiBot.TimerAfter`)

`MultiBot.TimerAfter` est défini/normalisé dans `Core/MultiBotAsync.lua` (utilise `C_Timer.After` si disponible, sinon fallback frame `OnUpdate`).

### 2.1 Répartition des appels par fichier

- `UI/MultiBotSpecUI.lua`: 6 appels
- `Core/MultiBotHandler.lua`: 4 appels
- `UI/MultiBotUnitsRootUI.lua`: 2 appels
- `UI/MultiBotTalentFrame.lua`: 2 appels
- `UI/MultiBotQuestsMenu.lua`: 2 appels
- `UI/MultiBotUnitsRosterUI.lua`: 1 appel
- `UI/MultiBotSpell.lua`: 1 appel
- `UI/MultiBotShamanQuickFrame.lua`: 1 appel
- `UI/MultiBotInventoryFrame.lua`: 1 appel
- `UI/MultiBotHunterQuickFrame.lua`: 1 appel
- `Core/MultiBotEngine.lua`: 1 appel

### 2.2 Usages fonctionnels identifiés

- **Quests / parsing / UI sync**: scheduling différé de rebuilds de listes et affichage progressif.
- **Roster / login / refresh**: retries légers au login et re-dispatch après initialisation UI.
- **Unités / guild roster**: retry différé pour peupler les données guilde/membres.
- **UI spécialisées** (Spec, Talent, Hunter/Shaman quick, Inventory, Spell): enchaînements asynchrones et refresh visuels/état.
- **Engine**: refresh inventaire bot avec délai optionnel.

## 3) Duplications et points de convergence prioritaires (entrée M11)

1. **Unifier tous les one-shot delay** sur `MultiBot.TimerAfter` (éviter les fallback locaux ad-hoc comme `C_Timer_After` inline de `Core/MultiBot.lua`).
2. **Documenter un owner unique par boucle périodique** (global runtime vs UI locale vs animation).
3. **Distinguer explicitement**:
   - boucles **hot path** à garder locales (throttle, automation core, drag handlers),
   - boucles **safe-to-centralize** (timeouts d'UI, retries one-shot, flush next-tick).

## 4) Vérifications techniques de l'audit

- Aucune occurrence `AceTimer` / `ScheduleTimer` / `ScheduleRepeatingTimer` active détectée dans `Core/`, `UI/`, `Features/`, `Strategies/`.
- Les mécanismes actuels reposent surtout sur:
  - `OnUpdate` périodique,
  - `MultiBot.TimerAfter` (wrapper unifié/fallback),
  - quelques timers one-shot inline historiques.

## 5) Sortie attendue pour la prochaine sous-étape M11

À partir de cet inventaire, la prochaine passe consiste à produire la **classification détaillée** (hot/local vs centralisable) avec décision par item (garder/migrer), puis plan PR séquencé de convergence.

## 6) Classification détaillée M11 (décision par item)

### 6.1 Boucles périodiques (`OnUpdate`)

| ID | Décision | Cible | Justification | Action PR |
|---|---|---|---|---|
| P1 (`Core/MultiBotHandler.lua`) | **Garder local** | `OnUpdate` existant | Boucle coeur automation avec gating d'intervalles; sensible latence/perf et ordre d'exécution | Documenter owner + vérifier bornes d'intervalle |
| P2 (`Core/MultiBotThrottle.lua`) | **Garder local** | `OnUpdate` token-bucket | Chemin critique anti-spam, nécessite débit frame-level et burst contrôlé | Ajouter garde-fous (visibilité queue / logs debug) sans changer l'algorithme |
| P3 (`UI/MultiBotMainUI.lua`) | **Garder local (M11)** | `OnUpdate` UI | Autohide dépend d'états souris/hover quasi-temps-réel; risque UX si timer discret | Encapsuler logique dans helper dédié + point de config unique |
| P4 (`Features/MultiBotRaidus.lua`) | **Migrer** | `MultiBot.TimerAfter` one-shot | Timeout visuel simple (extinction feedback), pas besoin de polling | Remplacer frame dédiée par one-shot annulable |
| P5 (`Features/MultiBotRaidus.lua`) | **Garder local** | `OnUpdate` animation | Pulse visuel court piloté à la frame; adaptation fluide | Isoler driver animation pour lisibilité/tests manuels |
| P6 (`UI/MultiBotSpecUI.lua`) | **Migrer** | Chaînage `MultiBot.TimerAfter` | Séquence asynchrone bornée (0.2s) déjà naturellement one-shot | Convertir en pipeline one-shot sans frame persistante |
| P7 (`UI/MultiBotMinimap.lua`) | **Garder local** | `OnUpdate` pendant drag | Interaction directe utilisateur, seulement actif pendant drag | Aucun changement fonctionnel; documenter cycle start/stop |
| P8 (`UI/MultiBotHunterQuickFrame.lua`) | **Migrer** | `MultiBot.TimerAfter(0, ...)` | Initialisation différée one-frame, exact match du besoin | Supprimer hook one-shot `OnUpdate` |
| P9 (`Core/MultiBotEngine.lua`) | **Migrer** | helper `NextTick` (sur `TimerAfter`) | Coalescence « frame suivante » assimilable à microtask | Créer utilitaire central `MultiBot.NextTick` + adoption |
| P10 (`Core/MultiBotAsync.lua`) | **Garder local (base)** | Wrapper central | Point d'abstraction/fallback legacy indispensable à M11 | Renforcer contrat API (doc + invariants) |
| P11 (`Core/MultiBot.lua`) | **Migrer** | `MultiBot.TimerAfter` | Duplication locale historique, augmente divergence comportementale | Supprimer fallback inline, appeler wrapper unique |

### 6.2 Timers différés (`MultiBot.TimerAfter`)

| Famille | Décision | Détails |
|---|---|---|
| Quests/parsing/UI sync | **Conserver via wrapper unique** | Garder `MultiBot.TimerAfter`; normaliser annulation et idempotence des refresh |
| Roster/login/retry | **Conserver via wrapper unique** | Uniformiser backoff léger (délais constants actuels) sans changer la logique métier |
| Unités/guild roster | **Conserver via wrapper unique** | Encadrer retries max et early-exit si données déjà présentes |
| UI spécialisées (Spec/Talent/Quick/Inventory/Spell) | **Conserver via wrapper unique** | Éviter `OnUpdate` temporaires si one-shot suffit |
| Engine (refresh inventaire) | **Conserver via wrapper unique** | Introduire `NextTick` pour les cas « prochaine frame » |

## 7) Plan PR séquencé de convergence M11

### PR-M11-1 — Fondations scheduler unifié
- **But**: verrouiller un point d'entrée unique.
- **Statut**: ✅ Implémenté le 2026-04-15.
- **Changements**:
  - Ajouter `MultiBot.NextTick(callback)` dans `Core/MultiBotAsync.lua` (implémenté via `MultiBot.TimerAfter(0, callback)` avec garde `type(callback) == "function"`).
  - Documenter le contrat: `TimerAfter`/`NextTick` sont les seules APIs de délai autorisées.
- **Critères d'acceptation**:
  - Aucune régression d'init/login.
  - Aucun appel direct nouveau à `C_Timer.After` hors `Core/MultiBotAsync.lua`.

### PR-M11-2 — Suppression des duplications runtime
- **But**: converger les one-shots historiques runtime.
- **Statut**: ✅ Implémenté le 2026-04-15.
- **Changements**:
  - Migrer P11 (`Core/MultiBot.lua`) vers `MultiBot.TimerAfter`.
  - Migrer P9 (`Core/MultiBotEngine.lua`) vers `MultiBot.NextTick`.
- **Critères d'acceptation**:
  - Comportement inchangé sur détection GM / refresh click-blocker.
  - Pas de double déclenchement observé.

### PR-M11-3 — Migration safe UI one-shot
- **But**: retirer les `OnUpdate` temporaires qui ne sont pas des animations continues.
- **Statut**: ✅ Implémenté le 2026-04-15.
- **Changements**:
  - Migrer P4 (`Features/MultiBotRaidus.lua`) vers one-shot timer.
  - Migrer P6 (`UI/MultiBotSpecUI.lua`) vers chaînage `TimerAfter`.
  - Migrer P8 (`UI/MultiBotHunterQuickFrame.lua`) vers `TimerAfter(0, ...)`.
- **Critères d'acceptation**:
  - Feedback visuel conservé (durées identiques).
  - Aucune frame/ticker orpheline après fermeture UI.

### PR-M11-4 — Stabilisation hot paths conservés
- **But**: figer explicitement ce qui reste en `OnUpdate` local.
- **Statut**: ✅ Implémenté le 2026-04-15.
- **Changements**:
  - Ajouter commentaires d'ownership et raison de conservation pour P1/P2/P3/P5/P7/P10.
  - Harmoniser constantes d'intervalle/nommage là où pertinent (sans changer les valeurs).
- **Critères d'acceptation**:
  - Débit/latence identiques en usage normal.
  - Aucun changement fonctionnel attendu.

## 8) Règles de validation M11

- Interdit: création de nouveaux wrappers locaux de délai (`C_Timer_After`, frames one-shot ad-hoc) hors `Core/MultiBotAsync.lua`.
- Autorisé:
  - `OnUpdate` local pour **hot path** runtime et interactions/animations frame-level.
  - `MultiBot.TimerAfter` / `MultiBot.NextTick` pour tout délai one-shot.
- Chaque migration doit vérifier:
  1. absence de régression UX (autohide, drag, pulse),
  2. absence de double exécution,
  3. absence de ticker/frame non libéré.

## 9) État de clôture M11

- **Statut global**: ✅ **Terminé** (2026-04-15).
- **Livré**:
  - PR-M11-1 (fondations scheduler unifié) ✅
  - PR-M11-2 (suppression duplications runtime) ✅
  - PR-M11-3 (migration UI one-shot safe) ✅
  - PR-M11-4 (stabilisation hot paths conservés) ✅
- **Décision finale**:
  - Conserver `OnUpdate` local uniquement pour hot paths / interactions / animations frame-level.
  - Utiliser `MultiBot.TimerAfter` / `MultiBot.NextTick` pour tous les délais one-shot.