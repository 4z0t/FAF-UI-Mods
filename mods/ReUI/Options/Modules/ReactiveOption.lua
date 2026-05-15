local LazyVar = import("/lua/lazyvar.lua").Create
local Prefs = import("/lua/user/prefs.lua")


local function FormatName(name)
    return (name:gsub("[^A-Za-z0-9]+", "_"))
end

---@class ReUI.Options.ReactiveOption
---@field _modName string
---@field _optionName string
---@field _var LazyVar
---@field _prev any
ReactiveOption = ReUI.Core.Class()
{
    ---@param self ReUI.Options.ReactiveOption
    ---@param modName string
    ---@param optionName string
    ---@param default any
    __init = function(self, modName, optionName, default)
        modName = FormatName(modName)
        optionName = FormatName(optionName)

        if default == nil then
            error(("Attempt to set option %s:%s to nil by default, dont do that!"):format(modName, optionName))
        end

        local modOptionsTable = Prefs.GetFromCurrentProfile(modName)
        local val = modOptionsTable and modOptionsTable[optionName]

        if val == nil then
            modOptionsTable = modOptionsTable or {}
            modOptionsTable[optionName] = default
            Prefs.SetToCurrentProfile(modName, modOptionsTable)
            val = default
        end

        self._modName = modName
        self._optionName = optionName
        self._var = LazyVar(val)
        self._prev = nil
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@return any
    __call = function(self)
        return self._var()
    end,

    OnChanged = ReUI.Core.Events.EventProperty(),

    OnSaved = ReUI.Core.Events.EventProperty(),

    ---@param self ReUI.Options.ReactiveOption
    ---@return LazyVar
    Raw = function(self)
        return self._var
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@param value any
    Set = function(self, value)
        if self._prev == nil then
            self._prev = self._var()
        end
        self._var:Set(value)
        self.OnChanged:Invoke(self, value)
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@return any
    Get = function(self)
        return self._var()
    end,

    ---@param self ReUI.Options.ReactiveOption
    Destroy = function(self)
        self._prev = nil
        self._var:Destroy()
        self._var = nil
        self._modName = nil
        self._optionName = nil
    end,
}
