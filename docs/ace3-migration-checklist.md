# ACE3 Migration Checklist (Before/After Validation)

Checklist for each migration PR to verify no user-facing regressions.
> Milestones M1-M7 are tracked here. Post-M7 expansion work (M8+) is tracked in `docs/ace3-expansion-checklist.md`.

## Current Progress Snapshot

- [x] ACE3 libraries are loaded from `MultiBot.toc`.
- [x] Lifecycle bridge exists (`OnInitialize` / `OnEnable`) with fallback behavior.
- [x] Central command alias registration is in place.
- [x] Central event/update dispatch entry points are in place.
- [x] Full event registration convergence (core + UI whisper handlers now dispatcher/lifecycle-driven, no standalone event listener frames remain).
- [x] SavedVariables migration to AceDB completed for runtime paths (timers/throttle + main UI/main bar state + layout memory + favorites + global-bot state + Raidus slots/layout apply path + one-way versioned legacy cutovers with guarded legacy creation/cleanup).
- [x] Minimap/options persistence fully switched to AceDB (minimap hide/angle + frame strata + timers/throttle + spec dropdown position + Hunter/Shaman quick-bar positions + Hunter pet stance state + Shaman totem choice state migrated with one-way versioned legacy cutover; read paths avoid legacy table creation and legacy writes are constrained to migration fallback windows).
- [ ] Optional AceGUI screen-by-screen migration.

---

## Smoke Tests (Run Before and After Each PR)

### 1) Load / reload safety
- [x] Addon loads without Lua errors.
- [x] `/reload` does not duplicate handlers, timers, or startup side effects.

### 2) Core slash commands
- [x] `/multibot` toggles main UI.
- [x] `/mbot` and `/mb` behave exactly like `/multibot`.
- [x] `/mbopt` opens options panel reliably.
- [x] `/mbclass` and `/mbclasstest` still work.

### 3) Core event-driven behavior
- [x] Bot roster processing still populates units/buttons correctly.
- [x] Party/raid refresh behavior remains stable.
- [x] Frequent events do not create chat/event spam regressions.

### 4) Quest / whisper parsing
- [x] Incompleted/completed quest parsing still updates expected views.
- [x] "Quests all" aggregation completes and displays correctly.
- [x] No blocking regressions between quest and non-quest whispers.

### 5) GameObject flow
- [x] Capture starts on relevant section headers.
- [x] Capture stops on terminal section/blank line and popup is shown once.
- [x] Copy box output is complete and readable.

### 6) Persistence
- [x] Frame positions restore after relog/reload.
- [x] Portal memory restore works.
- [x] Main UI visibility persists correctly.
- [x] Main bar state toggles restore correctly.

### 7) Options / minimap
- [x] Minimap button show/hide behavior is unchanged.
- [x] Options panel controls still apply values immediately.

---

 ### 8) Milestone 10 — data model lifecycle validations
- [x] Targeted read paths do not create tables implicitly (audit via instrumentation + grep review sur le périmètre M10 ciblé).
- [x] Store helpers for normalization/validation are centralized and reused (core/ui slices migrated to `MultiBot.Store`).
- [x] Migrated modules no longer contain ad-hoc inline bootstrap snippets (final audit pass sur les slices migrés Store).
- [x] Runtime behavior parity validated in-game for migrated slices (Quest/SpellBook/Reward/mainBar/layout).
- [x] `docs/milestone10-data-model-lifecycle-tracker.md` and this checklist are updated per PR.

---