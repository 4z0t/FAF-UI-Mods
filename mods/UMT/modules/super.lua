local SuperMetaTable = {}

function SuperMetaTable:__index(key)

end

function SuperMetaTable:__newindex(key, value)

end

function super(obj, class)
    local result = {
        __obj = obj or false,
        __class = class or false
    }

    setmetatable(result, SuperMetaTable)
    return result
end

_G.super = super
