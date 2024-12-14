local setmetatable = setmetatable
local iscallable = iscallable
local TableInsert = table.insert
local getmetatable = getmetatable
local next = next

-- ---@generic R
-- ---@generic K
-- ---@generic V?
-- ---@class FunctionalTransformer<R, K, V>
-- ---@field private fn function
-- local FunctionalTransformer = {
--     ---@param self FunctionalTransformer
--     ---@param func function
--     ---@return FunctionalTransformer
--     __call = function(self, func)
--         self.fn = func
--         return self
--     end
-- }

-- ---Pops function from functional transformer
-- ---@param fnObj FunctionalTransformer
-- ---@return function
-- local function PopFn(fnObj)
--     local fn = fnObj.fn
--     fnObj.fn = nil
--     return fn
-- end

-- ---@class Comparator
-- ---@field fn fun(a, b):boolean

-- ---@class Selector
-- ---@field fn fun(v:any):any

-- ---@class SelectorKV
-- ---@field fn fun(k, v):any

-- ---@class Conditional
-- ---@field fn fun(v):boolean

-- ---@class ConditionalKV
-- ---@field fn fun(k, v):boolean

-- ---@alias Yielder fun(t:table, k):(any,any)

-- ---@class BORPipe<K,V> : {iterator:fun(iterator:fun(t:table<K,V>, k:K):(K,V), self:FunctionalTransformer):(fun(t:table<K,V>, k:K):(K,V))}

-- ---@class Iterator
-- ---@field fn fun(iterator, key):(any,any)
-- ---@operator call(table):Yielder,table

-- Iterator = {
--     __call = function(self, t)
--         return self.fn(t)
--     end,

--     __bor = function(l, r)

--         local borl = getmetatable(l).__bor
--         local borr = getmetatable(r).__bor
--         if borl and borr then -- we are on left side called by right one
--             return borr(l, r)
--         end

--         if borr then
--             return r.fn(l)
--         end

--         error "Unexpected order of Stateless iterator"
--     end,
-- }

-- ---@param fn fun(iterator, key):(any,any)
-- ---@return Iterator
-- local function CreateGenerator(fn)
--     return setmetatable({ fn = fn }, Iterator)
-- end

-- BORPipe = table.combine(FunctionalTransformer, {
--     ---@generic K,V
--     ---@param proto Iterator
--     ---@param self BORPipe<K,V>
--     __bor = function(proto, self)
--         return CreateGenerator(self.iterator(proto.fn, self))
--     end
-- })

-- ---@generic K
-- ---@generic V
-- ---@generic Class: fa-class
-- ---@return Class
-- local function MakePipe()
--     return BORPipe
-- end

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

-- pairsIterator = CreateGenerator(next)
-- ipairsIterator = CreateGenerator(nexti)
-- reversedIpairsIterator = CreateGenerator(function(t, k)
--     if k == nil then
--         k = table.getn(t)
--     else
--         k = k - 1
--     end
--     if k == 0 then
--         return nil, nil
--     end
--     local v = t[k]
--     return k, v
-- end)


-- ---@class FunctionalPipe
-- ---@operator bor(fun(t:table, k):(any,any)):fun(t:table, k):(any,any)
-- ---@operator call(fun():any):FunctionalPipe


-- ---@generic K
-- ---@generic V
-- ---@param bor fun(iterator:fun(t:table<K,V>, k:K):(K,V), self:FunctionalTransformer):(fun(t:table<K,V>, k:K):(K,V))
-- ---@return FunctionalPipe
-- local function MakeFunctionalPipe(bor)
--     return setmetatable({ iterator = bor }, MakePipe())
-- end

-- where = MakeFunctionalPipe(function(iterator, self)
--     local selector = PopFn(self)
--     return function(t, k)
--         local nk = k
--         local v
--         repeat
--             nk, v = iterator(t, nk)
--             if nk == nil then
--                 return nil, nil
--             end
--         until selector(v)
--         return nk, v
--     end
-- end)


