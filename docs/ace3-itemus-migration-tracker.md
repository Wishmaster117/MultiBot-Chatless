# Ace3 ITEMUS Migration Tracker (Milestone 8)

Dedicated tracking document for the full migration of the GM **ITEMUS** frame from the legacy `MultiBot.newFrame(...)` path to a native AceGUI/Ace3 implementation.

> Scope: rebuild `ITEMUS` as a real Ace3 screen under `UI/`, remove the legacy frame shell for this screen, preserve the exact GM/item-generation behavior, and modernize the Lua structure without wrapping the old frame inside AceGUI.

---

## 1) Current legacy scope

### Source-of-truth files
- `Core/MultiBotInit.lua`
- `Data/MultiBotItemus.lua`
- `Core/MultiBotHandler.lua`
- `Locales/MultiBotAceLocale-*.lua`
- `docs/ace3-ui-frame-inventory.md`

### Legacy responsibilities currently coupled together
- Window creation, static layout, texture shell, and frame controls.
- Filter state management (`level`, `rare`, `slot`, `type`).
- Page state management (`now`, `max`) and page button visibility.
- Filter-menu expand/collapse logic.
- Item dataset indexing and classification into `level -> rare -> slot -> type`.
- Dense item-grid rendering for the current page.
- Item click dispatch (`.additem <id> 1` on the current target).
- Saved-position compatibility via `ItemusPoint`.

---

## 2) Functional audit summary

### What ITEMUS does today
- [x] Opens from the GM/Masters utility section.
- [x] Loads a paged catalogue of GM-spawnable items when shown.
- [x] Combines four filters: `Level`, `Rare`, `Slot`, and `Type`.
- [x] Resets to page 1 when a filter changes.
- [x] Preserves the active filter combination in session memory while the addon remains loaded.
- [x] Spawns exactly **one** item per click with `.additem <itemId> 1`.
- [x] Shows `0/0` and hides page navigation when a filter combination has no result.

### Current default state
- [x] `level = L10`
- [x] `rare = R00`
- [x] `slot = S00`
- [x] `type = PC`
- [x] `color = cff9d9d9d`
- [x] `now = 1`
- [x] `max = 1`

### Important current semantics to preserve
- [x] `Level` is a required bucketed filter with 8 ranges (`L10..L80`).
- [x] `Rare` drives both the dataset branch and the colored item hyperlink style.
- [x] `Slot` includes both equipable slots and `S00` non-equipable.
- [x] `Type` is a binary `PC/NPC` toggle, not a submenu.
- [x] `NPC` detection currently comes from the item name prefix (`"NPC"`), not from a dedicated typed field.
- [x] The item grid is dense and optimized for rapid GM browsing, not for verbose row-based listing.

---

## 3) Migration goals

### Functional goals
- [x] Preserve the exact open/show behavior from the `Masters -> Itemus` button.
- [x] Preserve all four filters and their current semantics.
- [x] Preserve page size at **112 items per page** unless we explicitly decide otherwise later.
- [x] Preserve the current `0/0` empty-state behavior for impossible/empty filter combinations.
- [x] Preserve one-click `.additem <id> 1` generation on the target.
- [x] Preserve tooltip intent and all existing localization keys.
- [x] Preserve `ItemusPoint` compatibility and global coordinate reset behavior.

### Technical goals
- [x] Remove the legacy `MultiBot.itemus = MultiBot.newFrame(...)` construction from `Core/MultiBotInit.lua`.
- [x] Rebuild the screen as a native AceGUI host window, not as a legacy frame embedded inside AceGUI.
- [x] Move the frame implementation into a dedicated file under `UI/`.
- [x] Separate data/index logic from view/layout logic more clearly than today.
- [x] Replace ad-hoc legacy button selection coupling (`MultiBot.Select`, frame-local state mutation) with explicit screen/controller state.
- [x] Modernize helper code with more local, table-driven Lua while preserving the existing addon API surface.

---

## 4) Recommended target structure

### Planned UI/module split
- [x] `UI/MultiBotItemusFrame.lua`
  - AceGUI host window creation.
  - Screen lifecycle (`Open`, `Hide`, `Refresh`, `SetFilters`, `SetPage`).
  - Layout composition and widget binding.
  - Empty-state and pagination rendering.
- [x] `Data/MultiBotItemus.lua`
  - Keep the item dataset here.
  - Option A: keep index build here and expose a structured lookup helper.
  - Option B: move only the index-builder helper to the new UI/controller module if that proves cleaner.
- [x] Existing entrypoints in `Core/MultiBotInit.lua`
  - Keep only the launch hook from the `Masters` button.
  - Remove direct legacy frame creation once the Ace3 window is ready.
