local TableInsert = table.insert


local LuaQWhereMetaTable = {
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

    __call = function(self, func)
        self.__func = func
        return self
    end
}
where = setmetatable({}, LuaQWhereMetaTable)



local LuaQDeepCopyMetaTable = {
    __bor = function(tbl, self)
        return table.deepcopy(tbl)
    end,

}
deepcopy = setmetatable({}, LuaQDeepCopyMetaTable)


local LuaQCopyMetaTable = {
    __bor = function(tbl, self)
        return table.copy(tbl)
    end,

}
copy = setmetatable({}, LuaQCopyMetaTable)



local LuaQSortMetaTable = {
    __bor = function(tbl, self)
        local func = self.__func
        self.__func = nil

        table.sort(tbl, func)

        return tbl
    end,

    __call = function(self, func)
        self.__func = func
        return self
    end
}
sort = setmetatable({}, LuaQSortMetaTable)



local LuaQContainsMetaTable = {
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

    __call = function(self, value)
        self.__value = value
        return self
    end
}
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

local LuaQForeachMetaTable = {
    __bor = function(tbl, self)
        local func = self.__func
        self.__func = nil

        for k, v in tbl do
            func(k, v)
        end

        return tbl
    end,

    __call = function(self, func)
        self.__func = func
        return self
    end
}
foreach = setmetatable({}, LuaQForeachMetaTable)


local LuaQSumMetaTable = {
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

    __call = function(self, selector)
        self.__selector = selector
        return self
    end
}
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


local LuaQKeyMetaTable = {
    __bor = function(tbl, self)
        local result = {}

        for k, _ in tbl do
            TableInsert(result, k)
        end

        return result
    end
}
keys = setmetatable({}, LuaQKeyMetaTable)


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
