local TableInsert = table.insert
local ipairs = ipairs
local setmetatable = setmetatable

---@class BORTable : table
---@operator bor(table):table

---@param tbl table
---@return BORTable
function From(tbl)
    return tbl
end

---@param pipeTable table
---@param kvTable? table
---@return table
local function CreatePipe(pipeTable, kvTable)
    local pipe = {}
    if kvTable then
        pipe.keyvalue = CreatePipe(kvTable)
    end
    return setmetatable(pipe, pipeTable)
end

---@generic R
---@generic K
---@generic V?
---@class FunctionalTransformer<R, K, V>
---@field private fn function
FunctionalTransformer = {
    ---@param self FunctionalTransformer
    ---@param func function
    ---@return FunctionalTransformer
    __call = function(self, func)
        self.fn = func
        return self
    end,

    ---@param self FunctionalTransformer
    ---@return function
    PopFn = function(self)
        local fn = self.fn
        self.fn  = nil
        return fn
    end
}

---@class Comparator
---@field fn fun(a, b):boolean

---@class Selector
---@field fn fun(v:any):any

---@class SelectorKV
---@field fn fun(k, v):any

---@class Conditional
---@field fn fun(v):boolean

---@class ConditionalKV
---@field fn fun(k, v):boolean



---@generic K
---@generic V
---@param bor fun(tbl:table<K, V>, self:table):table
---@generic T: fa-class
---@return T
local function BORPipe(bor)
    return { __bor = bor }
end

---@generic K
---@generic V
---@param bor fun(tbl:table<K, V>, self:FunctionalTransformer):table
---@generic T: fa-class
---@return T
local function MakePipe(bor)
    return table.merged(BORPipe(bor), FunctionalTransformer)
end

---@class LuaQWherePipeTable : Conditional
LuaQWhere = MakePipe(function(tbl, self)
    local func = self:PopFn()

    local result = {}

    for _, v in ipairs(tbl) do
        if func(v) then
            TableInsert(result, v)
        end
    end

    return result
end)

---Selects key-values that satisfy the condition
---```lua
--- ... | where(function(k, v) v > 3 and type(k) == "string" end)
---```
--- `K`,`V`:`bool` -> `K`,`V`
---@class LuaQWhereKVPipeTable : ConditionalKV
LuaQWhereKV = MakePipe(function(tbl, self)
    local func = self:PopFn()

    local result = {}

    for k, v in tbl do
        if func(k, v) then
            result[k] = v
        end
    end

    return result
end)

---Selects values that satisfy the condition
---```lua
--- ... | where(function(v) v > 3 end)
---```
--- `V`:`bool` -> `V`
---@class LuaQWhere : LuaQWherePipeTable
---@field keyvalue LuaQWhereKVPipeTable
where = CreatePipe(LuaQWhere, LuaQWhereKV)


---@class LuaQSortPipeTable : Comparator
LuaQSortKV = MakePipe(function(tbl, self)
    local func = self:PopFn()
    table.sort(tbl, func)
    return tbl
end)


---@class LuaQSelectKVPipeTable : SelectorKV
LuaQSelectKV = MakePipe(function(tbl, self)
    local selector = self:PopFn()

    local result = {}

    if type(selector) == "string" then
        for k, v in tbl do
            result[k] = v[selector]
        end
    elseif iscallable(selector) then
        for k, v in tbl do
            result[k] = selector(k, v)
        end
    else
        error("Unsupported selector type " .. tostring(selector))
    end

    return result
end)

---@class LuaQSelectPipeTable : Selector
LuaQSelect = MakePipe(function(tbl, self)
    local selector = self:PopFn()

    local result = {}

    if type(selector) == "string" then
        for _, v in ipairs(tbl) do
            TableInsert(result, v[selector])
        end
    elseif iscallable(selector) then
        for _, v in ipairs(tbl) do
            TableInsert(result, selector(v))
        end
    else
        error("Unsupported selector type " .. tostring(selector))
    end

    return result
end)

---@class LuaQForEachPipeTable : Selector
LuaQForEach = MakePipe(function(tbl, self)
    local func = self:PopFn()

    for k, v in tbl do
        func(k, v)
    end

    return tbl
end)


---@class LuaQSumPipeTable : Selector
LuaQSum = MakePipe(function(tbl, self)
    local selector = self:PopFn()

    local _sum = 0
    if selector then
        for _, v in ipairs(tbl) do
            _sum = _sum + selector(v)
        end
    else
        for _, v in ipairs(tbl) do
            _sum = _sum + v
        end
    end

    return _sum
end)

