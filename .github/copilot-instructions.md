# WoW Addon Developer Instructions

**Defaults** (assume silently unless told otherwise):
- **Target**: Midnight retail (Interface 120001)
- **Libraries**: Standalone (no Ace/LibStub) unless complexity demands it
- **Inter-addon comms**: None
- **SavedVariables**: Basic account-wide table
- **UI**: Slash commands and options panel only when requested

---

## Project Structure

### Standard Addon Folder Layout
```
AddonName/
├── AddonName.toc          # Manifest file (required)
├── Core.lua               # Entry point / namespace definition
├── Features/              # Optional: submodules
│   ├── Feature1.lua
│   └── Feature2.lua
├── UI/                    # Optional: UI frames and panels
│   └── Options.lua
├── libs/                  # Optional: embedded libraries
│   ├── LibStub/
│   └── AceAddon-3.0/
└── README.md              # Documentation
```

### TOC File Format

The `.toc` file is a plaintext manifest that Blizzard's game client parses. Example:

```toc
## Interface: 120001
## Title: My Addon
## Notes: Brief description of what the addon does
## Version: 1.0
## Author: Your Name
## IconTexture: Interface\AddOns\MyAddon\icon.tif
## Dependencies: 
## OptionalDeps: LibStub, AceAddon-3.0
## SavedVariables: MyAddon_SavedVars
## SavedVariablesPerCharacter: MyAddon_CharVars

Core.lua
Features/Feature1.lua
Features/Feature2.lua
UI/Options.lua
```

**Key directives:**
- `## Interface`: Current retail patch interface version (find via `/run print(select(4, GetBuildInfo()))` in-game)
- `## Title`: Appears in addon list
- `## Version`: Semantic versioning recommended
- `## Dependencies`: Addons that MUST be loaded before this one; load will fail if missing
- `## OptionalDeps`: Libraries that enhance but aren't required (e.g., LibStub)
- `## SavedVariables`: Account-wide persistent data (format: `Var1, Var2, Var3`)
- `## SavedVariablesPerCharacter`: Per-character persistent data
- **Load order matters**: List files in dependency order. Libs first, then core, then features, then UI.

---

## Language & Runtime

### Lua Version
- WoW uses **Lua 5.1** (embedded in the client)
- **NOT available**: `io`, `os`, `coroutine.*`, `debug.*` libraries
- **Available**: `string`, `table`, `math`, `pairs`, `ipairs`, `type`, `select`, `unpack`, `setmetatable`, `getmetatable`

### Global vs Local Scoping

**Always prefer `local`:**
```lua
-- Good: prevents namespace pollution
local function MyFunction()
    local x = 10
    return x
end

-- Bad: global scope pollution
function GlobalFunction()
    y = 20  -- Creates global _G.y
    return y
end
```

**Why?** Globals are slower to access and can conflict with other addons. Use a namespace table for intentional globals:
```lua
MyAddon = MyAddon or {}
MyAddon.VERSION = "1.0"

local function InternalHelper()
    return MyAddon.VERSION
end
```

### WoW Globals (Always Available)

These are safe to call from any context:
- `print(msg)` — prints to DEFAULT_CHAT_FRAME
- `string.format()`, `string.sub()`, `string.gsub()`, etc.
- `table.insert()`, `table.remove()`, `table.wipe()`, `tinsert()`, `tremove()`, `wipe()`
- `math.floor()`, `math.ceil()`, `math.max()`, `math.min()`
- `strsplit(delim, str)` — WoW custom, very useful
- `Ambiguate(name, type)` — standardizes character names across realms
- `time()`, `date()` — standard Lua time functions
- `GetTime()` — float seconds since addon load
- `CreateFrame(type, name, parent, template)` — frame factory
- `SetCVar(name, value)` / `GetCVar(name)` / `GetCVarBool(name)` — console variables
- `hooksecurefunc(table, name, hook)` — safe post-hook on any function

### Chat Color Codes

