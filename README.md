<img width="1024" height="559" alt="image" src="https://github.com/user-attachments/assets/3ac43983-8767-4dd6-9a17-4548ede1e9d3" />

# MultiBot
User interface for AzerothCore-Module "Playerbots" by Playerbots team https://github.com/mod-playerbots/mod-playerbots.<br>
Tested with American, German, French and Spanish 3.3.5 Wotlk-Client.

# Installation
Simply place the files in a folder called "MultiBot" in your World of Warcraft AddOns directory.<br>
Example: "C:\WorldOfWarcraft\Interface\AddOns\MultiBot"
# Use
Start World of Warcraft and enter "/multibot" or "/mbot" or "/mb" in the chat, or use the minimap button.

---

## ⚠️ Notice — About This Fork

This is a fork of the original [MultiBot addon by Macx-Lio](https://github.com/Macx-Lio/MultiBot).

The reason for this fork is that I submitted several pull requests to the original repository, but since the creator, **Macx-Lio**, is currently unavailable, those changes could not be merged.

To allow the community to benefit from the additional features and improvements I have implemented, I’ve published this fork **as a temporary solution**.

> **All credit for the original addon goes to Macx-Lio.** I do not claim ownership of this project — I’m simply maintaining a working version until development resumes on the main repository.

Thank you for understanding.

---

# Comming soon

Port Multibot to ACE 3

# MultiBot ACE3 Migration Roadmap (Updated)

## Current Status Snapshot

- **Milestone 1 (Baseline / safety net):** In progress.
  - Baseline behavior is mostly known through manual validation.
  - Dedicated migration checklist file : https://github.com/Wishmaster117/MultiBot/blob/feature/ace3-migration/docs/ace3-migration-checklist.md
- **Milestone 2 (Add ACE3 libs):** Completed.
  - ACE3 libraries are loaded in `MultiBot.toc`.
- **Milestone 3 (Initialization lifecycle):** Mostly completed, hardening pending.
  - `OnInitialize` and `OnEnable` are in place.
  - Legacy frame-based startup/event code still exists in a few places.
- **Milestone 4 (Command system):** Mostly completed.
  - Central alias registration exists and is used for core commands.
- **Milestone 5 (Event bus migration):** In progress.
  - Dispatcher architecture exists.
  - Some legacy `CreateFrame + RegisterEvent + SetScript` blocks remain.
- **Milestone 6 (SavedVariables -> AceDB):** Not started.
- **Milestone 7 (Minimap/options integration):** Partially completed.
  - Current minimap/options are stable, but not yet AceDB/LibDBIcon-driven.
- **Milestone 8 (AceGUI UI refactor):** Not started.

---

## Execution Plan to Completion

## Phase A — Close lifecycle + command + event gaps

### A1. Lifecycle hardening
1. Keep `OnInitialize` / `OnEnable` as the single startup path.
2. Move remaining startup side effects behind lifecycle-safe guards.
3. Ensure no duplicate initialization on reload/login.

**Exit criteria**
- No duplicate startup behavior.
- No extra event registrations after repeated reloads.

### A2. Command system finalization
1. Keep `RegisterCommandAliases` as the only command registration API.
2. Remove scattered direct slash registrations if any remain.
3. Preserve all current aliases and behavior.

**Exit criteria**
- `/multibot`, `/mbot`, `/mb`, `/mbopt`, `/mbclass`, `/mbclasstest` unchanged.

### A3. Event convergence
1. Keep `DispatchEvent` / `DispatchUpdate` as central dispatch points.
2. Gradually migrate remaining local frame-event blocks into centralized registration.
3. Validate high-frequency paths for duplicate callback regressions.

**Exit criteria**
- No duplicated callbacks.
- No observable event spam regression.

---

## Phase B — SavedVariables migration to AceDB

### B1. Introduce AceDB schema (non-breaking)
1. Add `MultiBot.db = AceDB:New(...)` with defaults equivalent to current settings.
2. Keep legacy variables readable during transition.

### B2. One-way migration from legacy storage
1. Migrate old keys once (timers, throttle, minimap, visibility, strata, favorites).
2. Mark migration version to avoid repeated imports.

### B3. Switch runtime reads/writes to AceDB
1. Move runtime config access to AceDB first.
2. Keep temporary fallback reads for one transition cycle.

**Exit criteria**
- Existing users retain settings.
- Fresh installs use AceDB defaults.

---

## Phase C — Minimap/options and optional UI modernization

### C1. Minimap/options stabilization
1. Keep current options UI intact.
2. Connect minimap/options persistence fully to AceDB.
3. Optionally add LibDBIcon integration without behavior changes.

**Exit criteria**
- Minimap toggle and options panel behavior unchanged for users.

### C2. Optional AceGUI refactor (last)
1. Migrate one screen at a time.
2. Keep data/control flow equivalent for each migrated screen.
3. Avoid big-bang rewrites.

**Exit criteria**
- Screen-by-screen functional parity before moving forward.

---

## PR Order

1. Lifecycle hardening.
2. Command system finalization.
3. Event convergence.
4. AceDB bootstrap.
5. Legacy -> AceDB one-way migration.
6. Runtime switch to AceDB.
7. Minimap/options persistence finalization.
8. Optional per-screen AceGUI refactor.

---

## Risk Controls (Apply on every PR)

- Keep changes localized and incremental.
- Avoid duplicate helper logic.
- Prefer reusing existing APIs/functions over adding new parallel paths.
- Validate no duplicate event registration and no repeated side effects on reload.
- Keep behavior identical unless explicitly planned and documented.
