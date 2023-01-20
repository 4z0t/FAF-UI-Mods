local math = math
local iscallable = iscallable
local MathFloor = math.floor

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local defaultScaleFactor = LayoutHelpers.GetPixelScaleFactor()


---@alias NumberFunction fun():number
---@alias NumberVar LazyVar<number>


---returns function of max between lazyvar or value
---@param var NumberVar
---@param value number
---@param scale number? # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _MaxVarOrValue(var, value, scale)
    scale = scale or defaultScaleFactor
    return function() return MathFloor(math.max(var(), value * scale)) end
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
---@param scale number? # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _MinVarOrValue(var, value, scale)
    scale = scale or defaultScaleFactor
    return function() return MathFloor(math.min(var(), value * scale)) end
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
---@param scale number? # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _DiffVarAndValue(var, value, scale)
    if value == 0 then return var end
    scale = scale or defaultScaleFactor
    return function() return MathFloor(var() - value * scale) end
end

---returns function of difference of value and lazyvar
---@param var NumberVar
---@param value number
---@param scale number? # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _DiffValueAndVar(value, var, scale)
    if value == 0 then return var end
    scale = scale or defaultScaleFactor
    return function() return MathFloor(value * scale - var()) end
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
---@param scale number? # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _SumVarAndValue(var, value, scale)
    if value == 0 then return var end

    scale = scale or defaultScaleFactor
    return function() return MathFloor(var() + value * scale) end
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

---returns function of mult of lazyvar and value
---@param var NumberVar
---@param value number
---@return NumberFunction
local function _MultVarAndValue(var, value)
    if value == 0 then return 0 end
    return function() return var() * value end
end

---returns function of mult of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:NumberVar, n2:number):NumberFunction
---@overload fun(n1:number, n2:NumberVar):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@return NumberFunction
function Mult(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return n1() * n2() end
    end
    if iscallable(n1) then return _MultVarAndValue(n1, n2) end
    if iscallable(n2) then return _MultVarAndValue(n2, n1) end
    return n1 * n2
end
