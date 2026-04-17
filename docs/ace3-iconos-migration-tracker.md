# Ace3 ICONOS Migration Tracker (Milestone 8)

Dedicated tracking document for the full migration of the GM **ICONOS** frame from the legacy `MultiBot.newFrame(...)` path to a native AceGUI/Ace3 implementation.

> Scope: rebuild `ICONOS` as a real Ace3 screen under `UI/`, remove the legacy frame shell for this screen, preserve the exact icon-browsing behavior, and modernize the Lua structure without wrapping the old frame inside AceGUI.

> Status update: the native AceGUI implementation is now in place in `UI/MultiBotIconosFrame.lua`; parity-critical migration work is completed, and the first UX uplift pass (search `ALL/PATH` + original/A-Z ordering + selected-icon preview + jump-to-letter) has landed, while additional refinements remain follow-up candidates.

---

## 1) Current legacy scope

### Source-of-truth files
- `Core/MultiBotInit.lua`
- `Data/MultiBotIconos.lua`
- `Core/MultiBotHandler.lua`
- `Locales/MultiBotAceLocale-*.lua`
- `docs/ace3-ui-frame-inventory.md`

### Legacy responsibilities currently coupled together
- Window creation, texture shell, title text, page text, close button, and drag button.
- Static icon dataset declaration inside `Data/MultiBotIconos.lua`.
- Runtime page state management (`now`, `max`).
- Previous/next button visibility logic.
- Dense 8-column icon-grid rendering for the active page.
- Tooltip generation using the icon short name plus full texture path.
- Saved-position compatibility via `IconosPoint`.

---

## 2) Functional audit summary

### What ICONOS does today
- [x] Opens from the GM/Masters utility section.
- [x] Reuses a singleton frame (`MultiBot.iconos`) created during addon initialization.
- [x] Displays a paged catalogue of icons sourced from `MultiBot.data.iconos`.
- [x] Renders **112 icons per page**.
- [x] Uses an **8 x 14** dense visual grid.
- [x] Displays a page label using the `current/max` format.
- [x] Hides the previous button on page `1`.
- [x] Hides the next button on the last page.
- [x] Uses the icon basename as the tooltip title.
- [x] Shows the full icon path in the tooltip body.
- [x] Keeps `IconosPoint` registered in the shared saved-layout system.

### Current dataset facts
- [x] `MultiBot.data.iconos` currently contains **5997** entries.
- [x] At the current page size, the dataset spans **54 pages**.
- [x] The dataset is **not alphabetically sorted**.
- [x] No exact duplicate icon paths were detected in the current source file.
- [x] A few entries look irregular and should be preserved/validated during migration (for example `.tga` suffixes and one path ending with a trailing dot).

### Important current semantics to preserve
- [x] Open/close behavior must stay bound to `Masters -> Iconos`.
- [x] Dense icon-first browsing is the primary interaction model.
- [x] Tooltip content must still expose the underlying icon path.
- [x] The page label and previous/next behavior must remain deterministic.
- [x] `IconosPoint` persistence and global coordinate reset compatibility must remain intact.

---

## 3) Legacy implementation audit

### Legacy construction path (pre-migration)
- `Core/MultiBotInit.lua` used to create `MultiBot.iconos` through `MultiBot.newFrame(...)`.
- The same file used to wire the move button, page buttons, close button, title text, and page text.
- The migrated path now keeps raw data in `Data/MultiBotIconos.lua`, while `UI/MultiBotIconosFrame.lua` owns the screen/controller logic.

### Legacy pain points that motivated the migration
- **Legacy shell coupling:** the old screen depended on the texture frame, hardcoded coordinates, and custom widget helpers. *(resolved in the Ace3 path)*
- **Data/view coupling:** the old icon dataset and refresh routine lived in the same module. *(resolved by `Data/MultiBotIconos.lua` + `UI/MultiBotIconosFrame.lua`)*
- **No direct discovery tools:** the old screen had no search box, alphabetical sort mode, or quick jump. *(resolved in the Ace3 path)*
- **No explicit empty/error state:** the old screen assumed the dataset always existed and silently rebuilt buttons every refresh. *(resolved in the Ace3 path with deterministic empty-state messaging)*
- **No reusable controller API:** pagination state was mutated directly on the frame table. *(resolved in the Ace3 path)*
- **Inefficient redraw path:** the old screen destroyed/rebuilt visible icon buttons every refresh. *(resolved via pooled buttons in the Ace3 path)*
- **Hardcoded visual geometry:** the old page size, offsets, spacing, and title coordinates were implicit magic numbers. *(resolved via table-driven UI settings)*

