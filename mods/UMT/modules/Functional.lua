local setmetatable = setmetatable
local iscallable = iscallable
local TableInsert = table.insert

---@generic R
---@generic K
---@generic V?
---@class FunctionalTransformer<R, K, V>
---@field private fn function
local FunctionalTransformer = {
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
---@param bor fun(iterable:fun(t:table<K,V>, k:K):(K,V), self:FunctionalTransformer):(fun(t:table<K,V>, k:K):(K,V))
---@generic Class: fa-class
---@return Class
local function MakePipe(bor)
    return table.combine(BORPipe(bor), FunctionalTransformer)
end

---@generic K, V
---@param t table<K, V>
---@param k? K
function nexti(t, k)
    local v = t[k + 1]

    if v == nil then
        return nil, nil
    end

    return k + 1, v
end

---@class FunctionalPipe
---@operator bor(fun(t:table, k):(any,any)):fun(t:table, k):(any,any)
---@operator call(fun():any):FunctionalPipe


---@generic K
---@generic V
---@param bor fun(iterable:fun(t:table<K,V>, k:K):(K,V), self:FunctionalTransformer):(fun(t:table<K,V>, k:K):(K,V))
---@return FunctionalPipe
local function MakeFunctionalPipe(bor)
    return setmetatable({}, MakePipe(bor))
end

where = MakeFunctionalPipe(function(iterable, self)
    local selector = PopFn(self)
    return function(t, k)
        local nk, v = iterable(t, k)
        if nk == nil then return nil, nil end

        while not selector(v) do
            nk, v = iterable(t, nk)
        end
        return nk, v
    end
end)


select = MakeFunctionalPipe(function(iterable, self)
    local selector = PopFn(self)

    if iscallable(selector) then
        return function(t, k)
            local nk, v = iterable(t, k)
            if nk == nil then return nil, nil end
            return nk, selector(v)
        end
    elseif type(selector) == "string" then
        return function(t, k)
            local nk, v = iterable(t, k)
            if nk == nil then return nil, nil end
            return nk, v[selector]
        end
    end

    error("Unsupported selector type " .. tostring(selector))
end)


foreach = MakeFunctionalPipe(function(iterable, self)
    local func = PopFn(self)
    return function(t, k)
        local nk, v = iterable(t, k)
        if nk == nil then return nil, nil end

        func(nk, v)

        return nk, v
    end
end)

toArray = MakeFunctionalPipe(function(iterable, self)
    return function(t)
        local nt = {}
        for _, v in iterable, t do
            TableInsert(nt, v)
        end
        return nt
    end
end)

toTable = MakeFunctionalPipe(function(iterable, self)
    return function(t)
        local nt = {}
        for k, v in iterable, t do
            nt[k] = v
        end
        return nt
    end
end)

toIterator = MakeFunctionalPipe(function(iterable, self)
    return function(t)
        return iterable, t
    end
end)
