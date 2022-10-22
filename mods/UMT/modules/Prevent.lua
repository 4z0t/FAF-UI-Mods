function UpdateOf(t)
    return setmetatable({}, {
        __index = t,
        __newindex = function(_, key, value)
            error("Attempt to update table that doesnt allow this")
        end
    })
end

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
