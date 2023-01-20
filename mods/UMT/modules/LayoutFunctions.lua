local math = math
local iscallable = iscallable
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

---@alias NumberFunction fun():number
---@alias NumberVar LazyVar<number>

---returns function of max between lazyvar or value
---@param var NumberVar
---@param value number
---@return NumberFunction
local function _MaxVarOrValue(var, value)
    return function()
        return math.max(var(), LayoutHelpers.ScaleNumber(value))
    end
end

---returns function of max of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:NumberVar, n2:number):NumberFunction
---@overload fun(n1:number, n2:NumberVar):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@return NumberFunction
function Max(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return math.max(n1(), n2()) end
    end
    if iscallable(n1) then return _MaxVarOrValue(n1, n2) end
    if iscallable(n2) then return _MaxVarOrValue(n2, n1) end
    return math.max(n1, n2)
end

---returns function of min between lazyvar or value
---@param var NumberVar
---@param value number
---@return NumberFunction
local function _MinVarOrValue(var, value)
    return function()
        return math.min(var(), LayoutHelpers.ScaleNumber(value))
    end
end

---returns function of min of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:NumberVar, n2:number):NumberFunction
---@overload fun(n1:number, n2:NumberVar):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@return NumberFunction
function Min(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return math.min(n1(), n2()) end
    end
    if iscallable(n1) then return _MinVarOrValue(n1, n2) end
    if iscallable(n2) then return _MinVarOrValue(n2, n1) end
    return math.min(n1, n2)
end

---returns function of difference of lazyvar and value
---@param var NumberVar
---@param value number
---@return NumberFunction
local function _DiffVarAndValue(var, value)
    if value == 0 then return var end
    return function()
        return var() - LayoutHelpers.ScaleNumber(value)
    end
end

---returns function of difference of value and lazyvar
---@param var NumberVar
---@param value number
---@return NumberFunction
local function _DiffValueAndVar(value, var)
    if value == 0 then return var end
    return function()
        return LayoutHelpers.ScaleNumber(value) - var()
    end
end

---returns function of difference of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:NumberVar, n2:number):NumberFunction
---@overload fun(n1:number, n2:NumberVar):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@return NumberFunction
function Diff(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return n1() - n2() end
    end
    if iscallable(n1) then return _DiffVarAndValue(n1, n2) end
    if iscallable(n2) then return _DiffValueAndVar(n1, n2) end
    return n1 - n2
end

---returns function of sum of lazyvar and value
---@param var NumberVar
---@param value number
---@return NumberFunction
local function _SumVarAndValue(var, value)
    if value == 0 then return var end
    return function()
        return var() + LayoutHelpers.ScaleNumber(value)
    end
end

---returns function of sum of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:NumberVar, n2:number):NumberFunction
---@overload fun(n1:number, n2:NumberVar):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@return NumberFunction
function Sum(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return n1() + n2() end
    end
    if iscallable(n1) then return _SumVarAndValue(n1, n2) end
    if iscallable(n2) then return _SumVarAndValue(n2, n1) end
    return n1 + n2
end
