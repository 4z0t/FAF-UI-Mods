--- Determines whether we have a simple class: one that has no base classes
local emptyMetaTable = getmetatable {}
local function IsSimpleClass(arg)
    return arg.n == 1 and getmetatable(arg[1]) == emptyMetaTable
end

---@class SetupPropertyTable
---@field  set fun(class:fa-class, value:any)
---@field  get fun(class:fa-class): any

---@class PropertyTable
---@field  set fun(class:fa-class, value:any)
---@field  get fun(class:fa-class): any
---@field __property true

---@param setup SetupPropertyTable
---@return PropertyTable
function Property(setup)
    local getFunc = setup.get
    local setFunc = setup.set
    return {
        __property = true,
        set = setFunc,
        get = getFunc
    }
end

local function MakeProperties(class)
    local setProperties = table.copy(class.__set) or {}
    local getProperties = table.copy(class.__get) or {}
    for k, v in class do
        if type(v) == "table" then
            if v.__property then
                if v.get then
                    getProperties[k] = v.get
                end
                if v.set then
                    setProperties[k] = v.set
                end
            end

        end
    end

    class.__set = setProperties
    class.__get = getProperties

    for k, _ in class.__set do
        class[k] = nil
    end

    for k, _ in class.__get do
        class[k] = nil
    end

    class.__index = function(self, key)
        if getProperties[key] then
            return getProperties[key](self)
        end
        return class[key]
    end

    class.__newindex = function(self, key, value)
        if setProperties[key] then
            return setProperties[key](self, value)
        end
        rawset(self, key, value)
    end


    return class
end

local function MakeUIClass(bases, spec)
    local class
    if spec then
        class = Class(unpack(bases))(spec)
    else
        class = ClassSimple(unpack(bases))
    end
    return MakeProperties(class)
end

function UIClass(...)
    if IsSimpleClass(arg) then
        return MakeUIClass(arg)
    end
    local bases = { unpack(arg) }
    return function(spec)
        return MakeUIClass(bases, spec)
    end
end

