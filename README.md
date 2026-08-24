<p align="center">
  <img width="1024" height="1024" alt="Gemini_Generated_Image_s1mnq6s1mnq6s1mn" src="https://github.com/user-attachments/assets/08aa1768-f5c2-49ce-9fe0-a22adb184ce7" />
</p>

<div align="center">

# MultiBot Chatless

### Bridge-first client addon for AzerothCore `mod-playerbots`

<strong>MultiBot-Chatless</strong> is the client-side World of Warcraft 3.3.5a addon for controlling and inspecting Playerbots through a cleaner, mostly chatless UI workflow.

<br>

<img alt="Repository" src="https://img.shields.io/badge/repository-MultiBot--Chatless-blue" />
<img alt="Bridge Module" src="https://img.shields.io/badge/requires-mod--multibot--bridge-orange" />
<img alt="WoW Version" src="https://img.shields.io/badge/client-WotLK%203.3.5a-lightgrey" />
<img alt="Architecture" src="https://img.shields.io/badge/architecture-bridge--first-success" />

<br><br>

<table>
  <tr>
    <th>Component</th>
    <th>Repository</th>
    <th>Install Location</th>
  </tr>
  <tr>
    <td><strong>Client Addon</strong></td>
    <td>
      <a href="https://github.com/Wishmaster117/MultiBot-Chatless">
        MultiBot-Chatless
      </a>
    </td>
    <td>
      <code>World of Warcraft/Interface/AddOns/MultiBot</code>
    </td>
  </tr>
  <tr>
    <td><strong>Server Bridge Module</strong></td>
    <td>
      <a href="https://github.com/Wishmaster117/mod-multibot-bridge">
        mod-multibot-bridge
      </a>
    </td>
    <td>
      <code>azerothcore/modules/mod-multibot-bridge</code>
    </td>
  </tr>
</table>

</div>

---

## Important Notice

`MultiBot-Chatless` is the **addon-side repository only**.

To get the new bridge-first / mostly chatless behavior, you also need the server-side AzerothCore module:

<div align="center">

### 👉 <a href="https://github.com/Wishmaster117/mod-multibot-bridge">mod-multibot-bridge</a>

</div>

Without the bridge module, the addon cannot use the new structured `MBOT GET~...` data flow.

---

# What is MultiBot Chatless?