WoW uses inline escape sequences for colored text:
```lua
-- Format: |cAARRGGBBtext|r  (AA = alpha, usually FF)
print("|cFFFF0000Red error text|r normal text")
print("|cFF00FF00Green success|r")
print("|cFFFFD100Gold/yellow (Blizzard standard)|r")
print("|cFF888888Gray (muted/disabled)|r")

-- Class colors (common):
-- Warrior: |cFFC79C6E   Paladin: |cFFF58CBA   Hunter: |cFFABD473
-- Rogue: |cFFFFF569    Priest: |cFFFFFFFF    Death Knight: |cFFC41F3B
-- Shaman: |cFF0070DE   Mage: |cFF40C7EB     Warlock: |cFF8787ED
-- Monk: |cFF00FF96     Druid: |cFFFF7D0A    Demon Hunter: |cFFA330C9
-- Evoker: |cFF33937F

-- Item links use |H...|h[Name]|h — do NOT fabricate these; use GetItemLink()
```

---

## Addon Lifecycle & Events

### Frame Creation & Event Registration

```lua
local frame = CreateFrame("Frame")

-- Reason: Initialize saved variables and options after addon files load
frame:RegisterEvent("ADDON_LOADED")
-- Reason: Apply player-specific logic once world is ready
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= "MyAddon" then return end
        -- Unregister immediately; this event fires for EVERY addon
        self:UnregisterEvent("ADDON_LOADED")
        -- Initialize here...
    elseif event == "PLAYER_LOGIN" then
        -- Player is in the world; safe to query UnitX(), GetX() APIs
    end
end)
```

### Key Events

| Event | When it fires | Use case |
|-------|---------------|----------|
| `ADDON_LOADED` | After each addon's `.lua` files load (fires once per addon) | Initialize saved variables, register slash commands, set up options panel. **Always unregister after handling your own addon.** |
| `PLAYER_LOGIN` | Once per session, after player has fully entered the world | Apply CVars, player-specific logic, initialize UI that needs player data |
| `PLAYER_ENTERING_WORLD` | Fires multiple times (login, zone change, instance entry, /reload) | Detect zone/instance changes; avoid for one-time init |
| `PLAYER_LOGOUT` | Player is logging out; fires before SavedVariables are saved to disk | Clean up, restore modified CVars to previous state |
| `GROUP_ROSTER_UPDATE` | Party/raid composition changes | Update raid frames, sync state across party |
| `CHAT_MSG_ADDON` | Addon communication message received | Inter-addon sync |

**ADDON_LOADED vs PLAYER_LOGIN:**
- **Use ADDON_LOADED** for initialization: saved variables, options, slash commands
- **Use PLAYER_LOGIN** for runtime logic that needs the player in-world (applying CVars, querying unit data)
- **Use PLAYER_ENTERING_WORLD** for per-zone logic (can fire multiple times)

---

## CVars (Console Variables)

CVars control game settings (graphics, UI behavior, chat, etc.). Addons commonly read/write them.

### API

```lua
-- Reference: https://warcraft.wiki.gg/wiki/API_SetCVar
SetCVar("nameCVar", value)          -- Set a CVar (string or number value)
local val = GetCVar("nameCVar")     -- Returns string
local bool = GetCVarBool("nameCVar") -- Returns boolean

-- Example: Force 24-hour clock
SetCVar("timeMgrUseMilitaryTime", 1)

-- Example: Toggle chat bubbles
SetCVar("chatBubbles", 0)  -- 0 = hidden, 1 = shown
```

### Common CVars

| CVar | Values | Description |
|------|--------|-------------|
| `timeMgrUseMilitaryTime` | 0/1 | 12h vs 24h clock |
| `chatBubbles` | 0/1 | NPC/player chat bubbles above heads |
| `chatBubblesParty` | 0/1 | Party member chat bubbles |
| `nameplateShowEnemies` | 0/1 | Enemy nameplates |
| `nameplateShowFriends` | 0/1 | Friendly nameplates |
| `Sound_EnableSFX` | 0/1 | Sound effects |
| `UnitNameOwn` | 0/1 | Show own name |
| `screenshotQuality` | 1-10 | Screenshot JPEG quality |

### CVar Best Practices