-- select = MakeFunctionalPipe(function(iterator, self)
--     local selector = PopFn(self)

--     if iscallable(selector) then
--         return function(t, k)
--             local nk, v = iterator(t, k)
--             if nk == nil then return nil, nil end
--             return nk, selector(v)
--         end
--     elseif type(selector) == "string" then
--         return function(t, k)
--             local nk, v = iterator(t, k)
--             if nk == nil then return nil, nil end
--             return nk, v[selector]
--         end
--     end

--     error("Unsupported selector type " .. tostring(selector))
-- end)


-- foreach = MakeFunctionalPipe(function(iterator, self)
--     local func = PopFn(self)
--     return function(t, k)
--         local nk, v = iterator(t, k)
--         if nk == nil then return nil, nil end

--         func(nk, v)

--         return nk, v
--     end
-- end)

-- toArray = MakeFunctionalPipe(function(iterator, self)
--     return function(t)
--         local nt = {}
--         for _, v in iterator, t do
--             TableInsert(nt, v)
--         end
--         return nt
--     end
-- end)

-- toTable = MakeFunctionalPipe(function(iterator, self)
--     return function(t)
--         local nt = {}
--         for k, v in iterator, t do
--             nt[k] = v
--         end
--         return nt
--     end
-- end)

-- toIterator = MakeFunctionalPipe(function(iterator, self)
--     return function(t)
--         return iterator, t
--     end
-- end)

-- keys = MakeFunctionalPipe(function(iterator, self)
--     return function(t, k)
--         local nk, v = iterator(t, k)
--         if nk == nil then return nil, nil end

--         return nk, nk
--     end
-- end)

-- toSet = MakeFunctionalPipe(function(iterator, self)
--     return function(t)
--         local nt = {}
--         for k, v in iterator, t do
--             nt[v] = true
--         end
--         return nt
--     end
-- end)

-- max = MakeFunctionalPipe(function(iterator, self)
--     local selector = PopFn(self)
--     if selector then
--         return function(t)
--             local valueMax
--             for k, v in iterator, t do
--                 local value = selector(v)
--                 if not valueMax or value > valueMax then
--                     valueMax = value
--                 end
--             end
--             return valueMax
--         end
--     end
--     return function(t)
--         local valueMax
--         for k, v in iterator, t do
--             if not valueMax or v > valueMax then
--                 valueMax = v
--             end
--         end
--         return valueMax
--     end
-- end)

-- min = MakeFunctionalPipe(function(iterator, self)
--     local selector = PopFn(self)
--     if selector then
--         return function(t)
--             local valueMin
--             for k, v in iterator, t do
--                 local value = selector(v)
--                 if not valueMin or value < valueMin then
--                     valueMin = value
--                 end
--             end
--             return valueMin
--         end
--     end
--     return function(t)
--         local valueMin
--         for k, v in iterator, t do
--             if not valueMin or v < valueMin then
--                 valueMin = v
--             end
--         end
--         return valueMin
--     end
-- end)

-- contains = MakeFunctionalPipe(function(iterator, self)
--     local value = PopFn(self)
--     return function(t)
--         for k, v in iterator, t do
--             if value == v then
--                 return k
--             end
--         end
--         return nil
--     end
-- end)



-- ---@class IEnumerable<K, V>: {iter : (fun(t: {[K]:V}, k:K):(K,V)), tbl:table<K,V> }
-- IEnumerable = {
--     ---@generic K, V
--     ---@param self IEnumerable<K, V>
--     ---@return fun(t: {[K]:V}, k:K):(K,V)
--     ---@return table<K, V>
--     Iterate = function(self)
--         return self.iter, self.tbl
--     end,

--     ---@generic K, V
--     ---@param self IEnumerable<K, V>
--     ---@return table<K, V>
--     Enumerate = function(self)
--         local nt = {}
--         for k, v in self:Iterate() do
--             nt[k] = v
--         end
--         return nt
--     end
-- }



-- ---@class StatefulIterator
-- StatefulIterator = {
--     __call = function(self, t, key)
--         LOG(key)
--         return next(t, key)
--     end,
-- }

-- iter = setmetatable({}, StatefulIterator)


