# Milestone 12 — Observabilité & garde-fous performance (tracker)

Date d'initialisation: 2026-04-15.
Références: `ROADMAP.md` (D5), `docs/ace3-expansion-checklist.md` (section M12), `docs/milestone11-scheduler-inventory.md` (M11 clôturé).

## 1) Objectif du milestone (pourquoi)

Le Milestone 12 introduit une couche d'**observabilité contrôlée** pour sécuriser la phase post-migration Ace3:

- diagnostiquer rapidement les régressions (état, timing, ordre des flux) sans bruit permanent,
- mesurer les zones à haute fréquence (roster/event handlers/timers) avec des compteurs légers,
- garantir un coût négligeable en mode normal (instrumentation désactivée par défaut).

Ce milestone ne change pas le gameplay: il ajoute des **outils de visibilité** et des **garde-fous perf**.

---

## 2) Scope M12 (in)

- [x] Toggles debug structurés par sous-système (off par défaut). *(PR-M12-1)*
- [x] Compteurs légers autour des handlers fréquents (roster, whisper parse, scheduler entry points). *(PR-M12-2: instrumentation `handler/events/scheduler/throttle`)*
- [x] Gating strict des logs/prints pour éviter le spam chat. *(PR-M12-3: `PrintRateLimited` + throttling `dprint` par clé)*
- [x] Validation de non-régression CPU/mémoire avec instrumentation désactivée. *(PR-M12-4: protocole baseline/debug OFF documenté + validation manuelle)*
- [x] Documenter l'usage des toggles et la lecture des compteurs. *(PR-M12-4: `docs/m12-debug-mode-emploi.md`)*

## 3) Hors scope M12 (out)

- [ ] Refonte UI supplémentaire (M8 est déjà traité).
- [ ] Refonte fonctionnelle des stratégies bots.
- [ ] Optimisations agressives algorithmiques hors zones instrumentées.

---

## 4) Livrables attendus

### 4.1 Instrumentation
- [ ] API de toggles debug centralisée (ex: table `MultiBot.DebugFlags` / helper dédié).
- [x] API de compteurs perf centralisée (increment/read/reset). *(PR-M12-2: `IncrementCounter`, `GetCounters`, `ResetCounters`, `FormatCounters`)*
- [x] Hooks intégrés sur les flux ciblés M12 uniquement. *(PR-M12-2/M12-3: handler/events/scheduler/throttle)*

