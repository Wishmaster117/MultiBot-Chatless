# Localization String Inventory (Milestone 9 kickoff)

Initial inventory of user-facing hardcoded strings in `Core/`, `UI/`, and `Features/`.

## Method

- Commands used:
  - `rg -n 'SetText\(|tooltipText\s*=|AddLine\(|SendChatMessage\("' Core UI Features`
  - `rg -n 'MultiBot\.L\(\s*"[^"]+"\s*,' Core UI Features`
- Manual filtering was applied to keep only strings visible to users (panel labels, tooltips, tab labels, placeholders).

## Priority candidates

### UI

- `UI/MultiBotOptions.lua`
- Existing options labels/tooltips now route through locale keys without inline fallbacks in runtime call sites.
- `UI/MultiBotPVPUI.lua`
  - PvP panel labels now route through locale keys, with inline fallback duplicates removed in UI call sites.
  - Remaining direct `MultiBot.tips.*` reference (`pvparenanoteamrank`) has been migrated to `MultiBot.L("tips.every.pvparenanoteamrank")`.

### Core

- `Core/MultiBotThrottle.lua`
  - Runtime fallback literal removed from throttle installation message; call site now uses locale key only.
- `Core/MultiBotInit.lua`
  - Runtime localization reads in this file now use `MultiBot.L(...)` key lookups (including previous `MultiBot.tips.*` table reads migrated to locale keys).

### Features

- `Features/MultiBotReward.lua`
  - Whisper command construction is command protocol text, not user-facing labels.
  - No direct panel label migration performed in this kickoff.

## Inline fallback scan snapshot (current)

- Current scan result for `Core/UI/Features`:
  - `rg -n 'MultiBot\.L\(\s*"[^"]+"\s*,' Core UI Features`
  - No remaining `MultiBot.L(key, fallback)` call sites in these directories.

## Legacy tips-read scan snapshot (current)

- Focused scan for legacy table reads:
  - `rg -n 'MultiBot\.tips' Core UI Features`
- Current status:
  - `Core/MultiBotInit.lua`: migrated.
  - `UI/MultiBotPVPUI.lua`: migrated.
  - `Features/MultiBotRaidus.lua`: migrated.
  - `Core/MultiBotEvery.lua`: migrated.
  - `Core/MultiBotEngine.lua`: migrated.
  - `Core/MultiBotHandler.lua`: migrated for runtime tooltip string reads.
  - `Strategies/MultiBotDruid.lua`: migrated.
  - `Strategies/MultiBotPaladin.lua`: migrated.
  - `Strategies/MultiBotMage.lua`: migrated.
  - `Strategies/MultiBotWarlock.lua`: migrated.
  - Remaining major targets in `Strategies/`: none (completed).
  - `Core/MultiBot.lua` remaining `MultiBot.tips` matches are intentional bootstrap lines (`MultiBot.tips = {}` and `MultiBot.tips.spec = ...`), not user-facing runtime tooltip reads.


## Pipeline decisions in this kickoff

- Added a centralized locale access helper (`MultiBot.GetLocaleString` / `MultiBot.L`) with deterministic fallback order:
  1. Active AceLocale table
  2. Registered `enUS` defaults
  3. Per-call fallback string
  4. Locale key itself
- Added dedicated AceLocale registration file (`Locales/MultiBotAceLocale.lua`) to start new keys without rewriting legacy locale files.

## Next milestone-9 increments

1. Continue scanning `Core/UI/Features/Strategies` for any newly introduced user-facing hardcoded strings in incremental PRs.
2. Expand key coverage locale-by-locale while keeping deterministic fallback behavior.
3. Keep class-specific AoE labels routed through locale keys (e.g. `tips.deathknight.dps.frostAoe` / `tips.deathknight.dps.unholyAoe`) instead of inline literals.
4. Keep generic prompt defaults localized/client-localized (e.g. `OKAY` and `MultiBot.info.hunterpeteditentervalue`) instead of inline literals in prompt builders.
5. Use client-localized global constants for Blizzard UI nouns when available (e.g. `SPELLBOOK` instead of inline `"Spellbook"`).
6. Use client-localized role nouns when available (e.g. `PLAYER` instead of inline `"Player"` in stats widgets).
7. Use client-localized status constants when available (e.g. `LOADING` instead of inline loading labels).
8. Route quest-search empty-state text through locale keys (e.g. `tips.quests.gobnosearchdata`) instead of inline literals.

 ## Milestone 9 final status
 - Milestone 9 is now considered complete for the current localization scope.
 - Runtime user-facing reads previously using `MultiBot.tips.*` and `MultiBot.info.*` ... migrated to `MultiBot.L(...)`.
 - Final UI literal pass completed ...
 - Intentional non-migrated literals are limited to technical/protocol identifiers ...

 ## Post-Milestone 9 maintenance
 1. Continue scanning ...
 2. Expand key coverage ...
 3. Keep using client-localized Blizzard globals ...
 4. Keep technical/protocol identifiers unchanged unless the protocol itself is migrated.