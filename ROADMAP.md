# MultiBot ACE3 Migration Roadmap (Updated)

## Current Status Snapshot

- **Milestone 1 (Baseline / safety net):** In progress.
  - Baseline behavior is mostly known through manual validation.
  - Migration checklist is tracked in `docs/ace3-migration-checklist.md` and must be updated per PR.
- **Milestone 2 (Add ACE3 libs):** Completed.
  - ACE3 libraries are loaded in `MultiBot.toc`.
- **Milestone 3 (Initialization lifecycle):** Mostly completed, hardening pending.
  - `OnInitialize` and `OnEnable` are in place.
  - Legacy frame-based startup/event code still exists in a few places.
- **Milestone 4 (Command system):** Completed.
  - Central alias registration is used for core commands via `RegisterCoreCommandsOnce` in lifecycle init.
  - Runtime command invocation paths are centralized through `RunRegisteredCommand` (slash + minimap click + helper dispatch).
- **Milestone 5 (Event bus migration):** Completed.
  - Dispatcher architecture drives core/quick-bar/UI whisper flows.
  - Legacy `CreateFrame + RegisterEvent + SetScript` listener blocks have been removed from addon runtime paths.
- **Milestone 6 (SavedVariables -> AceDB):** Completed.
  - AceDB bootstrap/runtime migration is now complete for supported SavedVariables paths; one-way versioned legacy cutovers are in place with guarded legacy creation and post-migration cleanup to avoid stale duplicate persistence.
- **Milestone 7 (Minimap/options integration):** Completed.
  - Minimap hide/angle, global frame strata, options timers/throttle, Spec dropdown positions, Hunter/Shaman quick-bar positions, Hunter pet stance state and Shaman totem choice state now run through AceDB-backed helpers with one-way versioned legacy cutover and guarded legacy fallback (no legacy table creation on pure read paths).
- **Milestone 8 (AceGUI UI refactor):** In progress (Raidus + SpellBook + Reward slices completed).
  - `UI/MultiBotOptions.lua` panel content has been migrated to AceGUI widgets while preserving category registration and slash/open flows.
  - `UI/MultiBotPVPUI.lua` migration slice is completed for the targeted controls (bot selector dropdown + tab group with localized fallback compatibility).
  - `UI/MultiBotSpecUI.lua` migration slice is completed for the spec popup/inspect helper controls (AceGUI window path finalized: close-cross UX, layering fix, compact size, and position persistence on AceDB path).
  - `Features/MultiBotRaidus.lua` migration/polish slice is completed (AceGUI window hosting path, close state sync with main button, slot/group score badges, drag/drop feedback, and interactive contrast pass).
  - `UI/MultiBotTalentFrame.lua` Talents/Glyphs migration slice is completed for the targeted host workflow with preserved tab/copy/apply behavior and custom glyph interactions.
  - `UI/MultiBotSpellBookFrame.lua` + `UI/MultiBotSpell.lua` SpellBook migration slice is completed (AceGUI window host, dynamic slot/check generation, page-size normalization, and stateful chat-collection parsing/finish flow).
  - Reward frame migration slice is completed (`UI/MultiBotRewardFrame.lua` + `Features/MultiBotReward.lua` + main-bar integration): native AceGUI host, deduped module API, saved-state-aware popup trigger, and parity close/paging behavior are in place.
  - Inventory migration slice is completed (`UI/MultiBotInventoryFrame.lua` + `UI/MultiBotInventoryItem.lua` + handler/request integration): native AceGUI host, controller API, hybrid dense-icon grid, inventory-button sync, and final UI/header polish are validated in game.
  - Quest popups, prompts, hunter family/search windows, and related AceGUI popup migrations are completed;
