<p align="center">
  <img width="1024" height="1024" alt="MultiBot Chatless" src="https://github.com/user-attachments/assets/08aa1768-f5c2-49ce-9fe0-a22adb184ce7" />
</p>

<div align="center">

# MultiBot Chatless

### Bridge-first Playerbots control for World of Warcraft 3.3.5a

<strong>MultiBot Chatless</strong> is a client addon for AzerothCore `mod-playerbots`.
It keeps the familiar MultiBot UI while moving more bot reads and actions away from automatic chat commands and into a structured server bridge.

<br>

<img alt="WoW Version" src="https://img.shields.io/badge/client-WotLK%203.3.5a-lightgrey" />
<img alt="Architecture" src="https://img.shields.io/badge/architecture-bridge--first-success" />
<img alt="Status" src="https://img.shields.io/badge/status-mostly%20chatless-blue" />

</div>

---

## Companion Bridge Required

This repository contains the **client addon**.

For the bridge-first features you also need:

### [`mod-multibot-bridge`](https://github.com/Wishmaster117/mod-multibot-bridge)

Install the addon as:

```text
World of Warcraft/Interface/AddOns/MultiBot
```

The folder must be named `MultiBot`.

---

# What the Addon Does

MultiBot Chatless provides a UI for controlling, inspecting and managing Playerbots without flooding normal gameplay with automatic bot chat replies.

The addon still supports intentional manual Playerbots commands where they are useful, but the main direction is:

```text
UI action
  -> structured addon message
  -> mod-multibot-bridge
  -> validated server-side action/read
  -> structured result
  -> authoritative UI refresh
```

The project is currently **bridge-first / mostly chatless** rather than fully chatless. Remaining automatic chat paths are migrated only after targeted audit and runtime validation.

---

# Main Features

| Area | Current behavior |
| --- | --- |
| **Bot rosters** | My Bots / Altbots, Group, Guild, Friends and Favorites with online/offline presence and structured lifecycle handling. |
| **Bot connect / disconnect** | `ALT_ROSTER_V1`, `BOT_LIFECYCLE_V1`, `BOT_TARGET_RESOLVE_V1` and `BOT_GROUP_LIFECYCLE_V1` provide structured discovery, unit lifecycle control and bounded group/raid bulk connect-disconnect from the Faction Banner. Offline EveryBars stay collapsed; online EveryBars expand consistently. |
| **Creator AddClass** | `CREATOR_ADDCLASS_V1` routes class/gender bot selection through the Bridge. Random, Male, Female and Death Knight paths are runtime validated; existing auto-group and roster refresh behavior is preserved. |
| **Creator Auto Init** | `CREATOR_INIT_AUTO_V1` routes target and group `init=auto` through the Bridge, which reuses Playerbots authorization and initialization rules instead of accepting a raw command string. |
| **Bot state & strategies** | Framed bot-state reads and structured strategy mutations for migrated controls, including Warlock selectors. |
| **Inventory** | Bag-aware exact inventory for Backpack, Bag 1..4 and Keyring, including empty slots and container filtering. |
| **Item movement** | Whole-stack drag/drop between supported physical inventory slots through the Bridge. |
| **Equipment** | Structured equip and unequip workflows with authoritative refresh. |
| **Trade & item use** | Exact-item Trade, item use and item destruction through dedicated structured actions. |
| **Vendor** | Single-item sale, bulk Sell Vendor, Buyback and Open Items bridge workflows. |
| **Bank / Guild Bank** | Bridge-backed views and actions; exact physical BANK/GBANK deposits are implemented. |
| **Talents** | Premade specialization apply and editable custom talent apply with server verification. |
| **Glyphs** | Glyph display and apply-related workflows integrated with the character UI. |
| **Professions** | Profession recipe browsing/crafting plus targeted item recipes. |
| **Enchanting** | Dedicated Enchanting Trade Service using the native WoW Trade workflow. |
| **Quests** | Bridge-backed quest list and abandon plus structured `QUEST_ACCEPT_ALL_V1`, `QUEST_TALK_V1`, `QUEST_GAMEOBJECT_USE_V1`, `QUEST_REWARD_V1` and `QUEST_REWARD_POLICY_V1` interactions. Native quest sharing remains available where intentionally retained. |
| **Autogear** | `AUTOGEAR_OPTIONS_V1` exposes server limits, quality/iLvl modes, explicit reset, PLAN → confirmation → APPLY, eight-locale UI, AceGUI presentation and deferred opening for ineligible bots. |
| **Hunter Pet** | Structured Hunter pet control through `HUNTER_PET_CONTROL_V1`, `HUNTER_PET_MANAGE_V1` and `HUNTER_PET_LIFECYCLE_V1`: stance/attack/follow/stay, tame by creature ID or family, rename, permanent abandon, temporary dismiss and Call Pet. |
| **Loot** | Structured loot profiles and exact persistent always-loot item add/remove. |
| **Group tools** | Formation, Roll, RTI, Pull Control and Disperse, plus bridge-first `FOLLOW_ORDER_V1`, `STAY_ORDER_V1`, `ATTACK_ORDER_V1`, `FLEE_ORDER_V1`, bounded `GROUP_ACTION_V1` and `RTSC_ORDER_V1`. RTSC selection, saved spots and GO/CANCEL now use the Bridge while AEDM movement remains the native WoW/Playerbots spell path. |
| **Raidus raid planner** | Persistent 8×5 Working Layout, Saved Layouts, Score/Level/Class sorting, drag/drop, Auto balance, structured Apply and human-safe outside-layout bot removal through `BOT_GROUP_REMOVE_V1`. |
| **Character information** | Bot skills, reputations, currencies/emblems, spellbook browsing/cast with authoritative ignored-spell management, stats and PvP stats. |
| **Outfits** | Outfit listing and actions through the Bridge. |
| **SelfBot** | Dedicated enable/disable, strategy and selected action support. |
| **Localization** | Eight runtime locales: `enUS`, `enGB`, `frFR`, `esES`, `deDE`, `ruRU`, `zhCN` and `koKR`. |

