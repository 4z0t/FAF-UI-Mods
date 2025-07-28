---@meta ReUI.Core

---@declare-global
---@type table
__active_mods = {}


---Consists of basic hooking and UI loading callbacks, also provides functions to create classes and their properties.
---@class ReUI.Core : ReUI.Module
ReUI.Core = {}

---@alias HookCallback<T> fun(field: T, module:table):T
---@alias OnCreateUICallback fun(isReplay:boolean)

---Replaces given field in module with one returned by callback.
---
---Any error or conflict will fail hook therefore a warning and fail of others hooks of mod.
---
---```lua
---ReUI.Core.Hook("/lua/ui/game/gamemain.lua", "DeselectSelens", function(field, module)
---    return function(selection)
---        local isShift = IsKeyDown("shift")
---        local isAlt = IsKeyDown("menu")
---        if isAlt and isShift then
---            local newSelection = EntityCategoryFilterDown(categories.ENGINEER, selection)
---            if TableGetN(newSelection) == TableGetN(selection) then
---                return selection, false
---            end
---            return newSelection, true
---        end
---        return field(selection)
---    end
---end)
---```
---Example from Engineer Alt Selection mod.
---
---After UI is loaded it is forbidden to create new hooks.
---@generic T
---@param moduleName FileName
---@param fieldName string
---@param callback HookCallback<T>
function ReUI.Core.Hook(moduleName, fieldName, callback)
end

---Creates object that hooks module's fields according to given hooking function:
---```lua
---local EconomyHook = ReUI.Core.HookModule "/lua/ui/game/economy.lua"
---
---EconomyHook("CreateEconomyBar", function(field, module)
---    return function(parent)
---        ...
---        return ...
---    end
---end)
---```
---You can also do this way:
---
---```lua
---local EconomyHook = ReUI.Core.HookModule "/lua/ui/game/economy.lua"
---
---function EconomyHook.CreateEconomyBar(field, module)
---    return function(parent)
---        ...
---        return ...
---    end
---end
---```
---@generic T
---@param moduleName FileName
---@return table<string, HookCallback<T>> | (fun(fieldName:string, callback:HookCallback<T>):T)
function ReUI.Core.HookModule(moduleName)
end

---Performs callback when UI starts to create
---@param callback OnCreateUICallback
function ReUI.Core.OnPreCreateUI(callback)
end

---Performs callback when UI ends to create
---@param callback OnCreateUICallback
function ReUI.Core.OnPostCreateUI(callback)
end

ReUI.Core.Weak = {}

---Makes table weak by key
---@generic T : table
---@param t T
---@return T
function ReUI.Core.Weak.Key(t)
end

---Makes table weak by value
---@generic T : table
---@param t T
---@return T
function ReUI.Core.Weak.Value(t)
end

---Makes table weak by key and value
---@generic T : table
---@param t T
---@return T
function ReUI.Core.Weak.KeyValue(t)
end

---Creates class with `ReUI.Core.Property` support
---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function ReUI.Core.Class(...)
end

---Creates property for `ReUI.Core.Class`
---@generic T
---@generic C: fa-class
---@param setup SetupPropertyTable<C,T>
---@return PropertyTable<C,T>
function ReUI.Core.Property(setup)
end
