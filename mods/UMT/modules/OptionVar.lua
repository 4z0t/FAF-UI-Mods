local LazyVar = import("/lua/lazyvar.lua").Create
local Prefs = import("/lua/user/prefs.lua")


---@class OptionVar
---@field _m string
---@field _o string
---@field _lv LazyVar
---@field _prev any
---@field OnChange fun(self : OptionVar)
---@field OnSave fun(self : OptionVar)
local OptionVarMetaTable = {}
OptionVarMetaTable.__index = OptionVarMetaTable

---returns stored value in optionvar
---@return any
function OptionVarMetaTable:__call()
    return self._lv()
end

---sets new value for optionvar
---@param value any
function OptionVarMetaTable:Set(value)
    if self._prev == nil then
        self._prev = self._lv()
    end
    self._lv:Set(value)
    self:OnChange()
end

---resets value to previous saved one
function OptionVarMetaTable:Reset()
    if self._prev ~= nil then
        self:Set(self._prev)
        self._prev = nil
    end
end

---saves value stored in optionvar
function OptionVarMetaTable:Save()
    local modOptionsTable = Prefs.GetFromCurrentProfile(self._m)
    modOptionsTable[self._o] = self._lv()
    Prefs.SetToCurrentProfile(self._m, modOptionsTable)
    self:OnSave()
    self._prev = nil
end

---returns option name of optionvar
---@return string
function OptionVarMetaTable:Option()
    return self._o
end

---returns lazyvar nested in optionvar
---@return LazyVar
function OptionVarMetaTable:Raw()
    return self._lv
end

---called when option data has been changed
---@return LazyVar
function OptionVarMetaTable:OnChange()
end

---called when option data has been saved
---@return LazyVar
function OptionVarMetaTable:OnSave()
end

---Sets OnChange function and calls it
---@param fn fun(opt: OptionVar)
function OptionVarMetaTable:Bind(fn)
    self.OnChange = fn
    self:OnChange()
end

---creates optionvar with default value if there is no saved one with given name
---@param modOptionName string
---@param subOption string
---@param default any
---@return OptionVar
function Create(modOptionName, subOption, default)

    if default == nil then
        error(("Attempt to set option %s:%s to nil by default, dont do that!"):format(modOptionName, subOption))
    end
    local modOptionsTable = Prefs.GetFromCurrentProfile(modOptionName)
    local val = modOptionsTable and modOptionsTable[subOption]

    if val == nil then
        modOptionsTable = modOptionsTable or {}
        modOptionsTable[subOption] = default
        Prefs.SetToCurrentProfile(modOptionName, modOptionsTable)
        val = default
    end

    return setmetatable({
        _m = modOptionName,
        _o = subOption,
        _lv = LazyVar(val),
        _prev = nil,
    }, OptionVarMetaTable)

end