1. **Apply CVars on `PLAYER_LOGIN`**, not `ADDON_LOADED` (some CVars need the player in-world)
2. **Restore CVars on `PLAYER_LOGOUT`** if the user disables the feature, or store original values:
```lua
-- Save original value before overriding
local originalValue = GetCVar("chatBubbles")

-- Restore on logout or when feature is toggled off
local function RestoreCVar()
    if originalValue then
        SetCVar("chatBubbles", originalValue)
    end
end
```
3. **Some CVars are protected** and cannot be changed during combat (the call silently fails). Check the wiki for restrictions.
4. **CVars persist across sessions** in the WoW config — if your addon sets a CVar, it stays set even if the addon is removed. Consider restoring on feature disable.

---

## Settings API (Modern Options Panel)

The modern `Settings` API (added in Dragonflight 10.0+) replaces the deprecated `InterfaceOptions_AddCategory`. **Always use the Settings API for options panels. Never use the deprecated InterfaceOptions system.**

### Basic Options Panel

```lua
-- Reference: https://warcraft.wiki.gg/wiki/Settings_API

local frame = CreateFrame("Frame")
-- Reason: Register options panel once SavedVariables are available
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "MyAddon" then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- Initialize SavedVariables
    if not MyAddon_Config then
        MyAddon_Config = {}
    end

    -- Create a vertical layout category (appears in Interface > AddOns)
    local category = Settings.RegisterVerticalLayoutCategory("MyAddon")

    -- Checkbox setting
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "MyAddon_EnableFeature",   -- Unique setting ID (global)
            "enableFeature",           -- Key in SavedVariables table
            MyAddon_Config,            -- SavedVariables table reference
            type(true),                -- Value type: "boolean", "number", "string"
            "Enable Cool Feature",     -- Display label
            true)                      -- Default value

        -- Optional: react immediately when user toggles
        setting:SetValueChangedCallback(function(_, value)
            print("Feature is now:", value and "ON" or "OFF")
        end)

        Settings.CreateCheckbox(category, setting,
            "When enabled, this addon does something cool.")
    end

    -- Slider setting (numeric)
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "MyAddon_Opacity",
            "opacity",
            MyAddon_Config,
            type(1),
            "UI Opacity",
            100)

        local options = Settings.CreateSliderOptions(0, 100, 5) -- min, max, step
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
            function(value) return value .. "%" end)

        Settings.CreateSlider(category, setting, options,
            "Adjust the opacity of the addon's UI elements.")
    end

    -- Dropdown setting
    do
        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add("small", "Small")
            container:Add("medium", "Medium")
            container:Add("large", "Large")
            return container:GetData()
        end

        local setting = Settings.RegisterAddOnSetting(category,
            "MyAddon_Size",
            "size",
            MyAddon_Config,
            type(""),
            "UI Size",
            "medium")

        Settings.CreateDropdown(category, setting, GetOptions,
            "Choose the size of the UI elements.")
    end

    -- Register the category to make it appear in Interface options
    Settings.RegisterAddOnCategory(category)
end)
```

### Settings API Key Points

- `Settings.RegisterVerticalLayoutCategory(name)` — creates a top-level category in Interface > AddOns
- `Settings.RegisterAddOnSetting(category, uniqueID, varKey, savedVarsTable, valueType, label, default)` — binds a setting to your SavedVariables table
- The `valueType` parameter uses Lua's `type()` result: pass `type(true)` for boolean, `type(1)` for number, `type("")` for string
- `setting:SetValueChangedCallback(fn)` — fires when the user changes the value in the panel OR via code
- Control types: `Settings.CreateCheckbox()`, `Settings.CreateSlider()`, `Settings.CreateDropdown()`
- **Never use**: `InterfaceOptions_AddCategory`, `InterfaceOptionsFrame_OpenToCategory` (removed/deprecated)

---

## API Conventions

### Namespaced vs Non-Namespaced APIs

Many modern WoW APIs use `C_` namespaces. Use them when they exist:
```lua
-- Namespaced (use these when available):
C_Timer.After(5, function() print("5 seconds later") end)
C_ChatInfo.RegisterAddonMessagePrefix("MYADDON")
C_ChatInfo.SendAddonMessage("MYADDON", "hello", "PARTY")
C_Map.GetBestMapForUnit("player")
```

