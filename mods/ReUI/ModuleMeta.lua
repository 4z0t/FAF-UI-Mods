---@declare-global
--- For mod to be loaded by ReUI loader specify
--- `ReUI = '<name>=<version>'` in mod_info.lua file.
---
--- Example:
---
--- `ReUI = 'ReUI.Core=1.0.0'`
---
--- `ReUI = 'MyModule=0.1.0'`
---
--- Other dependencies are specified with `ReUI.Require` function
---@see ReUI.Require
---@class ReUI
ReUI = {}

---@class DependencyInfo
---@field enabled boolean @Ensures that mod is enabled
---@field version number? @Required version of the game, checked as '>='.

--- Tells ReUI what modules to load and which versions are required
--- for this mod to function.
--- Example:
--- ```lua
--- ReUI.Require
--- {
---     "ReUI.Core >= 0.0.1",
---     "ReUI.Functional == 0.2.0",
--- }
--- ```
--- If versions for mod don't satisfy conditions, then error will interrupt this mod from loading.
---
---If mod tries to perform Require call outside of UI creation then it will fail.
---
--- Invalid string will also cause error.
---@param deps string[]|DependencyInfo
function ReUI.Require(deps)
end

---Returns module with given name if it satisfies version and is loaded.
---Otherwise returns nil.
---Example:
---```lua
---local module = ReUI.Exists "ReUI.LINQ >= 1.0.0"
---```
---Primarily used to check for optional modules.
--- @param tag string
--- @return ReUI.Module?
function ReUI.Exists(tag)
end

---Returns module with given name.
--- @param name string
--- @return ReUI.Module?
function ReUI.Get(name)
end

---@class LazyObj<T> : { Set: fun(self:LazyObj<T>, value: LazyOrValue<T>) }
---@alias LazyOrValue<T> Lazy<T>|LazyObj<T>
