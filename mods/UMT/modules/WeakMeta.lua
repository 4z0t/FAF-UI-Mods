local setmetatable = setmetatable

local weakKey = { __mode = 'k' }
local weakValue = { __mode = 'v' }
local weakKeyValue = { __mode = 'kv' }


---Makes table weak by key
---@generic T : table
---@param t T
---@return T
Key = function(t)
    return setmetatable(t, weakKey)
end
---Makes table weak by value
---@generic T : table
---@param t T
---@return T
Value = function(t)
    return setmetatable(t, weakValue)
end
---Makes table weak by key and value
---@generic T : table
---@param t T
---@return T
KeyValue = function(t)
    return setmetatable(t, weakKeyValue)
end