---

# Recent Milestone — Alt Roster & Bot Lifecycle

The roster/lifecycle work was merged and post-merge audited on **30 August 2026**.

It standardizes lifecycle behavior across:

- My Bots / Altbots;
- Group;
- Guild;
- Friends;
- Favorites.

User-facing behavior now follows the same rule everywhere:

- **offline bot** → EveryBar collapsed;
- **online bot** → EveryBar expanded;
- roster-specific UI state must not leak into another roster.

The companion Bridge also gained the server-side lifecycle authorization and hardening required for these flows.

---

# Recent Milestone — Raidus Working Layout & Safe Apply

Raidus was completed and runtime validated on **3 September 2026** as a persistent raid-planning workflow.

Current behavior includes:

- an **8 groups × 5 slots** Working Layout;
- persistent Working Layout restoration across close/reopen and `/reload`;
- Saved Layout slots exposed by the UI;
- Score, Level and Class pool sorting;
- drag/drop and slot swapping;
- score-based and role-based Auto balance;
- structured bot connect/disconnect from the pool;
- structured `Apply` for required bot connections;
- `BOT_GROUP_REMOVE_V1` for safe removal of managed Playerbots that are currently grouped but absent from the layout;
- an empty Working Layout acting as **cleanup-only** instead of starting AutoSort.

The Bridge revalidates group-removal mutations server-side. A connected human player is not treated as a Playerbot simply because that character is in the group.

See the [Raidus User Guide](docs/RAIDUS_GUIDE.md) for the current user-facing workflow.

---

# Recent Milestone — Bulk Group Lifecycle

The Faction Banner bulk lifecycle path was completed, compiled and runtime validated on **6 September 2026**.

The addon now uses the dedicated capability:

```text
BOT_GROUP_LIFECYCLE_V1
```

for the historical group-wide lifecycle actions:

- left click → structured `CONNECT`;
- right click → structured `DISCONNECT`;
- scope → the requester's real party/raid membership, excluding the requester;
- disconnect → bots go offline without being forcibly removed from the group;
- connect → offline controllable group members are handed back to Playerbots for normal asynchronous login.

The structured path preserves Playerbots' real-group `*` semantics without interpreting `*` as every bot on the account. The legacy `.playerbot bot add *` / `.playerbot bot remove *` transport remains only behind the explicit compatibility fallback and was not observed during the validated runtime test.

---

# Recent Milestone — Creator AddClass

The Creator `addclass` path was migrated and runtime validated on **6 September 2026** through the dedicated capability:

```text
CREATOR_ADDCLASS_V1
```

The normal Creator flow now sends only typed class/gender data to the Bridge. The Bridge validates the request, builds the specialized Playerbots `addclass` operation server-side, and preserves Playerbots' existing AddClass pool, permission and Death Knight level rules.

Validated runtime behavior:

