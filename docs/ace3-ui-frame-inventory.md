# ACE3 UI Frame Inventory (Milestone 8)

Inventory of addon UI frame construction points found via `CreateFrame(...)` scan in `Core/`, `UI/`, and `Features/`.

> Goal: track every user-facing frame cluster to migrate to AceGUI (screen-by-screen), and check off progress per PR.

## Status legend
- `[x]` Migrated to AceGUI path (legacy fallback may still exist temporarily).
- `[ ]` Not migrated.
- `[-]` Keep as native frame (non-screen utility/runtime frame).

---

## 1) Interface Options / Configuration

- [x] **Options panel** (`/mbopt`, Interface Options category) — AceGUI path in place with temporary legacy fallback.
  Files: `UI/MultiBotOptions.lua` (panel + sliders/dropdowns/buttons)..  
  References: `UI/MultiBotOptions.lua:234`, `UI/MultiBotOptions.lua:268`.

---

## 2) Dedicated top-level windows/popups (user-facing)

> Follow-up note: the Quest/GameObject slice already has AceGUI hosts, but its implementation still lives mainly in `Core/MultiBotInit.lua`. The extraction/rewrite plan is tracked in `docs/ace3-quests-gobjects-migration-tracker.md`.

- [x] **PVP window** (`MultiBotPVPFrame`) with tabs and dropdown (AceGUI widgets for tab group + bot dropdown, with legacy fallback).
  File: `UI/MultiBotPVPUI.lua`.  
  References: lines `11`, `98`, `201`.

- [x] **Spec window / inspect helpers** (`df` popup and related frame/button controls) migrated and finalized with AceGUI window path (close-cross UX), corrected layering/clickability, compacted frame height, and preserved legacy icon-button inspect-refresh behavior.
  File: `UI/MultiBotSpecUI.lua`.  
  References: lines `542`, `590` (plus timer/utility frames at `231`, `294`).

- [x] **Raidus management window** (`MultiBot.raidus`) finalized for the M8 slice with AceGUI host window path + legacy fallback, close-button state synchronization, visual polish, and drag/drop feedback integration.
  File: `Features/MultiBotRaidus.lua`.
  References: lines `119`, `164`, `599`, `1372`.
  
- [x] **Quest summary popup** (`MB_QuestPopup`) migrated to an AceGUI host window path, but the screen implementation is still in `Core/MultiBotInit.lua`; dedicated `UI/` extraction + full native rewrite plan is tracked in `docs/ace3-quests-gobjects-migration-tracker.md`.
  File: `Core/MultiBotInit.lua`.  
  References: lines `1760`, `1787`, `1845`.

- [x] **Bot quest popup** (`MB_BotQuestPopup`) migrated to an AceGUI host window path, but the screen implementation is still in `Core/MultiBotInit.lua`; dedicated `UI/` extraction + full native rewrite plan is tracked in `docs/ace3-quests-gobjects-migration-tracker.md`.
  File: `Core/MultiBotInit.lua`.  
  References: lines `1942`, `1966`, `1995`.

- [x] **Bot quest complete popup** (`MB_BotQuestCompPopup`) migrated to an AceGUI host window path, but the screen implementation is still in `Core/MultiBotInit.lua`; dedicated `UI/` extraction + full native rewrite plan is tracked in `docs/ace3-quests-gobjects-migration-tracker.md`.
  File: `Core/MultiBotInit.lua`.  
  References: lines `2161`, `2185`, `2215`.

- [x] **Bot quest all popup** (`MB_BotQuestAllPopup`) migrated to an AceGUI host window path, but the screen implementation is still in `Core/MultiBotInit.lua`; dedicated `UI/` extraction + full native rewrite plan is tracked in `docs/ace3-quests-gobjects-migration-tracker.md`.
  File: `Core/MultiBotInit.lua`.  
  References: lines `2387`, `2416`, `2467`

- [x] **GameObject popup/copy box** (`MB_GameObjPopup`, `MB_GameObjCopyBox`) migrated to AceGUI windows/widgets paths, but the implementation is still coupled to `Core/MultiBotInit.lua`; dedicated `UI/` extraction + Itemus-style harmonization plan is tracked in `docs/ace3-quests-gobjects-migration-tracker.md`.
  File: `Core/MultiBotInit.lua`. 
  References: lines `2745`, `2789`

- [x] **Universal prompt dialog** (`MBUniversalPrompt`) migrated to AceGUI window+widgets path (no legacy frame fallback).
  File: `Core/MultiBotInit.lua`.  
  References: line `2893`.

- [x] **Hunter prompt/search/family windows** (`MBHunterPrompt`, `MBHunterPetSearch`, `MBHunterPetFamily`) migrated to AceGUI host/prompt paths (no legacy frame fallback for prompt/search/family hosts; preview model retained).
  File: `Core/MultiBotInit.lua`. 
  References: lines `5505`, `5551`, `5730`, `5588`.

- [x] **SpellBook window** (`MultiBot.spellbook`) migrated to AceGUI host window path with programmatic slot/check generation and stateful chat-collection handling (replacing legacy hardcoded slot blocks and inline footer-only stop logic).
  Files: `UI/MultiBotSpellBookFrame.lua`, `UI/MultiBotSpell.lua`, `Core/MultiBotHandler.lua`.
  References: lines `330`, `294`, `173`, `1517`.