--[[
Functional library logic:

Functor - base interface to process tables and get tables in return.
Functors work with pipe operators to simplify understanding and maintainability of code.

Operations:
    Functor | Extender -> Functor
    table | Functor -> table
    Functor(table) -> iterator, table

Functor is made of 2 fields:
    iterator - function that iterates over input table, it is stateless
    transformer - function that takes table and returns table; used when result table can't be produced with iterators only (like distinct values or groupBy)

Some Functor | Extender will return function only. It is done to ensure that result is not iterable like in (min, max, first or last)
]]

---@alias IteratorFunc fun(t, k):(any, any)
---@alias TransformerFunc fun(t:table):table
---@alias EndFunc fun(t:table):any

---@class Functor
---@field iterator IteratorFunc
---@field transformer TransformerFunc


---@param f Functor
---@param iterator IteratorFunc
---@return Functor
local function ExtendFunctor(f, iterator)
    error "Not implemented"
end

---@param f Functor
---@param t table
local function ComputeFunctor(f, t)
    local nt = {}
    for k, v in f(t) do
        nt[k] = v
    end
    return nt
end

---@param l Functor | table
---@param r FunctorExtender | IteratorFunc
---@return  Functor | table | IteratorFunc
local function FunctorBORBase(l, r)
    local borl = getmetatable(l).__bor
    if borl and r.IsExtender then -- we are on left side called by right one
        return r:Extend(l)
    end
    local borr = getmetatable(r).__bor

    if borr then -- left is table, right is Functor
        return ComputeFunctor(r, l)
    end

    if borl then
        return ExtendFunctor(l, r)
    end
    error "Unexpected BOR for Functor"
end

---@class BaseFunctor : Functor
BaseFunctor = ClassSimple
{
    ---@param self any
    ---@param iterator any
    ---@param transformer any
    __init = function(self, iterator, transformer)
        self.iterator = iterator
        self.transformer = transformer
    end,

    ---@param self BaseFunctor
    ---@param t table
    ---@return IteratorFunc, table
    __call = function(self, t)
        local transformer = self.transformer
        if transformer then
            t = transformer(t)
        end
        return self.iterator, t
    end,

    iterator = next,
    __bor = FunctorBORBase,

    ---@param self BaseFunctor
    ---@param iterator IteratorFunc
    ---@param transformer TransformerFunc
    ---@return Functor
    ContinueFunctor = function(self, iterator, transformer)
        return BaseFunctor(iterator, transformer)
    end,

    ---@param self BaseFunctor
    ---@param endFunc EndFunc
    ---@return Functor
    EndFunctor = function(self, endFunc)
        return endFunc
    end,
}

---@class RangeFunctor : BaseFunctor
RangeFunctor = Class(BaseFunctor)
{
    __init = function(self, from, to, step)
        step = step or 1
        from = from - 1
        local endIndex = to - from
        BaseFunctor.__init(self, function(t, k)
            if k == nil then
                return 1, from + 1
            end
            k = k + step
            if k <= endIndex then
                return k, k + from
            end

            return nil, nil
        end)
    end
}

---@class FunctorExtender
---@field extender fun(self:FunctorExtender, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)
FunctorExtender = ClassSimple
{
    IsExtender = true,

    ---@param self FunctorExtender
    ---@param extender fun(self:FunctorExtender, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)
    __init = function(self, extender)
        self.extender = extender
    end,

    ---@param self FunctorExtender
    ---@param f Functor
    ---@return Functor
    Extend = function(self, f)
        local iterator, transformer = self:extender(f.iterator, f.transformer)
        return f:ContinueFunctor(iterator, transformer)
    end,
}
---@class FunctorEnder : FunctorExtender
---@field extender fun(self:FunctorExtender, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)
FunctorEnder = Class(FunctorExtender)
{
    ---@param self FunctorExtender
    ---@param f Functor
    ---@return Functor
    Extend = function(self, f)
        local iterator, transformer = self:extender(f.iterator, f.transformer)
        assert(transformer == nil, "Functor Ender mustn't have transformer")
        return f:EndFunctor(iterator)
    end,
}

