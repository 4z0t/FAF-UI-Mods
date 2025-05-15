local math = math
local iscallable = iscallable
local MathFloor = math.floor
local MathRound = MATH_IRound

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local defaultScaleFactor = LayoutHelpers.GetPixelScaleFactor()


---@alias NumberVar LazyVar<number>
---@alias NumberFunction fun():number | NumberVar

---@alias FunctionalNumber NumberFunction|number


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

---returns function of mult of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:NumberVar, n2:number):NumberFunction
---@overload fun(n1:number, n2:NumberVar):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@return NumberFunction
function Div(n1, n2)
    if iscallable(n1) and iscallable(n2) then
        return function() return n1() / n2() end
    end
    if iscallable(n1) then
        assert(n2 ~= 0, "Attempt to divide by zero")
        return function()
            return n1() / n2
        end
    end
    if iscallable(n2) then
        if n1 == 0 then
            return 0
        end
        return function()
            return n1 / n2()
        end
    end
    return n1 / n2
end

---returns function of max between lazyvar or value
---@param var NumberVar
---@param value number
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _MaxVarOrValue(var, value, scale)
    scale = scale or defaultScaleFactor
    if iscallable(scale) then
        return function() return math.max(var(), value * scale()) end
    end
    local offset = value * scale
    return function() return math.max(var(), offset) end
end

---returns function of max of two given lazyvars
---@overload fun(n1:number, n2:number, scale?:FunctionalNumber):number
---@overload fun(n1:NumberVar, n2:number, scale?:FunctionalNumber):NumberFunction
---@overload fun(n1:number, n2:NumberVar, scale?:FunctionalNumber):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
function Max(n1, n2, scale)
    if iscallable(n1) and iscallable(n2) then
        return function() return math.max(n1(), n2()) end
    end
    if iscallable(n1) then return _MaxVarOrValue(n1, n2, scale) end
    if iscallable(n2) then return _MaxVarOrValue(n2, n1, scale) end

    scale = scale or defaultScaleFactor
    return Mult(math.max(n1, n2), scale)
end

---returns function of min between lazyvar or value
---@param var NumberVar
---@param value number
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _MinVarOrValue(var, value, scale)
    scale = scale or defaultScaleFactor
    if iscallable(scale) then
        return function() return math.min(var(), value * scale()) end
    end
    local offset = value * scale
    return function() return math.min(var(), offset) end
end

---returns function of min of two given lazyvars
---@overload fun(n1:number, n2:number, scale?:FunctionalNumber):number
---@overload fun(n1:NumberVar, n2:number, scale?:FunctionalNumber):NumberFunction
---@overload fun(n1:number, n2:NumberVar, scale?:FunctionalNumber):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
function Min(n1, n2, scale)
    if iscallable(n1) and iscallable(n2) then
        return function() return math.min(n1(), n2()) end
    end
    if iscallable(n1) then return _MinVarOrValue(n1, n2, scale) end
    if iscallable(n2) then return _MinVarOrValue(n2, n1, scale) end

    scale = scale or defaultScaleFactor
    return Mult(math.min(n1, n2), scale)
end

---returns function of difference of lazyvar and value
---@param var NumberVar
---@param value number
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _DiffVarAndValue(var, value, scale)
    if value == 0 then return var end
    scale = scale or defaultScaleFactor
    if iscallable(scale) then
        return function() return var() - value * scale() end
    end
    local offset = value * scale
    return function() return var() - offset end
end

---returns function of difference of value and lazyvar
---@param var NumberVar
---@param value number
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _DiffValueAndVar(value, var, scale)
    if value == 0 then return function() return -var() end end
    scale = scale or defaultScaleFactor
    if iscallable(scale) then
        return function() return value * scale() - var() end
    end
    local offset = value * scale
    return function() return offset - var() end
end

---returns function of difference of two given lazyvars
---@overload fun(n1:number, n2:number, scale?:FunctionalNumber):number
---@overload fun(n1:NumberVar, n2:number, scale?:FunctionalNumber):NumberFunction
---@overload fun(n1:number, n2:NumberVar, scale?:FunctionalNumber):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
function Diff(n1, n2, scale)
    if iscallable(n1) and iscallable(n2) then
        return function() return n1() - n2() end
    end
    if iscallable(n1) then return _DiffVarAndValue(n1, n2, scale) end
    if iscallable(n2) then return _DiffValueAndVar(n1, n2, scale) end

    scale = scale or defaultScaleFactor
    return Mult(n1 - n2, scale)
end

---returns function of sum of lazyvar and value
---@param var NumberVar
---@param value number
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
local function _SumVarAndValue(var, value, scale)
    if value == 0 then return var end

    scale = scale or defaultScaleFactor
    if iscallable(scale) then
        return function() return var() + value * scale() end
    end
    local offset = value * scale
    return function() return var() + offset end
end

---returns function of sum of two given lazyvars
---@overload fun(n1:number, n2:number, scale?:FunctionalNumber):number
---@overload fun(n1:NumberVar, n2:number, scale?:FunctionalNumber):NumberFunction
---@overload fun(n1:number, n2:NumberVar, scale?:FunctionalNumber):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
function Sum(n1, n2, scale)
    if iscallable(n1) and iscallable(n2) then
        return function() return n1() + n2() end
    end
    if iscallable(n1) then return _SumVarAndValue(n1, n2, scale) end
    if iscallable(n2) then return _SumVarAndValue(n2, n1, scale) end

    scale = scale or defaultScaleFactor
    return Mult(n1 + n2, scale)
end

---returns function of floor of a given lazyvar
---@overload fun(n:number):number
---@overload fun(n:NumberVar):NumberFunction
---@param n NumberVar
---@return NumberFunction
function Floor(n)
    if iscallable(n) then
        return function() return MathFloor(n()) end
    end
    return MathFloor(n)
end

---returns function of floor of a given lazyvar
---@overload fun(n:number):number
---@overload fun(n:NumberVar):NumberFunction
---@param n NumberVar
---@return NumberFunction
function Round(n)
    if iscallable(n) then
        return function() return MathRound(n()) end
    end
    return MathRound(n)
end

function AtCenterOffset(base, baseLen, len, offset, scale)
    if offset == 0 then
        return function()
            return base() + 0.5 * (baseLen() - len())
        end
    end
    scale = scale or defaultScaleFactor
    if iscallable(scale) then
        return function()
            return base() + 0.5 * (baseLen() - len()) + offset * scale()
        end
    else
        local _offset = offset * scale
        return function()
            return base() + 0.5 * (baseLen() - len()) + _offset
        end
    end
end

---@overload fun(value:number):number
---@param value FunctionalNumber
---@return number
function Calculate(value)
    if iscallable(value) then
        return value()
    end
    return value
end
