local GetPreference = GetPreference
local SetPreference = SetPreference


---@param levels string?
---@return boolean
local function IsValidLevels(levels)
    if type(levels) ~= "string" then
        return false
    end


    local pattern = "^[a-zA-Z_][a-zA-Z0-9_]*(%.[a-zA-Z_][a-zA-Z0-9_]*)*$"
    return levels:find(pattern) ~= nil
end

---@class ReUI.Options.OptionRef
---@field _levels string
OptionRef = ReUI.Core.Class()
{
    ---@param self ReUI.Options.OptionRef
    ---@param levels string[]
    __init = function(self, levels)
        local lvls = table.concat(levels, ".")
        -- if not IsValidLevels(lvls) then
        --     error("ReUI.Options.OptionRef: invalid option ref " .. tostring(lvls))
        -- end

        self._levels = lvls
    end,

    ---@param self ReUI.Options.OptionRef
    ---@return string
    GetPath = function(self)
        return self._levels
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
