local math = math
local iscallable = iscallable
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')



---returns function of max between lazyvar or value
---@param var LazyVar<number>
---@param value number
---@return fun():number
local function _MaxVarOrValue(var, value)
    return function()
        return math.max(var(), LayoutHelpers.ScaleNumber(value))
    end
end

---returns function of max of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:LazyVar<number>, n2:number):(fun():number)
---@overload fun(n1:number, n2:LazyVar<number>):(fun():number)
---@param n1 LazyVar<number>
---@param n2 LazyVar<number>
---@return fun():number
function Max(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return math.max(n1(), n2()) end
    end
    if iscallable(n1) then return _MaxVarOrValue(n1, n2) end
    if iscallable(n2) then return _MaxVarOrValue(n2, n1) end
    return math.max(n1, n2)
end

---returns function of min between lazyvar or value
---@param var LazyVar<number>
---@param value number
---@return fun():number
local function _MinVarOrValue(var, value)
    return function()
        return math.min(var(), LayoutHelpers.ScaleNumber(value))
    end
end

---returns function of min of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:LazyVar<number>, n2:number):(fun():number)
---@overload fun(n1:number, n2:LazyVar<number>):(fun():number)
---@param n1 LazyVar<number>
---@param n2 LazyVar<number>
---@return fun():number
function Min(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return math.min(n1(), n2()) end
    end
    if iscallable(n1) then return _MinVarOrValue(n1, n2) end
    if iscallable(n2) then return _MinVarOrValue(n2, n1) end
    return math.min(n1, n2)
end

---returns function of difference of lazyvar and value
---@param var LazyVar<number>
---@param value number
---@return fun():number
local function _DiffVarAndValue(var, value)
    return function()
        return var() - LayoutHelpers.ScaleNumber(value)
    end
end

---returns function of difference of value and lazyvar
---@param var LazyVar<number>
---@param value number
---@return fun():number
local function _DiffValueAndVar(value, var)
    return function()
        return LayoutHelpers.ScaleNumber(value) - var()
    end
end

---returns function of difference of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:LazyVar<number>, n2:number):(fun():number)
---@overload fun(n1:number, n2:LazyVar<number>):(fun():number)
---@param n1 LazyVar<number>
---@param n2 LazyVar<number>
---@return fun():number
function Diff(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return n1() - n2() end
    end
    if iscallable(n1) then return _DiffVarAndValue(n1, n2) end
    if iscallable(n2) then return _DiffValueAndVar(n1, n2) end
    return n1 - n2
end

---returns function of sum of lazyvar and value
---@param var LazyVar<number>
---@param value number
---@return fun():number
local function _SumVarAndValue(var, value)
    return function()
        return var() + LayoutHelpers.ScaleNumber(value)
    end
end

---returns function of sum of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:LazyVar<number>, n2:number):(fun():number)
---@overload fun(n1:number, n2:LazyVar<number>):(fun():number)
---@param n1 LazyVar<number>
---@param n2 LazyVar<number>
---@return fun():number
function Sum(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return n1() + n2() end
    end
    if iscallable(n1) then return _SumVarAndValue(n1, n2) end
    if iscallable(n2) then return _SumVarAndValue(n2, n1) end
    return n1 + n2
end