---@class LuaQSumKVPipeTable : SelectorKV
LuaQSumKV = MakePipe(function(tbl, self)
    local selector = self:PopFn()

    local _sum = 0
    if selector then
        for k, v in tbl do
            _sum = _sum + selector(k, v)
        end
    else
        for _, v in tbl do
            _sum = _sum + v
        end
    end

    return _sum
end)

---@class LuaQAllPipeTable: ConditionalKV
LuaQAll = MakePipe(function(tbl, self)
    local condition = self:PopFn()

    if condition then
        for k, v in tbl do
            if not condition(k, v) then
                return false
            end
        end
    end

    return true
end)

---@class LuaQAnyPipeTable: ConditionalKV
LuaQAny = MakePipe(function(tbl, self)
    local condition = self:PopFn()

    if not condition then
        return not table.empty(tbl)
    end

    for k, v in tbl do
        if condition(k, v) then
            return true
        end
    end

    return false
end)

---@class LuaQValuesPipeTable
LuaQValues = BORPipe(function(tbl, self)
    local result = {}

    for _, v in tbl do
        TableInsert(result, v)
    end

    return result
end)

---@class LuaQKeysPipeTable
LuaQKeys = BORPipe(function(tbl, self)
    local result = {}

    for k in tbl do
        TableInsert(result, k)
    end

    return result
end)


---@class LuaQToSetPipeTable
LuaQToSet = BORPipe(function(tbl, self)
    local result = {}

    for _, v in tbl do
        result[v] = true
    end

    return result
end)

---@class LuaQFirstPipeTable : Conditional
LuaQFirst = MakePipe(function(tbl, self)
    local condition = self:PopFn()

    for _, v in ipairs(tbl) do
        if condition(v) then
            return v
        end
    end

    return nil
end)

---@class LuaQDistinctPipeTable
LuaQDistinct = BORPipe(function(tbl, self)
    return tbl | toSet | keys
end)


---@class LuaQCountPipeTable : Conditional
LuaQCount = MakePipe(function(tbl, self)
    local condition = self:PopFn()

    if not condition then
        return table.getn(tbl)
    end

    local count = 0
    for _, v in ipairs(tbl) do
        if condition(v) then
            count = count + 1
        end
    end

    return count
end)

---@class LuaQCountKVPipeTable : ConditionalKV
LuaQCountKV = MakePipe(function(tbl, self)
    local condition = self:PopFn()

    if not condition then
        return table.getsize(tbl)
    end

    local count = 0
    for k, v in tbl do
        if condition(k, v) then
            count = count + 1
        end
    end

    return count
end)

---@class DeepCopyPipeTable
local LuaQDeepCopyMetaTable = {
    ---returns the deep copy of the table
    ---@generic K
    ---@generic V
    ---@param tbl table<K,V>
    ---@param self DeepCopyPipeTable
    ---@return table<K,V>
    __bor = function(tbl, self)
        return table.deepcopy(tbl)
    end,
}
---@type DeepCopyPipeTable
deepcopy = setmetatable({}, LuaQDeepCopyMetaTable)


---@class CopyPipeTable
local LuaQCopyMetaTable = {
    ---returns the deep copy of the table
    ---@generic K
    ---@generic V
    ---@param tbl table<K,V>
    ---@param self CopyPipeTable
    ---@return table<K,V>
    __bor = function(tbl, self)
        return table.copy(tbl)
    end,
}
---@type CopyPipeTable
copy = setmetatable({}, LuaQCopyMetaTable)


---@class SortPipeTable
local LuaQSortMetaTable = {
    ---sorts table based on the given function
    ---@generic K
    ---@generic V
    ---@param tbl table<K,V>
    ---@param self SortPipeTable
    ---@return table<K,V>
    __bor = function(tbl, self)
        local func = self.__func
        self.__func = nil

        table.sort(tbl, func)

        return tbl
    end,

    ---sets sort function
    ---@generic K
    ---@generic V
    ---@param self SortPipeTable
    ---@param func fun(a:V, b:V):boolean
    ---@return SortPipeTable
    __call = function(self, func)
        self.__func = func
        return self
    end
}
---@type SortPipeTable
sort = setmetatable({}, LuaQSortMetaTable)


---@class ContainsPipeTable
local LuaQContainsMetaTable = {
    ---returns if table contains a given value
    ---@generic K
    ---@generic V
    ---@param tbl table<K,V>
    ---@param self ContainsPipeTable
    ---@return K?
    __bor = function(tbl, self)
        local value = self.__value
        self.__value = nil

        if value ~= nil then
            for k, v in tbl do
                if v == value then
                    return k
                end
            end
        end
        return nil
    end,
    ---sets value to be seek in the table
    ---@generic V
    ---@param self ContainsPipeTable
    ---@param value V
    ---@return ContainsPipeTable
    __call = function(self, value)
        self.__value = value

        return self
    end
}
---@type ContainsPipeTable
contains = setmetatable({}, LuaQContainsMetaTable)


