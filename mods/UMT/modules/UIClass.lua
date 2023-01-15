--- Determines whether we have a simple class: one that has no base classes
local emptyMetaTable = getmetatable {}
local function IsSimpleClass(arg)
    return arg.n == 1 and getmetatable(arg[1]) == emptyMetaTable
end

---@generic T
---@generic C: fa-class
---@class SetupPropertyTable<C,T> : { set : fun(self: C, value: T), get : fun(self: C): T }

---@generic T
---@generic C: fa-class
---@class PropertyTable<C,T> : { set : fun(self: C, value: T), get : fun(self: C): T }
---@field __property true

---@generic T
---@generic C: fa-class
---@param setup SetupPropertyTable<C,T>
---@return PropertyTable<C,T>
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
    local setProperties = {}
    local getProperties = {}
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
    if not table.empty(getProperties) then
        class.__index = function(self, key)
            local get = getProperties[key]
            if get then
                return get(self)
            end
            return class[key]
        end
    end
    if table.empty(setProperties) then
        class.__newindex = nil
    else
        class.__newindex = function(self, key, value)
            local set = setProperties[key]
            if set then
                return set(self, value)
            end
            rawset(self, key, value)
        end
    end

    return class
end

local function CacheClassFields(classes, fields)
    local cache = {}
    for _, field in fields do
        cache[field] = {}
        for i, class in ipairs(classes) do
            if class[field] then
                cache[field][i] = class[field]
                class[field] = false
            end
        end
    end
    return cache
end

local function RestoreClassFields(classes, cache)
    for field, data in cache do
        for i, class in ipairs(classes) do
            if data[i] then
                class[field] = data[i]
            end
        end
    end
end

local function MakeUIClass(bases, spec)
    local cache = CacheClassFields(bases, { "__newindex" })

    -- make those fields true, so older versions wont complain about class editting
    if spec then
        spec.__newindex = true
    else
        bases[1].__newindex = true
    end

    local class = Class(unpack(bases))
    if spec then
        class = class(spec)
    end
    RestoreClassFields(bases, cache)
    return MakeProperties(class)
end

---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function UIClass(...)
    if IsSimpleClass(arg) then
        return MakeUIClass(arg)
    end
    local bases = { unpack(arg) }
    return function(spec)
        return MakeUIClass(bases, spec)
    end
end
