local TableInsert = table.insert

---@class WherePipeTable
local LuaQWhereMetaTable = {
    ---return new table with elements satisfying the given condition
    ---@generic K
    ---@generic V
    ---@param tbl table<K,V>
    ---@param self WherePipeTable
    ---@return table<K,V>
    __bor = function(tbl, self)
        local func = self.__func
        self.__func = nil

        local result = {}

        for k, v in tbl do
            if func(k, v) then
                result[k] = v
            end
        end

        return result
    end,

    ---Sets condition for filtering table
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
---@type WherePipeTable
where = setmetatable({}, LuaQWhereMetaTable)


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
    ---@return boolean, V?
    __bor = function(tbl, self)
        local value = self.__value
        self.__value = nil

        if value ~= nil then
            for k, v in tbl do
                if v == value then
                    return true, k
                end
            end
        end
        return false, nil
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


local LuaQSelectMetaTable = {
    __bor = function(tbl, self)
        local selector = self.__selector
        self.__selector = nil

        local result = {}

        if type(selector) == "string" then
            for k, v in tbl do
                result[k] = v[selector]
            end
        elseif type(selector) == "function" then
            for k, v in tbl do
                local value = selector(k, v)
                if value ~= nil then
                    result[k] = value
                end
            end
        end

        return result
    end,

    __call = function(self, selector)
        self.__selector = selector
        return self
    end
}
select = setmetatable({}, LuaQSelectMetaTable)

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
---@type SumPipeTable
sum = setmetatable({}, LuaQSumMetaTable)


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
            for k, _ in tbl do
                if condition(k) then
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
    ---@param self LuaQKeysTable
    ---@param condition fun(key:K):boolean
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
                if condition(v) then
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
    ---@generic V
    ---@param self LuaQValuesTable
    ---@param condition fun(value:V):boolean
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


local LuaQCountMetaTable = {
    __bor = function(tbl, self)

        local condition = self.__condition
        self.__condition = nil

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
count = setmetatable({}, LuaQCountMetaTable)


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



function range(startValue, endValue)
    local result = {}
    local i = startValue
    repeat
        TableInsert(result, i)
        i = i + 1
    until i >= endValue + 1
    return result
end
