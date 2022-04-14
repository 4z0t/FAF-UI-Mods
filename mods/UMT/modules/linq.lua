local LinqFromMetaTable = {}
LinqFromMetaTable.__index = LinqFromMetaTable

local passthroughCondition = function(k, v)
    return true
end
local passthroughSelector = function(k, v)
    return v
end

function LinqFromMetaTable:Select(p)
    local result = {}
    local value
    for k, v in self.t do
        value = p(k, v)
        if value then
            result[k] = value
        end
    end
    return from(result)
end

function LinqFromMetaTable:Where(p)
    local result = from()
    for k, v in self.t do
        if p(k, v) then
            result:AddValue(v)
        end
    end
    return result
end

function LinqFromMetaTable:Distinct()
    local result = from()
    for k, v in self.t do
        if not result:Contains(v) then
            result:AddValue(v)
        end
    end
    return result
end

function LinqFromMetaTable:All(p)
    for k, v in self.t do
        if not p(k, v) then
            return false
        end
    end
    return true
end

function LinqFromMetaTable:Values()
    local result = {}
    for k, v in self.t do
        table.insert(result, v)
    end
    return from(result)
end

function LinqFromMetaTable:Keys()
    local result = {}
    for k, v in self.t do
        table.insert(result, k)
    end
    return from(result)
end

function LinqFromMetaTable:First(condition)
    for k, v in self.t do
        if not condition or condition(k, v) then
            return v
        end
    end
    return nil
end

function LinqFromMetaTable:Last(condition)
    local l = nil
    for k, v in self.t do
        if not condition or condition(k, v) then
            l = v
        end
    end
    return l
end

function LinqFromMetaTable:Contains(value)
    for k, v in self.t do
        if v == value then
            return true
        end
    end
    return false
end

function LinqFromMetaTable:Max(selector)
    local best = nil
    for k, v in self.t do
        if selector then
            v = selector(k, v)
        end
        if v > best then
            best = v
        end
    end
    return best
end

function LinqFromMetaTable:Any(condition)
    for k, v in self.t do
        if not condition or condition(k, v) then
            return true
        end
    end
    return false
end

function LinqFromMetaTable:Count(condition)
    if condition then
        return table.getn(self:Where(condition):ToArray())
    end
    return table.getsize(self.t)
end

function LinqFromMetaTable:Foreach(action)
    for k, v in self.t do
        action(k, v)
    end
    return self -- ?
end

function LinqFromMetaTable:Dump(fmtStr)
    LOG("-----")
    fmtStr = fmtStr or '%s:\t%s'
    for k, v in self.t do
        LOG(string.format(fmtStr, tostring(k), tostring(v)))
    end
    LOG("-----")
    return self -- ?
end

function LinqFromMetaTable:Sum(selector)
    local query = self
    if selector then
        query = query:Select(selector)
    end
    local result = 0
    query:Foreach(function(k, v)
        result = result + v
    end)
    return result
end

function LinqFromMetaTable:Avg(selector)
    local query = self
    if selector then
        query = query:Select(selector)
    end
    local result = 0
    query:Foreach(function(k, v)
        result = result + v
    end)
    return result / query:Count()
end

function LinqFromMetaTable:Copy()
    local result = {}
    self:Foreach(function(k, v)
        result[k] = v
    end)
    return from(result)
end

function LinqFromMetaTable:Get(k)
    return self.t[k]
end

function LinqFromMetaTable:Concat(t2)
    local result = self:Copy()
    t2:Foreach(function(tk, tv)
        result:AddValue(tv)
    end)
    return result
end

function LinqFromMetaTable:ToArray()
    local result = {}
    for k, v in self.t do
        table.insert(result, v)
    end
    return result
end

function LinqFromMetaTable:AddValue(v)
    table.insert(self.t, v)
end

function LinqFromMetaTable:AddKeyValue(k, v)
    self.t[k] = v
end

function LinqFromMetaTable:RemoveKey(k)
    self.t[k] = nil
end

function LinqFromMetaTable:RemoveByKey(k)
    table.remove(self.t, k)
    return self
end

function LinqFromMetaTable:RemoveByValue(vToRemove)
    for k, v in ipairs(self.t) do
        if v == vToRemove then
            table.remove(self.t, k)
            return self
        end
    end
    LOG("value not found " .. tostring(vToRemove))
    return self
end

function LinqFromMetaTable:ToDictionary()
    return self.t
end

function LinqFromMetaTable:__newindex(key,value)
    error('attempt to set new index for a Linq object')
end

-- local WrapperLinqFromMetaTable = table.deepcopy(LinqFromMetaTable)

-- function WrapperLinqFromMetaTable:__index(key)
--     if key == 't' then
--         return rawget(self, key)
--     end
--     return function(...)
--         local t = self.t
--         return rawget(t.__index, key)(t, unpack(arg))
--     end
-- end

-- function WrapperLinqFromMetaTable:__newindex(key, value)
--     error('attemt to set value for linq table')
-- end

function from(t)
    local result = {}
    result.t = t or {}
    setmetatable(result, LinqFromMetaTable)
    return result
end
From = from

-- function from_(t)
--     local result = {}
--     setmetatable(result, LinqFromMetaTable)
--     result.t = t or {}
--     local wrapper = {}
--     wrapper.t = result
--     setmetatable(wrapper, WrapperLinqFromMetaTable)
--     return wrapper
-- end

function range(startValue, endValue)
    local result = from()
    local i = startValue
    local finished = false
    while not finished do
        result:AddValue(i)
        i = i + 1
        finished = i >= endValue + 1
    end
    return result
end
Range = range
