local LuaQWhereMetaTable = {
    __bor = function(tbl, self)
        local func = self.__func
        self.__func = nil

        for k, v in tbl do
            if not func(k, v) then
                tbl[k] = nil
            end
        end

        return tbl
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

        if type(selector) == "string" then
            for k, v in tbl do
                tbl[k] = v[selector]
            end
        elseif type(selector) == "function" then
            for k, v in tbl do
                local value = selector(k, v)
                if value ~= nil then
                    tbl[k] = value
                end
            end
        end

        return tbl
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
        local keys = {}

        for k, _ in tbl do
            table.insert(keys, k)
        end

        return keys
    end
}

keys = setmetatable({}, LuaQKeyMetaTable)