**However**, many core APIs are intentionally non-namespaced and correct to use as-is:
```lua
-- Non-namespaced (these are correct and current):
CreateFrame("Frame")
SetCVar("chatBubbles", 0)
GetCVar("chatBubbles")
UnitHealth("player")
UnitName("target")
GetTime()
hooksecurefunc(obj, "Method", hookFn)
print("message")
```

**Rule**: If a `C_` namespace version exists for a function, use it. If not, use the non-namespaced version. Check https://warcraft.wiki.gg when unsure.

**Common namespaces:**
- `C_Timer` — delayed actions, repeated callbacks
- `C_ChatInfo` — addon messaging
- `C_Map` — map data and quests
- `C_Spell` — spell queries
- `C_ChallengeMode` / `C_MythicPlus` — mythic+ info
- `C_PartyInfo` — party/raid data

### Finding API Documentation

1. **In-game**: Type `/api` or `/fstack` in chat (if enabled)
2. **Web**: https://warcraft.wiki.gg — search API function name
3. **Return values**: Always check the wiki; many functions return multiple values:
   ```lua
   local health, maxHealth = UnitHealth("target"), UnitHealthMax("target")
   if not health then return end  -- Nil-check first!
   ```

### Secure vs Insecure Functions & Taint

**Secure functions** can be called from protected contexts (combat):
- Spell-cast APIs, some UI APIs

**Insecure functions** trigger taint if called during protected events:
- Frame positioning, reparenting in combat
- Never call insecure code from combat event handlers

**Protected frames** (nameplates, raid frames, quest tracker) cannot be directly modified by addons. Create overlay frames or separate UI elements instead.

**If a request touches protected frames or combat-sensitive code**: proceed with the safe approach (overlay frames, out-of-combat hooks) and explain the limitation in a code comment. Do not block on asking the user.

---

## Inter-Addon Communication

Use `C_ChatInfo` for addon-to-addon messaging. Key constraints:
- Register prefix in `ADDON_LOADED`: `C_ChatInfo.RegisterAddonMessagePrefix("PREFIX")` (max 8 chars)
- Send: `C_ChatInfo.SendAddonMessage("PREFIX", msg, "PARTY"|"RAID"|"GUILD"|"WHISPER")`
- Receive: listen for `CHAT_MSG_ADDON` event; signature: `(prefix, message, channel, sender)`
- Max 255 chars per message; ~500 msgs/sec rate limit across all addons
- For complex data, serialize tables with a simple key=value or CSV format

Full reference: https://warcraft.wiki.gg/wiki/API_C_ChatInfo.SendAddonMessage

---

## SavedVariables

### Declaration

In your `.toc` file:
```toc
## SavedVariables: MyAddon_Config, MyAddon_Profiles
## SavedVariablesPerCharacter: MyAddon_CharData
```

At addon load, Blizzard automatically creates these global tables from disk (or as empty tables if first load).

### Initialization Pattern

```lua
local frame = CreateFrame("Frame")
-- Reason: SavedVariables become available when ADDON_LOADED fires for our addon
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "MyAddon" then return end
    self:UnregisterEvent("ADDON_LOADED")
    
    -- SafeInit: Check if vars exist, create defaults if not
    if not MyAddon_Config then
        MyAddon_Config = {}
    end
    
    -- Merge defaults with saved data
    local defaults = {
        version = 1,
        theme = "dark",
        enabled = true,
    }
    
    for key, defaultValue in pairs(defaults) do
        if MyAddon_Config[key] == nil then
            MyAddon_Config[key] = defaultValue
        end
    end
end)
```

**Why on ADDON_LOADED?** SavedVariables are not yet loaded during file execution. Always unregister the event after handling it.

### Persisting Changes

Blizzard automatically serializes the global table to disk on `/reload` or logout. No explicit "save" call is needed — just modify the table:
```lua
MyAddon_Config.lastZone = GetRealZoneText()
```

---

## Slash Commands

```lua
SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"  -- Alias

SlashCmdList["MYADDON"] = function(msg)
    local cmd, args = strsplit(" ", msg, 2)
    cmd = (cmd or ""):lower()
    
    if cmd == "reset" then
        MyAddon_Config = nil
        print("Config reset. Please /reload")
    elseif cmd == "config" then
        -- Open the modern Settings panel to our category
        Settings.OpenToCategory("MyAddon")
    else
        print("Usage: /myaddon [reset|config]")
    end
end
```

