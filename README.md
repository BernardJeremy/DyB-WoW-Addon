# DyBAddon

A lightweight World of Warcraft addon for DayBar that provides customizable gameplay features.

## Features

- **Force 24-Hour Clock**: Automatically enables 24-hour military time format on login (configurable, enabled by default)
- **Hide NPC Chat Bubbles**: Toggle to hide all in-game chat bubbles above characters (configurable, disabled by default)
- **Group Inspector**: When joining a group or when a new member arrives, logs each member's race (with icon), class (with icon), specialization (with icon), and item level to your chat window (configurable, enabled by default). A separate option controls whether inspection runs in raid groups (disabled by default).
- **Decimal Item Level**: Replaces the character sheet item level display with a two-decimal-precision value. Shows equipped item level alongside the overall average in the tooltip, and includes PvP item level when it differs. (configurable, enabled by default)
- **Inspect Item Level**: When inspecting another player, their item level is shown as a gold number overlay in the bottom-left corner of the Inspect frame. (configurable, enabled by default)
- **Durability Display**: Shows the average item durability percentage (sum of current / sum of max across all equipped items) in the top-left area of the character frame header, between the class/spec icon and the class/spec name. The percentage is color-coded: green (≥60%), gold (30–59%), red (<30%). (configurable, enabled by default)
- **Ready Check Consumable Check**: When a ready check is triggered inside an instance, displays a small popup centered horizontally at 33% from the top of the screen. Three icons indicate whether the player has an active Flask, Food buff, and Weapon enchant. Each icon shows a green checkmark if the buff is present or is desaturated with a red cross if missing. The popup can be dismissed at any time via the X button in the top-left corner. While visible, icons update live as buffs are gained or lost. (configurable, enabled by default)
- **Combat Timer**: Displays a small, movable window showing the elapsed time since the start of the current combat in `mm:ss.c` format (tenths of a second). The timer resets automatically each time combat begins and freezes when combat ends, keeping the last value visible. Window position is saved across sessions. (configurable, enabled by default)

All features can be enabled/disabled in-game via **System Settings > Addons > DyBAddon** and apply changes immediately.

## Architecture

The addon is modularized across 12 Lua files for clean separation of concerns:

### **DyBCore.lua**
- Defines the `DyBAddon` namespace table
- Shared module for all features

### **DyBClockFixer.lua**
- Listens to `PLAYER_LOGIN` event
- Applies 24-hour military time if the option is enabled
- Exposes `DyBAddon.OnMilitaryTimeChanged()` callback for real-time option toggling

### **DyBBubbleHider.lua**
- Listens to `PLAYER_LOGIN` event
- Applies chat bubble hiding if the option is enabled
- Exposes `DyBAddon.OnHideBubblesChanged()` callback for real-time option toggling

### **DyBGroupInspector.lua**
- Listens to `GROUP_ROSTER_UPDATE` to detect new group members
- Uses `NotifyInspect()` / `INSPECT_READY` to query each member's specialization and item level
- Displays race, class, and spec icons inline in chat via texture escape sequences
- Queues inspect requests one at a time with throttling and a 5-second safety timeout
- Exposes `DyBAddon.OnGroupInspectChanged()` and `DyBAddon.OnGroupInspectRaidChanged()` callbacks
- Offers a slash command `/info` to log up to date group members info

### **DyBDurability.lua**
- Hooks `CharacterFrame.OnShow` on `PLAYER_LOGIN` to refresh the display whenever the character frame is opened
- Listens to `UPDATE_INVENTORY_DURABILITY` and `PLAYER_EQUIPMENT_CHANGED` to keep the value up to date while the frame is visible
- Iterates equipment slots 1–17 via `GetInventoryItemDurability(slot)` to compute the ratio of total current over total max durability
- Renders the percentage as a color-coded `FontString` anchored to the right of `CharacterFramePortrait` (green ≥60%, gold 30–59%, red <30%)
- Respects the `showDurability` saved variable; exposes `DyBAddon.OnShowDurabilityChanged()` callback for real-time toggling

### **DyBOptions.lua**
- Registers the settings category using the `Settings` API
- Creates ten checkbox options with tooltips
- Initializes saved variables on `ADDON_LOADED`
- Manages setting callbacks for immediate UI updates

