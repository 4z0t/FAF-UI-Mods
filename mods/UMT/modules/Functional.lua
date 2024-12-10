local setmetatable = setmetatable
local iscallable = iscallable
local TableInsert = table.insert
local getmetatable = getmetatable

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

---@alias Yielder fun(t:table, k):(any,any)

---@class BORPipe<K,V> : {iterator:fun(iterator:fun(t:table<K,V>, k:K):(K,V), self:FunctionalTransformer):(fun(t:table<K,V>, k:K):(K,V))}

---@class Iterator
---@field fn fun(iterator, key):(any,any)
---@operator call(table):Yielder,table

Iterator = {
    __call = function(self, t)
        return self.fn(t)
    end,

    __bor = function(l, r)

        local borl = getmetatable(l).__bor
        local borr = getmetatable(r).__bor
        if borl and borr then -- we are on left side called by right one
            return borr(l, r)
        end

        if borr then
            return r.fn(l)
        end

        error "Unexpected order of Stateless iterator"
    end,
}

---@param fn fun(iterator, key):(any,any)
---@return Iterator
local function CreateGenerator(fn)
    return setmetatable({ fn = fn }, Iterator)
end

BORPipe = table.combine(FunctionalTransformer, {
    ---@generic K,V
    ---@param proto Iterator
    ---@param self BORPipe<K,V>
    __bor = function(proto, self)
        return CreateGenerator(self.iterator(proto.fn, self))
    end
})

---@generic K
---@generic V
---@generic Class: fa-class
---@return Class
local function MakePipe()
    return BORPipe
end

---@generic K, V
---@param t table<K, V>
---@param k? K
function nexti(t, k)
    k = k or 0
    local v = t[k + 1]

    if v == nil then
        return nil, nil
    end

    return k + 1, v
end

pairsIterator = CreateGenerator(next)
ipairsIterator = CreateGenerator(nexti)
reversedIpairsIterator = CreateGenerator(function(t, k)
    if k == nil then
        k = table.getn(t)
    else
        k = k - 1
    end
    if k == 0 then
        return nil, nil
    end
    local v = t[k]
    return k, v
end)


---@class FunctionalPipe
---@operator bor(fun(t:table, k):(any,any)):fun(t:table, k):(any,any)
---@operator call(fun():any):FunctionalPipe


---@generic K
---@generic V
---@param bor fun(iterator:fun(t:table<K,V>, k:K):(K,V), self:FunctionalTransformer):(fun(t:table<K,V>, k:K):(K,V))
---@return FunctionalPipe
local function MakeFunctionalPipe(bor)
    return setmetatable({ iterator = bor }, MakePipe())
end

where = MakeFunctionalPipe(function(iterator, self)
    local selector = PopFn(self)
    return function(t, k)
        local nk = k
        local v
        repeat
            nk, v = iterator(t, nk)
            if nk == nil then
                return nil, nil
            end
        until selector(v)
        return nk, v
    end
end)


select = MakeFunctionalPipe(function(iterator, self)
    local selector = PopFn(self)

    if iscallable(selector) then
        return function(t, k)
            local nk, v = iterator(t, k)
            if nk == nil then return nil, nil end
            return nk, selector(v)
        end
    elseif type(selector) == "string" then
        return function(t, k)
            local nk, v = iterator(t, k)
            if nk == nil then return nil, nil end
            return nk, v[selector]
        end
    end

    error("Unsupported selector type " .. tostring(selector))
end)


foreach = MakeFunctionalPipe(function(iterator, self)
    local func = PopFn(self)
    return function(t, k)
        local nk, v = iterator(t, k)
        if nk == nil then return nil, nil end

        func(nk, v)

        return nk, v
    end
end)

toArray = MakeFunctionalPipe(function(iterator, self)
    return function(t)
        local nt = {}
        for _, v in iterator, t do
            TableInsert(nt, v)
        end
        return nt
    end
end)

toTable = MakeFunctionalPipe(function(iterator, self)
    return function(t)
        local nt = {}
        for k, v in iterator, t do
            nt[k] = v
        end
        return nt
    end
end)

toIterator = MakeFunctionalPipe(function(iterator, self)
    return function(t)
        return iterator, t
    end
end)

keys = MakeFunctionalPipe(function(iterator, self)
    return function(t, k)
        local nk, v = iterator(t, k)
        if nk == nil then return nil, nil end

        return nk, nk
    end
end)

toSet = MakeFunctionalPipe(function(iterator, self)
    return function(t)
        local nt = {}
        for k in iterator, t do
            nt[k] = true
        end
        return nt
    end
end)

max = MakeFunctionalPipe(function(iterator, self)
    local selector = PopFn(self)
    if selector then
        return function(t)
            local valueMax
            for k, v in iterator, t do
                local value = selector(v)
                if not valueMax or value > valueMax then
                    valueMax = value
                end
            end
            return valueMax
        end
    end
    return function(t)
        local valueMax
        for k, v in iterator, t do
            if not valueMax or v > valueMax then
                valueMax = v
            end
        end
        return valueMax
    end
end)

min = MakeFunctionalPipe(function(iterator, self)
    local selector = PopFn(self)
    if selector then
        return function(t)
            local valueMin
            for k, v in iterator, t do
                local value = selector(v)
                if not valueMin or value < valueMin then
                    valueMin = value
                end
            end
            return valueMin
        end
    end
    return function(t)
        local valueMin
        for k, v in iterator, t do
            if not valueMin or v < valueMin then
                valueMin = v
            end
        end
        return valueMin
    end
end)

contains = MakeFunctionalPipe(function(iterator, self)
    local value = PopFn(self)
    return function(t)
        for k, v in iterator, t do
            if value == v then
                return k
            end
        end
        return nil
    end
end)



---@class IEnumerable<K, V>: {iter : (fun(t: {[K]:V}, k:K):(K,V)), tbl:table<K,V> }
IEnumerable = {
    ---@generic K, V
    ---@param self IEnumerable<K, V>
    ---@return fun(t: {[K]:V}, k:K):(K,V)
    ---@return table<K, V>
    Iterate = function(self)
        return self.iter, self.tbl
    end,

    ---@generic K, V
    ---@param self IEnumerable<K, V>
    ---@return table<K, V>
    Enumerate = function(self)
        local nt = {}
        for k, v in self:Iterate() do
            nt[k] = v
        end
        return nt
    end
}



---@class StatefulIterator
StatefulIterator = {
    __call = function(self, t, key)
        LOG(key)
        return next(t, key)
    end,
}

iter = setmetatable({}, StatefulIterator)
