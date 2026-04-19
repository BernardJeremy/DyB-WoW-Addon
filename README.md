# DyBAddon

A lightweight World of Warcraft addon for DayBar that provides two customizable gameplay features.

## Features

- **Force 24-Hour Clock**: Automatically enables 24-hour military time format on login (configurable, enabled by default)
- **Hide NPC Chat Bubbles**: Toggle to hide all in-game chat bubbles above characters (configurable, disabled by default)

Both features can be enabled/disabled in-game via **System Settings > Addons > DyBAddon** and apply changes immediately.

## Architecture

The addon is modularized across 4 Lua files for clean separation of concerns:

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

### **DyBOptions.lua**
- Registers the settings category using the `Settings` API
- Creates two checkbox options with tooltips
- Initializes saved variables on `ADDON_LOADED`
- Manages setting callbacks for immediate UI updates

### **DyBAddon.toc**
- Addon manifest with metadata
- Declares `DyBAddon_SavedVars` as saved variables
- Specifies load order: Core → Features → Options

## Load Sequence

1. **Addon Load**: All `.lua` files loaded in order (Core → Features → Options)
2. **ADDON_LOADED**: Saved variables initialized, settings panel registered
3. **PLAYER_LOGIN**: Features apply their settings based on saved preferences
4. **Option Toggling**: Callbacks fire immediately when user changes settings in-game

## Compatibility

- Requires World of Warcraft 12.0.1 or later (Midnight+)
- Uses modern Settings API (Blizzard Menu implementation)

---

**Author**: Chef  
**Version**: 1.0
