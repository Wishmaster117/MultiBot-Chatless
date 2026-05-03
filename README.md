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

Examples of bridge requests:

```text
MBOT HELLO
MBOT PING
GET~ROSTER
GET~STATES
GET~DETAILS
GET~STATS
GET~PVP_STATS
GET~TALENT_SPEC_LIST
GET~INVENTORY
GET~SPELLBOOK
GET~BOT_SKILLS
GET~PROFESSION_RECIPES
GET~GLYPHS
GET~OUTFITS
GET~QUESTS
GET~GAMEOBJECTS
RUN~CRAFT_RECIPE
RUN~OUTFIT
RUN~RTI
RUN~COMBAT
RUN~POSITION
RUN~LOOT
```

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
    <td><strong>Bridge-first</strong></td>
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
    <td>Talent spec lists</td>
    <td><strong>Bridge-first</strong> template listing without automatic <code>talents spec list</code> chat spam</td>
  </tr>
  <tr>
    <td>Inventory</td>
    <td><strong>Bridge-first</strong> with icons and item tooltips</td>
  </tr>
  <tr>
    <td>Spellbook</td>
    <td><strong>Bridge-first</strong> combat spell listing separated from profession recipe data</td>
  </tr>
  <tr>
    <td>Character Info frame</td>
    <td><strong>Bridge-first</strong> class skills, professions, secondary skills, weapon skills and armor skills</td>
  </tr>
  <tr>
    <td>Profession recipe frame</td>
    <td><strong>Bridge-first</strong> recipe listing and recipe crafting opened from Character Info profession and secondary skill rows</td>
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
    <td>Legacy automatic chat fallback</td>
    <td><strong>Disabled by default</strong></td>
  </tr>
  <tr>
    <td>Outfits</td>
    <td><strong>Bridge-first</strong> listing, create/update, reset, equip and replace</td>
  </tr>
  <tr>
    <td>Quests</td>
    <td><strong>Bridge-first</strong> incompleted, completed and all quest lists</td>
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
- Bot states refresh.
- Bot details refresh.
- Stats refresh.
- PvP stats refresh.
- Talent spec list refresh.
- Inventory refresh with icons and item tooltips.
- Spellbook refresh, with profession/crafting spells separated from the combat spellbook path.
- Character Info frame through the bridge with class, profession, secondary, weapon and armor skills.
- Profession recipe frame through the bridge, opened from profession and secondary skill rows.
- Glyph refresh with icons and glyph tooltips.
- Outfits refresh and actions through the bridge.
- Outfit equip/replace without detailed `Equipping [item] ...` chat spam.
- Quest list refresh through the bridge.
- Game object search results and copy frame through the bridge.
- RTI controls through the bridge.
- Pull Control frame through the bridge.
- Combat strategy fine tuning through the bridge.
- Disperse controls through the bridge with `disperse set <yards>` and `disperse disable`.
- Loot rules through the bridge with `nc +loot`, `nc -loot` and `ll all|normal|gray|quest|skill`.
- Loot Master UI for master-loot distribution with item tooltips, candidate scoring, profession/spec hints, saved preferences and recent loot history.
- Bridge-visible bot discovery for AddClass bots, altbots and grouped randombots.
- Custom glyph socket mapping and apply order.
- Talent tab navigation stability after switching between tabs.
- Automatic bot reconnect on login/reload for bots already present in the group or raid.
- Units bar refresh after adding a bot through AddClass.

Kept intentionally:

- Manual whisper/playerbot commands for diagnostics.
- Commands such as `who`, `co ?`, `nc ?`, `ss ?`.
- Gameplay write actions that still rely on existing playerbot commands.
- Optional legacy fallback behavior only for debugging or compatibility.

---

# Remaining Work

The Outfits, RTI, Pull Control, Combat Strategy, Disperse, Loot Rules, Quest, Game Object, Character Info and Profession Recipe migrations are implemented. The Loot Master UI is also implemented as an optional client-side master-loot helper. The next step is final stabilization and cleanup.

Planned follow-up work:

- Regression test login, `/reload`, large raid groups, Units, EveryBars, Stats, PvP Stats, Inventory, Spellbook, Character Info, Profession Recipes, Talents, Glyphs, Outfits, Quests, Game Objects, RTI, Pull Control, Combat Strategies, Disperse, Loot Rules and Loot Master.
- Verify that `MultiBot.allowLegacyChatFallback = false` prevents automatic legacy refresh spam on all migrated UI paths.
- Keep manual diagnostic commands documented and functional.
- Remove obsolete debug prints.
- Remove dead legacy parser paths once bridge-first behavior is fully stable.
- Update screenshots and user documentation after wider testing.

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
<summary><strong>Inventory, spellbook, glyphs or outfits do not update</strong></summary>

Check the server console for bridge requests such as:

```text
GET~INVENTORY
GET~SPELLBOOK
GET~GLYPHS
GET~OUTFITS
GET~BOT_SKILLS
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
