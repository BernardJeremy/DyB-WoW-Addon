# DyBAddon

A lightweight World of Warcraft addon for DayBar that provides customizable gameplay features.

## Features

- **Force 24-Hour Clock**: Automatically enables 24-hour military time format on login (configurable, enabled by default)
- **Hide NPC Chat Bubbles**: Toggle to hide all in-game chat bubbles above characters (configurable, disabled by default)
- **Group Inspector**: When joining a group or when a new member arrives, logs each member's race (with icon), class (with icon), specialization (with icon), and item level to your chat window (configurable, enabled by default). A separate option controls whether inspection runs in raid groups (disabled by default).
- **Pull Timer**: Launch an in-game countdown for the whole group using `/pull <seconds>`. Requires party/raid leader or raid officer status (or none if solo). Use `/pull 0` to cancel the countdown.
- **Combat Meter Reset Prompt**: Displays a Yes/No popup offering to reset all combat sessions (`C_DamageMeter.ResetAllCombatSessions()`) when joining a group and/or entering an instance. Each trigger has a dedicated toggle in the options panel (both enabled by default).
- **Decimal Item Level**: Replaces the character sheet item level display with a two-decimal-precision value. Shows equipped item level alongside the overall average in the tooltip, and includes PvP item level when it differs. Active for all player levels.

All features can be enabled/disabled in-game via **System Settings > Addons > DyBAddon** and apply changes immediately.

## Architecture

The addon is modularized across 7 Lua files for clean separation of concerns:

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

### **DyBOptions.lua**
- Registers the settings category using the `Settings` API
- Creates six checkbox options with tooltips
- Initializes saved variables on `ADDON_LOADED`
- Manages setting callbacks for immediate UI updates

### **DybPullTimer.lua**
- Register a `/pull` command to trigger pull countdown
- Use `/pull 0` to cancel pull countdown
- Check for party leaderer / raid leader/co-leader role

### **DyBMeterReset.lua**
- Listens to `GROUP_ROSTER_UPDATE` to detect when the player newly joins a group
- Listens to `PLAYER_ENTERING_WORLD` to detect instance entry (skips login and UI reload)
- Shows a `StaticPopup` Yes/No dialog to reset all combat sessions via `C_DamageMeter.ResetAllCombatSessions()`
- Each trigger is independently toggled via options (both enabled by default)
- Exposes `DyBAddon.OnMeterResetOnGroupChanged()` and `DyBAddon.OnMeterResetOnInstanceChanged()` callbacks


### **DybItemLevelDecimal.lua**
- Hooks `PaperDollFrame_SetItemLevel` via `hooksecurefunc` to override the character sheet item level display
- Sets `MIN_PLAYER_LEVEL_FOR_ITEM_LEVEL_DISPLAY` to `1` so the stat shows at all levels
- Rounds average, equipped, and PvP item levels to two decimal places
- Displays the equipped item level in the tooltip alongside the overall average
- Appends PvP item level to the tooltip when it differs from the average
- No SavedVariables or options panel integration; always active

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
6. **Option Toggling**: Callbacks fire immediately when user changes settings in-game

## Compatibility

- Requires World of Warcraft 12.0.1 or later (Midnight+)
- Uses modern Settings API (Blizzard Menu implementation)

---

**Author**: Chef  
**Version**: 1.0