### Current behavior details worth keeping in mind
- [x] The tooltip title is derived from `string.sub(tIcon, 17)`, so it effectively strips `Interface\\Icons\\` from the stored path.
- [x] The page label is written before next/previous button visibility is updated.
- [x] The current Masters button only calls `addIcons()` when the show/hide toggle returns true.
- [x] The current layout is visually very close to the old dense catalogue style used by legacy utility tools.

---

## 4) Migration goals

### Functional goals
- [x] Preserve the exact open/show behavior from the `Masters -> Iconos` button.
- [x] Preserve dense icon browsing with the same default page size baseline (**112**).
- [x] Preserve the current tooltip intent: short icon name + full path.
- [x] Preserve `IconosPoint` compatibility and global coordinate reset behavior.
- [x] Preserve reopen behavior without recreating the entire screen every time.

### Technical goals
- [x] Remove the legacy `MultiBot.iconos = MultiBot.newFrame(...)` construction from `Core/MultiBotInit.lua`.
- [x] Rebuild the screen as a native AceGUI host window, not as a legacy frame embedded inside AceGUI.
- [x] Move the frame implementation into a dedicated file under `UI/` (`UI/MultiBotIconosFrame.lua`).
- [x] Decouple icon data access from the visual/controller layer.
- [x] Replace direct frame-table pagination mutation with an explicit controller API (`Toggle`, `ShowWindow`, `HideWindow`, `Refresh`, `SetPage`).
- [x] Modernize the layout code with localized helpers, pooled widgets/buttons, and table-driven settings.

---

## 5) Recommended target structure

### Planned UI/module split
- [x] `UI/MultiBotIconosFrame.lua`
  - AceGUI host window creation.
  - Screen lifecycle (`Open`, `Hide`, `Toggle`, `Refresh`).
  - Search/sort state, page state, and filtered result projection.
  - Dense icon-grid rendering and tooltip binding.
- [x] `UI/MultiBotIconos.lua` or `Data/MultiBotIconos.lua`
  - Keep the raw icon dataset in a dedicated data-oriented file.
  - Expose a read-only accessor/helper if needed.
- [x] `Core/MultiBotInit.lua`
  - Keep only the launcher hook from the `Masters` button.
  - Remove direct legacy frame creation once the Ace3 window is ready.
- [x] `Core/MultiBotHandler.lua`
  - Preserve `IconosPoint` compatibility.

### Target responsibilities
- [x] Controller-owned page state.
- [x] Controller-owned sort/search state.
- [x] Pooled icon button refresh pipeline.
- [x] Explicit summary text (`page`, `count`, and optionally visible range).
- [x] Explicit empty-state rendering when a search yields no match.
- [x] Compatibility shim only where needed during the transition.

---

## 6) UX recommendations for the Ace3 rewrite

### Baseline recommendation
Keep the **Itemus-style host window** and visual language, but simplify the control surface because `Iconos` has a single dataset and no hierarchical filters.

### Recommended first-pass improvements
- [x] **Alphabetical sorting toggle** (`A → Z` / `Original order`).
- [x] **Search box** filtering by icon basename and full path.
- [x] **Result summary** showing something like `1-112 / 5997 icons`.
- [x] **Copy-friendly path display** in a dedicated text area or selectable input widget.
- [x] **Stable pooled grid** instead of recreating all visible buttons on each refresh.

### Nice improvements if scope allows
- [x] **Jump-to-letter** shortcut (`A`, `B`, `C`, ...).
- [ ] **Recent/favorite icons** if the GM workflow benefits from repetition.
- [x] **Path-only search mode** for technical users.
- [x] **Optional larger preview pane** for the selected icon.
- [ ] **Case-insensitive normalized sort** so irregular uppercase entries do not feel random.

### Recommendation priority
1. **Search box** → biggest productivity gain.
2. **Alphabetical sort toggle** → best harmonization with the requested Itemus-style modernization.
3. **Visible result counter/range** → clarifies navigation immediately.
4. **Copy-friendly selected path field** → makes the tool genuinely more useful than the legacy version.

---

## 7) Feature parity checklist