---@class Functor1Arg
---@field [1] any
Functor1Arg = ClassSimple
{
    ---@param self Functor1Arg
    ---@param arg any
    ---@return Functor1Arg
    __call = function(self, arg)
        self[1] = arg
        return self
    end,

    ---@param self Functor1Arg
    ---@return any
    PopArg = function(self)
        local arg = self[1]
        self[1] = nil
        return arg
    end,
}

---@class Functor2Arg
---@field [1] any
---@field [2] any
Functor2Arg = ClassSimple
{
    ---@param self Functor2Arg
    ---@param arg1 any
    ---@param arg2 any
    ---@return Functor2Arg
    __call = function(self, arg1, arg2)
        self[1] = arg1
        self[2] = arg2
        return self
    end,

    ---@param self Functor2Arg
    ---@return any
    ---@return any
    PopArg = function(self)
        local arg1 = self[1]
        local arg2 = self[2]
        self[1] = nil
        self[2] = nil
        return arg1, arg2
    end,
}

---@class FunctorExtender1Arg : FunctorExtender, Functor1Arg
FunctorExtender1Arg = Class(FunctorExtender, Functor1Arg) {}
---@class FunctorEnder1Arg : FunctorEnder, Functor1Arg
FunctorEnder1Arg = Class(FunctorEnder, Functor1Arg) {}

---@class FunctorExtender2Arg : FunctorExtender, Functor2Arg
FunctorExtender2Arg = Class(FunctorExtender, Functor2Arg) {}
---@class FunctorEnder2Arg : FunctorEnder, Functor2Arg
FunctorEnder2Arg = Class(FunctorEnder, Functor2Arg) {}


---@type fun(extender: fun(self:FunctorExtender1Arg, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)):FunctorExtender1Arg
local FE1 = FunctorExtender1Arg
---@type fun(extender: fun(self:FunctorExtender2Arg, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)):FunctorExtender2Arg
local FE2 = FunctorExtender2Arg
---@type fun(extender: fun(self:FunctorExtender, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)):FunctorExtender
local FE0 = FunctorExtender

---@type fun(extender: fun(self:FunctorExtender, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)):FunctorEnder
local FEE = FunctorEnder
---@type fun(extender: fun(self:FunctorEnder1Arg, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)):FunctorEnder1Arg
local FEE1 = FunctorEnder1Arg
---@type fun(extender: fun(self:FunctorEnder2Arg, iterator:IteratorFunc, transformer:TransformerFunc):(IteratorFunc, TransformerFunc)):FunctorEnder2Arg
local FEE2 = FunctorEnder2Arg


---@class LightweightFunctor : BaseFunctor
---@field t table
LightweightFunctor = Class(BaseFunctor)
{
    __init = function(self, t)
        self.t = t
    end,

    ---@param self LightweightFunctor
    __call = function(self)
        local t = self.t
        local transformer = self.transformer
        if transformer then
            t = transformer(t)
        end
        return self.iterator, t
    end,

    ---@param self LightweightFunctor
    ---@param iterator IteratorFunc
    ---@param transformer TransformerFunc
    ---@return Functor
    ContinueFunctor = function(self, iterator, transformer)
        self.iterator = iterator
        self.transformer = transformer
        return self
    end,

    ---@param self LightweightFunctor
    ---@param endFunc EndFunc
    ---@return any
    EndFunctor = function(self, endFunc)
        return endFunc(self.t)
    end,

    ---@param self LightweightFunctor
    ---@return LightweightFunctor
    Clone = function(self)
        ---@type LightweightFunctor
        local lwf = LightweightFunctor(self.t)
        lwf.iterator = self.iterator
        lwf.transformer = self.transformer
        return lwf
    end
}
---@class LightweightFunctorExecutor : FunctorExtender
LightweightFunctorExecutor = ClassSimple(FunctorExtender)
{
    ---@param self LightweightFunctor
    ---@param f Functor
    Extend = function(self, f)
        for k, v in f() do
        end
    end,
}

