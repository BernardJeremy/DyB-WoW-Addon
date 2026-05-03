# DyBAddon

A lightweight World of Warcraft addon for DayBar that provides customizable gameplay features.

## Features

- **Force 24-Hour Clock**: Automatically enables 24-hour military time format on login (configurable, enabled by default)
- **Hide NPC Chat Bubbles**: Toggle to hide all in-game chat bubbles above characters (configurable, disabled by default)
- **Group Inspector**: When joining a group or when a new member arrives, logs each member's race (with icon), class (with icon), specialization (with icon), and item level to your chat window (configurable, enabled by default). A separate option controls whether inspection runs in raid groups (disabled by default).
- **Decimal Item Level**: Replaces the character sheet item level display with a two-decimal-precision value. Shows equipped item level alongside the overall average in the tooltip, and includes PvP item level when it differs. (configurable, enabled by default)
- **Inspect Item Level**: When inspecting another player, their item level is shown as a gold number overlay in the bottom-left corner of the Inspect frame. (configurable, enabled by default)
- **Durability Display**: Shows the average item durability percentage (sum of current / sum of max across all equipped items) in the top-left area of the character frame header, between the class/spec icon and the class/spec name. The percentage is color-coded: green (≥60%), gold (30–59%), red (<30%). (configurable, enabled by default)
- **Ready Check Consumable Check**: When a ready check is triggered inside an instance, displays a small popup centered horizontally at 33% from the top of the screen. The popup has two rows of icons:
  - **Row 1 – Consumables**: Flask, Food buff, and Weapon enchant.
  - **Row 2 – Class buffs**: One icon per class buff provider present in the group (Mage, Warrior, Evoker, Druid, Priest, Shaman). Only classes actually in the group and meeting the required level are shown; both rows are horizontally centered even when they have different widths.
  - Each icon shows a green checkmark if the buff is present or is desaturated with a red cross if missing. Icons update live while the popup is open.
  - A **build name label** at the bottom of the popup shows the current specialization and active talent loadout name in the format `Spec / Loadout` (e.g. `Fire / M+ Build`). If no named loadout is selected, only the spec name is shown. The label updates live when the player switches loadout while the popup is open.
  - A **minimap button** (draggable around the minimap edge, position saved across sessions) lets you open the popup at any time without a ready check.
  - The popup can be dismissed at any time via the X button in its top-left corner.
  - Both the popup-on-ready-check and the minimap button are independently togglable in the options panel. (both enabled by default)
- **Combat Timer**: Displays a small, movable window showing the elapsed time since the start of the current combat in `mm:ss.c` format (tenths of a second). The timer resets automatically each time combat begins and freezes when combat ends, keeping the last value visible. Window position is saved across sessions. (configurable, enabled by default)
- **Cursor Circle**: Displays a colored ring of dots around the mouse cursor while in game. The ring color can be chosen from eight presets (White, Red, Green, Blue, Yellow, Purple, Cyan, Orange). An optional **combat-only** mode hides the ring outside of combat and shows it automatically on combat entry. (configurable, disabled by default)

All features can be enabled/disabled in-game via **System Settings > Addons > DyBAddon** and apply changes immediately.

All user-facing text is **localized**: French (`frFR`) and English are supported. Any other game client language falls back to English automatically.

## Architecture

The addon is modularized across 13 Lua files for clean separation of concerns:

### **DyBCore.lua**
- Defines the `DyBAddon` namespace table
- Shared module for all features

### **DyBLocales.lua**
- Defines `DyBAddon.L`, a flat key→string table used by every other module
- English strings are the default; French (`frFR`) strings override them when `GetLocale() == "frFR"`
- All other locales fall back to English automatically
- Loaded immediately after `DyBCore.lua` so strings are available to every subsequent file

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
- Creates eleven checkbox options with tooltips across five subcategories
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
- Scans the group roster (`GetGroupMembers`) to determine which class buff providers are present and at what level; re-scans on `GROUP_ROSTER_UPDATE` while the popup is visible
- Renders a two-row `BackdropTemplate` popup centered horizontally with its top edge at 33% from the screen top:
  - Row 1 (consumables): Flask, Food, Weapon — always shown, horizontally centered
  - Row 2 (class buffs): one icon per relevant class in the group (Mage/Warrior/Evoker/Druid/Priest/Shaman), horizontally centered; row is hidden when no class buffs apply