- [x] **Reward window** (`MultiBot.reward`) migrated to a native AceGUI host window path with dedicated Reward module flow, stable close/paging behavior, and localized saved-state-aware config popup on activation.
  Files: `UI/MultiBotRewardFrame.lua`, `Features/MultiBotReward.lua`, `Core/MultiBotInit.lua`.
  References: `UI/MultiBotRewardFrame.lua:193`, `Features/MultiBotReward.lua:5`, `Core/MultiBotInit.lua:1510`.

- [x] **Inventory window** (`MultiBot.inventory`) migrated to a native AceGUI host window path with dedicated controller API, item renderer split, hybrid dense-icon scroll grid, action/refresh parity, and legacy shell removal.
  Files: `UI/MultiBotInventoryFrame.lua`, `UI/MultiBotInventoryItem.lua`, `Core/MultiBotHandler.lua`, `Core/MultiBotEvery.lua`, `Core/MultiBotEngine.lua`.
  References: `UI/MultiBotInventoryFrame.lua:704`, `UI/MultiBotInventoryItem.lua:221`, `Core/MultiBotHandler.lua:1506`, `Core/MultiBotEvery.lua:142`, `Core/MultiBotEngine.lua:1554`.

- [x] **Talents/Glyphs frame** (`MultiBot.talent`) migrated with AceGUI host integration for the talents/glyphs workflow while preserving tab-state, copy/apply actions, and custom glyph socket interactions.
  File: `UI/MultiBotTalentFrame.lua`.
  References: lines `5`, `23`, `119`, `2228`.

- [x] **ITEMUS frame** (`MultiBot.itemus`) migrated to a native AceGUI host window with a dedicated UI module, controller-owned paged payloads, lazy launcher/reset initialization, preserved filter semantics (`Level`/`Rare`/`Slot`/`Type`), dense item grid, and localized in-window guidance based on the existing `tips.game.itemus` text.
  Files: `UI/MultiBotItemusFrame.lua`, `Data/MultiBotItemus.lua`, `Core/MultiBotInit.lua`.
  References: `UI/MultiBotItemusFrame.lua:3`, `Data/MultiBotItemus.lua:43881`, `Core/MultiBotInit.lua:1661`.

- [x] **ICONOS frame** (`MultiBot.iconos`) migrated to a native AceGUI host window with a dedicated UI module, legacy shell removal, dense 112-icon grid parity, persistent `IconosPoint` anchoring, ESC close support, in-window path reuse, and a first UX uplift pass with search (`ALL/PATH`) + original/A-Z ordering + selected-icon preview + jump-to-letter.
  Files: `UI/MultiBotIconosFrame.lua`, `Core/MultiBotInit.lua`, `UI/MultiBotIconos.lua`, `Core/MultiBotHandler.lua`.
  References: `UI/MultiBotIconosFrame.lua:1`, `Core/MultiBotInit.lua:1675`, `Core/MultiBotInit.lua:3189`, `UI/MultiBotIconos.lua:1`, `Core/MultiBotHandler.lua:265`.

- [x] **Quick Hunter / Quick Shaman bars** (`MultiBot.HunterQuick`, `MultiBot.ShamanQuick`) migrated out of `Core/MultiBotInit.lua` into dedicated UI modules with native AceGUI-hosted quick frames, preserved position/state persistence, validated gameplay parity, and a compact persisted show/hide handle for both class-specific mini bars without reintroducing legacy shells.
   Files: `UI/MultiBotHunterQuickFrame.lua`, `UI/MultiBotShamanQuickFrame.lua`, `Core/MultiBotInit.lua`, `Core/MultiBot.lua`.
   References: `UI/MultiBotHunterQuickFrame.lua:1`, `UI/MultiBotShamanQuickFrame.lua:1`, `Core/MultiBotInit.lua:1916`, `Core/MultiBotInit.lua:3437`, `Core/MultiBotInit.lua:3440`, `Core/MultiBot.lua:613`, `Core/MultiBot.lua:858`.

---

## 3) Embedded controls inside existing screens (likely migrate with owning screen)

- [x] **Raidus slot/group controls** inside Raidus UI finalized in the Raidus migration slice.
  File: `Features/MultiBotRaidus.lua`.
  References: lines `415`, `945`, `989`, `1021`.

- [-] **Quest/localization tooltip frame** (`MB_LocalizeQuestTooltip`) kept as native tooltip; creation is now centralized via hidden-tooltip helper.
  File: `Core/MultiBotInit.lua`.  
  Reference: line `1730`.

- [-] **Hidden glyph tooltip** (`MBHiddenTip`) kept as native tooltip; now reuses the same hidden-tooltip helper.
  File: `Core/MultiBotInit.lua`.  
  Reference: line `4701`.

---

## 4) Runtime/utility frames (not direct Milestone 8 AceGUI screens)

- [-] **Minimap button** (`MultiBot_MinimapButton`) keep native frame.
  File: `Core/MultiBotInit.lua`.

- [-] **Event/timer/dispatch helper frames** (`CreateFrame("Frame")` without visible UI).
  Files: `Core/MultiBotThrottle.lua`, `Core/MultiBotHandler.lua`, `Core/MultiBotAsync.lua` (legacy fallback scheduler), `Core/MultiBotInit.lua` (misc helper frame usages).

- [-] **Engine widget factory primitives** in `Core/MultiBotEngine.lua` (button/check/model constructors for core UI system).
  These are shared low-level primitives and should be migrated only when the owning screen is migrated.

---

## Per-PR update rule

For each Milestone 8 PR:
1. Update this inventory file (`[ ] -> [x]`) for the migrated screen/control cluster.
2. Update `docs/ace3-expansion-checklist.md` progress bullets.
3. Keep migrations localized (one UI domain per PR).