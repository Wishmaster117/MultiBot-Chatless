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
| **Bot connect / disconnect** | `ALT_ROSTER_V1`, `BOT_LIFECYCLE_V1` and `BOT_TARGET_RESOLVE_V1` provide structured discovery, target resolution and lifecycle control. Offline EveryBars stay collapsed; online EveryBars expand consistently. |
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
| **Quests** | Bridge-backed quest list and structured bot quest abandon. Native quest sharing remains available. |
| **Loot** | Structured loot profiles and exact persistent always-loot item add/remove. |
| **Group tools** | Formation, Roll, RTI, Pull Control and Disperse, plus bridge-first `FOLLOW_ORDER_V1`, `STAY_ORDER_V1` and `ATTACK_ORDER_V1` collective orders. Attack keeps the validated Tank / Healer / DPS / Melee / Ranged audiences. |
| **Raidus raid planner** | Persistent 8×5 Working Layout, Saved Layouts, Score/Level/Class sorting, drag/drop, Auto balance, structured Apply and human-safe outside-layout bot removal through `BOT_GROUP_REMOVE_V1`. |
| **Character information** | Bot skills, reputations, currencies/emblems, spellbook, stats and PvP stats. |
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
FOLLOW_ORDER_V1
STAY_ORDER_V1
ATTACK_ORDER_V1
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

The current lifecycle audit shows that unitary roster lifecycle, AutoInvite and Raidus are already structured-first or explicitly legacy-gated. The next normal lifecycle migration is the remaining **group bulk** pair `.playerbot bot add *` / `.playerbot bot remove *`, preserving Playerbots' real-group semantics rather than interpreting `*` as every bot on the account.

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
