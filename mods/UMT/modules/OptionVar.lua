local LazyVar = import("/lua/lazyvar.lua")
local Prefs = import("/lua/user/prefs.lua")

local OptionVarMetaTable = {}
OptionVarMetaTable.__index = OptionVarMetaTable

function OptionVarMetaTable:__call()
    return self._lv()
end

function OptionVarMetaTable:Set(value)
    if self._prev == nil then
        self._prev = self._lv()
    end
    self._lv:Set(value)
    self:OnChange()
end

function OptionVarMetaTable:Reset()
    if self._prev ~= nil then
        self:Set(self._prev)
        self._prev = nil
    end
end

function OptionVarMetaTable:Save()
    local modOptionsTable = Prefs.GetFromCurrentProfile(self._m)
    modOptionsTable[self._o] = self._lv()
    Prefs.SetToCurrentProfile(self._m, modOptionsTable)
    self._prev = nil
end

function OptionVarMetaTable:Option()
    return self._o
end

function OptionVarMetaTable:Raw()
    return self._lv
end


function Create(modOptionName, subOption, default)
    local modOptionsTable = Prefs.GetFromCurrentProfile(modOptionName)
    local val = modOptionsTable and modOptionsTable[subOption]
    if val == nil then
        modOptionsTable = modOptionsTable or {}
        modOptionsTable[subOption] = default
        Prefs.SetToCurrentProfile(modOptionName, modOptionsTable)
    end

    local result = {
        _m = modOptionName,
        _o = subOption,
        _lv = LazyVar.Create(val or default),
        _prev = nil,
        OnChange = function(self)
        end
    }
    setmetatable(result, OptionVarMetaTable)
    return result
end