- Each icon is shown with a green checkmark when active, or desaturated with a red cross when missing
- A **build name label** at the bottom of the popup displays the current specialization and active talent loadout in the format `Build : Spec / Loadout` (e.g. `Build : Fire / M+ Build`). If no named loadout is selected only the spec name is shown (`Build : Fire`). Uses `C_ClassTalents.GetLastSelectedSavedConfigID` + `C_Traits.GetConfigInfo` and updates live via `TRAIT_CONFIG_UPDATED` while the popup is open
- The popup resizes dynamically so both rows always fit and remain centered
- The popup is dismissible at any time via an X button in the top-left corner
- While visible, listens to `UNIT_AURA`, `PLAYER_EQUIPMENT_CHANGED`, `GROUP_ROSTER_UPDATE`, and `TRAIT_CONFIG_UPDATED`; all unregistered when the popup is hidden
- Provides a **minimap button** that rotates around the minimap edge (draggable, angle persisted in `DyBAddon_SavedVars.minimapAngle`); left-clicking opens the popup at any time
- Exposes `DyBAddon.OnReadyCheckConsumablesChanged()` (popup on ready check) and `DyBAddon.OnMinimapReadyCheckConsumablesChanged()` (minimap button visibility) callbacks

### **DyBCursorCircle.lua**
- Listens to `ADDON_LOADED` to initialize and apply the saved color and enabled state
- Listens to `PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED` to show/hide the ring automatically when the **combat-only** option is enabled
- Creates a tracking frame (`TOOLTIP` strata) positioned over the cursor every frame via `GetCursorPosition()` divided by `UIParent:GetEffectiveScale()`
- Renders a smooth ring using the `Interface\Minimap\MiniMap-TrackingBorder` built-in texture (a white circle outline with a transparent center) sized 64×64 on a `TOOLTIP`-strata frame
- Applies vertex color from eight presets (White, Red, Green, Blue, Yellow, Purple, Cyan, Orange) via `SetVertexColor`
- The frame is hidden by default; `OnUpdate` only executes while the frame is shown, adding no overhead when disabled
- Persists state in `DyBAddon_SavedVars.cursorCircle` (bool), `DyBAddon_SavedVars.cursorCircleColor` (string key), `DyBAddon_SavedVars.cursorCircleSize` (number), and `DyBAddon_SavedVars.cursorCircleOnlyCombat` (bool)
- Exposes `DyBAddon.OnCursorCircleChanged()`, `DyBAddon.OnCursorCircleColorChanged()`, `DyBAddon.OnCursorCircleSizeChanged()`, and `DyBAddon.OnCursorCircleOnlyCombatChanged()` callbacks for real-time options panel updates

### **DyBAddon.toc**
- Addon manifest with metadata
- Declares `DyBAddon_SavedVars` as saved variables
- Specifies load order: Core → Locales → Features → Options

## Load Sequence

1. **Addon Load**: All `.lua` files loaded in order (Core → Locales → Features → Options)
2. **ADDON_LOADED**: Saved variables initialized, settings panel registered
3. **PLAYER_LOGIN**: CVar-based features apply their settings
4. **GROUP_ROSTER_UPDATE**: Group inspector detects new members and queues inspections
5. **INSPECT_READY**: Inspect results are received and printed to chat
6. **READY_CHECK**: Consumable popup is shown when inside an instance
7. **UNIT_AURA / PLAYER_EQUIPMENT_CHANGED / GROUP_ROSTER_UPDATE / TRAIT_CONFIG_UPDATED**: Consumable and class buff icons, and the build name label, refresh live while the popup is visible
8. **PLAYER_REGEN_DISABLED / PLAYER_REGEN_ENABLED**: Combat timer starts/freezes on combat enter/exit
9. **Option Toggling**: Callbacks fire immediately when user changes settings in-game

## Compatibility

- Requires World of Warcraft 12.0.1 or later (Midnight+)
- Uses modern Settings API (Blizzard Menu implementation)

---

**Author**: Chef  
**Version**: 1.0
