--[[*
 * File: ReUI.LINQ.lua
 * Author: 4z0t
 * Description: Provides functional approach to work with collections in Lua.
 *                _          _
 *               | |        | |
 *               | |        |_|
 *               | |  ____________   ___________________
 *               | | |__________  | |__________   ______|
 *               | |__________  | |  ________  | |
 *               |__________  | | | |  ____  | | |
 *                          | | | | | |    | | | |
 *                          | | | | | |____| | | |
 *                          | | | | |________| | |
 *                          | | | |__________  | |
 *                          |_| |____________| |_|
 *
 * Copyright (c) 2025 4z0t
 * All rights reserved.
 *
 * This software is provided "as is" without warranty of any kind, express or
 * implied, including but not limited to the warranties of merchantability,
 * fitness for a particular purpose and noninfringement. In no event shall the
 * authors or copyright holders be liable for any claim, damages or other
 * liability, whether in an action of contract, tort or otherwise, arising from,
 * out of or in connection with the software or the use or other dealings in the
 * software.
 *]]

function Main(isReplay)

    ---#region Upvalues
    local _setmetatable = setmetatable
    local _iscallable = iscallable
    local TableInsert = table.insert
    local _getmetatable = getmetatable
    local _next = next
    local _ipairs = ipairs
    ---@diagnostic disable-next-line:deprecated
    local TableGetN = table.getn
    ---@diagnostic disable-next-line:deprecated
    local unpack = unpack
    local TableSize = table.getsize
    local TableSort = table.sort
    local _type = type

    ---@generic T
    ---@param v T
    ---@return T
    local function Identity(v)
        return v
    end

    ---@generic K,V
    ---@param it fun(k: K):K,V
    ---@param k K
    ---@return K,V
    local function CallStatefulIterator(it, k)
        return it(k)
    end

    ---#endregion

    ---#region UtilityFunctions

    ---Creates an iterator that transforms each element using a selector function or key
    ---@generic K,V,R
    ---@param iterator fun(t:table, k:K):K,V @The source iterator
    ---@param transformer? fun(t:table):table<K,V> @Optional transformer function
    ---@param selector (fun(value:V, key:K):R)|string|number @The selector function or key to transform elements
    ---@return fun(t:table<K, V>, k:K):K,R @Iterator function that yields transformed elements
    ---@return (fun(t:table):table<K,V>)? @Optional transformer function
    local function SelectIterator(iterator, transformer, selector)
        local selectorType = _type(selector)
        if selectorType == "function" then
            return function(t, k)
                local v
                k, v = iterator(t, k)
                if k == nil then
                    return nil, nil
                end
                return k, selector(v, k)
            end, transformer
        elseif selectorType == "string" or selectorType == "number" then
            return function(t, k)
                local v
                k, v = iterator(t, k)
                if k == nil then
                    return nil, nil
                end
                return k, v[selector]
            end, transformer
        end
        error("Invalid selector type: " .. selectorType)
    end

    ---Creates an iterator that filters elements based on a condition
    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V @The source iterator
    ---@param transformer? fun(t:table):table<K,V> @Optional transformer function
    ---@param condition fun(value:V, key:K):boolean @The predicate function to test elements
    ---@return fun(t:table, k:K):K,V @Iterator function that yields filtered elements
    ---@return (fun(t:table):table<K,V>)? @Optional transformer function
    local function WhereIterator(iterator, transformer, condition)
        return function(t, k)
            local v
            repeat
                k, v = iterator(t, k)
                if k == nil then
                    return nil, nil
                end
            until condition(v, k)
            return k, v
        end, transformer
    end

    ---Creates an iterator that yields only the keys from the source iterator
    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V @The source iterator
    ---@param transformer? fun(t:table):table<K,V> @Optional transformer function
    ---@return fun(t:table, k:K):K,K @Iterator function that yields keys
    ---@return (fun(t:table):table<K,V>)? @Optional transformer function
    local function KeysIterator(iterator, transformer)
        return function(t, k)
            k = iterator(t, k)
            return k, k
        end, transformer
    end

    ---@generic T,K,V
    ---@param iterator fun(t:T, k:K):K,V
    ---@param t T
    ---@return fun(k:K):K,V
    local function CreateDistinctIterator(iterator, t)
        local seen
        ---@generic K
        ---@param sk K
        return function(sk)
            seen = seen or {}
            for k, v in iterator, t, sk do
                if not seen[v] then
                    seen[v] = true
                    return k, v
                end
            end
            seen = nil
            return nil, nil
        end
    end

    ---Creates an iterator that yields only distinct elements from the source iterator, keeping the original order
    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V @The source iterator
    ---@param transformer? fun(t:table):table<K,V> @Optional transformer function
    ---@return fun(table: V[], i?: integer):integer, V @Iterator function that yields distinct elements
    ---@return fun(t:table):V[] @Transformer function that returns array of distinct elements
    local function DistinctIterator(iterator, transformer)
        if transformer then
            return CallStatefulIterator, function(t)
                return CreateDistinctIterator(iterator, transformer(t))
            end
        end
        return CallStatefulIterator, function(t)
            return CreateDistinctIterator(iterator, t)
        end
    end

    ---Creates an iterator that executes a function for each element in the source iterator without modifying the elements
    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V @The source iterator
    ---@param transformer? fun(t:table):table<K,V> @Optional transformer function
    ---@param func fun(value:V, key:K) @Function to execute for each element
    ---@return fun(table: table<K,V>, key?: K):K, V @Iterator function that yields the original elements
    ---@return (fun(t:table):table<K,V>)? @Optional transformer function
    local function ForeachIterator(iterator, transformer, func)
        return function(t, k)
            local v
            k, v = iterator(t, k)
            if k == nil then
                return nil, nil
            end

            func(v, k)

            return k, v
        end, transformer
    end

    ---Creates a transformer that reverses the order of elements in the source iterator
    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V @The source iterator
    ---@param transformer? fun(t:table):table<K,V> @Optional transformer function
    ---@return fun(table: V[], i?: integer):integer, V @ipairs iterator
    ---@return fun(t:table):V[] @Transformer function that returns array of reversed elements
    local function ReverseTransformer(iterator, transformer)
        if transformer then
            -- Would be nice to have but rn it breaks some things
            -- if iterator == _ipairs then
            --     return ReverseIPairsIterator, function(t)
            --         t = transformer(t)
            --         return t, TableGetN(t) + 1
            --     end
            -- end

            return _ipairs, function(t)
                local nt = {}
                for _, v in iterator, transformer(t) do
                    TableInsert(nt, 1, v)
                end
                return nt
            end
        end

        -- if iterator == _ipairs then
        --     return ReverseIPairsIterator, function(t)
        --         return t, TableGetN(t) + 1
        --     end
        -- end

        return _ipairs, function(t)
            local nt = {}
            for _, v in iterator, t do
                TableInsert(nt, 1, v)
            end
            return nt
        end
    end

    ---@param iterator IteratorFunc
    ---@param outTable table
    ---@param outKey any
    ---@param inTable table
    ---@param inKey any
    ---@param index number?
    ---@return any # outKey
    ---@return table? # inTable
    ---@return any # inKey
    ---@return number? # index
    ---@return any # value
    local function IterateMany(iterator, outTable, outKey, inTable, inKey, index)
        if outKey == nil then
            outKey, inTable = iterator(outTable, outKey)
            inKey = nil
            index = 0
        end

        while true do
            local v
            inKey, v = _next(inTable, inKey)
            if inKey ~= nil then
                return outKey, inTable, inKey, index + 1, v
            end

            outKey, inTable = iterator(outTable, outKey)
            if outKey == nil then
                return nil, nil, nil, nil, nil
            end
        end
    end

    ---@param iterator IteratorFunc
    ---@param selector fun(any, any):table
    ---@param outTable table
    ---@param outKey any
    ---@param inTable table
    ---@param inKey any
    ---@param index number?
    ---@return any # outKey
    ---@return table? # inTable
    ---@return any # inKey
    ---@return number? # index
    ---@return any # value
    local function IterateManyWithSelector(iterator, selector, outTable, outKey, inTable, inKey, index)
        if outKey == nil then
            outKey, inTable = iterator(outTable, outKey)
            if outKey == nil then
                return nil, nil, nil, nil, nil
            end
            inTable = selector(inTable, outKey)
            inKey = nil
            index = 0
        end

        while true do
            local v
            inKey, v = _next(inTable, inKey)
            if inKey ~= nil then
                return outKey, inTable, inKey, index + 1, v
            end

            outKey, inTable = iterator(outTable, outKey)
            if outKey == nil then
                return nil, nil, nil, nil, nil
            end
            inTable = selector(inTable, outKey)
        end
    end

    ---@generic K,V,R
    ---@param iterator fun(t:table, k:K):K,V
    ---@param transformer? fun(t:table):table<K,V>
    ---@param selector? fun(value: V, key:K):R
    local function SelectManyIterator(iterator, transformer, selector)
        if selector then
            if transformer then
                return CallStatefulIterator, function(t)
                    t = transformer(t)

                    -- context of selectMany
                    local outerKey = nil
                    local inTable = nil
                    local innerKey = nil
                    ---@type number?
                    local curIndex = 0

                    return function(_)
                        local v
                        outerKey, inTable, innerKey, curIndex, v = IterateManyWithSelector(iterator, selector, t,
                            outerKey, inTable, innerKey, curIndex)
                        return curIndex, v
                    end
                end
            end

            return CallStatefulIterator, function(t)
                -- context of selectMany
                local outerKey = nil
                local inTable = nil
                local innerKey = nil
                ---@type number?
                local curIndex = 0

                return function(_)
                    local v
                    outerKey, inTable, innerKey, curIndex, v = IterateManyWithSelector(iterator, selector, t, outerKey,
                        inTable, innerKey, curIndex)
                    return curIndex, v
                end
            end
        end

        if transformer then
            return CallStatefulIterator, function(t)
                t = transformer(t)

                -- context of selectMany
                local outerKey = nil
                local inTable = nil
                local innerKey = nil
                ---@type number?
                local curIndex = 0

                return function(_)
                    local v
                    outerKey, inTable, innerKey, curIndex, v = IterateMany(iterator, t, outerKey, inTable, innerKey,
                        curIndex)
                    return curIndex, v
                end
            end
        end

        return CallStatefulIterator, function(t)
            -- context of selectMany
            local outerKey = nil
            local inTable = nil
            local innerKey = nil
            ---@type number?
            local curIndex = 0

            return function(_)
                local v
                outerKey, inTable, innerKey, curIndex, v = IterateMany(iterator, t, outerKey, inTable, innerKey,
                    curIndex)
                return curIndex, v
            end
        end
    end

    ---Creates a transformer that groups elements by a key selector function
    ---@generic K,V,R
    ---@param iterator fun(t:table, k:K):K,V @The source iterator
    ---@param transformer? fun(t:table):table<K,V> @Optional transformer function
    ---@param selector fun(value: V, key:K):R @Function to select the group key for each element
    ---@return fun(table: table<R,V[]>, key?: R):R, V[] @Iterator over the grouped elements
    ---@return fun(t:table):table<R,V[]> @Transformer function that returns table mapping group keys to arrays of elements
    local function GroupByTransformer(iterator, transformer, selector)
        if transformer then
            return _next, function(t)
                local r = {}
                for k, v in iterator, transformer(t) do
                    local nk = selector(v, k)
                    r[nk] = r[nk] or {}
                    TableInsert(r[nk], v)
                end
                return r
            end
        end

        return _next, function(t)
            local r = {}
            for k, v in iterator, t do
                local nk = selector(v, k)
                r[nk] = r[nk] or {}
                TableInsert(r[nk], v)
            end
            return r
        end
    end

    ---Creates a transformer that counts elements by a key selector function
    ---@generic K,V,R
    ---@param iterator fun(t:table, k:K):K,V @The source iterator
    ---@param transformer? fun(t:table):table<K,V> @Optional transformer function
    ---@param selector fun(value: V, key:K):R @Function to select the group key for each element
    ---@return fun(table: table<R, number>, key?: R):R, number @Iterator over the grouped elements
    ---@return fun(t:table):table<R, number> @Transformer function that returns table mapping group keys to arrays of elements
    local function CountByTransformer(iterator, transformer, selector)
        if transformer then
            return _next, function(t)
                local r = {}
                for k, v in iterator, transformer(t) do
                    local nk = selector(v, k)
                    r[nk] = (r[nk] or 0) + 1
                end
                return r
            end
        end

        return _next, function(t)
            local r = {}
            for k, v in iterator, t do
                local nk = selector(v, k)
                r[nk] = (r[nk] or 0) + 1
            end
            return r
        end
    end

    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V
    ---@param transformer? fun(t:table):table<K,V>
    ---@param comparer? fun(left: V, right: V): boolean
    ---@return fun(t: table):V?
    local function MinTerminator(iterator, transformer, comparer)
        if comparer then
            if transformer then
                return function(t)
                    local minValue = nil
                    for _, value in iterator, transformer(t) do
                        if minValue == nil or not comparer(minValue, value) then
                            minValue = value
                        end
                    end
                    return minValue
                end
            end
            return function(t)
                local minValue = nil
                for _, value in iterator, t do
                    if minValue == nil or not comparer(minValue, value) then
                        minValue = value
                    end
                end
                return minValue
            end
        end

        if transformer then
            return function(t)
                local minValue = nil
                for _, value in iterator, transformer(t) do
                    if minValue == nil or minValue > value then
                        minValue = value
                    end
                end
                return minValue
            end
        end
        return function(t)
            local minValue = nil
            for _, value in iterator, t do
                if minValue == nil or minValue > value then
                    minValue = value
                end
            end
            return minValue
        end
    end

    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V
    ---@param transformer? fun(t:table):table<K,V>
    ---@param comparer? fun(left: V, right: V): boolean
    ---@return fun(t: table):V?
    local function MaxTerminator(iterator, transformer, comparer)
        if comparer then
            if transformer then
                return function(t)
                    local maxValue = nil
                    for _, value in iterator, transformer(t) do
                        if maxValue == nil or comparer(maxValue, value) then
                            maxValue = value
                        end
                    end
                    return maxValue
                end
            end
            return function(t)
                local maxValue = nil
                for _, value in iterator, t do
                    if maxValue == nil or comparer(maxValue, value) then
                        maxValue = value
                    end
                end
                return maxValue
            end
        end

        if transformer then
            return function(t)
                local maxValue = nil
                for _, value in iterator, transformer(t) do
                    if maxValue == nil or maxValue < value then
                        maxValue = value
                    end
                end
                return maxValue
            end
        end
        return function(t)
            local maxValue = nil
            for _, value in iterator, t do
                if maxValue == nil or maxValue < value then
                    maxValue = value
                end
            end
            return maxValue
        end
    end

    ---@generic K,V,R
    ---@param iterator fun(t:table, k:K):K,V
    ---@param transformer? fun(t:table):table<K,V>
    ---@param reducer fun(result:R, value:V, key:K):R
    ---@param initial R
    ---@return fun(t:table):R
    local function ReduceTerminator(iterator, transformer, reducer, initial)
        if transformer then
            return function(t)
                local r = initial
                for k, v in iterator, transformer(t) do
                    r = reducer(r, v, k)
                end
                return r
            end
        end
        return function(t)
            local r = initial
            for k, v in iterator, t do
                r = reducer(r, v, k)
            end
            return r
        end
    end

    ---@generic V,R
    ---@param selector fun(value:V):R
    ---@param comparer? fun(left: R, right: R): boolean
    local function AscendingSortFunction(selector, comparer)
        if comparer then
            return function(a, b)
                return comparer(selector(a), selector(b))
            end
        end
        return function(a, b)
            return selector(a) < selector(b)
        end
    end

    ---@generic V,R
    ---@param selector fun(value:V):R
    ---@param comparer? fun(left: R, right: R): boolean
    local function DescendingSortFunction(selector, comparer)
        if comparer then
            return function(a, b)
                return not comparer(selector(b), selector(a))
            end
        end
        return function(a, b)
            return selector(b) > selector(a)
        end
    end

    ---@generic K,V,R
    ---@param iterator fun(t:table, k:K):K,V
    ---@param transformer? fun(t:table):table<K,V>
    ---@param sortFunc fun(left: V, right: V): boolean
    ---@return fun(table: V[], i?: integer):integer, V
    ---@return fun(t:table):V[]
    local function OrderByTransformer(iterator, transformer, sortFunc)
        if iterator == _ipairs then
            if transformer then
                return _ipairs, function(t)
                    local nt = transformer(t)
                    TableSort(nt, sortFunc)
                    return nt
                end
            end
            return _ipairs, function(t)
                TableSort(t, sortFunc)
                return t
            end
        end

        if transformer then
            return _ipairs, function(t)
                local nt = {}
                for _, v in iterator, transformer(t) do
                    TableInsert(nt, v)
                end
                TableSort(nt, sortFunc)
                return nt
            end
        end

        return _ipairs, function(t)
            local nt = {}
            for _, v in iterator, t do
                TableInsert(nt, v)
            end
            TableSort(nt, sortFunc)
            return nt
        end
    end

    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V
    ---@param transformer? fun(t:table):table<K,V>
    ---@return fun(table: table<V,true>, key?: V):V,true
    ---@return fun(t:table):table<V,true>
    local function AsSetTransformer(iterator, transformer)
        if transformer then
            return _next, function(t)
                local nt = {}
                for _, v in iterator, transformer(t) do
                    nt[v] = true
                end
                return nt
            end
        end
        return _next, function(t)
            local nt = {}
            for _, v in iterator, t do
                nt[v] = true
            end
            return nt
        end
    end

    ---#endregion

    ---#region Enumerator

    ---@class Enumerator
    ---@field iterator (fun(t:table, k:any):any, any)
    ---@field transformer (fun(t:table):table)
    local EnumeratorMeta = {}
    EnumeratorMeta.__index = EnumeratorMeta

    ---@generic K,V
    ---@param t table
    ---@return fun(t:table, k:K):K,V
    ---@return table
    function EnumeratorMeta:__call(t)
        local transformer = self.transformer
        -- local initial = nil
        -- if transformer then
        --     t, initial = transformer(t)
        -- end
        -- return self.iterator, t, initial
        if transformer then
            t = transformer(t)
        end
        return self.iterator, t
    end

    ---@generic K,V
    ---@param iterator fun(t:table, k:K):K,V
    ---@param transformer? fun(t:table):table<K,V>
    ---@return Enumerator
    local function EnumeratorCreate(iterator, transformer)
        return _setmetatable(
            {
                iterator = iterator,
                transformer = transformer or false
            },
            EnumeratorMeta)
    end

    EnumeratorMeta.Create = EnumeratorCreate

    ---Filters elements in sequence by given condition.
    ---@generic K,V
    ---@param condition fun(value:V, key:K):boolean
    ---@return Enumerator
    function EnumeratorMeta:Where(condition)
        if condition == nil then
            error("Enumerator:Where: condition is required")
        end
        return EnumeratorCreate(WhereIterator(self.iterator, self.transformer, condition))
    end

    ---Transforms elements in sequence with given selector.
    ---@generic K,V,R
    ---@param selector (fun(value:V, key:K):R)|string|number
    ---@return Enumerator
    function EnumeratorMeta:Select(selector)
        if selector == nil then
            error("Enumerator:Select: selector is required")
        end
        return EnumeratorCreate(SelectIterator(self.iterator, self.transformer, selector))
    end

    ---Transforms the sequence into an array of keys.
    ---@return Enumerator
    function EnumeratorMeta:Keys()
        return EnumeratorCreate(KeysIterator(self.iterator, self.transformer))
    end

    ---Transforms the sequence into an array of distinct elements.
    ---@return Enumerator
    function EnumeratorMeta:Distinct()
        return EnumeratorCreate(DistinctIterator(self.iterator, self.transformer))
    end

    ---Executes a callback for each element in the sequence.
    ---@generic K,V
    ---@param func fun(value:V, key:K)
    ---@return Enumerator
    function EnumeratorMeta:Foreach(func)
        if func == nil then
            error("Enumerator:Foreach: func is required")
        end
        return EnumeratorCreate(ForeachIterator(self.iterator, self.transformer, func))
    end

    ---Reverses the sequence.
    ---@return Enumerator
    function EnumeratorMeta:Reverse()
        return EnumeratorCreate(ReverseTransformer(self.iterator, self.transformer))
    end

    ---Groups elements in sequence by given selector.
    ---@generic K,V,R
    ---@param selector fun(value: V, key:K):R
    ---@return Enumerator
    function EnumeratorMeta:GroupBy(selector)
        if selector == nil then
            error("Enumerator:GroupBy: selector is required")
        end
        return EnumeratorCreate(GroupByTransformer(self.iterator, self.transformer, selector))
    end

    ---Counts elements in sequence by given selector.
    ---@generic K,V,R
    ---@param selector fun(value: V, key:K):R
    ---@return Enumerator
    function EnumeratorMeta:CountBy(selector)
        if selector == nil then
            error("Enumerator:CountBy: selector is required")
        end
        return EnumeratorCreate(CountByTransformer(self.iterator, self.transformer, selector))
    end

    ---@generic V,R
    ---@param selector fun(value: V):R
    ---@param comparer? fun(left:R, right:R):boolean
    ---@return Enumerator
    function EnumeratorMeta:OrderBy(selector, comparer)
        return EnumeratorCreate(OrderByTransformer(self.iterator, self.transformer,
            AscendingSortFunction(selector, comparer)))
    end

    ---@generic V,R
    ---@param selector fun(value: V):R
    ---@param comparer? fun(left:R, right:R):boolean
    ---@return Enumerator
    function EnumeratorMeta:OrderByDescending(selector, comparer)
        return EnumeratorCreate(OrderByTransformer(self.iterator, self.transformer,
            DescendingSortFunction(selector, comparer)))
    end

    ---@return Enumerator
    function EnumeratorMeta:AsSet()
        return EnumeratorCreate(AsSetTransformer(self.iterator, self.transformer))
    end

    ---@generic R:table
    ---@generic K,V
    ---@param selector? fun(value:V, key:K): R
    ---@return Enumerator
    function EnumeratorMeta:SelectMany(selector)
        return EnumeratorCreate(SelectManyIterator(self.iterator, self.transformer, selector))
    end

    ---@generic K,V,Arg
    ---@param fn fun(iterator:(fun(t:table, k:K):K,V),transformer?:(fun(t:table):table<K,V>),...:Arg):((fun(table: table<K,V>, key?: K):K, V),(fun(t:table):table<K,V>)?)
    ---@param ... Arg
    ---@return Enumerator
    function EnumeratorMeta:Use(fn, ...)
        return EnumeratorCreate(fn(self.iterator, self.transformer, unpack(arg)))
    end

    ---Executes a callback for each element in the sequence.
    ---@generic K,V
    ---@param callback fun(value:V, key:K)
    ---@return fun(t:table)
    function EnumeratorMeta:Execute(callback)
        if callback == nil then
            error("Enumerator:Execute: callback is required")
        end

        local iterator, transformer = self.iterator, self.transformer
        if transformer then
            return function(t)
                for k, v in iterator, transformer(t) do
                    callback(v, k)
                end
            end
        end
        return function(t)
            for k, v in iterator, t do
                callback(v, k)
            end
        end
    end

    ---@generic V
    ---@param comparer? fun(left:V, right:V):boolean
    ---@return fun(t: table):V
    function EnumeratorMeta:Min(comparer)
        return MinTerminator(self.iterator, self.transformer, comparer)
    end

    ---@generic V
    ---@param comparer? fun(left:V, right:V):boolean
    ---@return fun(t: table):V
    function EnumeratorMeta:Max(comparer)
        return MaxTerminator(self.iterator, self.transformer, comparer)
    end

    ---@generic K,V
    ---@param condition fun(value:V, key:K):boolean
    ---@return fun(t:table):boolean
    function EnumeratorMeta:All(condition)
        local iterator, transformer = self.iterator, self.transformer
        if condition then
            if transformer then
                return function(t)
                    for k, value in iterator, transformer(t) do
                        if not condition(value, k) then
                            return false
                        end
                    end
                    return true
                end
            end

            return function(t)
                for k, value in iterator, t do
                    if not condition(value, k) then
                        return false
                    end
                end
                return true
            end
        end

        if transformer then
            return function(t)
                for _, value in iterator, transformer(t) do
                    if not value then
                        return false
                    end
                end
                return true
            end
        end

        return function(t)
            for _, value in iterator, t do
                if not value then
                    return false
                end
            end
            return true
        end
    end

    ---@generic K,V
    ---@param condition fun(value:V, key:K):boolean
    ---@return fun(t:table):boolean
    function EnumeratorMeta:Any(condition)
        local iterator, transformer = self.iterator, self.transformer
        if condition then
            if transformer then
                return function(t)
                    for k, value in iterator, transformer(t) do
                        if condition(value, k) then
                            return true
                        end
                    end
                    return false
                end
            end

            return function(t)
                for k, value in iterator, t do
                    if condition(value, k) then
                        return true
                    end
                end
                return false
            end
        end

        if transformer then
            return function(t)
                for _, value in iterator, transformer(t) do
                    if value then
                        return true
                    end
                end
                return false
            end
        end

        return function(t)
            for _, value in iterator, t do
                if value then
                    return true
                end
            end
            return false
        end
    end

    ---@generic K,V
    ---@param condition? fun(value:V, key:K):boolean
    ---@return fun(t:table):V?
    function EnumeratorMeta:First(condition)
        local iterator, transformer = self.iterator, self.transformer
        if condition then
            if transformer then
                return function(t)
                    for k, value in iterator, transformer(t) do
                        if condition(value, k) then
                            return value
                        end
                    end
                    return nil
                end
            end

            return function(t)
                for k, value in iterator, t do
                    if condition(value, k) then
                        return value
                    end
                end
                return nil
            end
        end

        if transformer then
            return function(t)
                for _, value in iterator, transformer(t) do
                    return value
                end
                return nil
            end
        end

        return function(t)
            for _, value in iterator, t do
                return value
            end
            return nil
        end
    end

    ---@generic K,V
    ---@param condition? fun(value:V, key:K):boolean
    ---@return fun(t:table):V?
    function EnumeratorMeta:Last(condition)
        local iterator, transformer = self.iterator, self.transformer
        if condition then
            if transformer then
                return function(t)
                    local result = nil
                    for k, value in iterator, transformer(t) do
                        if condition(value, k) then
                            result = value
                        end
                    end
                    return result
                end
            end

            return function(t)
                local result = nil
                for k, value in iterator, t do
                    if condition(value, k) then
                        result = value
                    end
                end
                return result
            end
        end

        if transformer then
            return function(t)
                local result = nil
                for _, value in iterator, transformer(t) do
                    result = value
                end
                return result
            end
        end

        return function(t)
            local result = nil
            for _, value in iterator, t do
                result = value
            end
            return result
        end
    end

    ---@generic K,V,R
    ---@param reducer fun(result:R, value:V, key:K):R
    ---@param initial R
    ---@return fun(t:table):R
    function EnumeratorMeta:Reduce(reducer, initial)
        if reducer == nil then
            error("Enumerator:Reduce: reducer is required")
        end
        return ReduceTerminator(self.iterator, self.transformer, reducer, initial)
    end

    ---@generic R
    ---@return fun(t:table):R?
    function EnumeratorMeta:Average()
        local iterator, transformer = self.iterator, self.transformer
        if transformer then
            return function(t)
                local r, n = 0, 0
                for _, v in iterator, transformer(t) do
                    r = r + v
                    n = n + 1
                end
                if n == 0 then
                    return nil
                end
                return r / n
            end
        end
        return function(t)
            local r, n = 0, 0
            for _, v in iterator, t do
                r = r + v
                n = n + 1
            end
            if n == 0 then
                return nil
            end
            return r / n
        end
    end

    ---@generic K,V
    ---@param condition? fun(value:V, key:K):boolean
    ---@return fun(t:table):integer
    function EnumeratorMeta:Count(condition)
        local iterator, transformer = self.iterator, self.transformer
        if condition then
            if transformer then
                return function(t)
                    local n = 0
                    for k, v in iterator, transformer(t) do
                        if condition(v, k) then
                            n = n + 1
                        end
                    end
                    return n
                end
            end

            return function(t)
                local n = 0
                for k, v in iterator, t do
                    if condition(v, k) then
                        n = n + 1
                    end
                end
                return n
            end
        end

        if transformer then
            if iterator == _ipairs then
                return function(t)
                    t = transformer(t)
                    return TableGetN(t)
                end
            end
            if iterator == _next then
                return function(t)
                    t = transformer(t)
                    return TableSize(t)
                end
            end

            return function(t)
                local n = 0
                for _ in iterator, transformer(t) do
                    n = n + 1
                end
                return n
            end
        end

        if iterator == _ipairs then
            return TableGetN
        end
        if iterator == _next then
            return TableSize
        end

        return function(t)
            local n = 0
            for _ in iterator, t do
                n = n + 1
            end
            return n
        end
    end

    ---@return fun(t:table):number
    function EnumeratorMeta:Sum()
        local iterator, transformer = self.iterator, self.transformer
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
    end

    ---@generic K,V
    ---@return fun(t:table, value:V):K?
    function EnumeratorMeta:Contains()
        local iterator, transformer = self.iterator, self.transformer
        if transformer then
            return function(t, value)
                for k, v in iterator, transformer(t) do
                    if v == value then
                        return k
                    end
                end
                return nil
            end
        end
        return function(t, value)
            for k, v in iterator, t do
                if v == value then
                    return k
                end
            end
            return nil
        end
    end

    ---Ensures that the enumerable contains a single value with given condition, otherwise returns nil
    ---@generic K,V
    ---@param condition? fun(value:V, key:K):boolean
    ---@return fun(t:table):V?
    function EnumeratorMeta:Single(condition)
        local iterator, transformer = self.iterator, self.transformer
        if condition then
            if transformer then
                return function(t)
                    local value = nil
                    for k, v in iterator, transformer(t) do
                        if condition(v, k) then
                            if value ~= nil then
                                return nil
                            end
                            value = v
                        end
                    end
                    return value
                end
            end

            return function(t)
                local value = nil
                for k, v in iterator, t do
                    if condition(v, k) then
                        if value ~= nil then
                            return nil
                        end
                        value = v
                    end
                end
                return value
            end
        end

        if transformer then
            return function(t)
                local value = nil
                for k, v in iterator, transformer(t) do
                    if value ~= nil then
                        return nil
                    end
                    value = v
                end
                return value
            end
        end

        return function(t)
            local value = nil
            for k, v in iterator, t do
                if value ~= nil then
                    return nil
                end
                value = v
            end
            return value
        end
    end

    ---@return fun(t:table):((fun(t:table, k:any):any, any), table)
    function EnumeratorMeta:ToFunction()
        local iterator, transformer = self.iterator, self.transformer
        if transformer then
            return function(t)
                return iterator, transformer(t)
            end
        end
        return function(t)
            return iterator, t
        end
    end

    ---@return fun(t:table):(fun(_, k:any):any, any)
    function EnumeratorMeta:ToIterator()
        local iterator, transformer = self.iterator, self.transformer
        if transformer then
            return function(t)
                t = transformer(t)
                return function(_, k)
                    return iterator(t, k)
                end
            end
        end
        return function(t)
            return function(_, k)
                return iterator(t, k)
            end
        end
    end

    ---@generic V
    ---@return fun(t: table):V[]
    function EnumeratorMeta:ToArray()
        local iterator, transformer = self.iterator, self.transformer
        if iterator == _ipairs then
            return transformer or Identity
        end
        if transformer then
            return function(t)
                local nt = {}
                for _, v in iterator, transformer(t) do
                    TableInsert(nt, v)
                end
                return nt
            end
        end
        return function(t)
            local nt = {}
            for _, v in iterator, t do
                TableInsert(nt, v)
            end
            return nt
        end
    end

    ---@generic K,V,KR,KV
    ---@param selector? fun(key:K, value:V):(KR,KV)
    ---@return fun(t:table):table
    function EnumeratorMeta:ToTable(selector)
        local iterator, transformer = self.iterator, self.transformer
        if selector then
            if transformer then
                return function(t)
                    local nt = {}
                    for k, v in iterator, transformer(t) do
                        local nk, nv = selector(k, v)
                        nt[nk] = nv
                    end
                    return nt
                end
            end
            return function(t)
                local nt = {}
                for k, v in iterator, t do
                    local nk, nv = selector(k, v)
                    nt[nk] = nv
                end
                return nt
            end
        end
        if iterator == _next or iterator == _ipairs then
            return transformer or Identity
        end
        if transformer then
            return function(t)
                local nt = {}
                for k, v in iterator, transformer(t) do
                    nt[k] = v
                end
                return nt
            end
        end
        return function(t)
            local nt = {}
            for k, v in iterator, t do
                nt[k] = v
            end
            return nt
        end
    end

    ---@generic T
    ---@return fun(t:table):table<T, boolean>
    function EnumeratorMeta:ToSet()
        local iterator, transformer = self.iterator, self.transformer
        if transformer then
            return function(t)
                local nt = {}
                for _, v in iterator, transformer(t) do
                    nt[v] = true
                end
                return nt
            end
        end
        return function(t)
            local nt = {}
            for _, v in iterator, t do
                nt[v] = true
            end
            return nt
        end
    end

    ---#endregion

    ---#region Enumerable

    ---@class Enumerable
    ---@field t table
    ---@field iterator (fun(t:table, k:any):any, any)
    ---@field transformer (fun(t:table):table)
    local EnumerableMeta = {}
    EnumerableMeta.__index = EnumerableMeta

    ---@generic K,V,R
    ---@param t table
    ---@param iterator? fun(t:table, k:K):K,V
    ---@param transformer? fun(t:table):table<K,V>
    ---@return Enumerable
    local function EnumerableCreate(t, iterator, transformer)
        return _setmetatable(
            {
                t = t,
                iterator = iterator or _ipairs,
                transformer = transformer or false
            },
            EnumerableMeta)
    end

    EnumerableMeta.Enumerate = EnumerableCreate

    ---@generic K,V
    ---@return fun(t:table, k:K):K,V
    ---@return table
    ---@return any
    function EnumerableMeta:__call()
        local t, transformer = self.t, self.transformer
        -- local initial = nil
        -- if transformer then
        --     t, initial = transformer(t)
        -- end
        -- return self.iterator, t, initial
        if transformer then
            t = transformer(t)
        end
        return self.iterator, t
    end

    ---@return Enumerable
    function EnumerableMeta:Clone()
        return EnumerableCreate(self.t, self.iterator, self.transformer)
    end

    ---@generic K,V
    ---@param condition fun(value:V, key:K):boolean
    ---@return Enumerable
    function EnumerableMeta:Where(condition)
        if condition == nil then
            error("Enumerable:Where: condition is required")
        end
        self.iterator, self.transformer = WhereIterator(self.iterator, self.transformer, condition)
        return self
    end

    ---@generic K,V,R
    ---@param selector (fun(value:V, key:K):R)|string|number
    ---@return Enumerable
    function EnumerableMeta:Select(selector)
        if selector == nil then
            error("Enumerable:Select: selector is required")
        end
        self.iterator, self.transformer = SelectIterator(self.iterator, self.transformer, selector)
        return self
    end

    ---@return Enumerable
    function EnumerableMeta:Keys()
        self.iterator, self.transformer = KeysIterator(self.iterator, self.transformer)
        return self
    end

    ---@return Enumerable
    function EnumerableMeta:Distinct()
        self.iterator, self.transformer = DistinctIterator(self.iterator, self.transformer)
        return self
    end

    ---@generic K,V
    ---@param func fun(value:V, key:K)
    ---@return Enumerable
    function EnumerableMeta:Foreach(func)
        if func == nil then
            error("Enumerable:Foreach: func is required")
        end
        self.iterator, self.transformer = ForeachIterator(self.iterator, self.transformer, func)
        return self
    end

    ---@return Enumerable
    function EnumerableMeta:Reverse()
        self.iterator, self.transformer = ReverseTransformer(self.iterator, self.transformer)
        return self
    end

    ---@generic K,V,R
    ---@param selector fun(value: V, key:K):R
    ---@return Enumerable
    function EnumerableMeta:GroupBy(selector)
        if selector == nil then
            error("Enumerable:GroupBy: selector is required")
        end
        self.iterator, self.transformer = GroupByTransformer(self.iterator, self.transformer, selector)
        return self
    end

    ---@generic K,V,R
    ---@param selector fun(value: V, key:K):R
    ---@return Enumerable
    function EnumerableMeta:CountBy(selector)
        if selector == nil then
            error("Enumerable:CountBy: selector is required")
        end
        self.iterator, self.transformer = CountByTransformer(self.iterator, self.transformer, selector)
        return self
    end

    ---@generic V,R
    ---@param selector fun(value: V):R
    ---@param comparer? fun(left:R, right:R):boolean
    ---@return Enumerable
    function EnumerableMeta:OrderBy(selector, comparer)
        self.iterator, self.transformer = OrderByTransformer(self.iterator, self.transformer,
            AscendingSortFunction(selector, comparer))
        return self
    end

    ---@generic V,R
    ---@param selector fun(value: V):R
    ---@param comparer? fun(left:R, right:R):boolean
    ---@return Enumerable
    function EnumerableMeta:OrderByDescending(selector, comparer)
        self.iterator, self.transformer = OrderByTransformer(self.iterator, self.transformer,
            DescendingSortFunction(selector, comparer))
        return self
    end

    ---@return Enumerable
    function EnumerableMeta:AsSet()
        self.iterator, self.transformer = AsSetTransformer(self.iterator, self.transformer)
        return self
    end

    ---@generic R:table
    ---@generic K,V
    ---@param selector? fun(value:V, key:K): R
    ---@return Enumerable
    function EnumerableMeta:SelectMany(selector)
        self.iterator, self.transformer = SelectManyIterator(self.iterator, self.transformer, selector)
        return self
    end

    ---@generic K,V,Arg
    ---@param fn fun(iterator:(fun(t:table, k:K):K,V),transformer?:(fun(t:table):table<K,V>),...:Arg):((fun(table: table<K,V>, key?: K):K, V),(fun(t:table):table<K,V>)?)
    ---@param ... Arg
    ---@return Enumerable
    function EnumerableMeta:Use(fn, ...)
        self.iterator, self.transformer = fn(self.iterator, self.transformer, unpack(arg))
        return self
    end

    ---#region Enumerable Terminators

    ---@generic K,V
    ---@param callback fun(value:V, key:K)
    function EnumerableMeta:Execute(callback)
        if callback == nil then
            error("Enumerable:Execute: callback is required")
        end

        -- local t, initial, iterator, transformer = self.t, nil, self.iterator, self.transformer
        -- if transformer then
        --     t, initial = transformer(t)
        -- end

        -- for k, v in iterator, t, initial do
        --     callback(v, k)
        -- end

        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        for k, v in iterator, t do
            callback(v, k)
        end
    end

    ---Creates a new Enumerable with the current sequence cached into a table.
    ---This is useful when you want to iterate over the same sequence multiple times without re-evaluating transformations.
    ---@return Enumerable @A new Enumerable containing the cached sequence
    function EnumerableMeta:Cache()
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end
        return EnumerableCreate(t, iterator)
    end

    ---@generic K,V
    ---@param condition? fun(value:V, key:K):boolean
    ---@return V?
    function EnumerableMeta:First(condition)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        if condition then
            for k, v in iterator, t do
                if condition(v, k) then
                    return v
                end
            end
            return nil
        end

        for _, v in iterator, t do
            return v
        end
        return nil
    end

    ---@generic K,V
    ---@param condition? fun(value:V, key:K):boolean
    ---@return V?
    function EnumerableMeta:Last(condition)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        if condition then
            local result = nil
            for k, v in iterator, t do
                if condition(v, k) then
                    result = v
                end
            end
            return result
        end

        local result = nil
        for _, v in iterator, t do
            result = v
        end
        return result
    end

    ---@generic R
    ---@return R?
    function EnumerableMeta:Average()
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        local r, n = 0, 0
        for _, v in iterator, t do
            r = r + v
            n = n + 1
        end
        if n == 0 then
            return nil
        end
        return r / n
    end

    ---@generic K,V
    ---@param condition? fun(value:V, key:K):boolean
    ---@return integer
    function EnumerableMeta:Count(condition)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        if condition then
            local n = 0
            for k, v in iterator, t do
                if condition(v, k) then
                    n = n + 1
                end
            end
            return n
        end

        if iterator == _ipairs then
            return TableGetN(t)
        end
        if iterator == _next then
            ---@diagnostic disable-next-line:return-type-mismatch
            return TableSize(t)
        end

        local n = 0
        for _ in iterator, t do
            n = n + 1
        end
        return n
    end

    ---@generic K,V,R
    ---@param reducer fun(result:R, value:V, key:K):R
    ---@param initial R
    ---@return R
    function EnumerableMeta:Reduce(reducer, initial)
        if reducer == nil then
            error("Enumerable:Reduce: reducer is required")
        end
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        local r = initial
        for k, v in iterator, t do
            r = reducer(r, v, k)
        end
        return r
    end

    ---@return number
    function EnumerableMeta:Sum()
        local t, iterator, transformer = self.t, self.iterator, self.transformer

        if transformer then
            t = transformer(t)
        end

        local s = 0
        for _, v in iterator, t do
            s = s + v
        end
        return s
    end

    ---@generic K,V
    ---@param value V
    ---@return K?
    function EnumerableMeta:Contains(value)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        for k, v in iterator, t do
            if v == value then
                return k
            end
        end
        return nil
    end

    ---Ensures that the enumerable contains a single value with given condition, otherwise returns nil
    ---@generic K,V
    ---@param condition? fun(value:V, key:K):boolean
    ---@return V?
    function EnumerableMeta:Single(condition)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        if condition then
            local value = nil
            for k, v in iterator, t do
                if condition(v, k) then
                    if value ~= nil then
                        return nil
                    end
                    value = v
                end
            end
            return value
        end

        local value = nil
        for k, v in iterator, t do
            if value ~= nil then
                return nil
            end
            value = v
        end
        return value
    end

    ---@generic V
    ---@param comparer? fun(left:V, right:V):boolean
    ---@return V?
    function EnumerableMeta:Min(comparer)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        if comparer then
            local minValue = nil
            for _, value in iterator, t do
                if minValue == nil or not comparer(minValue, value) then
                    minValue = value
                end
            end
            return minValue
        end

        local minValue = nil
        for _, value in iterator, t do
            if minValue == nil or minValue > value then
                minValue = value
            end
        end
        return minValue
    end

    ---@generic V
    ---@param comparer? fun(left:V, right:V):boolean
    ---@return V?
    function EnumerableMeta:Max(comparer)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        if comparer then
            local maxValue = nil
            for _, value in iterator, t do
                if maxValue == nil or comparer(maxValue, value) then
                    maxValue = value
                end
            end
            return maxValue
        end

        local maxValue = nil
        for _, value in iterator, t do
            if maxValue == nil or maxValue < value then
                maxValue = value
            end
        end
        return maxValue
    end

    ---@generic V,K
    ---@param condition? fun(value:V, key:K):boolean
    ---@return boolean
    function EnumerableMeta:All(condition)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end
        if condition then
            for k, v in iterator, t do
                if not condition(v, k) then
                    return false
                end
            end
            return true
        end
        for _, v in iterator, t do
            if not v then
                return false
            end
        end
        return true
    end

    ---@generic V,K
    ---@param condition? fun(value:V, key:K):boolean
    ---@return boolean
    function EnumerableMeta:Any(condition)
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end
        if condition then
            for k, v in iterator, t do
                if condition(v, k) then
                    return true
                end
            end
            return false
        end
        for _, v in iterator, t do
            if v then
                return true
            end
        end
        return false
    end

    ---@generic V
    ---@return V[]
    function EnumerableMeta:ToArray()
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end

        if iterator == _ipairs then
            return t
        end

        local nt = {}
        for _, v in iterator, t do
            TableInsert(nt, v)
        end
        return nt
    end

    ---@generic K,V,KR,KV
    ---@param selector? fun(key:K, value:V):(KR,KV)
    ---@return table
    function EnumerableMeta:ToTable(selector)
        local t, iterator, transformer = self.t, self.iterator, self.transformer

        if transformer then
            t = transformer(t)
        end

        if selector then
            local nt = {}
            for k, v in iterator, t do
                local nk, nv = selector(k, v)
                nt[nk] = nv
            end
            return nt
        end

        if iterator == _next or iterator == _ipairs then
            return t
        end

        local nt = {}
        for k, v in iterator, t do
            nt[k] = v
        end
        return nt
    end

    ---@generic T
    ---@return table<T, true>
    function EnumerableMeta:ToSet()
        local t, iterator, transformer = self.t, self.iterator, self.transformer
        if transformer then
            t = transformer(t)
        end
        local nt = {}
        for _, v in iterator, t do
            nt[v] = true
        end
        return nt
    end

    ---#endregion

    ---Creates Enumerable based on Enumerator and given table
    ---@param t table
    ---@return Enumerable
    function EnumeratorMeta:Enumerate(t)
        return EnumerableCreate(t, self.iterator, self.transformer)
    end

    ---#endregion

    return {
        PairsEnumerator = EnumeratorMeta.Create(_next),
        IPairsEnumerator = EnumeratorMeta.Create(_ipairs),
        Enumerate = EnumerableMeta.Enumerate,

        Enumerable = EnumerableMeta,
        Enumerator = EnumeratorMeta,
    }
end
