---@meta

---@class ReUI.UI : ReUI.Module
ReUI.UI = {}

---Global table with controls from mods
---@class ReUI.UI.Global
ReUI.UI.Global = {}

---@type ReUI.UI.Layouter | fun(scale?:NumberVar):ReUI.UI.Layouter
ReUI.UI.Layouter = ...

---@type ReUI.UI.Layouter | fun(scale?:NumberVar):ReUI.UI.Layouter
ReUI.UI.FloorLayouter = ...

---@type ReUI.UI.Layouter | fun(scale?:NumberVar):ReUI.UI.Layouter
ReUI.UI.RoundLayouter = ...

---@type ReUI.UI.Layouter
ReUI.UI.FloorLayoutFor = ...

---@type ReUI.UI.Layouter
ReUI.UI.RoundLayoutFor = ...

---@type ReUI.UI.Layoutable
ReUI.UI.Layoutable = ...

---@type ReUI.UI.BaseLayout
ReUI.UI.BaseLayout = ...


---Collection of functions for working with lazy variables and layout calculations
---@class ReUI.UI.LayoutFunctions
ReUI.UI.LayoutFunctions = {}

---Returns function of mult of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:NumberVar, n2:number):NumberFunction
---@overload fun(n1:number, n2:NumberVar):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Mult(n1, n2)
end

---Returns function of div of two given lazyvars
---@overload fun(n1:number, n2:number):number
---@overload fun(n1:NumberVar, n2:number):NumberFunction
---@overload fun(n1:number, n2:NumberVar):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Div(n1, n2)
end

---Returns function of sum of two given lazyvars
---@overload fun(n1:number, n2:number, scale?:FunctionalNumber):number
---@overload fun(n1:NumberVar, n2:number, scale?:FunctionalNumber):NumberFunction
---@overload fun(n1:number, n2:NumberVar, scale?:FunctionalNumber):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Sum(n1, n2, scale)
end

---Returns function of diff of two given lazyvars
---@overload fun(n1:number, n2:number, scale?:FunctionalNumber):number
---@overload fun(n1:NumberVar, n2:number, scale?:FunctionalNumber):NumberFunction
---@overload fun(n1:number, n2:NumberVar, scale?:FunctionalNumber):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Diff(n1, n2, scale)
end

---Returns function of max of two given lazyvars
---@overload fun(n1:number, n2:number, scale?:FunctionalNumber):number
---@overload fun(n1:NumberVar, n2:number, scale?:FunctionalNumber):NumberFunction
---@overload fun(n1:number, n2:NumberVar, scale?:FunctionalNumber):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Max(n1, n2, scale)
end

---Returns function of min of two given lazyvars
---@overload fun(n1:number, n2:number, scale?:FunctionalNumber):number
---@overload fun(n1:NumberVar, n2:number, scale?:FunctionalNumber):NumberFunction
---@overload fun(n1:number, n2:NumberVar, scale?:FunctionalNumber):NumberFunction
---@param n1 NumberVar
---@param n2 NumberVar
---@param scale? FunctionalNumber # defaults to pixel scale factor defined in interface options
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Min(n1, n2, scale)
end

---Returns function of floor of a given lazyvar
---@overload fun(n:number):number
---@overload fun(n:NumberVar):NumberFunction
---@param n NumberVar
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Floor(n)
end

---Returns function of round of a given lazyvar
---@overload fun(n:number):number
---@overload fun(n:NumberVar):NumberFunction
---@param n NumberVar
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Round(n)
end

function ReUI.UI.LayoutFunctions.AtCenterOffset(base, baseLen, len, offset, scale)
end

---Returns calculated value of a given FunctionalNumber
---@overload fun(value:number):number
---@param value FunctionalNumber
---@return number
function ReUI.UI.LayoutFunctions.Calculate(value)
end

---Returns one of two vars result based on condition (computes both paths before picking one)
---@param condition LazyOrValue<boolean>
---@param trueVar NumberVar
---@param falseVar NumberVar
---@return NumberFunction
function ReUI.UI.LayoutFunctions.Conditional(condition, trueVar, falseVar)
end