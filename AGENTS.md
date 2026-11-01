# AGENTS.md — AI Agent Guidelines for FAF-UI-Mods & ReUI

Welcome to the **FAF-UI-Mods** repository. This document serves as the operational guide, codebase context, architecture reference, and rulebook for AI agents (and human contributors) modifying or adding code to this project.

---

## 1. Project & Repository Overview

- **Purpose:** A suite of modular user interface mods and the **ReUI** modernization framework for **Supreme Commander: Forged Alliance**, designed specifically for the **Forged Alliance Forever (FAF)** community.
- **Scope:** All mods in this repository are **client-side UI mods** (`ui_only = true`). They must **never** modify the simulation state, tamper with sim checksums, or cause simulation desyncs.
- **Repository Structure:**
  - `mods/ReUI/`: The core ReUI framework and shared libraries (`Core`, `UI`, `Options`, `LINQ`, `ECS`, `WorldView`, `Actions`, `Selection`, `Quick`, `QoL`).
  - `mods/ReUI.*/`: Official modular ReUI suite mods (`ReUI.Score`, `ReUI.Construction`, `ReUI.Economy`, `ReUI.Hotbuild`, `ReUI.Minimap`, `ReUI.Reclaim`, `ReUI.ActionsPanel`).
  - `mods/<ModName>/`: Standalone mods and extensions (`ACUEnhancements`, `AKA`, `AOE`, `ASE`, `Ctrl`, `EAS`, `InstantAssist`, `RFA`, `GS`, `STP`, etc.).
  - `Deprecated/`: Superseded legacy mods and historical code. **Do not modify files here.**
  - `Docs/`: Project documentation (`PLAYER_GUIDE.md`, `DEVELOPER_GUIDE.md`, `Overview/`).
  - `.vscode/`: Workspace configuration, launch tasks, and development code snippets.

---

## 2. Runtime Environment & Lua 5.0.1 Gotchas

The Forged Alliance engine executes an embedded **Lua 5.0.1** environment with custom engine C++ bindings. AI agents **must strictly adhere** to the following dialect rules:

### Syntax & Standard Library Constraints
- **NO `#` length operator:** `#table` does NOT exist in Lua 5.0. Always use `table.getn(t)`.
- **Dictionary size:** Use `table.getsize(dict)` or `table.empty(t)`.
- **Module imports:** Use `import('/lua/path/to/module.lua')` instead of `require()`.
- **Script execution:** Use `doscript(path, env)` to evaluate scripts in isolated environments.
- **Global logging:** Use `LOG(...)`, `WARN(...)`, or `SPEW(...)`. Never call standard `print()` in game code.
- **Formatting:** Use `string.format(...)` or string methods like `str:format(...)`.
- **String patterns:** Lua 5.0 uses `%1`, `%2` pattern capture replacements.
- **Bitwise operations:** No native bitwise operators (`&`, `|`, `~`). Use engine math or lookups.

### Maui C++ GUI Framework
- Native engine controls (`Control`, `Group`, `Bitmap`, `Text`, `Button`, `Edit`, `Checkbox`, `Frame`, `Dragger`) are backed by C++ userdata.
- **Memory Leak Warning:** Never hold hard references to Maui controls inside long-lived closures or global tables without weak tables (`ReUI.Core.Weak.Value {}`) or explicit cleanup in `OnDestroy`.
- **Control Coordinate System:** Dimensions and positions use reactive `LazyVar` objects. Always resolve coordinate math through `ReUI.UI.Layouter` or `ReUI.UI.LayoutFunctions`.

---

## 3. Core Architecture & Architectural Commandments

### Rule 1: NEVER Destructively Overwrite Global Functions
Never replace engine or game functions directly (`GameMain.CreateUI = myFunc` or `OldFunc = Func; Func = ...` is strictly forbidden).
- **Always use `ReUI.Core.Hook`:**
  ```lua
  ReUI.Core.Hook("/lua/ui/game/score.lua", "CreateScoreUI", function(originalFunc, module)
      return function(...)
          -- Custom pre-logic
          local result = originalFunc(...)
          -- Custom post-logic
          return result
      end
  end)
  ```
- Or scope to a module using `ReUI.Core.HookModule(modulePath)`.

### Rule 2: Proper Manifest & Loader Registration
Every ReUI module must declare its identity and dependencies:
1. In `mod_info.lua`:
   ```lua
   ReUI = 'MyMod=1.0.0'
   ui_only = true
   selectable = true
   ```
2. In `Main.lua`:
   ```lua
   Version = "1.0.0"

   ReUI.Require
   {
       "ReUI.Core >= 1.6.0",
       "ReUI.UI >= 1.5.0",
       "ReUI.Options >= 2.0.0",
       enabled = true,
   }

   function Main(isReplay)
       -- Return table to export public API under ReUI.<MyMod>
       return { ... }
   end
   ```