- [x] Existing saved-layout integration in `Core/MultiBotHandler.lua`
  - Preserve `ItemusPoint` compatibility.

### Target responsibilities
- [x] Controller-owned filter state.
- [x] Controller-owned page state.
- [x] Reusable filter metadata tables (`level`, `rare`, `slot`, `type`).
- [x] Dedicated item-grid refresh pipeline.
- [x] Explicit empty-state rendering instead of legacy button wiping side effects.
- [x] Explicit lifecycle helpers (`Refresh`, `SetFilters`, `SetPage`) live on the controller.
- [x] Legacy compatibility shims kept only where required during the transition.

---

## 5) Recommended UX direction for the Ace3 rewrite

### Recommended overall layout
- [x] Left column or top-left zone for filter controls.
- [x] Main results panel dedicated to the item grid.
- [x] Native AceGUI titlebar/close handling instead of the legacy texture shell and hardcoded close button.
- [x] Native drag handling with saved-position persistence aligned with the current `ItemusPoint` behavior.
- [x] Clear current-page text and previous/next controls.

### Filter UX recommendation
- [x] Keep `Level`, `Rare`, `Slot`, and `Type` as first-class visible controls.
- [x] Preserve the current fast-access behavior; do not hide everything behind a single generic dropdown if that slows GM usage.
- [x] Treat `Slot` as a visually rich selector because the slot cartography is already meaningful (`S00..S28`).
- [x] Keep `Type` as an immediate toggle because that matches the current flow well.
- [x] Make the currently selected filter values visually obvious without relying on the legacy frame-border selection style.

### Item-grid UX recommendation
- [x] Preserve dense icon browsing as the primary interaction model.
- [x] Keep item tooltips/hyperlinks visible and colorized by rarity.
- [x] Show an explicit empty-state message in-frame in addition to preserving the current feedback behavior.
- [x] Avoid a row/list layout that would reduce scan speed for GM use.

---

## 6) Feature parity checklist

### A. Window lifecycle
- [x] Opening ITEMUS from the `Masters` menu still opens the correct window.
- [x] Reopening ITEMUS reuses screen state safely.
- [x] Closing from the AceGUI close button works consistently.
- [x] Escape/close behavior matches other migrated AceGUI windows if appropriate.
- [x] Position persistence still uses `ItemusPoint` semantics.
- [x] Ace3 title drag hint reuses `tips.move.itemus`.

### B. Filter state
- [x] `Level` options cover `L10` through `L80`.
- [x] `Rare` options cover `R00` through `R07`.
- [x] `Slot` options cover `S00` through `S28`.
- [x] `Type` still toggles `PC/NPC`.
- [x] Changing any filter refreshes the page and resets page index to `1`.
- [x] Current selection is clearly visible for each filter family.

### C. Dataset/indexing
- [x] Index still resolves via `level -> rare -> slot -> type`.
- [x] `NPC` classification remains compatible with the current dataset rules.
- [x] No valid current legacy combinations disappear silently.
- [x] Empty combinations still produce a deterministic empty state.

### D. Pagination/results
- [x] Page size remains `112`.
- [x] Previous/next visibility remains correct.
- [x] Page label remains correct after filter changes and page navigation.
- [x] Refreshing a page no longer depends on recreating fragile legacy frame state.
- [x] Results header shows the visible range and total item count.
- [x] The controller/data layer supplies an explicit paged payload to the view.

### E. Item actions
- [x] Each visible result still carries the correct item id.
- [x] Clicking an item still issues `.additem <id> 1`.
- [x] Missing icons still fall back to question mark safely.
- [x] Tooltip/hyperlink rendering still works with the selected rarity color.
- [x] Hidden pooled result buttons clear stale item metadata before reuse.

### F. Integration / localization
- [x] `tips.game.itemus` continues to describe the screen correctly.
- [x] Existing `tips.itemus.*` strings remain valid and are still consumed by the Ace3 screen.
- [x] No regression is introduced for the `Masters` utility menu flow.
- [x] The TOC load order is updated if a new dedicated UI file is added.

---

## 7) Known migration risks and mitigations

### Risk 1 — Accidental “wrapper migration”
- Problem: creating an AceGUI host and then inserting the old legacy ITEMUS frame inside it would violate the migration goal.
- Mitigation: the new screen must own its own layout, widgets, selection state, and pagination controls from day one.

### Risk 2 — Breaking `NPC/PC` filtering
- Problem: the current dataset derives `NPC` from the item name prefix rather than a dedicated schema field.
- Mitigation: preserve that classification logic exactly unless the underlying data file is explicitly normalized in the same migration.

