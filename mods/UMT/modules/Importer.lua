local ImportMetaTable = {}

local function Require(initPath)
    local result = {
        __p = initPath or ""
    }
    setmetatable(result, ImportMetaTable)
    return result
end

function ImportMetaTable:__index(key)
    if key == "_" then
        return Require(self.__p .. "/..")
    end
    return Require(self.__p .. "/" .. string.lower(key))
end

function ImportMetaTable:__call()
    local s = string.sub(self.__p, 2)

    local okl, localImport = pcall(import, s .. ".lua")
    if okl then
        return localImport
    end
    local okg, globalImport = pcall(import, self.__p .. ".lua")
    if okg then
        return globalImport
    end
    error(string.format("Can't import file '%s'", s .. ".lua"))

end

function ImportMetaTable:__newindex(key, value)
    error("attempt to set new index for an Import object")
end

_G.require = Require()
