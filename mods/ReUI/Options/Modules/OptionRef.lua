local Prefs = import("/lua/user/prefs.lua")

local GetPreference = GetPreference
local SetPreference = SetPreference

---@class ReUI.Options.OptionRef
---@field _levels string
OptionRef = ReUI.Core.Class()
{
    ---@param self ReUI.Options.OptionRef
    ---@param levels string[]
    __init = function(self, levels)
        self._levels = table.concat(levels, ".")
    end,

    ---@param self ReUI.Options.OptionRef
    ---@param default? any
    ---@return any
    Get = function(self, default)
        return GetPreference(self._levels, default)
    end,

    ---@param self ReUI.Options.OptionRef
    ---@param value any
    Set = function(self, value)
        SetPreference(self._levels, value)
    end
}
