local ImportMetaTable = {}

local function Require(initPath)
    local result = {
        __p = initPath or ""
    }
    setmetatable(result, ImportMetaTable)
    return result
end

function ImportMetaTable:__index(key)
    return Require(self.__p .. "/" .. string.lower(key))
end

function ImportMetaTable:__call()
    local s = string.sub(self.__p, 2)
    if string.find(s, '/') then
        return import(self.__p .. ".lua")
    end
    return import(s .. ".lua")
end

function ImportMetaTable:__newindex(key, value)
    error("attempt to set new index for an Import object")
end

_G.require = Require()
