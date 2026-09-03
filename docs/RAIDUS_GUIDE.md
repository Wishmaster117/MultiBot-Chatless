# Raidus User Guide

Raidus is MultiBot Chatless's raid-planning window for arranging the player and managed Playerbots into a persistent 40-slot layout before applying that plan to the live party or raid.

The current implementation is **bridge-first** for bot lifecycle operations. It is designed for World of Warcraft 3.3.5a with the matching `mod-multibot-bridge` server module.

---

## 1. What Raidus Manages

The planner contains:

- **8 raid groups**;
- **5 slots per group**;
- a bot **Pool** on the right;
- a card for the current player;
- a persistent **Working Layout**;
- **Saved Layouts**;
- pool sorting by **Score**, **Level** or **Class**;
- score-based and role-based **Auto** balancing;
- structured **Apply** behavior for connecting required bots, removing managed Playerbots that are outside the layout, and sorting the live raid into the planned groups.

The Working Layout is the arrangement currently visible in Raidus. It is separate from the live party/raid until you press **Apply**.

---

## 2. Opening and Closing Raidus

Open MultiBot and use the **Raidus** control from the addon UI.

When Raidus opens, the addon rebuilds the pool and, when the Bridge target-resolution capability is available, validates pool entries against the server. Entries that the Bridge explicitly reports as unavailable to the current player can be filtered from the active pool.

Closing and reopening Raidus does not intentionally discard the Working Layout.

The Raidus window also restores its persisted Working Layout after `/reload` when the saved state is valid.

---

## 3. The Pool

The Pool contains the current player's card plus known bot cards that can be represented from the addon bot-details store.

Each bot card displays summary information such as:

- name;
- level;
- specialization;
- score.

Hovering a bot card opens a larger detail panel with additional character information. For bots, this includes the detected Tank / Heal / DPS role when available.

The visible pool page contains up to **11 entries**. Use the `<` and `>` buttons to move between pages.

### Pool sorting

Use:

- **Score** — score first, then level;
- **Level** — level first, then score;
- **Class** — class-based ordering, with level and score used as secondary values.

Changing the sort rebuilds the pool while preserving the current Working Layout.

---

## 4. Drag, Drop and Swap

Use the **left mouse button** on a card to drag it.

You can:

- drag a pool card into a raid-group slot;
- move a card from one group slot to another;
- drop onto an occupied slot to swap the two cards;
- move a card back toward the Pool through the same slot-swap mechanism.

A successful drop updates group/raid score displays and persists the Working Layout.

If a drag ends without a valid drop target, the card returns to its previous position.

---

## 5. Bot Lifecycle from the Pool

For a bot card:

- **Right-click** toggles that bot's lifecycle state through the Bridge;
- an offline bot can be connected;
- an online bot can be disconnected.

The current player's own card is never treated as a bot lifecycle target.

Raidus requires the Bridge lifecycle and target-resolution capabilities for this operation. It does not silently fall back to a Raidus `.playerbot bot add/remove` command when those structured capabilities are unavailable.

### Shift + Right-click

**Shift + Right-click** is available only for a bot card that is currently in the Pool.

It opens a confirmation dialog and removes that bot entry from the addon's global Raidus bot pool/store. The current Working Layout is rebuilt and preserved around that operation.

This is different from normal right-click lifecycle control.

---

## 6. The Working Layout

The **Working Layout** is the live planner state currently shown in the 8 × 5 grid.

It is persisted separately from named Saved Layouts. The addon stores:

- the serialized 8-group layout;
- the currently selected Saved Layout slot.

The Working Layout is refreshed after relevant pool/detail updates without intentionally discarding the arrangement.

### Persistence

The validated behavior is:

- close Raidus and reopen it → Working Layout remains;
- `/reload` → Working Layout is restored;
- bot-detail refresh → Working Layout is preserved.

---

## 7. Saved Layouts

Raidus exposes Saved Layout slots **1 through 10** in the current UI.

Use the **Slot** button to choose the active Saved Layout number.

### Save

Press **Save** to serialize the current 8 × 5 arrangement into the selected Saved Layout slot.

Saving also persists the current Working Layout.

### Load

Press **Load** to restore the selected Saved Layout into the Working Layout.

Loading a valid Saved Layout also persists the newly restored Working Layout.

If the selected Saved Layout has no stored data, Raidus reports that there is nothing to load.

### Legacy migration note

The current UI exposes slots 1–10. The legacy-key migration helper in the current code covers the older slot range 1–8. This only matters when migrating very old legacy SavedVariables; current profile-backed saves use the modern store.

---

## 8. Auto Balance

The **Auto** button has two modes.

### Left-click — Score balance

Left-click **Auto** to rebuild the Working Layout using score-based balancing.

Bots are ordered by score, with level as a secondary value, and then distributed across the required raid groups.

### Right-click — Role balance

Right-click **Auto** for Tank / Heal / DPS balancing.

Raidus derives roles primarily from class plus the dominant talent-tree distribution. If that information cannot be resolved, it uses class-based fallback roles.

The role mode distributes:

1. tanks;
2. healers;
3. DPS;

across the groups in round-robin order.

### Which bots Auto uses

Auto first looks for selected bot buttons in the MultiBot Units UI.