local LuaQSelectKeyValueMetaTable = {
    __bor = function(tbl, self)
        local selector = self.__selector
        self.__selector = nil

        local result = {}

        if type(selector) == "string" then
            for k, v in tbl do
                result[k] = v[selector]
            end
        elseif iscallable(selector) then
            for k, v in tbl do
                result[k] = selector(k, v)
            end
        else
            error("Unsupported selector type " .. tostring(selector))
        end

        return result
    end,

    __call = function(self, selector)
        self.__selector = selector
        return self
    end
}

local LuaQSelectMetaTable = {
    __bor = function(tbl, self)
        local selector = self.__selector
        self.__selector = nil

        local result = {}

        if type(selector) == "string" then
            for _, v in ipairs(tbl) do
                TableInsert(result, v[selector])
            end
        elseif iscallable(selector) then
            for _, v in ipairs(tbl) do
                TableInsert(result, selector(v))
            end
        else
            error("Unsupported selector type " .. tostring(selector))
        end

        return result
    end,

    __call = function(self, selector)
        self.__selector = selector
        return self
    end
}

select = setmetatable({
    keyvalue = setmetatable({}, LuaQSelectKeyValueMetaTable)
}, LuaQSelectMetaTable)

---@class ForeachPipeTable
local LuaQForeachMetaTable = {
    ---loops over table applying a function to each entry in the table
    ---@generic K
    ---@generic V
    ---@param tbl table<K,V>
    ---@param self WherePipeTable
    ---@return table<K,V>
    __bor = function(tbl, self)
        local func = self.__func
        self.__func = nil

        for k, v in tbl do
            func(k, v)
        end

        return tbl
    end,

    ---Sets function to be called for each entry in the table
    ---@generic K
    ---@generic V
    ---@param self WherePipeTable
    ---@param func fun(key:K, value:V):boolean
    ---@return WherePipeTable
    __call = function(self, func)
        self.__func = func
        return self
    end
}
---@type ForeachPipeTable
foreach = setmetatable({}, LuaQForeachMetaTable)


---@class SumPipeTable
local LuaQSumKeyValueMetaTable = {
    ---sums values of the table
    ---@generic K
    ---@generic V
    ---@param tbl table<K,V>
    ---@param self SumPipeTable
    ---@return V
    __bor = function(tbl, self)
        local selector = self.__selector
        self.__selector = nil

        local _sum = 0
        if selector then
            for k, v in tbl do
                _sum = _sum + selector(k, v)
            end
        else
            for _, v in tbl do
                _sum = _sum + v
            end
        end

        return _sum
    end,

    ---sets selector for summing values of the table
    ---@generic K
    ---@generic V
    ---@param self SumPipeTable
    ---@param selector fun(key:K, value:V):V
    ---@return SumPipeTable
    __call = function(self, selector)
        self.__selector = selector
        return self
    end
}

---@class SumPipeTable
local LuaQSumMetaTable = {
    ---sums values of the table
    ---@generic K
    ---@generic V
    ---@param tbl table<K,V>
    ---@param self SumPipeTable
    ---@return V
    __bor = function(tbl, self)
        local selector = self.__selector
        self.__selector = nil

        local _sum = 0
        if selector then
            for _, v in ipairs(tbl) do
                _sum = _sum + selector(v)
            end
        else
            for _, v in tbl do
                _sum = _sum + v
            end
        end

        return _sum
    end,

    ---sets selector for summing values of the table
    ---@generic T
    ---@generic V
    ---@param self SumPipeTable
    ---@param selector fun(value:V):T
    ---@return SumPipeTable
    __call = function(self, selector)
        self.__selector = selector
        return self
    end
}

---@type SumPipeTable
sum = setmetatable({
    keyvalue = setmetatable({}, LuaQSumKeyValueMetaTable)
}, LuaQSumMetaTable)


local LuaQReduceMetaTable = {
    __bor = function(tbl, self)
        local reducer = self.__reducer
        local result = self.__initialValue or 0
        self.__reducer = nil
        self.__initialValue = nil

        for k, v in tbl do
            result = reducer(result, k, v)
        end

        return result
    end,

    __call = function(self, reducer, initialValue)
        self.__reducer = reducer
        self.__initialValue = initialValue
        return self
    end
}
reduce = setmetatable({}, LuaQReduceMetaTable)