### 4.2 Documentation
- [x] Guide court “comment activer/désactiver un sous-système debug”. *(PR-M12-4: mode d'emploi)*
- [x] Mapping “compteur -> interprétation”. *(PR-M12-4: mode d'emploi)*
- [x] Procédure de capture minimale lors d'un bug report. *(PR-M12-4: mode d'emploi)*

### 4.3 Validation
- [x] Sanity: chargement/reload sans erreur Lua. *(PR-M12-4: validation manuelle en jeu)*
- [x] Vérif: aucun spam chat/log quand debug OFF. *(PR-M12-3: prints debug conditionnels + rate-limit)*
- [x] Vérif: overhead négligeable debug OFF vs baseline. *(PR-M12-4: protocole baseline/debug OFF documenté + validation manuelle)*

---

## 5) Plan d'implémentation (PR séquencées)

### PR-M12-1 — Fondation observabilité
- [x] Créer les primitives centralisées de toggles debug (off par défaut). *(PR-M12-1 livré: API `MultiBot.Debug` + flags par sous-système + commande `/mbdebug`.)*
- [x] Ajouter un point d'accès unique pour lire/écrire l'état des toggles. *(PR-M12-1: `IsEnabled`, `SetEnabled`, `SetAllEnabled`, `Toggle`, `GetFlags`.)*
- [x] Interdire les `print`/debug directs hors helper central. *(PR-M12-1: `MultiBot.dprint` routé via `MultiBot.Debug.Print` pour la trace core.)*

### PR-M12-2 — Compteurs perf légers
- [x] Ajouter des compteurs monotoniques sur handlers haute fréquence. *(PR-M12-2: `events.*`, `handler.onupdate.*`, `throttle.*`, `scheduler.*`)*
- [x] Ajouter timestamps/mesures minimales uniquement sous garde-fou debug. *(PR-M12-2: `AddDuration`/`IncrementCounter` actives sous flag `perf`)*
- [x] Prévoir reset atomique des compteurs pour fenêtres de test. *(PR-M12-2: `ResetCounters` + `/mbdebug counters reset`)*

### PR-M12-3 — Gating anti-spam + hygiène runtime
- [x] Ajouter rate-limit/échantillonnage des diagnostics verbaux si nécessaire. *(PR-M12-3: `Debug.PrintRateLimited(key, interval, ...)`)*
- [x] Confirmer que debug OFF évite allocations évitables. *(PR-M12-3: helpers `perfCount/perfDuration` court-circuitent tôt via `IsPerfEnabled`)*
- [x] Revue des chemins chauds conservés en M11 pour instrumentation non-intrusive. *(PR-M12-3: instrumentation maintenue O(1), sans mutation métier)*

### PR-M12-4 — Validation finale & doc d'exploitation
- [x] Exécuter smoke tests post-M11 + scénarios ciblés M12. *(PR-M12-4: campagne manuelle décrite dans `docs/m12-debug-mode-emploi.md`)*
- [x] Documenter résultats baseline vs debug OFF. *(PR-M12-4: mode d'emploi + protocole de comparaison)*
- [x] Clôturer checklist M12 dans `docs/ace3-expansion-checklist.md`. *(PR-M12-4)*

---

## 6) Zones candidates à instrumenter (premier inventaire)

- [x] `Core/MultiBotHandler.lua` — refresh roster et dispatchs fréquents.
- [x] `Core/MultiBotThrottle.lua` — file d'attente/throttle chat.
- [x] `Core/MultiBotAsync.lua` — `TimerAfter` / `NextTick` usage counts.
- [ ] `Core/MultiBotEngine.lua` — enchaînements refresh UI/état runtime.
- [ ] `UI/MultiBotMainUI.lua` — points de rafraîchissement à fréquence soutenue.

> Note: l'objectif est une mesure légère et ciblée, sans transformer les hot paths en pipeline verbeux.

---

## 7) Critères de sortie (DoD M12)

- [x] Les diagnostics sont activables **par sous-système** (pas un mode global binaire uniquement). *(M12-1)*
- [x] Debug OFF = pas de spam chat, pas de logs persistants inutiles. *(M12-3/M12-4)*
- [x] Debug OFF = pas de dégradation perceptible (CPU/mémoire) en usage standard. *(PR-M12-4: validation manuelle + protocole documenté)*
- [x] Les compteurs fournis sont lisibles et actionnables pour triage. *(PR-M12-4: mapping documenté)*
- [x] Checklist M12 synchronisée entre roadmap et docs de suivi. *(PR-M12-4)*

---

## 8) Journal de suivi

### Entrées
- 2026-04-15 — Création du tracker M12 et cadrage du plan PR.
- 2026-04-15 — PR-M12-1 livrée: API centralisée `MultiBot.Debug` (flags par sous-système), routage `dprint` sur sous-système `core`, et commande slash `/mbdebug` pour pilotage runtime.
- 2026-04-15 — PR-M12-2 livrée: compteurs perf légers centralisés + instrumentation handlers/events/scheduler/throttle + consultation/reset via `/mbdebug counters`.
- 2026-04-15 — PR-M12-3 livrée: anti-spam diagnostics (`PrintRateLimited`) + court-circuit perf OFF dans les hot paths + revue non-intrusive des chemins M11.
- 2026-04-15 — PR-M12-4 livrée: guide détaillé debug/perf (`docs/m12-debug-mode-emploi.md`), protocole baseline/debug OFF et clôture checklist M12.

### Risques ouverts
- [ ] Risque de sur-instrumentation sur hot paths si le gating est incomplet.
- [ ] Risque de dérive documentaire si les compteurs évoluent sans mise à jour du guide.

### Décisions
- 2026-04-15 — Prioriser des primitives centralisées avant toute instrumentation dispersée.
- 2026-04-15 — Conserver un fallback rétrocompatible (`MultiBot.debug`) mais aligner la source de vérité sur les flags `MultiBot.Debug`.


## 9) État de clôture M12

- **Statut global**: ✅ **Terminé** (2026-04-15).
- **Livré**:
  - PR-M12-1 (fondation observabilité) ✅
  - PR-M12-2 (compteurs perf légers) ✅
  - PR-M12-3 (gating anti-spam + hygiène runtime) ✅
  - PR-M12-4 (validation finale + mode d'emploi) ✅
- **Documentation associée**:
  - `docs/m12-debug-mode-emploi.md`
  - `docs/ace3-expansion-checklist.md`
  - `ROADMAP.md` (D5 statut complété)