- Random → OK;
- Male → OK;
- Female → OK;
- Death Knight → OK;
- automatic group invitation preserved;
- roster refresh and EveryBar behavior preserved;
- no `.playerbot bot addclass ...` SAY observed with `MultiBot.allowLegacyChatFallback = false`;
- no Lua error or crash observed.

The legacy AddClass chat producer remains compatibility-fallback-only. Creator `init=auto` has since been migrated separately through `CREATOR_INIT_AUTO_V1`.

---

# Recent Milestone — Creator Auto Init

Creator `init=auto` was migrated after AddClass through the dedicated capability:

```text
CREATOR_INIT_AUTO_V1
```

The addon sends only a bounded semantic mode (`TARGET` or `GROUP`) and, for target mode, the requested bot name. The Bridge revalidates requester/session state, target/control rights, rate limits and replay tokens, then delegates the actual initialization to Playerbots' native `init=auto` behavior.

The group path scans the requester's real group/raid membership, initializes only controlled eligible AddClass bots, and returns structured initialized/skipped/failed counts. No generic Playerbots command executor was added, and the old chat path remains compatibility-fallback-only.

---

# Recent Milestone — Flee Chatless

Flee was migrated, compiled and runtime validated on **11 September 2026** through the dedicated capability:

```text
FLEE_ORDER_V1
```

The structured path covers:

- `ALL`;
- `TARGET`;
- `TANK`;
- `HEALER`;
- `DPS`;
- `MELEE`;
- `RANGED`.

The Bridge remains authoritative for role matching and invokes the audited native Playerbots `flee chat shortcut` behavior rather than reimplementing Flee movement/strategy logic in the addon. `ALL` and successful `TARGET` feedback show bot names, while role-scoped Flee receives authoritative per-bot `FLEE_ORDER_ITEM` results before the final `FLEE_ORDER_ACK`.

Normal Playerbots Flee success whispers are filtered client-side only while a matching Flee request is pending. Playerbots error feedback and unrelated human whispers remain visible. Runtime validation covered ALL, controlled TARGET, non-bot TARGET rejection, all role audiences, name feedback, whisper suppression and Follow / Stay / Attack non-regression.

The bounded Group Actions set `drink`, `release`, `revive` and `summon` has since been migrated through `GROUP_ACTION_V1`, and RTSC has now been migrated through `RTSC_ORDER_V1`.

---

# Recent Milestone — Group Actions Chatless

The bounded Group Actions set was migrated, compiled and runtime validated on **11 September 2026** through:

```text
GROUP_ACTION_V1
```

Covered actions are:

- `drink` → native Playerbots `drink`;
- `release` → native Playerbots `release`;
- `revive` → native Playerbots `spirit healer`;
- `summon` → native Playerbots `summon`.

The Bridge keeps a closed action allowlist, revalidates requester/group/bot state and Playerbots control permission, and reuses the existing group-order rate-limit, replay protection and validated 40-bot bound. The addon routes only these four exact actions through this endpoint.

Runtime validation covered all four actions, including the full `Release -> Revive` ghost/spirit-healer flow. `GROUP_ACTION_ACK` was observed, no automatic legacy PARTY/RAID command chat was observed, `MultiBotComm.lua` remained at **199 top-level locals**, and `mod-playerbots` remained strictly read-only.

RTSC has since been migrated through `RTSC_ORDER_V1`. Quest interactions and Autogear are now also closed; the active queue has moved to the remaining ordinary-bot actions and the final legacy parser/fallback cleanup.

---

# Recent Milestone — RTSC Chatless

RTSC was migrated, compiled and runtime validated on **12 September 2026** through:

```text
RTSC_ORDER_V1
```

The structured endpoint accepts only the audited semantic operations:

```text
ENABLE
RESET
SELECT
CANCEL
SAVE
UNSAVE
GO
```

Supported audiences are `ALL`, `TANK`, `HEALER`, `DPS`, `MELEE`, `RANGED`, `MELEE_DPS`, `RANGED_DPS` and `GROUPS`. Group selection uses a bounded bitmask; the current UI exposes groups 1..5, while the protocol validates the mask within its defined 1..31 bound. `SAVE`, `UNSAVE` and `GO` use slots 1..9.

The Bridge delegates RTSC behavior to the native Playerbots `rtsc` action through `PlayerbotAI::DoSpecificAction(...)`. It does **not** receive raw movement coordinates and does not recreate the AEDM packet path. `/cast aedm` remains a native WoW cast handled by Playerbots `SeeSpellAction` / `MoveToSpell`.

