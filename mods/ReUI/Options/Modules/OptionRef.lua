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

---@param s string
---@param n number
---@return string
---@return string
local function SplitAt(s, n)
    if n <= 0 then
        return "", s
    end

    local initial = 1
    local len = s:len()
    local splitAt = len
    for i = 1, n do
        local start_, end_ = s:find(".", initial, true)
        initial = (end_ or len) + 1
        splitAt = start_
        if splitAt == nil then
            splitAt = len + 1
            break
        end
    end
    return s:sub(1, splitAt - 1), s:sub(splitAt + 1)
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
    ---@param start? number
    ---@return string
    GetPath = function(self, start)
        if start then
            local l, r = SplitAt(self._levels, start - 1)
            return r
        end
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