MultiBot is a user interface addon for the AzerothCore [`mod-playerbots`](https://github.com/mod-playerbots/mod-playerbots) module.

This fork focuses on removing automatic bot chat spam from the main UI refresh paths by using a dedicated AzerothCore bridge module instead of relying on legacy chat parsing.

The addon now requests structured data from the server through `mod-multibot-bridge`.

Examples of bridge request families (arguments omitted here for readability):

```text
MBOT HELLO
MBOT PING
GET~ROSTER
GET~STATES
GET~WEAPON_ENCHANT
GET~DETAILS
GET~STATS
GET~PVP_STATS
GET~TALENT_SPEC_LIST
GET~INVENTORY
GET~BANK
GET~GBANK
GET~SPELLBOOK
GET~BOT_SKILLS
GET~BOT_REPUTATIONS
GET~BOT_EMBLEMS
GET~PROFESSION_RECIPES
GET~ENCHANT_TRADE
GET~GLYPHS
GET~OUTFITS
GET~QUESTS
GET~GAMEOBJECTS
GET~FORMATIONS
RUN~CRAFT_RECIPE
RUN~CRAFT_RECIPE_TARGET
RUN~ITEM_ACTION
RUN~ITEM_EQUIP
RUN~ITEM_UNEQUIP
RUN~ITEM_TRADE
RUN~QUEST_ABANDON
RUN~OUTFIT
RUN~RTI
RUN~COMBAT
RUN~POSITION
RUN~LOOT
RUN~STRATEGY
RUN~FORMATION
RUN~GROUP_ROLL
RUN~ENCHANT_TRADE
```

The Formation family uses the following complete party/raid-wide contracts:

```text
RUN~FORMATION~GROUP~~<token>~<formation>
FORMATION_ACK~GROUP~~<token>~<success>~<failure>~<formation>

GET~FORMATIONS~GROUP~~<token>
FORMATIONS_BEGIN~<token>~<count>
FORMATIONS_ITEM~<token>~<botName>~<formation>
FORMATIONS_END~<token>~<sentCount>
```

`GROUP` covers every controllable bot in the player's current party or raid. It does not target individual raid subgroups.

## Current state and strategy capabilities

The addon and bridge negotiate dedicated capabilities so newer write/read paths are used only when both sides support them:

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
GROUP_ROLL_V1
ENCHANT_TRADE_V1
CRAFT_RECIPE_TARGET_V1
QUEST_ABANDON_V1
SELF_BOT_V1
SELF_STRATEGY_V1
SELF_ACTION_V1
```

`STATE_FRAMING_V1` uses tokenized `STATE` / `STATES` transactions with framed responses, bounded payloads, cleanup on terminal errors/timeouts, and stale-response protection. Per-bot requests use a 5-second timeout; global state requests use a 15-second timeout.

`STRATEGY_MUTATION_V1` provides structured `co/nc` mutations through `RUN~STRATEGY` and completion through `STRATEGY_ACK`. The bridge reports matched, succeeded and failed bot counts, while the addon applies explicit timeout and rejection diagnostics.

`INVENTORY_V1` provides the established native inventory read/refresh path. `INVENTORY_EXACT_V1` complements it with exact physical topology for Backpack, Bag 1..4 and Keyring, including empty slots and per-container filtering in the inventory UI. `ITEM_MOVE_V1` adds server-authoritative whole-stack drag/drop between allowed physical slots. The addon keeps only synthetic drag state: it does not call `PickupContainerItem`, `PickupInventoryItem`, `GetCursorInfo` or `ClearCursor`, and it does not mutate the displayed inventory optimistically; an exact snapshot refresh follows the server result. Stack splitting remains outside this capability. `ITEM_EQUIP_V1` equips an exact item from Backpack or Bag 1..4 through a structured bridge request and waits for the authoritative result before refreshing. `ITEM_UNEQUIP_V1` routes Inspect right-click through the exact equipment slot plus item ID, converts client Inspect slots 1..19 to Core slots 0..18, waits for the structured result and then refreshes. `ITEM_TRADE_V1` routes Inventory -> Trade through an exact source identity, preserves the native WoW Trade UI, waits for the structured `INVENTORY_ITEM_TRADE` result and keeps the historical give path behind the explicit compatibility fallback flag. The historical `ue` whisper fallback is used only when `MultiBot.allowLegacyChatFallback == true`; normal bridge-first configuration keeps that fallback disabled. `ITEM_USE_V1` uses the exact physical source, waits for the structured `INVENTORY_ITEM_USE` result and delegates execution to the native use-item path. `ITEM_DESTROY` is a specialized exact-item destruction path with server-side source revalidation and an authoritative result. `ITEM_SELL_SINGLE_V1` validates the exact source and nearby vendor before native single-item sale and returns `INVENTORY_ITEM_SELL`. `VENDOR_BUYBACK_V1` exposes a structured Buyback list/result flow and uses the native Buyback handler before authoritative inventory/list refreshes. `INVENTORY_BULK_SELL_V1` gates the current bulk-sell path. Normal `SELL_VENDOR` operation is bridge-first; the historical `s vendor` whisper is reachable only when `MultiBot.allowLegacyChatFallback == true`. The validated Bridge path accepts `ITEM_USAGE_VENDOR` only for `SELL_VENDOR` and excludes `ITEM_USAGE_AH`. `INVENTORY_OPEN_V1` gates the current `OPEN_ITEMS` bridge path. `GROUP_ROLL_V1` gates the group Roll workflow; normal rolls and item-linked rolls are tokenized and completed through a structured `GROUP_ROLL_ACK`. `ENCHANT_TRADE_V1` gates the Enchanting Trade Service: the addon lists only known Enchanting spells exposed by the bot, uses the native WoW Trade window and the non-traded item slot, then requests one validated numeric spell ID through the bridge. `QUEST_ABANDON_V1` routes bot quest abandon through a tokenized structured request/result; the player still abandons locally with the native WoW quest API, while the legacy `drop` group-chat fallback is available only when `MultiBot.allowLegacyChatFallback == true`. Quest sharing remains intentionally native through `QuestLogPushQuest()` and does not require a `QUEST_SHARE_V1` bridge capability.

`CRAFT_RECIPE_TARGET_V1` handles profession recipes that require an exact bot-owned item target. Normal `RUN~CRAFT_RECIPE` remains unchanged for ordinary crafting and returns `TARGET_REQUIRED` for exact-item recipes. The addon then reuses the selected bot's Inventory and Inspect views, sends the exact `bag` / `slot` / `itemId` identity, keeps at most 8 pending target requests with a 5-second timeout and consumes `CRAFT_RECIPE_TARGET_RESULT` through the structured opcode dispatcher. Target selection is limited to equipment, Backpack and equipped Bag 1..4; Bank, Keyring and player Trade items are outside this capability. Recipes with `craftable > 0` are highlighted with a bright-green name, while non-craftable recipes keep their existing difficulty color.

`SELF_BOT_V1` controls the player's own SelfBot mode with explicit ENABLE/DISABLE requests and authoritative state/result replies. `SELF_STRATEGY_V1` reads and mutates only the active SelfBot's whitelisted combat/non-combat strategies through framed state plus `SELF_STRATEGY_ACK`; it is not a generic strategy executor. `SELF_ACTION_V1` exposes only the audited SelfBot actions `AUTOGEAR`, `MAINTENANCE` and `WAIT_ATTACK_TIME`, with server-side SelfBot/security/rate-limit checks. These SelfBot paths are a separate completed workstream inherited by the Jellypowered v2 branch; normal-bot Maintenance/Autogear paths that still use legacy chat are not implicitly migrated by these capabilities.

The migration is intentionally incremental. The Warlock stone, soulstone, pet and curse selectors are now migrated to structured `RUN~STRATEGY` mutations. When those selectors use the bridge, the addon waits for authoritative server `STATE` data before committing the selected UI state instead of applying an optimistic local state. Other specialized legacy UI paths still issue Playerbots chat commands directly and must be migrated before the addon can be described as fully chatless.

Manual playerbot commands are still intentionally preserved for diagnostics and gameplay actions.

Commands such as:

```text
who
co ?
nc ?
ss ?
```

still work when the player explicitly wants to inspect a bot state.

The goal is not to remove useful manual commands.  
The goal is to remove automatic UI-refresh spam.

The remaining legacy Playerbots Trade inventory dump is also suppressed locally by the addon. The filter recognizes the exact `=== Inventory ===` dump from known bots and hides that automatic dump for Inventory -> Trade, Enchanting -> Trade and the native WoW client Trade action, while leaving the Trade workflow itself unchanged.

### Warlock weapon-enchant diagnostic

For targeted runtime diagnostics, the addon exposes:

```text
/mbdebug enchant [bot]
```

If the bot name is omitted, the current target is used. The command sends a single `GET~WEAPON_ENCHANT` request and displays the structured `WEAPON_ENCHANT` response with main-hand/off-hand item entries, temporary enchant IDs and remaining durations. This path is diagnostic only: it is on-demand, server-authorized and rate-limited, and is not used for polling or normal selector state synchronization.

The endpoint and safe Firestone/Spellstone switching code are present, but the project-level final revalidation of the real `TEMP_ENCHANTMENT_SLOT` behavior is intentionally deferred until the end of the normal roadmap.

---

# Features

<table>
  <tr>
    <th>Area</th>
    <th>Status</th>
  </tr>
  <tr>
    <td>Bridge handshake</td>
    <td><strong>Implemented</strong> — <code>HELLO</code>, <code>HELLO_ACK</code>, <code>PING</code>, <code>PONG</code></td>
  </tr>
  <tr>
    <td>Roster refresh</td>
    <td><strong>Bridge-first</strong></td>
  </tr>
  <tr>
    <td>Bot states</td>
    <td><strong>Bridge-first, framed</strong> — <code>STATE_FRAMING_V1</code>, tokenized <code>STATE/STATES</code> transactions, bounded payloads, timeout cleanup and stale-response protection</td>
  </tr>
  <tr>
    <td>Strategy mutations</td>
    <td><strong>Bridge-first where migrated</strong> — <code>STRATEGY_MUTATION_V1</code>, <code>RUN~STRATEGY</code>, <code>STRATEGY_ACK</code> and explicit rejection/timeout diagnostics</td>
  </tr>
  <tr>
    <td>Warlock strategy selectors</td>
    <td><strong>Bridge-first and runtime validated</strong> — Stones, Soulstones, Pets and Curses use structured strategy mutations; bridge-backed selections wait for authoritative state, invalid Warlock <code>dps</code>/<code>dps debuff</code> controls and the disabled Buff placeholder were removed, and the selector layout was compacted</td>
  </tr>
  <tr>
    <td>Bot details</td>
    <td><strong>Bridge-first</strong></td>
  </tr>
  <tr>
    <td>Stats</td>
    <td><strong>Bridge-first</strong></td>
  </tr>
  <tr>
    <td>PvP stats</td>
    <td><strong>Bridge-first</strong></td>
  </tr>
  <tr>
    <td>Talent spec templates</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>GET~TALENT_SPEC_LIST</code> lists server-side premade templates; <code>TALENT_SPEC_CURRENT</code> returns the authoritative active slot/tree totals, and <code>TALENT_SPEC_APPLY_V1</code> applies a server-revalidated template index to slot 1 or 2 with dual-spec handling, glyph initialization and structured verification without normal chat commands</td>
  </tr>
  <tr>
    <td>Custom talent apply</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>TALENT_APPLY_V1</code> validates the complete custom talent build against the bot class/DBC/available points, applies it through the audited Playerbots factory path and confirms success only after authoritative tree-point verification</td>
  </tr>
  <tr>
    <td>Inventory</td>
    <td><strong>Bridge-first, exact and bag-aware</strong> — <code>INVENTORY_V1</code> remains the established read/refresh path, while <code>INVENTORY_EXACT_V1</code> exposes Backpack, Bag 1..4 and Keyring with physical locations, empty slots and container filters</td>
  </tr>
  <tr>
    <td>Inventory item move</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>ITEM_MOVE_V1</code> moves one whole stack by synthetic addon drag/drop between allowed physical slots, waits for the structured server result and refreshes the exact snapshot without using the native player cursor APIs</td>
  </tr>
  <tr>
    <td>Inventory item equip</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>ITEM_EQUIP_V1</code> equips one exact item from Backpack or Bag 1..4 through the Bridge, waits for the structured result and refreshes authoritatively without optimistic UI mutation</td>
  </tr>
  <tr>
    <td>Inspect item unequip</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>ITEM_UNEQUIP_V1</code> routes Inspect right-click by exact equipment slot and item ID; the legacy <code>ue</code> whisper is available only when <code>MultiBot.allowLegacyChatFallback == true</code> and is disabled in normal bridge-first configuration</td>
  </tr>
  <tr>
    <td>Inventory item use</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>ITEM_USE_V1</code> revalidates the exact physical source, executes through the native use-item path, returns a structured result and refreshes authoritatively</td>
  </tr>
  <tr>
    <td>Inventory item destroy</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>ITEM_DESTROY</code> uses a specialized exact-item request with server-side source revalidation and an authoritative result</td>
  </tr>
  <tr>
    <td>Inventory item single sell</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>ITEM_SELL_SINGLE_V1</code> revalidates the exact source and nearby vendor, performs the native sale and returns a structured <code>INVENTORY_ITEM_SELL</code> result</td>
  </tr>
  <tr>
    <td>Vendor Buyback</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>VENDOR_BUYBACK_V1</code> lists authoritative Buyback entries, executes one native buyback after server validation and refreshes inventory and Buyback state</td>
  </tr>
  <tr>
    <td>Inventory bulk sell</td>
    <td><strong>Bridge-first and runtime revalidated</strong> — <code>INVENTORY_BULK_SELL_V1</code> routes <code>SELL_VENDOR</code> and the existing <code>SELL_GREY</code> action through the bridge. For <code>SELL_VENDOR</code>, the legacy <code>s vendor</code> path is available only when <code>MultiBot.allowLegacyChatFallback == true</code>; the Bridge accepts <code>ITEM_USAGE_VENDOR</code> only and excludes <code>ITEM_USAGE_AH</code>. Runtime regression tests preserved Symbol of Kings and Gold Ore. Further SELL_GREY work remains deferred.</td>
  </tr>
  <tr>
    <td>Open items</td>
    <td><strong>Bridge-first and validated</strong> — <code>INVENTORY_OPEN_V1</code> / <code>OPEN_ITEMS</code> with structured result handling and no silent chat fallback in normal bridge-first use</td>
  </tr>
  <tr>
    <td>Group Roll</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>GROUP_ROLL_V1</code> supports normal 0–100 rolls and Shift+click item rolls with tokenized pending state, duplicate-send protection and structured ACK handling</td>
  </tr>
  <tr>
    <td>Spellbook</td>
    <td><strong>Bridge-first</strong> combat spell listing separated from profession recipe data</td>
  </tr>
  <tr>
    <td>Character Info frame</td>
    <td><strong>Bridge-first</strong> Blizzard-style tabs for skills, reputations and currencies/emblems</td>
  </tr>
  <tr>
    <td>Bot bank / guild bank / vendor buy</td>
    <td><strong>Bridge-first</strong> bank and guild-bank snapshots plus vendor buy actions. `BANK_DEPOSIT` and `GBANK_DEPOSIT` use negotiated <code>ITEM_DEPOSIT_EXACT_V1</code> when available, carrying exact <code>bag/slot/itemId/count</code> source identity and whole-stack semantics. Bank and guild-bank withdrawals remain on the existing non-exact-stack path; exact withdrawals are deferred.</td>
  </tr>
  <tr>
    <td>Profession recipe frame</td>
    <td><strong>Bridge-first and runtime validated</strong> — recipe listing and normal crafting remain on <code>RUN~CRAFT_RECIPE</code>; item-target recipes return <code>TARGET_REQUIRED</code> and continue through <code>CRAFT_RECIPE_TARGET_V1</code> with exact Inventory/Inspect selection by <code>bag/slot/itemId</code>. Recipes currently craftable are highlighted with a bright-green name.</td>
  </tr>
  <tr>
    <td>Enchanting Trade Service</td>
    <td><strong>Bridge-first and runtime validated</strong> — <code>ENCHANT_TRADE_V1</code> exposes known Enchanting services, reagent/tool availability and native Trade-slot execution without a generic cast/chat executor; the same dedicated window is available from the enchanter EveryBar and Character Info, with UI text localized in all eight runtime locales. Enchantments for which all reagents and required tools are present are highlighted with a bright-green name.</td>
  </tr>
  <tr>
    <td>Trade inventory chat suppression</td>
    <td><strong>Runtime validated</strong> — the legacy Playerbots <code>=== Inventory ===</code> Trade-start dump is hidden for Inventory, Enchanting and native client Trade openings; the filter is limited to the exact dump sequence from known bots and does not modify Playerbots or the Bridge</td>
  </tr>
  <tr>
    <td>Glyphs</td>
    <td><strong>Bridge-first</strong> with glyph icons and tooltips</td>
  </tr>  <tr>
    <td>Loot rules</td>
    <td><strong>Bridge-first</strong> loot enable/disable and loot list profiles through <code>RUN~LOOT</code></td>
  </tr>
  <tr>
    <td>Loot Master frame</td>
    <td><strong>Implemented</strong> optional auto-opening master-loot UI with candidate scoring, preferences and recent loot history</td>
  </tr>
  <tr>
    <td>Units / EveryBars</td>
    <td><strong>Improved</strong> login, reload and AddClass refresh behavior</td>
  </tr>
  <tr>
    <td>Random bot visibility</td>
    <td><strong>Improved</strong> bridge-visible grouped randombots alongside AddClass bots and altbots</td>
  </tr>
  <tr>
    <td>Party / raid formation controls</td>
    <td><strong>Bridge-first and chatless</strong> — left-click applies one formation to every controllable bot in the current party or raid through <code>RUN~FORMATION</code>; right-click reads each bot's effective formation through <code>GET~FORMATIONS</code> and displays a localized tooltip</td>
  </tr>
  <tr>
    <td>Legacy automatic chat fallback</td>
    <td><strong>Disabled by default</strong></td>
  </tr>
  <tr>
    <td>Outfits</td>
    <td><strong>Bridge-first</strong> listing, create/update, reset, equip and replace</td>
  </tr>
  <tr>
    <td>Quests</td>
    <td><strong>Bridge-first</strong> incompleted, completed and all quest lists with dark result frames and per-bot abandon buttons</td>
  </tr>
  <tr>
    <td>Game object search</td>
    <td><strong>Bridge-first</strong> results and copy frame without localized chat parsing</td>
  </tr>
  <tr>
    <td>RTI controls</td>
    <td><strong>Bridge-first</strong> icon assignment and RTI target actions</td>
  </tr>
  <tr>
    <td>Pull Control</td>
    <td><strong>Bridge-first</strong> wait, focus, DPS assist, AoE and RTI pull/attack controls</td>
  </tr>
  <tr>
    <td>Combat strategy fine tuning</td>
    <td><strong>Bridge-first</strong> avoid AoE, save mana, threat and behind controls</td>
  </tr>
  <tr>
    <td>Disperse controls</td>
    <td><strong>Bridge-first</strong> distance set and disable actions through <code>RUN~POSITION</code></td>
  </tr>
  <tr>
    <td>Loot rules</td>
    <td><strong>Bridge-first</strong> loot enable/disable and loot list profiles through <code>RUN~LOOT</code></td>
  </tr>
  <tr>
    <td>Loot Master frame</td>
    <td><strong>Implemented</strong> optional auto-opening master-loot UI with candidate scoring, preferences and recent loot history</td>
  </tr>
  <tr>
    <td>Units / EveryBars</td>
    <td><strong>Improved</strong> login, reload and AddClass refresh behavior</td>
  </tr>
  <tr>
    <td>Random bot visibility</td>
    <td><strong>Improved</strong> bridge-visible grouped randombots alongside AddClass bots and altbots</td>
  </tr>
  <tr>
    <td>Legacy automatic chat fallback</td>
    <td><strong>Disabled by default</strong></td>
  </tr>
</table>

---

# Requirements

## Client

- World of Warcraft 3.3.5a / Wrath of the Lich King client.
- Tested with:
  - English / US client
  - German client
  - French client
  - Spanish client
- Localization files included for <code>enUS</code>, <code>enGB</code>, <code>frFR</code>, <code>esES</code>, <code>deDE</code>, <code>ruRU</code>, <code>zhCN</code> and <code>koKR</code>.

## Server

- [`AzerothCore WotLK`](https://github.com/mod-playerbots/azerothcore-wotlk/tree/Playerbot).
- [`mod-playerbots`](https://github.com/mod-playerbots/mod-playerbots).
- [`mod-multibot-bridge`](https://github.com/Wishmaster117/mod-multibot-bridge).

---

# Installation

## 1. Install the server-side bridge module

Clone the bridge module inside your AzerothCore `modules` directory:

```bash
cd /path/to/azerothcore/modules
git clone https://github.com/Wishmaster117/mod-multibot-bridge.git mod-multibot-bridge
```

Expected structure:

```text
azerothcore/
└── modules/
    └── mod-multibot-bridge/
        ├── conf/
        └── src/
```

Then:

1. Re-run CMake if required by your build workflow.
2. Rebuild AzerothCore.
3. Copy/install the generated configuration file if required.
4. Start the server.
5. Check that `mod-multibot-bridge` is loaded.

When the addon connects successfully, the server console should show messages similar to:

```text
MBOT HELLO
MBOT HELLO_ACK
MBOT PING
MBOT PONG
GET~ROSTER
GET~STATES
GET~DETAILS
```

---

## 2. Install the client addon

Clone this repository into your World of Warcraft AddOns directory.

```bash
cd "World of Warcraft/Interface/AddOns"
git clone https://github.com/Wishmaster117/MultiBot-Chatless.git MultiBot
```

Expected structure:

```text
World of Warcraft/
└── Interface/
    └── AddOns/
        └── MultiBot/
            ├── MultiBot.toc
            ├── Core/
            ├── Data/
            ├── Features/
            ├── Icons/
            ├── Libs/
            ├── Locales/
            ├── Strategies/
            ├── Textures/
            └── UI/
```

> The GitHub repository is named `MultiBot-Chatless`, but the local addon folder must be named `MultiBot`.

Do not install it like this:

```text
Interface/AddOns/MultiBot/MultiBot/MultiBot.toc
```

The `.toc` file must be directly here:

```text
Interface/AddOns/MultiBot/MultiBot.toc
```

---

# Updating

## Update the addon

```bash
cd "World of Warcraft/Interface/AddOns/MultiBot"
git pull
```

## Update the bridge module

```bash
cd /path/to/azerothcore/modules/mod-multibot-bridge
git pull
```

Then rebuild your AzerothCore server if the module code changed.

---

# Recommended Configuration

For normal bridge-first usage, keep legacy automatic chat fallback disabled:

```lua
MultiBot.allowLegacyChatFallback = false
```

Only enable it temporarily for debugging or compatibility testing:

```lua
MultiBot.allowLegacyChatFallback = true
```

---

# Usage

Start World of Warcraft and use one of the following commands:

```text
/multibot
/mbot
/mb
```

You can also use the minimap button.

When the bridge is available, the addon automatically uses structured bridge messages for the main UI refresh paths instead of legacy chat replies.

Manual commands are still available when you intentionally want them.

Examples:

```text
/w BotName who
/w BotName co ?
/w BotName nc ?
/w BotName ss ?
```

---

# Bridge-First Architecture

<div align="center">

<table>
  <tr>
    <th>Old behavior</th>
    <th>New behavior</th>
  </tr>
  <tr>
    <td>Addon triggers bot commands</td>
    <td>Addon sends structured <code>MBOT GET~...</code> requests</td>
  </tr>
  <tr>
    <td>Bots answer with chat text</td>
    <td>Bridge returns structured addon messages</td>
  </tr>
  <tr>
    <td>Addon parses localized chat lines</td>
    <td>Addon consumes stable protocol payloads</td>
  </tr>
  <tr>
    <td>Automatic UI refresh creates chat spam</td>
    <td>Main UI refresh paths are mostly chatless</td>
  </tr>
</table>

</div>

---

# Current Status

Implemented bridge-first / chatless areas:

- Bridge handshake: `HELLO`, `HELLO_ACK`, `PING`, `PONG`.
- Roster refresh.
- Bot states through `STATE_FRAMING_V1`, with tokenized per-bot/global transactions, framed responses, bounded state payloads, timeout cleanup and stale-response protection.
- Strategy mutations through `STRATEGY_MUTATION_V1` for migrated controls, with `RUN~STRATEGY`, `STRATEGY_ACK`, result counters and explicit rejection/timeout diagnostics.
- Bot details refresh.
- Stats refresh.
- PvP stats refresh.
- Talent spec list refresh.
- Inventory read/refresh through `INVENTORY_V1`, complemented by `INVENTORY_EXACT_V1` for bag-aware physical topology across Backpack, Bag 1..4 and Keyring, including empty slots and per-container filters.
- Whole-stack inventory drag/drop through `ITEM_MOVE_V1`, with synthetic addon drag state, no native player cursor APIs, no optimistic inventory mutation and an exact snapshot refresh after the structured server result. Stack splitting remains out of scope.
- Exact inventory equip through `ITEM_EQUIP_V1`, with source identity revalidation, authoritative result handling and no optimistic UI mutation.
- Exact Inspect unequip through `ITEM_UNEQUIP_V1`, with exact equipment slot/item identity and legacy `ue` fallback disabled unless explicitly enabled.
- Generic exact-item Trade through `ITEM_TRADE_V1`, with exact source identity, native WoW Trade UI preservation, native AzerothCore trade handling, structured `INVENTORY_ITEM_TRADE` completion and legacy give fallback only when compatibility fallback is explicitly enabled. Runtime validation passed in both trade directions.
- Exact item use through `ITEM_USE_V1`, with native use-item execution, source revalidation, structured result handling and localized failure reasons.
- Exact item destruction through the specialized `ITEM_DESTROY` path with server-side source revalidation.
- Exact single-item vendor sale through `ITEM_SELL_SINGLE_V1`, with nearby-vendor validation, protected-item guards, replay/rate limiting and structured result handling.
- Vendor Buyback through `VENDOR_BUYBACK_V1`, with structured list/result messages, native Buyback execution and authoritative inventory/list refreshes.
- Bulk inventory sell through `INVENTORY_BULK_SELL_V1` when supported; `SELL_VENDOR` is bridge-first in normal operation, its historical `s vendor` fallback is reachable only when `MultiBot.allowLegacyChatFallback == true`, and the validated Bridge action accepts `ITEM_USAGE_VENDOR` only while excluding `ITEM_USAGE_AH`. Runtime regression testing preserved Symbol of Kings and Gold Ore; SELL_GREY follow-up remains deferred.
- `OPEN_ITEMS` through `INVENTORY_OPEN_V1`, with structured result handling and no silent chat fallback in the normal bridge-first path.
- Group Roll through `GROUP_ROLL_V1`: normal 0–100 roll and Shift+click item roll, tokenized pending state, duplicate-send protection, timeout/cleanup handling and structured `GROUP_ROLL_ACK`.
- SelfBot enable/disable through `SELF_BOT_V1`, with explicit desired state, authoritative server verification and legacy `.playerbot bot self` fallback only when compatibility fallback is explicitly enabled.
- SelfBot strategy state/mutation through `SELF_STRATEGY_V1`, restricted to the player's active SelfBot and server-side class/state allowlists.
- SelfBot EveryBar actions through `SELF_ACTION_V1` for `AUTOGEAR`, `MAINTENANCE` and `WAIT_ATTACK_TIME`; this does not migrate equivalent normal-bot legacy chat paths.
- Spellbook refresh, with profession/crafting spells separated from the combat spellbook path.
- Character Info frame through the bridge with Blizzard-style tabs for class, profession, secondary, weapon and armor skills, reputations and currencies/emblems.
- Bot bank and guild bank snapshots through the bridge, plus vendor buy and bank/guild-bank item actions. Exact deposits use `ITEM_DEPOSIT_EXACT_V1`: the addon sends the selected inventory `bag/slot/itemId/count`, waits for the authoritative structured result and refreshes after success. Runtime validation confirmed only the clicked physical stack moves for both BANK and GBANK; stale source identity is rejected with `SOURCE_STALE`. Exact BANK/GBANK withdrawals are deferred because their current snapshots do not expose a selectable physical source stack end to end.
- Profession recipe frame through the bridge, opened from profession and secondary skill rows. Normal recipes use `RUN~CRAFT_RECIPE`; exact-item recipes continue through the runtime-validated `CRAFT_RECIPE_TARGET_V1` flow after `TARGET_REQUIRED`, using exact Inventory/Inspect `bag/slot/itemId` selection. Recipes with `craftable > 0` use a bright-green name.
- Enchanting Trade Service through `ENCHANT_TRADE_V1`: dedicated enchanter-only UI from EveryBar/Character Info, known-spell listing, reagent/tool availability, native `TRADE_SLOT_NONTRADED` targeting and validated numeric spell execution without generic Playerbots command/chat dispatch. Entries with all required reagents and tools available use a bright-green name.
- Glyph refresh with icons and glyph tooltips.
- Outfits refresh and actions through the bridge.
- Outfit equip/replace without detailed `Equipping [item] ...` chat spam.
- Quest list refresh through the bridge.
- Quest abandon through `QUEST_ABANDON_V1`: right-click keeps the player's native `SetAbandonQuest()` / `AbandonQuest()` path, sends a structured bot-abandon request through the bridge and emits no legacy `drop` chat in normal bridge-first configuration. Runtime validation with one controlled bot passed with zero chat spam and zero Lua errors; the mixed multi-bot scenario is explicitly deferred until suitable bots are available.
- Quest sharing remains intentionally native/chatless through `QuestLogPushQuest()`; no `QUEST_SHARE_V1` endpoint is required for the current behavior.
- Game object search results and copy frame through the bridge.
- RTI controls through the bridge.
- Pull Control frame through the bridge.
- Combat strategy fine tuning through the bridge.
- Disperse controls through the bridge with `disperse set <yards>` and `disperse disable`.
- Party/raid-wide formation application through `RUN~FORMATION`, with per-bot effective formation inspection through `GET~FORMATIONS` and no PARTY/RAID chat output.
- Localized formation status tooltip for all eight addon locale files.
- Loot rules through the bridge with `nc +loot`, `nc -loot` and `ll all|normal|gray|quest|skill`.
- Loot Master UI for master-loot distribution with item tooltips, candidate scoring, profession/spec hints, saved preferences and recent loot history.
- Bridge-visible bot discovery for AddClass bots, altbots and grouped randombots.
- Custom glyph socket mapping and apply order.
- Talent tab navigation stability after switching between tabs.
- Automatic bot reconnect on login/reload for bots already present in the group or raid.
- Units bar refresh after adding a bot through AddClass.

Validated development milestones on the current line:

- PR #49 — bridge synchronization, strategy controls, persistent/offline favorites and STATE stabilization.
- PR #50 — explicit strategy-command rejection diagnostics.
- PR #51 — mechanical deduplication of shared roster workflow helpers.
- PR #53 — prevent silent chat fallback for strategy mutations.
- PR #54 — outfit actions migrated to the negotiated bridge capability.
- PR #55 — strict bridge routing for inventory read/refresh.
- PR #58 — single-bot inventory Sell Vendor migrated to the bridge.
- PR #60 — bridge-first `OPEN_ITEMS`.
- PR #61 — chatless Group Roll UI, merged as `106074c3c93f80812f73af27e746860c7c8a4dcf`.
- PR #67 — Jellypowered chatless/inventory integration merged into `main`, merge commit `70e72ba6cb9a7170497b201e0dbe469bb29e6be9`.
- PR #72 — `Complete SelfBot chatless integration`, merged into `main`; current audited Addon baseline is merge commit `833d541063f207354c4131cf6a614c7df176348d`.
- The current `jellypowered-chatless-integration-v2` branch was created from that `main` baseline on 2026-08-20 and initially matched `main`/`origin/main`/its remote tracking branch at 0/0 ahead-behind.
- Final static STATE/strategy audit on 2026-08-07: 57 checks, 0 failures; final manual runtime matrix remains pending.
- Warlock selector batch is migrated to bridge strategy mutations; final project-level real TEMP_ENCHANT revalidation and the four remaining LuaLint warnings are explicitly deferred.
- Group Roll runtime validation on 2026-08-14: normal roll, item roll, eligibility, no chat spam, duplicate protection, invalid/empty item rejection and pending cleanup all validated.
- Enchanting Trade Service runtime validation on 2026-08-14: enchanter-only button, list/search/tooltips, localized 440 px frame, normal WoW Trade flow and real item enchant application all validated with no automatic chat executor.

<!-- MULTIBOT_TALENT_PROGRESS_SYNC_2026-08-21 -->
## Talent migration progress — 2026-08-21

- `TALENT_APPLY_V1` is implemented, compiled and runtime validated for the editable **Custom Talents** flow. The Bridge validates the complete build, reuses the audited Playerbots parse/apply path, verifies the resulting three talent-tree totals with `BuildTalentTabPoints`, resets strategies only after successful verification, and the Addon displays localized success only after the structured server `OK`.
- `TALENT_SPEC_APPLY_V1` is implemented, compiled and runtime validated for the EveryBar premade specialization selector. `TALENT_SPEC_CURRENT` replaces the normal current-spec whisper, left-click applies slot 1, right-click applies slot 2 including dual-spec creation/validation where eligible, the server reproduces cast interruption, revalidates the premade spec index, applies talents, resets `custom_glyphs`, runs `InitGlyphs(false)`, verifies final tree totals and returns one structured result.
- Normal Bridge operation no longer needs `talents`, `talents spec list`, `stopcasting`, `talents switch <slot>` or `talents spec <name>` for these selector flows. The historical chat path remains available only when `MultiBot.allowLegacyChatFallback == true`.
- Both talent success/failure messages are localized in the 8 currently loaded locales; successful operations are shown in white only after authoritative server confirmation.
- `mod-playerbots` remains strictly read-only and no generic Playerbots command executor was introduced.

`CRAFT_RECIPE_TARGET_V1` is now implemented, compiled and runtime validated.

`SELL_VENDOR` safety hardening was completed and runtime revalidated on 2026-08-23. The Addon remains bridge-first and exposes the historical `s vendor` whisper only when `MultiBot.allowLegacyChatFallback == true`; the Bridge accepts `ITEM_USAGE_VENDOR` only for this action and excludes `ITEM_USAGE_AH`. Symbol of Kings and Gold Ore were both preserved in the runtime regression test while `SELL_VENDOR` remained functional. Validated commits: Addon `fe2c807785219b82ca885f1a95d7c1dc27f0eed0`, Bridge `3ccf5047f7994218b742312fe1437f4b303f7159`.

The bank / guild-bank comparison produced the completed `ITEM_DEPOSIT_EXACT_V1` P3A path. Exact BANK withdrawal (P3B) and exact GBANK withdrawal (P3C) are intentionally deferred because their current read models do not expose a physical source stack end to end. The normal roadmap now resumes with `LOOT_RULE_EXACT_ITEM_ADD_REMOVE`.
Known migration remaining:


- Remaining direct `SendChatMessage` occurrences outside migrated paths still need to be classified as manual command, diagnostic fallback, information message, UI mechanism to migrate, compatibility fallback, or dead code.
- Item enchanting is now **implemented and runtime validated** through the closed `ENCHANT_TRADE_V1` Trade Service; it does not expose a generic cast or arbitrary Playerbots command executor.
- `ITEM_MOVE_V1` already covers whole-stack movement between allowed Backpack / Bag 1..4 / Keyring physical slots, including inter-container moves. A future `BAG_MOVE` item must therefore mean moving/re-equipping the **bag objects themselves** in equipped bag slots, not moving ordinary inventory items.
- Generic exact-item Trade is now implemented and runtime validated through `ITEM_TRADE_V1`; it remains distinct from the specialized `ENCHANT_TRADE_V1` service and does not expose a generic command executor.
- Quest abandon is now implemented through `QUEST_ABANDON_V1` and runtime validated with one bot. Quest sharing remains native through `QuestLogPushQuest()`. The mixed multi-bot Quest Abandon runtime scenario is deferred until suitable bots are available.
- `TALENT_APPLY_V1`, `TALENT_SPEC_APPLY_V1`, `CRAFT_RECIPE_TARGET_V1` and P3A `ITEM_DEPOSIT_EXACT_V1` are complete and runtime validated. `ITEM_DEPOSIT_EXACT_V1` moves only the selected physical inventory stack for BANK/GBANK deposits and rejects stale `bag/slot/itemId/count` identity before mutation. P3B/P3C exact withdrawals are deferred. The normal roadmap now resumes with item-specific loot-rule add/remove, followed by the Quest/Skill versus Disenchant decision and collective `follow` / `attack` / `stay` orders.
- The project should be described as **bridge-first / mostly chatless**, not fully chatless, until these remaining paths are classified/migrated and the final runtime matrix is closed.

Kept intentionally:

- Manual whisper/playerbot commands for diagnostics.
- Commands such as `who`, `co ?`, `nc ?`, `ss ?`.
- Gameplay write actions that still rely on existing playerbot commands.
- Optional legacy fallback behavior only for debugging or compatibility.

---

# Remaining Work

The current `jellypowered-chatless-integration-v2` line starts from the merged Jellypowered inventory baseline plus the separately completed SelfBot work. It continues the remaining Jellypowered items feature-family by feature-family rather than reapplying already merged code or jumping directly to final cleanup.

Immediate roadmap work:

1. Audit and implement `LOOT_RULE_EXACT_ITEM_ADD_REMOVE` using verified Playerbots interfaces only.
2. Decide the Quest/Skill versus Disenchant path from verified Playerbots capabilities.
3. Audit collective `follow`, `attack` and `stay` selectors before any structured group-order migration.

Completed on the current v2 line before this next step: `TALENT_APPLY_V1`, `TALENT_SPEC_APPLY_V1`, `CRAFT_RECIPE_TARGET_V1`, the 2026-08-23 `SELL_VENDOR` safety hardening and P3A `ITEM_DEPOSIT_EXACT_V1`. P3A was runtime validated for BANK and GBANK with two identical physical stacks: only the selected stack moved. A deliberately stale `count` returned `SOURCE_STALE` and left the real stack unchanged.

Low-priority residual: moving/re-equipping the **equipped bag objects themselves** (`BAG_MOVE`) only if the need remains; ordinary item moves between Backpack / Bag 1..4 / Keyring are already covered by `ITEM_MOVE_V1`.

Explicitly deferred until the normal roadmap is complete:

- P3B — exact BANK withdrawal; current bank withdrawal snapshot is aggregated and needs a wider protocol/UI design.
- P3C — exact GBANK withdrawal; physical source selection is not exposed end to end to the addon.
- Dedicated localized UI text for `SOURCE_STALE`; the current generic error text is non-blocking.
- SELL_GREY / sell-grey core API / bridge-first follow-up.
- Final real Firestone/Spellstone `TEMP_ENCHANTMENT_SLOT` revalidation.
- Four remaining LuaLint warnings in `Strategies/MultiBotWarlock.lua`.
- Other small items that were explicitly deferred during previous validated batches.

Ongoing finalization work remains unchanged: regression testing, classification of residual `SendChatMessage` paths, removal of dead legacy parsers only after proof of non-regression, and documentation/screenshot cleanup after wider testing.

---

# Troubleshooting

<details>
<summary><strong>The addon does not load</strong></summary>

Check that the folder is named exactly:

```text
Interface/AddOns/MultiBot
```

and that the `.toc` file is here:

```text
Interface/AddOns/MultiBot/MultiBot.toc
```

If the `.toc` file is inside another nested `MultiBot` folder, the addon is installed incorrectly.

</details>

<details>
<summary><strong>The addon loads but the bridge does not connect</strong></summary>

Check that:

- `mod-multibot-bridge` is installed in the AzerothCore `modules` directory.
- AzerothCore was rebuilt after installing the module.
- The server was restarted after rebuilding.
- The bridge module is visible in server logs.
- Your client is logged into a character connected to the server.

</details>

<details>
<summary><strong>I still see some chat messages</strong></summary>

This project removes automatic UI-refresh spam where the bridge path has been implemented.

Manual commands and gameplay actions may still produce intentional messages.

Make sure this value is disabled unless you are debugging:

```lua
MultiBot.allowLegacyChatFallback = false
```

</details>

<details>
<summary><strong>The formation tooltip does not appear or is incomplete</strong></summary>

Check that the bridge is connected and that the bots are controllable members of the same party or raid as the player.

A right-click on the Formation button should produce structured bridge traffic similar to:

```text
GET~FORMATIONS~GROUP~~<token>
FORMATIONS_BEGIN~<token>~<count>
FORMATIONS_ITEM~<token>~<botName>~<formation>
FORMATIONS_END~<token>~<sentCount>
```

The query is raid-wide: it includes all controllable bots in the current party or raid and does not target individual raid subgroups.

</details>

<details>
<summary><strong>Inventory, spellbook, glyphs or outfits do not update</strong></summary>

Check the server console for bridge requests such as:

```text
GET~INVENTORY
GET~BANK
GET~GBANK
GET~SPELLBOOK
GET~GLYPHS
GET~OUTFITS
GET~BOT_SKILLS
GET~BOT_REPUTATIONS
GET~BOT_EMBLEMS
GET~PROFESSION_RECIPES
GET~QUESTS
GET~GAMEOBJECTS
```

If these requests do not appear, the addon may not be connected to the bridge.

</details>

<details>
<summary><strong>The Loot Master frame does not open</strong></summary>

Check that:

- The Loot Master UI option is enabled in the addon options.
- The group loot method is set to Master Loot.
- Your character is the detected master looter.
- The opened loot contains relevant loot slots.

The frame uses the client master-loot candidate API and enriches candidates with cached bridge details when available.

</details>

<details>
<summary><strong>The Loot Master frame does not open</strong></summary>

Check that:

- The Loot Master UI option is enabled in the addon options.
- The group loot method is set to Master Loot.
- Your character is the detected master looter.
- The opened loot contains relevant loot slots.

The frame uses the client master-loot candidate API and enriches candidates with cached bridge details when available.

</details>

---

# Project Documentation

The active project documentation is intentionally limited to two files:

- [Development roadmap](docs/ROADMAP.md) — current phases, priorities, risks and acceptance criteria.
- [Debug and observability runbook](docs/DEBUG_RUNBOOK.md) — in-game debug commands, performance counters and bug-report procedure.

---

# Repository Layout

```text
MultiBot-Chatless/
├── Core/
├── Data/
├── Features/
├── Icons/
├── Libs/
├── Locales/
├── Strategies/
├── Textures/
├── UI/
├── docs/
│   ├── DEBUG_RUNBOOK.md
│   └── ROADMAP.md
└── MultiBot.toc
```

---

# Related Repositories

<table>
  <tr>
    <th>Repository</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>
      <a href="https://github.com/Wishmaster117/MultiBot-Chatless">
        MultiBot-Chatless
      </a>
    </td>
    <td>
      Client-side World of Warcraft addon.
    </td>
  </tr>
  <tr>
    <td>
      <a href="https://github.com/Wishmaster117/mod-multibot-bridge">
        mod-multibot-bridge
      </a>
    </td>
    <td>
      AzerothCore server-side bridge module.
    </td>
  </tr>
  <tr>
    <td>
      <a href="https://github.com/Wishmaster117/MultiBot-Standalone">
        MultiBot-Standalone
      </a>
    </td>
    <td>
      Deprecated combined repository kept for history.
    </td>
  </tr>
  <tr>
    <td>
      <a href="https://github.com/mod-playerbots/mod-playerbots">
        mod-playerbots
      </a>
    </td>
    <td>
      Original AzerothCore Playerbots module.
    </td>
  </tr>
</table>

---

# Credits

MultiBot is built for use with AzerothCore `mod-playerbots`.

Thanks to <b>Macx-Lio</b> for the original MultiBot Module.

Thanks to the Playerbots team and the AzerothCore community.

---

<div align="center">

## MultiBot Chatless

<strong>Less automatic chat spam. Cleaner UI refreshes. Bridge-first bot data.</strong>

<br><br>

<a href="https://github.com/Wishmaster117/MultiBot-Chatless">
  Client Addon
</a>
&nbsp;•&nbsp;
<a href="https://github.com/Wishmaster117/mod-multibot-bridge">
  Bridge Module
</a>

</div>