### Rule 3: Respect the 6-Stage Execution Lifecycle
- **Stage 1 (Preload):** Dependency graph and topological sort.
- **Stage 2 (Load):** `Main(isReplay)` is executed for each module in order.
- **Stage 3 (PreCreateUI):** Hooks run via `ReUI.Core.OnPreCreateUI(callback)`.
- **Stage 4 (Engine CreateUI):** Native base game HUD is constructed.
- **Stage 5 (PostCreateUI):** Custom UI elements attached via `ReUI.Core.OnPostCreateUI(callback)`.
- **Stage 6 (Dispose):** Loader state is sealed. Do not call `ReUI.Require` after this point.

### Rule 4: Fluent Layout & Resolution Independence
Never hardcode pixel math. Use `ReUI.UI.FloorLayoutFor` (prevents subpixel blurring) and `Layouter`:
```lua
local LayoutFor = ReUI.UI.FloorLayoutFor

LayoutFor(myControl)
    :AtLeftTopIn(parentControl, 10, 20)
    :Width(120)
    :Height(30)
    :Over(parentControl, 2)
```
Separate layout definition from control structure using the `ReUI.UI.Layoutable` pattern (`InitLayout(self, layouter)`).

### Rule 5: Reactive Options & Profile Persistence
Never invent custom ad-hoc configuration files. Always use `ReUI.Options`:
1. Define reactive schemas in `Options.lua`:
   ```lua
   local OptionValue = ReUI.Options.OptionValue
   ReUI.Options.Mods["MyMod"] = {
       myToggle = OptionValue(true),
       myThreshold = OptionValue(50),
   }
   ```
2. Build UI inside `Main()` using `ReUI.Options.Window`:
   ```lua
   function Main()
       ReUI.Options.Add("MyMod", function(frame)
           local options = ReUI.Options.Mods["MyMod"]
           return ReUI.Options.Window("My Mod", function(q)
               q:OptionCheckbox("Enable Feature", options.myToggle)
               q:OptionSlider("Threshold", 0, 100, 5, options.myThreshold)
           end)
       end)
   end
   ```
3. Subscribe reactively in code via `options.myToggle:Bind(function(var) ... end)`.

### Rule 6: Use `ReUI.LINQ` for Collection Operations
Avoid nested loops and mutable array allocations when filtering or transforming collections:
```lua
local Enumerate = ReUI.LINQ.Enumerate

local unitIds = Enumerate(units)
    :Where(function(u) return not u:IsDead() end)
    :OrderByDescending(function(u) return u:GetBlueprint().Economy.BuildCostMass end)
    :Select(function(u) return u:GetEntityId() end)
    :ToArray()
```

### Rule 7: Immediate-Style UI for Dialogs & Debug Tools
For floating windows, debug tools, or dialogs, use `ReUI.UI.Quick.Window`:
```lua
local QuickWindow = ReUI.UI.Quick.Window

QuickWindow("Diagnostic Panel", function(q)
    q:Title("Status", 16)
    q:Text("Monitoring active...")
    q:SameLine()
    q:Button("Refresh", function() q:Context():UpdateWindow() end)
end, "diagnostic_panel_id")
```

---

## 4. Coding Conventions & Quality Guidelines

- **Documentation & Types:** Annotate all classes, methods, and functions with EmmyLua / LuaLS doc comments (`---@class`, `---@param`, `---@return`, `---@field`).
- **Comments Integrity:** Preserve all existing comments, docstrings, and headers.
- **Naming Conventions:**
  - PascalCase for Class names, methods, and exported module tables (`MyClass`, `InitLayout`, `HandleEvent`).
  - camelCase for local variables and function arguments (`unitId`, `selection`, `isReplay`).
  - Prefix private or internal fields with an underscore (`self._cachedUnits`, `self._isDestroyed`).
- **Safe Events:** When defining event properties on classes, prefer `ReUI.Core.Events.SafeEvent` to ensure an error in one subscriber does not disrupt the caller.

---

## 5. Development Workflow & Verification

### Running FAF in Developer Mode
Use the predefined VS Code task **`FAF dev`** (`.vscode/tasks.json`):
```shell
ForgedAlliance.exe /init init-dev.lua /nobugreport /EnableDiskWatch /showlog
```
- `/EnableDiskWatch`: Dynamically monitors disk file changes.
- `/showlog`: Launches the game with the real-time engine console open.

### In-Game Hot Reloading
Modules can support live hot-reloading during development using `__moduleinfo`:
```lua
function __moduleinfo.OnDirty()
    if myControlInstance then
        myControlInstance:Destroy()
        myControlInstance = nil
    end
    ForkThread(function()
        WaitFrames(1)
        import(__moduleinfo.name).Run()
    end)
end
```

### Checking Logs
FA output logs are located at:
`C:\ProgramData\FAForever\bin\logs\game.log`
When verifying behavior or troubleshooting, filter the log for `ReUI:`, `ReUI.Core:`, and `WARNING:`.

---

## 6. Prohibited Actions for Agents
- ❌ **DO NOT** use Lua 5.1+ syntax (`#`, `goto`, `//`, etc.).
- ❌ **DO NOT** modify files in `Deprecated/`.
- ❌ **DO NOT** overwrite engine global variables or functions directly.
- ❌ **DO NOT** instantiate UI controls during `Load` / `Main()` stage (wait for `OnPostCreateUI`).
- ❌ **DO NOT** introduce simulation logic or state changes into these UI mods.
