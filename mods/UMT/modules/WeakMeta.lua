local weakKey = { __mode = 'k' }
local weakValue = { __mode = 'v' }
local weakKeyValue = { __mode = 'kv' }



---Makes table weak by key
---@param t table
---@return table
Key = function(t)
    return setmetatable(t, weakKey)
end
---Makes table weak by value
---@param t table
---@return table
Value = function(t)
    return setmetatable(t, weakValue)
end
---Makes table weak by key and value
---@param t table
---@return table
KeyValue = function(t)
    return setmetatable(t, weakKeyValue)
end
