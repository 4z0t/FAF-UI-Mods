local preventDelete = {
    __newindex = function(self, key, value)
        if rawget(self, key) ~= nil and value == nil then
            error("Attempt to delete value in a table that doesnt allow this")
        end
        rawset(self, key, value)
    end
}

local preventEdit = {
    __newindex = function(self, key, value)
        if rawget(self, key) ~= nil then
            error("Attempt to edit value in a table that doesnt allow this")
        end
        rawset(self, key, value)
    end
}

local preventUpdate = {
    __newindex = function(self, key, value)
        error("Attempt to update table that doesnt allow this")
    end
}

function UpdateOf(t)
    return setmetatable(t, preventUpdate)
end

function DeleteOf(t)
    return setmetatable(t, preventDelete)
end

function EditOf(t)
    return setmetatable(t, preventEdit)
end