local LuaQAllMetaTable = {
    __bor = function(tbl, self)
        local condition = self.__condition
        self.__condition = nil

        if condition then
            for k, v in tbl do
                if not condition(k, v) then
                    return false
                end
            end
        end

        return true
    end,

    __call = function(self, condition)
        self.__condition = condition
        return self
    end
}
all = setmetatable({}, LuaQAllMetaTable)


local LuaQAnyMetaTable = {
    __bor = function(tbl, self)
        local condition = self.__condition
        self.__condition = nil

        if not condition then
            return not table.empty(tbl)
        end

        for k, v in tbl do
            if condition(k, v) then
                return true
            end
        end

        return false
    end,



    __call = function(self, condition)
        self.__condition = condition
        return self
    end
}
any = setmetatable({}, LuaQAnyMetaTable)

---@class LuaQKeysTable
local LuaQKeysMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil

        local result = {}
        if condition then
            for k, v in tbl do
                if condition(k, v) then
                    TableInsert(result, k)
                end
            end
        else
            for k, _ in tbl do
                TableInsert(result, k)
            end
        end

        return result
    end,

    ---sets condition for keys to be selected
    ---@generic K
    ---@generic V
    ---@param self LuaQKeysTable
    ---@param condition fun(key:K, value:V):boolean
    ---@return LuaQKeysTable
    __call = function(self, condition)
        self.__condition = condition
        return self
    end
}
---@type LuaQKeysTable
keys = setmetatable({}, LuaQKeysMetaTable)


---@class LuaQValuesTable
local LuaQValuesMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil
        local result = {}

        if condition then
            for _, v in tbl do
                if condition(k, v) then
                    TableInsert(result, v)
                end
            end
        else
            for _, v in tbl do
                TableInsert(result, v)
            end
        end

        return result
    end,


    ---sets condition for values to be selected
    ---@generic K
    ---@generic V
    ---@param self LuaQValuesTable
    ---@param condition fun(key:K, value:V):boolean
    ---@return LuaQValuesTable
    __call = function(self, condition)
        self.__condition = condition
        return self
    end
}
---@type LuaQValuesTable
values = setmetatable({}, LuaQValuesMetaTable)


local LuaQFirstMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil

        for _, v in ipairs(tbl) do
            if condition(v) then
                return v
            end
        end

        return nil
    end,

    __call = function(self, condition)
        self.__condition = condition
        return self
    end
}
first = setmetatable({}, LuaQFirstMetaTable)


local LuaQCountKeyValueMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil

        if not condition then
            return table.getsize(tbl)
        end

        local count = 0
        for k, v in tbl do
            if condition(k, v) then
                count = count + 1
            end
        end

        return count
    end,

    __call = function(self, condition)
        self.__condition = condition
        return self
    end
}

local LuaQCountMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil

        if not condition then
            return table.getn(tbl)
        end

        local count = 0
        for _, v in ipairs(tbl) do
            if condition(v) then
                count = count + 1
            end
        end

        return count
    end,

    __call = function(self, condition)
        self.__condition = condition
        return self
    end
}


count = setmetatable({
    keyvalue = setmetatable({}, LuaQCountKeyValueMetaTable)
}, LuaQCountMetaTable)


local LuaQToSetMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil

        local result = {}

        if condition then
            for k, v in tbl do
                if condition(k, v) then
                    result[v] = true
                end
            end
        else
            for _, v in tbl do
                result[v] = true
            end
        end

        return result
    end,

    __call = function(self, condition)
        self.__condition = condition
        return self
    end
}
toSet = setmetatable({}, LuaQToSetMetaTable)


local LuaQDistinctMetaTable = {
    __bor = function(tbl, self)
        return tbl | toSet | keys
    end,
}
distinct = setmetatable({}, LuaQDistinctMetaTable)


---retuns max of the given table
---@generic K
---@generic V
---@generic T
---@param tbl table<K,V>
---@param condition fun(k:K , v:V) :T
---@return K?
---@return V?
---@return T?
local function FindMax(tbl, condition)

    local keyMax
    local valueMax

    if condition then
        for k, v in tbl do
            local value = condition(k, v)
            if not valueMax or value > valueMax then
                keyMax = k
                valueMax = value
            end
        end
    else
        for k, v in tbl do
            if v > valueMax then
                keyMax = k
                valueMax = v
            end
        end
    end

    if not keyMax then
        return nil, nil, nil
    end
    return keyMax, tbl[keyMax], valueMax
end