- **Milestone 9 (Localization and text pipeline):** Completed.
  - Core locale loader + per-locale payload files are integrated (`Core/MultiBotLocale.lua`, `Locales/MultiBotAceLocale-*.lua`).
  - `Core/MultiBotInit.lua`, `Features/MultiBotRaidus.lua`, `Core/MultiBotEvery.lua`, `Core/MultiBotEngine.lua`, `Core/MultiBotHandler.lua`, `Strategies/MultiBotDruid.lua`, `Strategies/MultiBotPaladin.lua`, `Strategies/MultiBotMage.lua`, `Strategies/MultiBotWarlock.lua`, `Strategies/MultiBotPriest.lua`, `Strategies/MultiBotShaman.lua`, `Strategies/MultiBotHunter.lua`, `Strategies/MultiBotRogue.lua`, `Strategies/MultiBotDeathKnight.lua`, and `Strategies/MultiBotWarrior.lua` migration sweeps are completed for legacy `MultiBot.tips.*` runtime reads.
  - `Core/MultiBot.lua` bootstrap `MultiBot.tips` initialization lines were validated/documented as intentional non-runtime-tooltip compatibility paths.
  - Remaining UI literal cleanup is completed for Milestone 9 scope (GM shortcut labels, Raidus group title formatting, shared UI defaults for page/title labels) while preserving technical/protocol identifiers (e.g. internal "Inventory" button/event keys).
- **Milestone 10 (Data model and table lifecycle hardening):** Completed.
  - Runtime/profile stores are centralized via `MultiBot.Store` with explicit `get*` vs `ensure*` semantics and read-path hardening validated in tracker `docs/milestone10-data-model-lifecycle-tracker.md`.
- **Milestone 11 (Scheduler/timers convergence):** Completed.
  - Scattered one-shot timers were converged to `MultiBot.TimerAfter` / `MultiBot.NextTick`, while hot-path `OnUpdate` loops were intentionally retained and documented.
- **Milestone 12 (Observability, diagnostics and perf guardrails):** Completed.
  - Structured debug toggles, lightweight perf counters, anti-spam diagnostics gating, and operator documentation are completed (`Core/MultiBotDebug.lua`, `/mbdebug`, `docs/milestone12-observability-perf-tracker.md`, `docs/m12-debug-mode-emploi.md`).
- **Milestone 13 (Release hardening and deprecation window close):** Planned.
  - Close migration fallback window, document upgrade path, and freeze compatibility guarantees for release.

---

## Execution Plan to Completion

## Phase A — Close lifecycle + command + event gaps

### A1. Lifecycle hardening
1. Keep `OnInitialize` / `OnEnable` as the single startup path.
2. Move remaining startup side effects behind lifecycle-safe guards.
3. Ensure no duplicate initialization on reload/login.

**Exit criteria**
- No duplicate startup behavior.
- No extra event registrations after repeated reloads.

### A2. Command system finalization
1. Keep `RegisterCommandAliases` as the only command registration API.
2. Remove scattered direct slash registrations if any remain.
3. Preserve all current aliases and behavior.

**Exit criteria**
- `/multibot`, `/mbot`, `/mb`, `/mbopt`, `/mbclass`, `/mbclasstest` unchanged.

### A3. Event convergence
1. Keep `DispatchEvent` / `DispatchUpdate` as central dispatch points.
2. Gradually migrate remaining local frame-event blocks into centralized registration.
3. Validate high-frequency paths for duplicate callback regressions.

**Exit criteria**
- No duplicated callbacks.
- No observable event spam regression.

---

## Phase B — SavedVariables migration to AceDB

### B1. Introduce AceDB schema (non-breaking)
1. Add `MultiBot.db = AceDB:New(...)` with defaults equivalent to current settings.
2. Keep legacy variables readable during transition.

### B2. One-way migration from legacy storage
1. Migrate old keys once (timers, throttle, minimap, visibility, strata, favorites).
2. Mark migration version to avoid repeated imports.

### B3. Switch runtime reads/writes to AceDB
1. Move runtime config access to AceDB first.
2. Keep temporary fallback reads for one transition cycle.

**Exit criteria**
- Existing users retain settings.
- Fresh installs use AceDB defaults.

---

## Phase C — Minimap/options and optional UI modernization

### C1. Minimap/options stabilization
1. Keep current options UI intact.
2. Connect minimap/options persistence fully to AceDB.
3. Optionally add LibDBIcon integration without behavior changes.