If no bots are selected there, it falls back to all valid known bots in the global bot store.

The current player is automatically placed in **Group 1 / Slot 1** by Auto.

---

## 9. Apply — Normal Layout

**Apply** turns the Working Layout into the desired live party/raid state.

For a non-empty layout, the current player must also appear in one of the Raidus group slots. If the player is missing, Raidus reports that the player must be placed in a Raidus raid-group slot before Apply can continue.

For the planned bot entries, Apply:

1. reads the Working Layout;
2. builds the list of bots that are planned but not currently grouped;
3. starts structured target resolution / bot connection for those missing bots;
4. inspects the current party or raid;
5. requests safe structured removal for currently grouped managed Playerbots that are not present in the layout;
6. once required invitations are complete, runs the existing raid subgroup sorting process.

The subgroup sorter uses the planned group number for each layout entry and uses the normal WoW raid subgroup operations (`SetRaidSubgroup` / `SwapRaidSubgroup`) when realignment is needed.

---

## 10. Apply — Empty Working Layout

A completely empty Working Layout is intentionally valid.

With an empty layout, **Apply is cleanup-only**:

1. inspect the current party/raid;
2. request safe removal of eligible managed Playerbots that are outside the empty layout;
3. stop.

No AutoSort is started for this empty-layout case.

This behavior is useful when you want Raidus to clear managed Playerbots from the current party/raid without creating a new planned raid.

---

## 11. Human-Safe Outside-Layout Removal

Raidus does not directly call the client `UninviteUnit()` API for outside-layout cleanup.

Instead, the addon requests `DISCONNECT_GROUP`, which requires the Bridge capability:

```text
BOT_GROUP_REMOVE_V1
```

The server-side path is deliberately restrictive.

The Bridge:

1. resolves the requested target;
2. proves that the GUID currently belongs to a Playerbot managed by `PlayerbotMgr`;
3. verifies requester and bot group membership;
4. rejects unsupported LFG, battleground and battlefield groups;
5. refuses to remove the group leader;
6. applies AzerothCore's normal group-uninvite permission check;
7. logs the bot out through the normal Playerbots lifecycle path;
8. rechecks the group after logout;
9. removes only a residual group membership if one remains;
10. verifies the final state before returning success.

A connected **human player** who is outside the Raidus layout is therefore not removed by this path merely because that player is in the group, on the same account, in the same guild, or otherwise visible to the addon.

This human-safety behavior has been runtime tested.

---

## 12. Party and Raid Behavior

Raidus cleanup detects the current live group from WoW's party/raid APIs.

Validated behavior includes:

- normal party cleanup;
- raid cleanup;
- removal of residual offline raid membership after a successful Playerbot logout when required;
- no removal of a real connected human outside the layout.

Raidus supports layouts up to the normal 40-slot raid size.

---

## 13. Status Messages and “Chatless”

Raidus lifecycle mutations are bridge-first, but the current Raidus implementation still uses a small number of `SendChatMessage` calls for **user-facing status/information**, for example Save/Load/Apply progress messages.

Therefore Raidus, like the wider project, should be described as **bridge-first / mostly chatless**, not fully chatless.

The important distinction is that current Raidus bot lifecycle control and safe outside-layout removal no longer depend on `.playerbot bot add/remove` chat commands.

---

## 14. Troubleshooting

### Right-click does nothing

Check that:

- the Bridge is connected;
- `BOT_LIFECYCLE_V1` is negotiated;
- `BOT_TARGET_RESOLVE_V1` is negotiated;
- the target is an authorized managed bot.

For outside-layout group removal, `BOT_GROUP_REMOVE_V1` must also be available.

### Apply does not continue on a non-empty layout

Make sure your own player card is placed in the Working Layout.

The non-empty Apply path requires the player to be represented in the planned layout.

### Empty Apply only removes bots and does not sort

That is expected.

An empty Working Layout is a cleanup-only operation and intentionally stops before AutoSort.

### A human outside the layout stays grouped

That is expected and is a security property.

Outside-layout cleanup is allowed only after the Bridge proves that the target is a currently managed Playerbot.

### A Saved Layout does not load

Confirm that the desired **Slot** is selected and that the slot has previously been saved.

### The pool changes after opening Raidus

When the Bridge is available, Raidus can validate pool names against the server and filter entries that are explicitly unavailable for the current player.

---

## 15. Recommended Workflow

A typical raid-planning workflow is:

1. open Raidus;
2. choose **Score**, **Level** or **Class** for the pool view;
3. drag the player and desired bots into the 8 × 5 Working Layout, or use **Auto**;
4. optionally choose a Saved Layout **Slot** and press **Save**;
5. press **Apply**;
6. allow structured bot connections/invitations to complete;
7. let Raidus realign raid subgroups to the planned group numbers.

For a cleanup-only operation:

1. clear the Working Layout;
2. press **Apply**;
3. eligible managed Playerbots are disconnected/removed safely;
4. real human players remain untouched.

---

## 16. Related Documentation

- [`README.md`](../README.md) — project overview and installation.
- [`ROADMAP.md`](ROADMAP.md) — technical project status, completed milestones and next migration work.
- [`DEBUG_RUNBOOK.md`](DEBUG_RUNBOOK.md) — debugging and observability workflow.
