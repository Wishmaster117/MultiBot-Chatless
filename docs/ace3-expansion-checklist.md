# ACE3 Expansion Checklist (Post-M7)

Checklist for the full addon-wide ACE3 expansion after M7 completion.

## Scope and Principles

- [ ] Keep behavior parity first (no feature redesign during migration PRs).
- [ ] Reuse existing helpers before introducing new APIs.
- [ ] Avoid legacy table creation on read paths unless explicitly required.
- [ ] Keep PRs localized per subsystem/screen.

---

## Milestone 8 — AceGUI UI refactor

- [x] Inventory all legacy frame-based screens and map migration order.
  - Source of truth: `docs/ace3-ui-frame-inventory.md` (update per M8 PR).
- [x] Migrate one screen at a time to AceGUI containers/widgets.
- [x] Inventory migration slice completed (`UI/MultiBotInventoryFrame.lua` + `UI/MultiBotInventoryItem.lua`): native AceGUI host window, dedicated controller API, hybrid dense-icon scroll grid, request/refresh parity, and legacy shell removal.
- [x] Options panel content migrated to AceGUI widgets (`UI/MultiBotOptions.lua`) while keeping InterfaceOptions category + slash entrypoint behavior.
- [x] Temporary shared migration debug helper introduced (`Core/MultiBotDebug.lua`) to avoid duplicated diagnostics across files.
- [x] PVP window migration slice completed for targeted controls (`UI/MultiBotPVPUI.lua`: bot selector dropdown + tab group, with localized fallback).
- [x] Spec window/inspect helper migration slice completed and finalized (`UI/MultiBotSpecUI.lua`): Ace window close-cross UX, layering/clickability fix, compact height, and position persistence via existing `specDropdownPositions` store.
- [x] Raidus migration/polish slice completed and finalized (`Features/MultiBotRaidus.lua`): Ace host window path + fallback, close-state sync with main button, score badges, drop feedback animation, and interactive contrast polish.
- [x] Universal prompt migration slice completed (`Core/MultiBotInit.lua`: `MBUniversalPrompt`) with AceGUI window/edit/button path and no legacy frame fallback.
- [x] SpellBook migration slice completed (`UI/MultiBotSpellBookFrame.lua` + `UI/MultiBotSpell.lua`): AceGUI host window, dynamic slot/check generation, normalized page-size handling, and stateful chat collection end-detection fallback.
- [x] Reward migration slice completed (`UI/MultiBotRewardFrame.lua` + `Features/MultiBotReward.lua`): native AceGUI window host, deduped Reward module exports, localized config popup on intended activation path, and stable multi-bot reward close/paging behavior.
- [x] Talents/Glyphs frame migration slice completed (`UI/MultiBotTalentFrame.lua`): AceGUI host integration for the talents/glyphs workflow with preserved tab/copy/apply behavior and custom glyph interactions.
- [x] ITEMUS migration slice completed (`UI/MultiBotItemusFrame.lua` + `Data/MultiBotItemus.lua` + `Core/MultiBotInit.lua`): native AceGUI host window, controller-owned paging/state helpers, lazy Masters launcher/reset initialization, dense icon grid parity, and verified legacy-combination coverage with localized in-window guidance reusing `tips.game.itemus`.
- [x] ICONOS migration slice completed (`UI/MultiBotIconosFrame.lua` + `Core/MultiBotInit.lua` + `Data/MultiBotIconos.lua` + `Core/MultiBotHandler.lua`): native AceGUI host window, full legacy shell removal, dense 112-icon paging parity, right-drag position persistence via `IconosPoint`, ESC close support, copy-friendly in-window icon path display, and a first UX uplift pass with search (`ALL/PATH`) + original/A-Z ordering + selected-icon preview + jump-to-letter.
- [x] Quick Hunter / Quick Shaman migration slice completed and finalized (`UI/MultiBotHunterQuickFrame.lua` + `UI/MultiBotShamanQuickFrame.lua` + `Core/MultiBotInit.lua` + `Core/MultiBot.lua`): both quick bars now live in dedicated UI modules with native AceGUI-hosted windows, preserved position/state persistence, validated Hunter/Shaman gameplay parity, and a lightweight persisted show/hide handle without legacy wrapper reintroduction.
- [x] Hidden tooltip utility cleanup completed (`Core/MultiBotInit.lua`): `MB_LocalizeQuestTooltip` and `MBHiddenTip` now reuse a shared hidden-tooltip helper and remain native by design.
- [x] AceGUI popup close-behavior parity tightened (`Core/MultiBotInit.lua`): migrated popup windows now hide on close (no release), preserving reopen behavior across the same session.
- [x] AceGUI resolver deduplication completed (`Core/MultiBotInit.lua`): migrated popup paths now share a single resolver helper for dependency lookup + error reporting.
- [x] Escape-close parity added for migrated AceGUI popups (`Core/MultiBotInit.lua`): popup windows are now registered in `UISpecialFrames` for consistent ESC close behavior.
- [x] Quest/GameObject architectural follow-up documented (`docs/ace3-quests-gobjects-migration-tracker.md`): the remaining extraction out of `Core/MultiBotInit.lua` and Itemus-style skin target are now tracked explicitly for the next M8 Quest-frame PRs.
- [x] Quest/GameObject extraction slice completed structurally (`UI/MultiBotQuestUIShared.lua`, `UI/MultiBotPromptDialog.lua`, `UI/MultiBotQuestLogFrame.lua`, `UI/MultiBotQuestIncompleteFrame.lua`, `UI/MultiBotQuestCompletedFrame.lua`, `UI/MultiBotQuestAllFrame.lua`, `UI/MultiBotGameObjectResultsFrame.lua`, `UI/MultiBotGameObjectCopyFrame.lua`, `UI/MultiBotQuestsMenu.lua` + `Core/MultiBotInit.lua` + `MultiBot.toc`): legacy inline frame construction was removed from Core and replaced by dedicated UI modules with shared helpers, deterministic aggregation helpers, and preserved Ace window close/ESC/position behavior.
- [x] Quest/GameObject slice final in-game parity validation + Itemus-style polish pass.
- [x] Preserve slash entry points and open/close behavior (aliases unchanged in migrated slices; popup close/hide + ESC parity preserved).
- [x] Keep persisted state routed through existing AceDB helpers (`Core/MultiBotInit.lua`: migrated popups now persist positions in `MultiBot.db.profile.ui.popupPositions`).
- [x] Validate visual/interaction parity per migrated screen (close/hide/ESC parity + popup reopen behavior aligned across migrated slices).

