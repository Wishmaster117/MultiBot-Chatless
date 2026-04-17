# Ace3 Inventory Migration Tracker (Milestone 8)

Dedicated tracking document for the full migration of the bot **INVENTORY** frame from the legacy `MultiBot.newFrame(...)` path to a native AceGUI/Ace3 implementation.

> Scope: migrate the bot inventory screen to a standalone UI module under `UI/`, remove the legacy frame shell for this screen, preserve all gameplay behavior, and modernize the Lua structure without regressing the playerbots command flow.

---

## 1) Current legacy scope

### Source-of-truth files
- `Core/MultiBotInit.lua`
- `Core/MultiBotEvery.lua`
- `Core/MultiBotHandler.lua`
- `Core/MultiBotEngine.lua`
- `UI/MultiBotItem.lua`
- `UI/MultiBotRewardFrame.lua`

### Legacy responsibilities currently coupled together
- Window creation and static layout.
- Inventory mode/action state (`sell`, `equip`, `use`, `trade`, `destroy`).
- Item grid population from bot chat lines.
- Refresh orchestration (`items` request replay).
- Close/open synchronization with the bot button in the main MultiBar.
- Follow-up flows after trade close and loot/open events.

---

## 2) Migration goals

### Functional goals
- [x] Preserve the exact bot command protocol (`items`, `stats`, `open items`, `s *`, `s vendor`, item actions by whisper).
- [x] Preserve close/open parity with the per-bot `Inventory` button.
- [x] Preserve the current action model: exclusive action modes plus instant actions.
- [x] Preserve refresh behavior after sell, trade close, loot/open, and bulk vendor actions.
- [x] Preserve safeguards around Hearthstone, keys, and epic+ destruction confirmation.
- [x] Preserve title updates and selected bot state.
- [x] Preserve compatibility with callers outside the main Inventory button flow (notably reward/inspect helpers).

### Technical goals
- [x] Remove the legacy visual shell for `MultiBot.inventory`.
- [x] Rebuild the screen as a native AceGUI window, not a legacy frame hosted inside AceGUI.
- [x] Move the screen implementation into a dedicated file under `UI/`.
- [x] Reduce UI/protocol coupling by introducing a clearer controller boundary.
- [x] Modernize local helpers/state handling in Lua while keeping the existing addon architecture stable.
- [x] Keep position persistence behavior aligned with the existing `InventoryPoint` expectation, or migrate it safely.

---

## 3) Recommended target structure

### Planned UI/module split
- [x] `UI/MultiBotInventoryFrame.lua`
  - AceGUI host window creation.
  - Layout composition.
  - Widget lifecycle.
  - Public open/hide/refresh hooks for the inventory screen.
- [x] `UI/MultiBotInventoryItem.lua` *(chosen split: inventory item renderer extracted from the generic legacy file for this migration)*
  - Item widget creation/binding.
  - Tooltip binding.
  - Item click dispatch to the active inventory action.
- [x] Existing handler integration in `Core/MultiBotHandler.lua`
  - Chat-driven data intake remains here unless a later refactor extracts protocol dispatch more broadly.
- [x] Existing request/refresh integration in `Core/MultiBotEvery.lua` and `Core/MultiBotEngine.lua`
  - Keep the external entrypoints stable while redirecting them to the new module behavior.

### Target responsibilities
- [x] Window/controller state.
- [x] Action-mode state.
- [x] Item collection/render state.
- [x] Refresh/request bridge.
- [x] Legacy compatibility shims kept only where needed during transition.

---

## 4) Feature parity checklist

### A. Window lifecycle
- [x] Opening inventory from a bot button selects the correct bot.
- [x] Opening inventory disables other bots' inventory toggles as before.
- [x] Closing from the window close button synchronizes the source bot button state.
- [x] Reopening the same bot inventory after close works without recreating stale state.
- [x] Escape/close behavior is consistent with other migrated AceGUI windows if applicable.

### B. Header/state
- [x] Window title reflects `NAME's Inventory` / localized equivalent.
- [x] Current bot name is stored centrally and reused by refresh/actions.
- [x] Default state when no bot is active is safe and inert.

### C. Action controls
- [x] `Sell` is an exclusive toggle mode.
- [x] `Equip` is an exclusive toggle mode.
- [x] `Use` is an exclusive toggle mode.
- [x] `Trade` is an exclusive toggle mode and still initiates trade correctly.
- [x] `Destroy` is an exclusive toggle mode.
- [x] `SellGrey` remains an instant action (`s *`).
- [x] `SellVendor` remains an instant action (`s vendor`).
- [x] `Open` remains an instant action (`open items`).
- [x] Switching modes still cancels incompatible trade state where required.
- [x] The UI clearly exposes which action mode is active.

### D. Item grid/content
- [x] The item list is cleared before a new inventory payload is rendered.
- [x] Items are added incrementally as chat lines arrive.
- [x] Tooltips show the item hyperlink correctly.
- [x] Clicking an item with no selected action still gives user feedback.
- [x] Layout supports the full inventory payload without depending on the legacy background texture shell.