**Exit criteria**
- Minimap toggle and options panel behavior unchanged for users.

### C2. Optional AceGUI refactor (last)
1. Migrate one screen at a time.
2. Keep data/control flow equivalent for each migrated screen.
3. Avoid big-bang rewrites.

## Phase D — Full ACE3 expansion plan (post-M7)

### D1. Milestone 8 — AceGUI UI refactor
1. Pick one UI domain per PR (Options, Class, Quest, Raidus auxiliary panes, etc.).
2. Keep slash commands and open/close behavior unchanged.
3. Reuse existing persistence helpers (no duplicate save logic).

**Exit criteria**
- Legacy frame templates are removed only for migrated screens.
- Each migrated screen reaches behavior parity before moving to the next one.

### D2. Milestone 9 — Localization and text pipeline
1. Inventory all user-facing strings in `Core/`, `UI/`, `Features/`. *(in progress)*
2. Route strings through locale tables (AceLocale integration when feasible with current packaging). *(in progress)*
3. Preserve fallback locale behavior and avoid nil-text regressions. *(in progress)*

**Exit criteria**
- New/edited UI text no longer ships as hardcoded literals outside locale tables.
- Missing keys fail gracefully with deterministic fallback.

### D3. Milestone 10 — Data model and table lifecycle hardening
1. Centralize table accessors for high-churn stores (`profile.ui`, runtime bot stores, quick UI caches).
2. Remove duplicate validators and one-off table bootstrap snippets.
3. Enforce read-only accessors that do not create tables unless explicitly requested.

**Exit criteria**
- No uncontrolled table creation on read paths in targeted modules.
- Store normalization helpers are reused across modules.

### D4. Milestone 11 — Scheduler/timers convergence
1. Inventory `OnUpdate`, elapsed counters, delayed whisper/refresh loops. ✅
2. Migrate safe candidates to a centralized scheduler strategy (`MultiBot.TimerAfter` / `MultiBot.NextTick`). ✅
3. Keep ultra-hot paths local if conversion adds risk/regression. ✅

**Exit criteria**
- Timer responsibilities are documented and mapped to one owner per feature.
- Duplicate periodic loops are reduced without behavior drift.

### D5. Milestone 12 — Observability and performance guardrails
1. Add structured debug toggles (off by default) for migration/state transitions. ✅
2. Add lightweight perf counters around roster refresh and high-frequency handlers. ✅
3. Gate diagnostics to avoid chat spam and runtime overhead in normal mode. ✅

**Exit criteria**
- Debug instrumentation can be enabled per subsystem. ✅
- No measurable baseline degradation with diagnostics disabled. ✅

**Status**
- Milestone 12 completed on 2026-04-15.
- Implementation/validation tracking: `docs/milestone12-observability-perf-tracker.md`.
- Operator guide: `docs/m12-debug-mode-emploi.md`.

### D6. Milestone 13 — Release hardening and migration window close
1. Define deprecation policy for remaining legacy fallback paths.
2. Add final upgrade notes and rollback instructions.
3. Freeze scope and run full pre-release checklist.

**Exit criteria**
- Fallback window closure is documented and predictable.
- Release notes reflect final compatibility contract.

---

## PR Order

1. Lifecycle hardening.
2. Command system finalization.
3. Event convergence.
4. AceDB bootstrap.
5. Legacy -> AceDB one-way migration.
6. Runtime switch to AceDB.
7. Minimap/options persistence finalization.
8. Milestone 8 (AceGUI screen-by-screen).
9. Milestone 9 (localization pipeline).
10. Milestone 10 (data model hardening).
11. Milestone 11 (timer convergence).
12. Milestone 12 (observability/perf guardrails).
13. Milestone 13 (release hardening).

---

## Risk Controls (Apply on every PR)

- Keep changes localized and incremental.
- Avoid duplicate helper logic.
- Prefer reusing existing APIs/functions over adding new parallel paths.
- Validate no duplicate event registration and no repeated side effects on reload.
- Keep behavior identical unless explicitly planned and documented.