Runtime validation covered ENABLE/RESET, all role audiences, groups 1..5, multi-group selection, SAVE/GO/UNSAVE, CANCEL, AEDM movement and the expected Follow-versus-Stay behavior. The RTSC group selector Lua pattern hotfix was also validated with no recurring Lua error. `MultiBotComm.lua` remains at **199 top-level locals**, and `mod-playerbots` remained strictly read-only.

Canonical final audit:

```text
audit-multibot-rtsc-order-v1-final-v1b-2026-09-12-122116.zip
SHA-256 FDE1388AD4F297A1552CD64F2805DB20CFC97F6A6CBA0050F71B484DD40FD297
FINAL_STATUS=OK
```

---

# Recent Milestone — Structured Quest Interactions

The main Quest interaction family is now structured through:

```text
QUEST_ACCEPT_ALL_V1
QUEST_TALK_V1
QUEST_GAMEOBJECT_USE_V1
QUEST_REWARD_V1
QUEST_REWARD_POLICY_V1
```

The Bridge remains authoritative for requester/bot validation and adapts these bounded requests to the audited Playerbots quest actions. Reward policy is sent as authoritative Bridge state, while gameobject use and reward selection use typed target/item data rather than a free-form command channel.

The Addon HEAD also includes the structured-only GameObject search/loading-gate correction used by the Quest workflow.

---

# Recent Milestone — Autogear Options

Autogear options were completed and runtime validated on **17 September 2026** through:

```text
AUTOGEAR_OPTIONS_V1
```

The panel now provides:

- authoritative server quality/iLvl limits;
- server defaults, explicit quality, match-player-iLvl and custom-iLvl modes;
- explicit reset of worn equipment;
- `PLAN → confirmation → APPLY` instead of immediate mutation;
- a silent lifecycle reset that avoids false login/reload warnings;
- 49 Autogear locale keys in each of the eight loaded locales;
- an AceGUI window consistent with current MultiBot UI;
- deferred opening: an ineligible bot such as a character below level 5 receives an alert instead of an empty disabled window.

Runtime validation covered a valid bot (`Viz`) and an ineligible low-level bot (`Heal`). The Bridge remains authoritative for eligibility and Autogear execution.

---

# Recent Milestone — Hunter Pet H1/H2/H3

Hunter Pet controls were completed, compiled where required and runtime validated on **18 September 2026** through three bounded capability families:

```text
HUNTER_PET_CONTROL_V1
HUNTER_PET_MANAGE_V1
HUNTER_PET_LIFECYCLE_V1
```

The final structured surface covers:

- H1 control: `AGGRESSIVE`, `DEFENSIVE`, `PASSIVE`, `ATTACK`, `FOLLOW`, `STAY`;
- H2 management: `TAME_ID`, `TAME_FAMILY`, `RENAME`, `ABANDON`;
- H3 lifecycle: `DISMISS`, `CALL`.

`ABANDON` remains the destructive path. `DISMISS` preserves the current pet with `PET_SAVE_AS_CURRENT` and suppresses Playerbots' non-combat `pet` auto-call strategy only when that strategy was previously enabled. `CALL` uses the Hunter Call Pet spell (`883`) and restores that strategy only when the Bridge disabled it.

The Hunter Quick UI now exposes distinct **Call / Dismiss / Abandon** actions with eight-locale tooltips. Final validation kept `MultiBotComm.lua` at **199 top-level locals**, Hunter Quick at **0 `SendChatMessage` occurrences**, and `mod-playerbots` strictly read-only.

Canonical final audit:

```text
audit-multibot-hunter-pet-h1-h2-h3-final-v1-2026-09-18-192853.zip
SHA-256 E4CFFD5763DA3C821830F188C9154E92B952C1AA96FCFC9CD99769300426EE26
FINAL_STATUS=OK
```

Final checkpoint:

```text
checkpoint-multibot-hunter-pet-h1-h2-h3-v1-2026-09-18-193155.zip
SHA-256 1DFB038072ED1DC75C97334EF666162C14B526185DC52CADCFD49D7D1664D4FD
manifest 146/146 verified
8 successful packages
FINAL_STATUS=OK_WITH_WARNINGS
```

The checkpoint warning status is documentary only: two historical apply reports were unavailable, while the archive manifest and final source state were fully verified.

---

# Recent Milestone — Spellbook Cast / Ignore Chatless

Spellbook cast and ignored-spell management were completed and runtime validated on **19 September 2026** through two dedicated capability families:

```text
SPELLBOOK_CAST_V1
SPELLBOOK_IGNORE_V1
```

The cast path sends the selected numeric `spellId` through the dedicated Bridge endpoint and waits for a structured ACK. The normal UI path does not fall back to whisper `cast` and does not use a generic `RUN~CAST_SPELL` executor.

Ignored-spell management uses typed `IGNORE` / `ALLOW` requests backed by Playerbots' existing ignored-spell state. The Addon no longer sends legacy `ss +<id>` / `ss -<id>` commands and does not depend on the historical `Ignored spell list` whisper.

The Spellbook reflects authoritative state returned by the Bridge. Successful ignore/allow ACKs produce localized system feedback in all eight loaded locales. The footer also provides a localized **Ignored (N) / All spells** filter with filtered pagination; the final validated button geometry is `125×18`, `TOPRIGHT`, `Y=-270`, `X=12`.

Runtime validation covered cast, ignore, allow, filtered removal, the empty filtered view after the final ignored spell is allowed, and return to the complete spell list. `MultiBotComm.lua` remains at **199 top-level locals**, and `mod-playerbots` remains strictly read-only.

---

# Bridge Capabilities

The addon negotiates feature capabilities with the Bridge before using newer paths.

Important current capabilities include:

```text
STATE_FRAMING_V1
STRATEGY_MUTATION_V1
OUTFIT_V1
INVENTORY_V1
INVENTORY_EXACT_V1
ITEM_MOVE_V1
ITEM_EQUIP_V1
ITEM_UNEQUIP_V1
ITEM_TRADE_V1
ITEM_USE_V1
ITEM_SELL_SINGLE_V1
VENDOR_BUYBACK_V1
INVENTORY_BULK_SELL_V1
INVENTORY_OPEN_V1
ITEM_DEPOSIT_EXACT_V1
GROUP_ROLL_V1
ENCHANT_TRADE_V1
CRAFT_RECIPE_TARGET_V1
QUEST_ABANDON_V1
LOOT_RULE_ITEM_V1
TALENT_APPLY_V1
TALENT_SPEC_APPLY_V1
SELF_BOT_V1
SELF_STRATEGY_V1
SELF_ACTION_V1
ALT_ROSTER_V1
BOT_LIFECYCLE_V1
BOT_TARGET_RESOLVE_V1
BOT_GROUP_REMOVE_V1
BOT_GROUP_LIFECYCLE_V1
CREATOR_ADDCLASS_V1
CREATOR_INIT_AUTO_V1
FOLLOW_ORDER_V1
STAY_ORDER_V1
ATTACK_ORDER_V1
FLEE_ORDER_V1
GROUP_ACTION_V1
RTSC_ORDER_V1
QUEST_ACCEPT_ALL_V1
QUEST_TALK_V1
QUEST_GAMEOBJECT_USE_V1
QUEST_REWARD_V1
QUEST_REWARD_POLICY_V1
AUTOGEAR_OPTIONS_V1
HUNTER_PET_CONTROL_V1
HUNTER_PET_MANAGE_V1
HUNTER_PET_LIFECYCLE_V1
SPELLBOOK_CAST_V1
SPELLBOOK_IGNORE_V1
```

The exact protocol is an implementation detail of the addon and Bridge. The normal user experience should remain UI-driven.

---

# Compatibility & Legacy Chat

The addon deliberately keeps some manual Playerbots commands for diagnostics and explicit gameplay use.

Automatic compatibility fallback is disabled by default:

```lua
MultiBot.allowLegacyChatFallback = false
```

When a migrated Bridge feature is available, the addon should prefer the structured path and wait for authoritative server state instead of pretending an action succeeded locally.

---

# Installation

