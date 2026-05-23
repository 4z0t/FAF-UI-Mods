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
    OnChanged = ReUI.Core.Events.EventProperty(),

    OnSaved = ReUI.Core.Events.EventProperty(),

    Value = ReUI.Core.Property
    {
        ---@param self ReUI.Options.ReactiveOption
        get = function(self)
            return self:Get()
        end,

        ---@param self ReUI.Options.ReactiveOption
        set = function(self, value)
            self:Set(value)
        end
    } --[[@as any]] ,

    ---@param self ReUI.Options.ReactiveOption
    ---@param modName string
    ---@param optionName string
    ---@param default any
    __init = function(self, modName, optionName, default)
        modName = FormatName(modName)
        optionName = FormatName(optionName)

        if default == nil then
            error(("Attempt to set option %s:%s to nil by default, don't do that!"):format(modName, optionName))
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
        return self:Get()
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@return LazyVar
    Raw = function(self)
        return self._var
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@return any
    Get = function(self)
        return self._var()
    end,

    ---@param self ReUI.Options.ReactiveOption
    Prev = function(self)
        return self._prev
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@param value any
    Set = function(self, value)
        if self._prev == nil then
            self._prev = self:Get()
        end

        self._var:Set(value)
        self.OnChanged:Invoke(self, value)
    end,

    ---@param self ReUI.Options.ReactiveOption
    Restore = function(self)
        if self._prev ~= nil then
            self:Set(self._prev)
            self._prev = nil
        end
    end,

    ---@param self ReUI.Options.ReactiveOption
    Save = function(self)
        local value = self:Get()

        local modOptionsTable = Prefs.GetFromCurrentProfile(self._modName)
        modOptionsTable[self._optionName] = value
        Prefs.SetToCurrentProfile(self._modName, modOptionsTable)

        self.OnSaved:Invoke(self, value)
        self._prev = nil
    end,

    ---@deprecated use OnChanged event to observe when the value of the option changes and get current value with `Get`
    ---@param self ReUI.Options.ReactiveOption
    ---@param f fun(opt: ReUI.Options.ReactiveOption)
    Bind = function(self, f)
        self.OnChanged:Add(f)
        f(self)
    end,

    ---@param self ReUI.Options.ReactiveOption
    Destroy = function(self)
        self.OnChanged = nil
        self.OnSaved = nil
        self._prev = nil
        self._var:Destroy()
        self._var = nil
        self._modName = nil
        self._optionName = nil
    end,
}
