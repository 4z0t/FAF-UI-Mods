---Prevents updating of a given table
---@param t table
---@return table
---@nodiscard
function UpdateOf(t)
    return setmetatable({}, {
        __index = t,
        __newindex = function(_, key, value)
            error("Attempt to update table that doesnt allow this")
        end
    })
end

---Prevents deleting the existing fields of a given table
---@param t table
---@return table
---@nodiscard
function DeleteOf(t)
    return setmetatable({}, {
        __index = t,
        __newindex = function(_, key, value)
            if t[key] ~= nil and value == nil then
                error("Attempt to delete value in a table that doesnt allow this")
            end
            t[key] = value
        end
    })
end

---Prevents editing the existing fields of a given table
---@param t table
---@return table
---@nodiscard
function EditOf(t)
    return setmetatable({}, {
        __index = t,
        __newindex = function(_, key, value)
            if t[key] ~= nil then
                error("Attempt to edit value in a table that doesnt allow this")
            end
            t[key] = value
        end
    })
end