---retuns min of the given table
---@generic K
---@generic V
---@generic T
---@param tbl table<K,V>
---@param condition fun(k:K , v:V) :T
---@return K?
---@return V?
---@return T?
local function FindMin(tbl, condition)

    local keyMin
    local valueMin

    if condition then
        for k, v in tbl do
            local value = condition(k, v)
            if not valueMin or value < valueMin then
                keyMin = k
                valueMin = value
            end
        end
    else
        for k, v in tbl do
            if v < valueMin then
                keyMin = k
                valueMin = v
            end
        end
    end

    if not keyMin then
        return nil, nil, nil
    end
    return keyMin, tbl[keyMin], valueMin
end

---@class LuaQMaxMetaTable
local LuaQMaxKeyMetaTable = {
    __bor = function(tbl, self)
        local condition = self.__condition
        self.__condition = nil

        local k, _, _ = FindMax(tbl, condition)
        return k
    end,

    ---sets function which returns value to be compared in order determine max value
    ---@generic K
    ---@generic V
    ---@generic T
    ---@param self LuaQMaxMetaTable
    ---@param condition fun(key:K, value:V):T
    ---@return LuaQMaxMetaTable
    __call = function(self, condition)
        self.__condition = condition
        return self
    end,
}



---@class LuaQMaxMetaTable
local LuaQMaxValueMetaTable = {
    __bor = function(tbl, self)
        local condition = self.__condition
        self.__condition = nil

        local _, v, _ = FindMax(tbl, condition)
        return v
    end,

    ---sets function which returns value to be compared in order determine max value
    ---@generic K
    ---@generic V
    ---@generic T
    ---@param self LuaQMaxMetaTable
    ---@param condition fun(key:K, value:V):T
    ---@return LuaQMaxMetaTable
    __call = function(self, condition)
        self.__condition = condition
        return self
    end,
}

---@class LuaQMaxMetaTable
local LuaQMaxMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil

        local _, _, t = FindMax(tbl, condition)
        return t
    end,

    ---sets function which returns value to be compared in order determine max value
    ---@generic K
    ---@generic V
    ---@generic T
    ---@param self LuaQMaxMetaTable
    ---@param condition fun(key:K, value:V):T
    ---@return LuaQMaxMetaTable
    __call = function(self, condition)
        self.__condition = condition
        return self
    end,
}
---@type LuaQMaxMetaTable
max = setmetatable({
    key = setmetatable({}, LuaQMaxKeyMetaTable),
    value = setmetatable({}, LuaQMaxValueMetaTable),
}, LuaQMaxMetaTable)



---@class LuaQMaxMetaTable
local LuaQMinKeyMetaTable = {
    __bor = function(tbl, self)
        local condition = self.__condition
        self.__condition = nil

        local k, _, _ = FindMin(tbl, condition)
        return k
    end,

    ---sets function which returns value to be compared in order determine max value
    ---@generic K
    ---@generic V
    ---@generic T
    ---@param self LuaQMaxMetaTable
    ---@param condition fun(key:K, value:V):T
    ---@return LuaQMaxMetaTable
    __call = function(self, condition)
        self.__condition = condition
        return self
    end,
}



---@class LuaQMaxMetaTable
local LuaQMinValueMetaTable = {
    __bor = function(tbl, self)
        local condition = self.__condition
        self.__condition = nil

        local _, v, _ = FindMin(tbl, condition)
        return v
    end,

    ---sets function which returns value to be compared in order determine max value
    ---@generic K
    ---@generic V
    ---@generic T
    ---@param self LuaQMaxMetaTable
    ---@param condition fun(key:K, value:V):T
    ---@return LuaQMaxMetaTable
    __call = function(self, condition)
        self.__condition = condition
        return self
    end,
}

---@class LuaQMinMetaTable
local LuaQMinMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil

        local _, _, t = FindMin(tbl, condition)
        return t
    end,

    ---sets function which returns value to be compared in order determine max value
    ---@generic K
    ---@generic V
    ---@generic T
    ---@param self LuaQMaxMetaTable
    ---@param condition fun(key:K, value:V):T
    ---@return LuaQMaxMetaTable
    __call = function(self, condition)
        self.__condition = condition
        return self
    end,
}
---@type LuaQMinMetaTable
min = setmetatable({
    key = setmetatable({}, LuaQMinKeyMetaTable),
    value = setmetatable({}, LuaQMinValueMetaTable),
}, LuaQMinMetaTable)



---returns table of integers from startValue to endValue including both
---@param startValue integer
---@param endValue integer
---@return integer[]
function range(startValue, endValue)
    local result = {}
    local i = startValue
    repeat
        TableInsert(result, i)
        i = i + 1
    until i >= endValue + 1
    return result
end