### Risk 3 — Losing `S00` semantics
- Problem: `S00` means non-equipable, not “unset slot”.
- Mitigation: keep `S00` as a first-class slot option in the new selector.

### Risk 4 — Over-simplifying the slot selector
- Problem: replacing the slot layout with a poor textual selector could slow down real GM usage.
- Mitigation: keep a visual slot-oriented selector or another equally fast icon-first design.

### Risk 5 — Regressing empty combinations
- Problem: some filter combinations intentionally return no result.
- Mitigation: preserve both the deterministic empty state and the absence of phantom fallback items.

---

## 8) Proposed migration sequence

### Phase 1 — Tracking and extraction prep
- [x] Audit current legacy behavior.
- [x] Create this tracking document.
- [x] Document the final target file path and TOC insertion point.

### Phase 2 — Data/controller boundary
- [x] Introduce a clearer Itemus controller API.
- [x] Centralize filter metadata tables in the new module.
- [x] Keep the index build in `Data/MultiBotItemus.lua` and expose it through controller helpers.

### Phase 3 — AceGUI host window
- [x] Create a native AceGUI ITEMUS host window.
- [x] Bind saved position using `ItemusPoint`.
- [x] Bind close behavior and optional Escape integration.

### Phase 4 — Filter controls
- [x] Recreate `Level` controls.
- [x] Recreate `Rare` controls.
- [x] Recreate `Slot` controls.
- [x] Recreate `Type` toggle.
- [x] Recreate explicit selected-state visuals without the legacy shell.

### Phase 5 — Item grid and pagination
- [x] Recreate dense paged item rendering.
- [x] Rebind tooltips and `.additem` click behavior.
- [x] Recreate empty-state handling and page navigation.

### Phase 6 — Legacy removal and cleanup
- [x] Remove legacy ITEMUS frame creation from `Core/MultiBotInit.lua`.
- [x] Keep only the launcher hook from the `Masters` menu.
- [x] Update migration docs/checklists once the rewrite lands.

---

## 9) Non-regression test matrix

### Manual gameplay checks
- [x] Open ITEMUS from `Masters`.
- [x] Navigate to next page and previous page.
- [x] Change `Level` and verify page resets to `1`.
- [x] Change `Rare` and verify hyperlink color matches the selected rarity.
- [x] Change `Slot` to an equipable slot and verify relevant results appear.
- [x] Change `Slot` to `S00` and verify non-equipable results appear.
- [x] Toggle `Type` from `PC` to `NPC` and verify the dataset changes.
- [x] Pick a known empty combination and verify `0/0` behavior.
- [x] Click an item with a valid target and verify one item is generated.
- [x] Reopen ITEMUS and verify filters/page state behave as intended.
- [x] Use the global coordinate reset flow and verify ITEMUS resets correctly.

### Static/code checks for the future PR
- [x] TOC load order updated for the new UI module.
- [x] No user-facing dependency remains on the legacy ITEMUS texture shell.
- [x] `ItemusPoint` persistence remains wired.
- [x] Documentation/checklists updated once the migration lands.

---

## 10) Open design decisions

- [x] Use a scrollable dense icon container with pooled buttons so the AceGUI host stays native while preserving rapid GM scanning.
- [x] Keep the slot selector as an icon grid because it matches the legacy slot cartography and remains the fastest scanable option.
- [x] Mirror the empty-state message in-frame while preserving deterministic empty results and avoiding phantom fallback items.
- [x] Keep index building and normalization in `Data/MultiBotItemus.lua`; the AceGUI module only consumes controller/data helpers.

## 10.1) Follow-up validation notes

- Legacy-vs-Ace3 bucket comparison was rerun against the current ITEMUS dataset and found `diff_count = 0` / `regression_count = 0`, confirming that no previously valid legacy combination became empty after the Ace3 rewrite.
- ITEMUS initialization now stays lazy from the `Masters` launcher and the global coordinate reset flow, avoiding an eager hidden-window construction during addon boot while preserving `ItemusPoint` compatibility.

---

## 11) PR checklist for the future migration patch

- [x] New dedicated ITEMUS UI file added under `UI/`.
- [x] Legacy ITEMUS shell removed from `Core/MultiBotInit.lua`.
- [x] Existing `Masters -> Itemus` flow verified.
- [x] `ItemusPoint` persistence verified.
- [x] `docs/ace3-ui-frame-inventory.md` updated to mark ITEMUS progress.
- [x] `docs/ace3-expansion-checklist.md` updated.
- [x] Screenshot captured if the final UI change is visually testable in this environment.
- [x] Final PR summary calls out preserved legacy behavior and any intentional UX improvements.