### **DyBCombatTimer.lua**
- Listens to `PLAYER_REGEN_DISABLED` to reset and start the timer on combat entry
- Listens to `PLAYER_REGEN_ENABLED` to freeze the display on combat exit
- Renders elapsed time as `mm:ss.c` (tenths of a second) in a white-on-black draggable frame
- Saves and restores window position via `DyBAddon_SavedVars.combatTimerPos`
- Respects the `combatTimer` saved variable; exposes `DyBAddon.OnCombatTimerChanged()` callback for real-time show/hide toggling

### **DyBMeterReset.lua**
- Listens to `GROUP_ROSTER_UPDATE` to detect when the player newly joins a group
- Listens to `PLAYER_ENTERING_WORLD` to detect instance entry (skips login and UI reload)
- Shows a `StaticPopup` Yes/No dialog to reset all combat sessions via `C_DamageMeter.ResetAllCombatSessions()`
- Each trigger is independently toggled via options (both enabled by default)
- Exposes `DyBAddon.OnMeterResetOnGroupChanged()` and `DyBAddon.OnMeterResetOnInstanceChanged()` callbacks


### **DybItemLevelDecimal.lua**
- Hooks `PaperDollFrame_SetItemLevel` via `hooksecurefunc` to override the character sheet item level display
- Rounds average, equipped, and PvP item levels to two decimal places
- Displays the equipped item level in the tooltip alongside the overall average
- Appends PvP item level to the tooltip when it differs from the average
- Respects the `decimalItemLevel` saved variable; exposes `DyBAddon.OnDecimalItemLevelChanged()` callback
- When disabled, the hook returns early and lets Blizzard render the stat frame normally

### **DybInspectItemLevel.lua**
- Listens to `INSPECT_READY` to render a gold item level overlay in the bottom-left corner of `InspectFrame` when viewing another player
- Uses `C_PaperDollInfo.GetInspectItemLevel(InspectFrame.unit)` to retrieve the inspected player's item level
- Respects the `inspectItemLevel` saved variable; exposes `DyBAddon.OnInspectItemLevelChanged()` callback that immediately hides the overlay when disabled

### **DyBReadyCheckConsumables.lua**
- Listens to the `READY_CHECK` event; ignores it when outside an instance or when the feature is disabled
- Checks for flask buffs by spell ID (`C_UnitAuras.GetAuraDataByIndex`), food buffs by icon file ID 136000 (the shared "Well Fed" icon), and main-hand weapon enchant via `GetWeaponEnchantInfo()`
- Renders a small `BackdropTemplate` popup centered horizontally with its top edge at 33% from the screen top
- Each of the three category icons (Flask, Food, Weapon) is shown normally with a green checkmark when the buff is active, or desaturated with a red cross when missing
- The popup is dismissible at any time via an X button in the top-left corner
- While the popup is visible, listens to `UNIT_AURA` (flask/food buff changes) and `PLAYER_EQUIPMENT_CHANGED` (weapon enchant changes) to keep icons up to date in real time; both events are unregistered when the popup is hidden to avoid unnecessary overhead
- Exposes `DyBAddon.OnReadyCheckConsumablesChanged()` callback for real-time option toggling

### **DyBAddon.toc**
- Addon manifest with metadata
- Declares `DyBAddon_SavedVars` as saved variables
- Specifies load order: Core → Features → Options

## Load Sequence

1. **Addon Load**: All `.lua` files loaded in order (Core → Features → Options)
2. **ADDON_LOADED**: Saved variables initialized, settings panel registered
3. **PLAYER_LOGIN**: CVar-based features apply their settings
4. **GROUP_ROSTER_UPDATE**: Group inspector detects new members and queues inspections
5. **INSPECT_READY**: Inspect results are received and printed to chat
6. **READY_CHECK**: Consumable popup is shown when inside an instance
7. **UNIT_AURA / PLAYER_EQUIPMENT_CHANGED**: Consumable icons refresh live while the popup is visible
8. **PLAYER_REGEN_DISABLED / PLAYER_REGEN_ENABLED**: Combat timer starts/freezes on combat enter/exit
9. **Option Toggling**: Callbacks fire immediately when user changes settings in-game

## Compatibility

- Requires World of Warcraft 12.0.1 or later (Midnight+)
- Uses modern Settings API (Blizzard Menu implementation)

---

**Author**: Chef  
**Version**: 1.0