### A. Window lifecycle
- [x] Opening ICONOS from the `Masters` menu still opens the correct window.
- [x] Reopening ICONOS reuses screen state safely.
- [x] Closing from the AceGUI close button works consistently.
- [x] Escape/close behavior matches the other migrated AceGUI windows.
- [x] Position persistence still uses `IconosPoint` semantics.
- [x] Ace3 title drag hint reuses `tips.move.iconos`.

### B. Dataset/view model
- [x] The icon dataset is still available without regression.
- [x] Original legacy order remains available even if alphabetical sorting is added.
- [x] No icon path disappears silently during normalization.
- [x] Irregular paths remain visible and testable.

### C. Pagination/results
- [x] Default page size remains `112` unless intentionally changed later.
- [x] Previous/next visibility remains correct.
- [x] Page label remains correct after page navigation and reopen cycles.
- [x] Result summary remains accurate.
- [x] Empty search results produce a deterministic in-window empty state.

### D. Interactions
- [x] Hovering an icon still shows the short name and full path.
- [x] Missing/invalid textures fall back safely.
- [x] A selected icon can expose its path in a copy-friendly way.
- [x] Hidden pooled icon buttons clear stale metadata before reuse.

### E. Integration / localization
- [x] `tips.game.iconos` continues to describe the screen correctly.
- [x] Existing `tips.move.iconos` remains valid and is still consumed by the Ace3 screen.
- [x] No regression is introduced for the `Masters` utility menu flow.
- [x] The TOC load order is updated if a new dedicated UI file is added.

---

## 8) Known migration risks and mitigations

### Risk 1 — Accidental “wrapper migration”
- Problem: embedding the old `MultiBot.iconos` frame inside an AceGUI container would violate the migration goal.
- Mitigation: the new screen must own its own layout, paging controls, tooltip handling, and dense grid from day one.

### Risk 2 — Losing the current scan speed
- Problem: over-designing the screen could make the icon browser slower than the current compact grid.
- Mitigation: preserve a dense icon-first layout and keep advanced controls lightweight.

### Risk 3 — Breaking saved coordinates
- Problem: replacing the host frame without preserving `IconosPoint` would regress user expectations and reset flows.
- Mitigation: bind the AceGUI frame position to the existing saved-layout helpers.

### Risk 4 — Over-normalizing the dataset
- Problem: cleaning the icon names too aggressively could hide malformed-but-real legacy entries.
- Mitigation: preserve the raw source paths and treat normalization as a derived display/search layer, not as destructive data cleanup.

---

## 9) Proposed migration sequence

### Phase 1 — Audit and tracking
- [x] Audit current legacy behavior.
- [x] Create this tracking document.
- [ ] Document the final target file path and TOC insertion point in the implementation PR.

### Phase 2 — Data/controller boundary
- [x] Split raw icon data access from the new controller/view layer.
- [x] Introduce a controller API for page, sort, search, and selection state.
- [x] Preserve original-order browsing while enabling derived filtered views.

### Phase 3 — AceGUI host window
- [x] Create a native AceGUI ICONOS host window.
- [x] Bind saved position using `IconosPoint`.
- [x] Bind close behavior and Escape integration.
- [x] Recreate the dense icon grid with pooled icon widgets/buttons.

### Phase 4 — UX uplift
- [x] Add search.
- [x] Add alphabetical/original-order sorting.
- [x] Add results summary and selected-path display.
- [ ] Validate that the screen still feels fast for GM usage.

### Phase 5 — Legacy removal and validation
- [x] Remove legacy `MultiBot.newFrame(...)` construction and related hardcoded shell widgets.
- [x] Update documentation/checklists once the migration lands.
- [ ] Smoke-test open/close, drag, page navigation, search, sort, and tooltip parity.

---

## 10) Decision proposal for the actual implementation

### Recommended implementation direction
- Use the **Itemus AceGUI window style** as the presentation template.
- Keep a **dense icon grid** as the main content area.
- Add a **small top control bar** with:
  - search input,
  - sort selector/toggle,
  - results summary,
  - previous/next paging.
- Add a **bottom or side detail field** showing the selected icon path for easy copy/reference.

### Why this is the best next step
- It preserves the current fast browsing workflow.
- It aligns visually with the newer Ace3 windows.
- It improves utility without changing the core purpose of the tool.
- It avoids making Iconos heavier than Itemus while still reusing its modern layout language.