Functors = {
    select = FE1(function(self, iterator, transformer)
        local selector = self:PopArg()
        if iscallable(selector) then
            return function(t, k)
                local nk, v = iterator(t, k)
                if nk == nil then return nil, nil end
                return nk, selector(v)
            end, transformer
        elseif type(selector) == "string" then
            return function(t, k)
                local nk, v = iterator(t, k)
                if nk == nil then return nil, nil end
                return nk, v[selector]
            end, transformer
        end

        error("Unsupported selector type " .. tostring(selector))
    end),

    where = FE1(function(self, iterator, transformer)
        local selector = self:PopArg()
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
        end, transformer
    end),

    keys = FE0(function(self, iterator, transformer)
        if transformer then
            return next, function(t)
                local nt = {}
                for k in iterator, transformer(t) do
                    TableInsert(nt, k)
                end
                return nt
            end
        end
        return next, function(t)
            local nt = {}
            for k in iterator, t do
                TableInsert(nt, k)
            end
            return nt
        end
    end),

    toSet = FE0(function(self, iterator, transformer)
        if transformer then
            return next, function(t)
                local nt = {}
                for k, v in iterator, transformer(t) do
                    nt[v] = true
                end
                return nt
            end
        end
        return next, function(t)
            local nt = {}
            for k, v in iterator, t do
                nt[v] = true
            end
            return nt
        end
    end),

    distinct = FE0(function(self, iterator, transformer)
        if transformer then
            return next, function(t)
                local nt = {}
                for _, v in iterator, transformer(t) do
                    nt[v] = true
                end
                local nta = {}
                for k in nt do
                    TableInsert(nta, k)
                end
                return nta
            end
        end
        return next, function(t)
            local nt = {}
            for _, v in iterator, t do
                nt[v] = true
            end
            local nta = {}
            for k in nt do
                TableInsert(nta, k)
            end
            return nta
        end
    end),

    foreach = FE1(function(self, iterator, transformer)
        local func = self:PopArg()
        return function(t, k)
            local nk, v = iterator(t, k)
            if nk == nil then return nil, nil end

            func(nk, v)

            return nk, v
        end, transformer
    end),


    -- reversed = FE0(function(self, iterator, transformer)
    --     return function(t, k)
    --         if k == nil then
    --             k = table.getn(t)
    --         else
    --             k = k - 1
    --         end
    --         if k == 0 then
    --             return nil, nil
    --         end
    --         local v = t[k]
    --         return k, v
    --     end, transformer
    -- end),

    pairs = BaseFunctor(),
    ipairs = BaseFunctor(nexti),
    range = RangeFunctor,


    sum = FEE(function(self, iterator, transformer)
        if transformer then
            return function(t)
                local s = 0
                for _, v in iterator, transformer(t) do
                    s = s + v
                end
                return s
            end
        end
        return function(t)
            local s = 0
            for _, v in iterator, t do
                s = s + v
            end
            return s
        end
    end),

    reduce = FEE2(function(self, iterator, transformer)
        local reducer, initial = self:PopArg()
        if transformer then
            return function(t)
                local r = initial
                for k, v in iterator, transformer(t) do
                    r = reducer(r, v)
                end
                return r
            end
        end
        return function(t)
            local r = initial
            for k, v in iterator, t do
                r = reducer(r, v)
            end
            return r
        end
    end),

    iterateOnCall = FEE(function(self, iterator, transformer)
        if transformer then
            return function(t)
                for k, v in iterator, transformer(t) do
                end
            end
        end
        return function(t)
            for k, v in iterator, t do
            end
        end
    end),

    applyTo = FEE1(function(self, iterator, transformer)
        local t = self:PopArg()
        if transformer then
            t = transformer(t)
        end
        for k, v in iterator, t do
        end
    end),

    execute = LightweightFunctorExecutor(),

    ---@type LightweightFunctor
    enumerate = LightweightFunctor,

    toFunction = FEE(function(self, iterator, transformer)
        if transformer then
            return function(t)
                return iterator, transformer(t)
            end
        end
        return function(t)
            return iterator, t
        end
    end)
}