## Milestone 9 — Localization and text pipeline

- [x] Inventory hardcoded user-facing strings in Core/UI/Features.
- [x] Move strings into locale tables (AceLocale strategy) where feasible.
- [x] Add deterministic fallback for missing locale keys.
- [ ] Remove duplicate literals once locale keys are stable. *(ongoing incremental cleanup by file)*

## Milestone 10 — Data model and table lifecycle hardening

- [x] Centralize store accessors for profile/runtime tables.
- [x] Remove duplicate validation/bootstrap snippets.
- [x] Ensure read accessors are non-creating by default.
- [x] Add cleanup for empty transient buckets where needed.

## Milestone 11 — Scheduler/timers convergence

- [x] Inventory all `OnUpdate` loops and elapsed timers. *(2026-04-05: cartographie initiale livrée dans `docs/milestone11-scheduler-inventory.md`.)*
- [x] Classify each loop (hot path/local, safe-to-centralize, keep-as-is).
- [x] Migrate safe loops to a shared scheduler approach.
- [x] Remove duplicate one-shot loops after parity validation.

## Milestone 12 — Observability and perf guardrails

- Statut: ✅ Completed (2026-04-15).
- Tracker détaillé: `docs/milestone12-observability-perf-tracker.md`.
- Mode d'emploi debug: `docs/m12-debug-mode-emploi.md`.

- [x] Add subsystem debug toggles (off by default). *(PR-M12-1: `MultiBot.Debug` flags + `/mbdebug` command control.)*
- [x] Add lightweight counters around high-frequency handlers. *(PR-M12-2: counters `events/handler/scheduler/throttle` gated by `perf`.)*
- [x] Ensure diagnostics do not spam chat/log by default. *(PR-M12-3: `PrintRateLimited` + `dprint` throttlé par clé.)*
- [x] Validate no notable overhead in normal mode. *(PR-M12-4: baseline/debug OFF protocol + validation manuelle.)*

## Milestone 13 — Release hardening and fallback closure

- [ ] Define closure policy for remaining legacy fallback writes.
- [ ] Document upgrade and rollback procedure.
- [ ] Execute full smoke + migration regression pass.
- [ ] Freeze release scope and publish compatibility notes.

---

## Post-M7 Smoke Tests (run per PR)

### 1) Startup / reload safety
- [ ] Addon loads without Lua errors.
- [ ] `/reload` does not duplicate handlers, loops, or startup effects.

### 2) UI parity
- [ ] Main UI toggles and panels open/close identically.
- [ ] Migrated AceGUI screens match legacy behavior.
- [ ] Drag/drop and frame anchoring still restore after relog/reload.

### 3) Persistence and migration safety
- [ ] No read path creates legacy tables accidentally.
- [ ] Legacy writes happen only in approved migration fallback windows.
- [ ] One-way migration markers prevent repeated imports.

### 4) Bot and event flows
- [ ] Roster refresh remains stable under frequent events.
- [ ] Whisper/quest parsing remains non-blocking and accurate.
- [ ] No new chat/event spam regressions.

### 5) Performance sanity
- [ ] No obvious CPU spikes from new scheduler/UI paths.
- [ ] No growth of transient tables across repeated open/close cycles.