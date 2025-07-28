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
---@param deps string[]
function ReUI.Require(deps)
end

---@class LazyObj<T> : { Set: fun(self:LazyObj<T>, value: LazyOrValue<T>) }
---@alias LazyOrValue<T> Lazy<T>|LazyObj<T>