---

## Libraries (Optional)

For standalone addons (under ~500 lines), no libraries are needed. For complex addons:
- **LibStub + AceAddon-3.0** — module system and lifecycle management
- **AceComm-3.0** — serialized inter-addon communication
- **AceDB-3.0** — profile-based SavedVariables with schema migration

Embed in a `libs/` folder and list them before Core.lua in the `.toc`. Reference: https://www.wowace.com/addons

---

## Debugging Tips

```lua
/reload                    -- Reload all addons and UI
/console scriptErrors 1    -- Show Lua errors on screen
/fstack                    -- Toggle frame stack inspector (hover to see frame names)

-- Quick in-game tests:
/run print("Zone:", GetRealZoneText())
/run for k, v in pairs(MyAddon_Config) do print(k, "=", v) end
```

```lua
-- Colored chat output
DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Error:|r Something broke")

-- Table dump utility
local function DumpTable(tbl, indent)
    indent = indent or 0
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(string.rep("  ", indent) .. k .. " = {")
            DumpTable(v, indent + 1)
            print(string.rep("  ", indent) .. "}")
        else
            print(string.rep("  ", indent) .. k .. " = " .. tostring(v))
        end
    end
end
```

---

## Code Style Rules (Agent Must Follow)

### Scoping
✅ **Always use `local`** for variables and functions unless intentionally global (namespace table):
```lua
local function Helper() local value = 10; return value end  -- Good
function Helper() value = 10; return value end               -- Bad: pollutes _G
```

### Nil Checks
✅ **Always nil-check API return values before use:**
```lua
local health = UnitHealth("player")
if health and health > 0 then
    print("Player has health")
end
```

### Event Hygiene
✅ **Add a `-- Reason:` comment above every `RegisterEvent()` call.**
✅ **Unregister one-shot events** (like `ADDON_LOADED`) after handling them:
```lua
-- Reason: Initialize saved variables after addon files load
frame:RegisterEvent("ADDON_LOADED")

-- Inside handler:
self:UnregisterEvent("ADDON_LOADED")
```

### Delayed Logic
✅ **Prefer `C_Timer.After()` over `OnUpdate`** for timed one-shots:
```lua
C_Timer.After(5, function() print("5 seconds later") end)
```

### API Names
✅ **Use `C_` namespaced APIs when they exist.** Non-namespaced core APIs (`CreateFrame`, `SetCVar`, `UnitHealth`, etc.) are correct when no `C_` alternative exists.

### API References
✅ **Include a wiki link** when first using a non-obvious API:
```lua
-- Reference: https://warcraft.wiki.gg/wiki/API_C_Timer.After
C_Timer.After(delay, function() ... end)
```

---

## Agent Workflow Rules

### Modifying an Existing Addon
1. **Read all existing `.lua` and `.toc` files first** to understand the namespace pattern, event structure, and SavedVariables layout.
2. **Follow the established conventions** of the existing codebase (naming, file organization, comment style).
3. **Add new features in separate files** when they represent distinct functionality; update the `.toc` file list accordingly.
4. **Preserve existing functionality** — do not refactor or restructure code that isn't related to the requested change.

### Scaffolding a New Addon
When asked to create a new addon, produce:
1. Complete `.toc` file with Interface 120001 and correct file order
2. `Core.lua` with namespace table (`AddonName = {}`)
3. Feature files with inline comments explaining WoW API usage
4. Options file using the modern Settings API (if settings are needed)

### Handling Risky Patterns
When a request involves protected frames, combat taint, or CVar side effects:
- **Proceed with the safe approach** (overlay frames, out-of-combat hooks, CVar restoration)
- **Explain the constraint in a brief code comment**, not a long pre-implementation discussion
- Only ask for clarification if there are genuinely multiple valid approaches with different tradeoffs

---

**Last Updated**: April 2026
**WoW Version**: Midnight (12.0.1, Interface 120001)
**Agent Version**: 2.0
