local TableInsert = table.insert
local ipairs = ipairs
local setmetatable = setmetatable
local TableSort = table.sort
local TableGetN = table.getn
local type = type
local iscallable = iscallable

---@class BORTable : table
---@operator bor(table):table

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
    end
}

---Pops function from functional transformer
---@param fnObj FunctionalTransformer
---@return function
local function PopFn(fnObj)
    local fn = fnObj.fn
    fnObj.fn = nil
    return fn
end

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
    return table.combine(BORPipe(bor), FunctionalTransformer)
end

---Selects key-values that satisfy the condition
---```lua
--- ... | where.keyvalue(function(k, v) return v > 3 and type(k) == "string" end)
---```
--- `K`,`V`:`bool` -> `K`,`V`
---@class LuaQWhereKVPipeTable : ConditionalKV
LuaQWhereKV = MakePipe(function(tbl, self)
    local func = PopFn(self)

    local result = {}

    for k, v in tbl do
        if func(k, v) then
            result[k] = v
        end
    end

    return result
end)

---@class LuaQWherePipeTable : Conditional
LuaQWhere = MakePipe(function(tbl, self)
    local func = PopFn(self)

    local result = {}

    for _, v in ipairs(tbl) do
        if func(v) then
            TableInsert(result, v)
        end
    end

    return result
end)
---Selects values that satisfy the condition
---```lua
--- ... | where(function(v) return v > 3 end)
---```
--- `V`:`bool` -> `V`
---@class LuaQWhere : LuaQWherePipeTable
---@field keyvalue LuaQWhereKVPipeTable
where = CreatePipe(LuaQWhere, LuaQWhereKV)

---Sorts values in table by the condition
---```lua
--- ... | sort(function(a, b) return a.value > b.value end)
---```
---@class LuaQSortPipeTable : Comparator
LuaQSort = MakePipe(function(tbl, self)
    local func = PopFn(self)
    TableSort(tbl, func)
    return tbl
end)
---@type LuaQSortPipeTable
sort = CreatePipe(LuaQSort)