1. Install and configure AzerothCore with `mod-playerbots`.
2. Install [`mod-multibot-bridge`](https://github.com/Wishmaster117/mod-multibot-bridge) on the server and rebuild AzerothCore.
3. Copy or clone this repository as:

```text
World of Warcraft/Interface/AddOns/MultiBot
```

4. Start the server and log into the WoW 3.3.5a client.
5. Confirm the addon and Bridge handshake successfully.

---

# Usage

Open MultiBot with any of these slash commands:

```text
/multibot
/mbot
/mb
```

You can also open the addon from its minimap button.

When the Bridge is available, supported UI actions automatically use the structured bridge-first path; you do not need to type protocol commands manually.

---

# Current Status

The major read paths and a large part of the action surface are now bridge-first and runtime validated.

The project is **not declared fully chatless yet**. Remaining `SendChatMessage` paths are handled family by family so that useful manual commands are not removed accidentally and legacy compatibility is not broken without testing.

Collective **Follow**, **Stay** and **Attack** are now bridge-first and runtime validated through dedicated structured endpoints. Their exact UI commands are routed before the legacy PARTY/RAID chat fallback, and no generic arbitrary Playerbots command executor is used.

**Flee** is also bridge-first and runtime validated through `FLEE_ORDER_V1`. ALL, TARGET and the Tank / Healer / DPS / Melee / Ranged audiences use the structured path; role names come from authoritative Bridge results and normal Playerbots Flee success whispers are suppressed without hiding unrelated human whispers or Playerbots error feedback.

Unitary roster lifecycle, AutoInvite and Raidus remain structured-first or explicitly legacy-gated. The Faction Banner bulk pair `.playerbot bot add *` / `.playerbot bot remove *` is now also migrated through `BOT_GROUP_LIFECYCLE_V1`, preserving Playerbots' real party/raid semantics and delegating the actual login/logout operations to `PlayerbotMgr`.

Creator `addclass` is bridge-first through `CREATOR_ADDCLASS_V1` and runtime validated, including Random/Male/Female/DK and existing auto-group behavior. Creator `init=auto` is also structured through `CREATOR_INIT_AUTO_V1` for bounded target/group initialization. Deferred Units/lifecycle legacy cleanup remains reserved for the final global fallback/parser cleanup.

The bounded **Group Actions** set (`drink`, `release`, `revive`, `summon`) is bridge-first through `GROUP_ACTION_V1`. **RTSC** is bridge-first and runtime validated through `RTSC_ORDER_V1`; AEDM itself intentionally remains on the native WoW/Playerbots spell path. The structured Quest interaction family is present through the five `QUEST_*` capabilities, **Autogear** is completed through `AUTOGEAR_OPTIONS_V1`, **Hunter Pet H1/H2/H3** is completed through `HUNTER_PET_CONTROL_V1`, `HUNTER_PET_MANAGE_V1` and `HUNTER_PET_LIFECYCLE_V1`, and **Spellbook Cast / Ignore** is completed through `SPELLBOOK_CAST_V1` and `SPELLBOOK_IGNORE_V1`. The next active work is the explicitly deferred technical residuals, followed by the final legacy parser/fallback cleanup.

The project therefore remains intentionally **mostly chatless**, not fully chatless.

Detailed development history, audits, deferred work and technical residuals are tracked in the project documentation.

---

# Documentation

- [`docs/ROADMAP.md`](docs/ROADMAP.md) — technical source of truth, completed milestones, audit references, next work and deferred backlog.
- [`docs/RAIDUS_GUIDE.md`](docs/RAIDUS_GUIDE.md) — current English user guide for the Raidus raid planner and its bridge-first lifecycle behavior.
- [`docs/DEBUG_RUNBOOK.md`](docs/DEBUG_RUNBOOK.md) — in-game debug commands, observability guidance and bug-report procedure.

---

# Deferred / Lower-Priority Work

The active roadmap currently keeps these items outside the next normal feature batch:

- exact BANK withdrawal (P3B);
- exact Guild Bank withdrawal (P3C);
- dedicated localized `SOURCE_STALE` UI text;
- moving/re-equipping the equipped bag objects themselves (`BAG_MOVE`);
- `SELL_GREY` follow-up;
- final real Firestone/Spellstone `TEMP_ENCHANTMENT_SLOT` revalidation;
- remaining Warlock LuaLint warnings;
- selected lifecycle/idempotence hardening for older pending-command flows.

---

# Credits

MultiBot Chatless builds on the AzerothCore and `mod-playerbots` ecosystem.

Special thanks to **Macx-Lio** for the original MultiBot Module that this project builds upon.

The project also retains attribution for the external **Jellypowered** bridge work that was audited and selectively adapted during the chatless migration. Details and commit references are preserved in the project roadmap.

---

# Troubleshooting

### The addon does not load

Confirm the folder is named exactly:

```text
MultiBot
```

and is located under:

```text
World of Warcraft/Interface/AddOns/
```

### Bridge features are unavailable

Confirm `mod-multibot-bridge` is installed, configured, compiled and loaded by the same AzerothCore server used by the client.

### I still see some Playerbots chat

That does not automatically mean the Bridge is broken. Manual commands and a small number of intentionally retained or not-yet-migrated paths still exist while the project remains **mostly chatless**.