### E. Item action rules
- [x] Selling still requires a valid vendor target.
- [x] Selling Hearthstone is blocked.
- [x] Selling keys is blocked.
- [x] Destroying Hearthstone asks for confirmation.
- [x] Destroying keys asks for confirmation.
- [x] Destroying epic-or-better items asks for confirmation.
- [x] Equip/use/trade actions still send the correct whisper command.
- [x] Immediate local feedback after destructive/vendor actions remains coherent.

### F. Refresh/event flows
- [x] `RefreshInventory(delay)` still works against the new window/controller state.
- [x] Selling an item triggers a delayed refresh.
- [x] `SellGrey` triggers a refresh.
- [x] `SellVendor` triggers a refresh.
- [x] `TRADE_CLOSED` still refreshes the currently open inventory.
- [x] Opening loot containers still triggers the `LOOT -> INVENTORY` recovery path.

### G. Cross-feature integration
- [x] Reward/inspect helpers can still request inventory data for a bot.
- [x] The main MultiBar button flow remains the canonical entrypoint.
- [x] No regression is introduced for stats/inspect follow-up triggered during inventory loading.

---

## 5) Proposed migration sequence

### Phase 1 — Extraction prep
- [x] Document all current entrypoints and side effects.
- [x] Inventory module file introduced under `UI/` (`UI/MultiBotInventoryFrame.lua`).
- [x] Item rendering moved to `UI/MultiBotInventoryItem.lua` with `UI/MultiBotItem.lua` kept as a thin compatibility shim.

### Phase 2 — AceGUI window host
- [x] AceGUI inventory host window created.
- [x] Recreate header/title/close behavior natively.
- [x] Visibility/open/close state wired to the existing bot-button flow.
- [x] Preserve persisted position semantics.

### Phase 3 — Action layer
- [x] Recreate the left action column with AceGUI/native widgets as needed.
- [x] Replace manual button-to-button exclusivity with centralized action-state logic.
- [x] Preserve instant action commands and target checks.

### Phase 4 — Item rendering
- [x] Rebuild the item area in the new screen.
- [x] Rebind tooltips and click handlers.
- [x] Preserve item metadata storage required by existing action rules.

### Phase 5 — Handler/refresh integration
- [x] Redirect inventory population to the new view/controller.
- [x] Validate `INVENTORY -> ITEM -> LOOT` transitions.
- [x] Validate trade-close refresh and delayed refresh paths.

### Phase 6 — Legacy removal
- [x] Remove the legacy Inventory frame construction from `Core/MultiBotInit.lua`.
- [x] Remove obsolete helper assumptions tied only to the old shell.
- [x] Update the Milestone 8 docs/checklists to mark the screen as migrated.

---

## 6) Non-regression test matrix

### Manual gameplay checks
- [ ] Open bot A inventory from MultiBar.
- [ ] Switch to bot B inventory from MultiBar.
- [ ] Close inventory from the window close button.
- [ ] Activate `Sell`, click a normal item at vendor.
- [ ] Activate `Sell`, click Hearthstone.
- [ ] Run `SellGrey` at vendor.
- [ ] Run `SellVendor` at vendor.
- [ ] Activate `Equip`, click equippable item.
- [ ] Activate `Use`, click usable item.
- [ ] Activate `Trade`, click item, then close trade.
- [ ] Activate `Destroy`, click a normal item.
- [ ] Activate `Destroy`, click a protected item needing confirmation.
- [ ] Use `Open` on a loot container item.
- [ ] Trigger inventory request from reward/inspect path.

### Static/code checks for the PR
- [x] TOC load order updated if new UI file is added.
- [x] No remaining user-facing dependency on the legacy Inventory texture shell.
- [x] Inventory migration is documented in the milestone checklist files.
- [x] No dead references to removed legacy inventory widgets remain.

---

## 7) Open design decisions

- [x] Item renderer moved to `UI/MultiBotInventoryItem.lua`; `UI/MultiBotItem.lua` now remains only as a compatibility shim for the existing global entrypoint.
- [x] The new inventory host uses a hybrid AceGUI host plus native scroll child for dense icon rendering.
- [x] `InventoryPoint` is preserved as-is with backward-compatible layout persistence wiring for the AceGUI host.
- [x] Should close-button parity be handled by calling the source MultiBar button behavior directly, or by centralizing open/close state in an inventory controller API?

---

## 8) PR checklist for the future migration patch

- [x] New dedicated inventory UI file added under `UI/`.
- [x] Legacy inventory shell removed from `Core/MultiBotInit.lua`.
- [x] Existing inventory flows verified against the parity checklist above.
- [x] `docs/ace3-ui-frame-inventory.md` updated.
- [x] `docs/ace3-expansion-checklist.md` updated.
- [x] Screenshot captured if the final UI change is visually testable in this environment.
- [x] Final PR summary explicitly calls out preserved behaviors and any intentional UX improvements.