---Creates new table based on return value of the selector
---```lua
--- ... | select.keyvalue(function(k, v) return v.value end)
---```
---With string selector
---```lua
--- ... | select.keyvalue "value"
---```
---@class LuaQSelectKVPipeTable : SelectorKV
LuaQSelectKV = MakePipe(function(tbl, self)
    local selector = PopFn(self)

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
    local selector = PopFn(self)

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

---Creates new table based on return value of the selector
---```lua
--- ... | select(function(v) return v.value end)
---```
---With string selector
---```lua
--- ... | select "value"
---```
---@class LuaQSelect : LuaQSelectPipeTable
---@field keyvalue LuaQSelectKVPipeTable
select = CreatePipe(LuaQSelect, LuaQSelectKV)

---Applies function to key-values of the table
---```lua
--- ... | foreach(function(k, v) print(tostring(k).. ":" .. tostring(v)) end)
---```
--- Returns table back
---@class LuaQForEachPipeTable : Selector
LuaQForEach = MakePipe(function(tbl, self)
    local func = PopFn(self)

    for k, v in tbl do
        func(k, v)
    end

    return tbl
end)
---@type LuaQForEachPipeTable
foreach = CreatePipe(LuaQForEach)

---Sums values of table, values can be selected with selector
---```lua
--- ... | sum.keyvalue(function(id, player) if team[id] then return player.rating end return 0 end)
---```
---@class LuaQSumKVPipeTable : SelectorKV
LuaQSumKV = MakePipe(function(tbl, self)
    local selector = PopFn(self)

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

---@class LuaQSumPipeTable : Selector
LuaQSum = MakePipe(function(tbl, self)
    local selector = PopFn(self)

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

---Sums values of table, values can be selected with selector
---```lua
--- ... | sum(function(v) return v.rating or 0 end)
---```
---@class LuaQSum : LuaQSumPipeTable
---@field keyvalue LuaQSumKVPipeTable
sum = CreatePipe(LuaQSum, LuaQSumKV)

---Returns true if all values satisfy the condition
---```lua
--- ... | all(function(k, v) return v < 0 end)
---```
---@class LuaQAllPipeTable: ConditionalKV
LuaQAll = MakePipe(function(tbl, self)
    local condition = PopFn(self)

    if condition then
        for k, v in tbl do
            if not condition(k, v) then
                return false
            end
        end
    end

    return true
end)
---@type LuaQAllPipeTable
all = CreatePipe(LuaQAll)

---Returns true if any of values satisfy the condition
---```lua
--- ... | any(function(k, v) return v < 0 end)
---```
---@class LuaQAnyPipeTable: ConditionalKV
LuaQAny = MakePipe(function(tbl, self)
    local condition = PopFn(self)

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

---@type LuaQAnyPipeTable
any = CreatePipe(LuaQAny)

---Returns table with only values of the given table
---```lua
--- ... | values
---```
---@class LuaQValuesPipeTable
LuaQValues = BORPipe(function(tbl, self)
    local result = {}

    for _, v in tbl do
        TableInsert(result, v)
    end

    return result
end)

---@type LuaQValuesPipeTable
values = CreatePipe(LuaQValues)

---Returns table with concatinated tables inside given one
---```lua
--- ... | concat
---```
---@class LuaQConcatPipeTable
LuaQConcat = BORPipe(function(tbl, self)
    local result = {}

    for _, v in tbl do
        for _, el in v do
            TableInsert(result, el)
        end
    end

    return result
end)

---@type LuaQConcatPipeTable
concat = CreatePipe(LuaQConcat)

---Returns table with only keys of the given table
---```lua
--- ... | keys
---```
---@class LuaQKeysPipeTable
LuaQKeys = BORPipe(function(tbl, self)
    local result = {}

    for k in tbl do
        TableInsert(result, k)
    end

    return result
end)

---@type LuaQKeysPipeTable
keys = CreatePipe(LuaQKeys)

---Returns table where keys are values of the given table
---```lua
--- ... | toSet
---```
---@class LuaQToSetPipeTable
LuaQToSet = BORPipe(function(tbl, self)
    local result = {}

    for _, v in tbl do
        result[v] = true
    end

    return result
end)
---@type LuaQToSetPipeTable
toSet = CreatePipe(LuaQToSet)

---Returns the first value that satisfy the condition, if none - nil
---```lua
--- ... | first(function(v) return v > 0 end)
---```
---@class LuaQFirstPipeTable : Conditional
LuaQFirst = MakePipe(function(tbl, self)
    local condition = PopFn(self)

    for _, v in ipairs(tbl) do
        if condition(v) then
            return v
        end
    end

    return nil
end)
---@type LuaQFirstPipeTable
first = CreatePipe(LuaQFirst)

---Returns index of the first value satisfying the condition, if none - nil
---```lua
--- ... | firstIndex(function(v) return v > 0 end)
---```
---@class LuaQFirstIPipeTable : Conditional
LuaQFirstI = MakePipe(function(tbl, self)
    local condition = PopFn(self)

    for i, v in ipairs(tbl) do
        if condition(v) then
            return i
        end
    end

    return nil
end)
---@type LuaQFirstIPipeTable
firstIndex = CreatePipe(LuaQFirstI)

---Returns the last value that satisfy the condition, if none - nil
---```lua
--- ... | last(function(v) return v > 0 end)
---```
---@class LuaQLastPipeTable : Conditional
LuaQLast = MakePipe(function(tbl, self)
    local condition = PopFn(self)

    for i = TableGetN(tbl), 1, -1 do
        local v = tbl[i]
        if condition(v) then
            return v
        end
    end

    return nil
end)
---@type LuaQLastPipeTable
last = CreatePipe(LuaQLast)

---Returns index of the last value satisfying the condition, if none - nil
---```lua
--- ... | lastIndex(function(v) return v > 0 end)
---```
---@class LuaQLastIPipeTable : Conditional
LuaQLastI = MakePipe(function(tbl, self)
    local condition = PopFn(self)

    for i = TableGetN(tbl), 1, -1 do
        local v = tbl[i]
        if condition(v) then
            return i
        end
    end

    return nil
end)
---@type LuaQLastIPipeTable
lastIndex = CreatePipe(LuaQLastI)

---Returns table of distinct values of given table
---@class LuaQDistinctPipeTable
LuaQDistinct = BORPipe(function(tbl, self)
    local result = {}
    local _set = {}

    for _, v in tbl do
        if not _set[v] then
            TableInsert(result, v)
            _set[v] = true
        end
    end

    return result
end)
---@type LuaQDistinctPipeTable
distinct = CreatePipe(LuaQDistinct)

---Makes shallow copy of the given table
---```lua
--- ... | copy
---```
---@class LuaQCopy
LuaQCopy = BORPipe(function(tbl, self)
    return table.copy(tbl)
end)
---@type LuaQCopy
copy = CreatePipe(LuaQCopy)

---Makes deep copy of the given table
---```lua
--- ... | deepcopy
---```
---@class LuaQDeepCopy
LuaQDeepCopy = BORPipe(function(tbl, self)
    return table.deepcopy(tbl)
end)
---@type LuaQDeepCopy
deepcopy = CreatePipe(LuaQDeepCopy)

---@class LuaQCountKVPipeTable : ConditionalKV
LuaQCountKV = MakePipe(function(tbl, self)
    local condition = PopFn(self)

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

---@class LuaQCountPipeTable : Conditional
LuaQCount = MakePipe(function(tbl, self)
    local condition = PopFn(self)

    if not condition then
        return TableGetN(tbl)
    end

    local count = 0
    for _, v in ipairs(tbl) do
        if condition(v) then
            count = count + 1
        end
    end

    return count
end)
---@class LuaQCount : LuaQCountPipeTable
---@field keyvalue LuaQCountKVPipeTable
count = CreatePipe(LuaQCount, LuaQCountKV)

---@class LuaQPartition : Conditional
LuaQPartition = MakePipe(function(tbl, self)
    local condition = PopFn(self)
    local _true = {}
    local _false = {}
    for _, v in ipairs(tbl) do
        if condition(v) then
            TableInsert(_true, v)
        else
            TableInsert(_false, v)
        end
    end
    return { [true] = _true, [false] = _false }
end)

---@class LuaQPartitionKV : ConditionalKV
LuaQPartitionKV = MakePipe(function(tbl, self)
    local condition = PopFn(self)
    local _true = {}
    local _false = {}
    for k, v in tbl do
        if condition(k, v) then
            _true[k] = v
        else
            _false[k] = v
        end
    end
    return { [true] = _true, [false] = _false }
end)

---@class LuaQPartitionPipe : LuaQPartition
---@field keyvalue LuaQPartitionKV
partition = CreatePipe(LuaQPartition, LuaQPartitionKV)

---@class LuaQGroupBy : Selector
LuaQGroupBy = MakePipe(function(tbl, self)
    local selector = PopFn(self)
    local result = {}

    for _, v in ipairs(tbl) do
        local group = selector(v)

        if not result[group] then
            result[group] = {}
        end

        TableInsert(result[group], v)
    end

    return result
end)

---@class LuaQGroupByKV : SelectorKV
LuaQGroupByKV = MakePipe(function(tbl, self)
    local selector = PopFn(self)
    local result = {}

    for k, v in tbl do
        local group = selector(k, v)

        if not result[group] then
            result[group] = {}
        end

        result[group][k] = v
    end

    return result
end)

---@class LuaQGroupByPipe : LuaQGroupBy
---@field keyvalue LuaQGroupByKV
groupBy = CreatePipe(LuaQGroupBy, LuaQGroupByKV)

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
