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
    Prefs.SetToCurrentProfile(self._m, table.merged(Prefs.GetFromCurrentProfile(self._m), {
        [self._o] = self._lv()
    }))
    self._prev = nil
end

function Create(modOptionName, subOption, default)
    local modOptionsTable = Prefs.GetFromCurrentProfile(modOptionName)
    local val = modOptionsTable and modOptionsTable[subOption]
    if val == nil then
        Prefs.SetToCurrentProfile(modOptionName, table.merged(modOptionsTable, {
            [subOption] = default
        }))
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
