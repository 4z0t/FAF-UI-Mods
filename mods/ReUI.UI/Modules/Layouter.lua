local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Functions = import("LayoutFunctions.lua")

local defaultScale = LayoutHelpers.GetPixelScaleFactor()

---@class ReUI.UI.Layouter
---@field c Control|false
---@field _scale NumberVar|false
---@operator call(Control):(ReUI.UI.Layouter)
Layouter = ReUI.Core.Class()
{
    ---@param self ReUI.UI.Layouter
    ---@param scale? NumberVar
    __init = function(self, scale)
        self.c = false
        self._scale = scale or false
    end,

    ---@type FunctionalNumber
    Scale = ReUI.Core.Property
    {
        get = function(self)
            return self._scale or defaultScale
        end,

        set = function(self, value)
            assert(type(self._scale) == "table", "No scale LazyVar provided during contruction!")
            self._scale:Set(value)
        end
    },

    ---@param self ReUI.UI.Layouter
    ---@param control Control
    ---@return ReUI.UI.Layouter
    __call = function(self, control)
        self.c = control or false
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param base FunctionalNumber
    ---@param baseLen FunctionalNumber
    ---@param len FunctionalNumber
    ---@param offset number
    ---@return FunctionalNumber
    AtCenterOffset = function(self, base, baseLen, len, offset)
        return Functions.AtCenterOffset(base, baseLen, len, offset, self.Scale)
    end,

    ---Scales given number / NumberVar
    ---@param self ReUI.UI.Layouter
    ---@param value FunctionalNumber
    ---@return FunctionalNumber
    ScaleVar = function(self, value)
        return Functions.Mult(value, self.Scale)
    end,

    ---Scales given number
    ---@param self ReUI.UI.Layouter
    ---@param value number
    ---@return number
    ScaleNumber = function(self, value)
        local scale = self.Scale
        if iscallable(scale) then
            return scale() * value
        end
        return scale * value
    end,

    ---@param self ReUI.UI.Layouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Sum = function(self, n1, n2)
        return Functions.Sum(n1, n2, self.Scale)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Diff = function(self, n1, n2)
        return Functions.Diff(n1, n2, self.Scale)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Max = function(self, n1, n2)
        return Functions.Max(n1, n2, self.Scale)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Min = function(self, n1, n2)
        return Functions.Min(n1, n2, self.Scale)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param value FunctionalNumber
    ---@return FunctionalNumber
    _ScaleValue = function(self, value)
        if iscallable(value) then
            return value
        else
            return self:ScaleVar(value)
        end
    end,

    ---@param self ReUI.UI.Layouter
    ---@param left FunctionalNumber
    ---@return ReUI.UI.Layouter
    Left = function(self, left)
        self.c.Left:Set(left)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param right FunctionalNumber
    ---@return ReUI.UI.Layouter
    Right = function(self, right)
        self.c.Right:Set(right)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param top FunctionalNumber
    ---@return ReUI.UI.Layouter
    Top = function(self, top)
        self.c.Top:Set(top)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param bottom FunctionalNumber
    ---@return ReUI.UI.Layouter
    Bottom = function(self, bottom)
        self.c.Bottom:Set(bottom)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param width FunctionalNumber
    ---@return ReUI.UI.Layouter
    Width = function(self, width)
        self.c.Width:Set(self:_ScaleValue(width))
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param height FunctionalNumber
    ---@return ReUI.UI.Layouter
    Height = function(self, height)
        self.c.Height:Set(self:_ScaleValue(height))
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param depth? FunctionalNumber
    ---@return ReUI.UI.Layouter
    Over = function(self, parent, depth)
        self.c.Depth:Set(Functions.Sum(parent.Depth, depth or 1))
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param depth? FunctionalNumber
    ---@return ReUI.UI.Layouter
    Under = function(self, parent, depth)
        self.c.Depth:Set(Functions.Diff(parent.Depth, depth or 1))
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param leftOffset? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AtLeftIn = function(self, parent, leftOffset)
        return self:Left(self:Sum(parent.Left, leftOffset or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param topOffset? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AtTopIn = function(self, parent, topOffset)
        return self:Top(self:Sum(parent.Top, topOffset or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param rightOffset? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AtRightIn = function(self, parent, rightOffset)
        return self:Right(self:Diff(parent.Right, rightOffset or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param bottomOffset? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AtBottomIn = function(self, parent, bottomOffset)
        return self:Bottom(self:Diff(parent.Bottom, bottomOffset or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param padding? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AnchorToLeft = function(self, parent, padding)
        return self:Right(self:Diff(parent.Left, padding or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param padding? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AnchorToTop = function(self, parent, padding)
        return self:Bottom(self:Diff(parent.Top, padding or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param padding? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AnchorToRight = function(self, parent, padding)
        return self:Left(self:Sum(parent.Right, padding or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param padding? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AnchorToBottom = function(self, parent, padding)
        return self:Top(self:Sum(parent.Bottom, padding or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@return ReUI.UI.Layouter
    FillHorizontally = function(self, parent)
        return self
            :AtLeftIn(parent)
            :AtRightIn(parent)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@return ReUI.UI.Layouter
    FillVertically = function(self, parent)
        return self
            :AtTopIn(parent)
            :AtBottomIn(parent)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@return ReUI.UI.Layouter
    Fill = function(self, parent)
        return self
            :FillHorizontally(parent)
            :FillVertically(parent)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param left? FunctionalNumber
    ---@param top? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AtLeftTopIn = function(self, parent, left, top)
        return self
            :AtLeftIn(parent, left)
            :AtTopIn(parent, top)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param right? FunctionalNumber
    ---@param top? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AtRightTopIn = function(self, parent, right, top)
        return self
            :AtRightIn(parent, right)
            :AtTopIn(parent, top)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param right? FunctionalNumber
    ---@param bottom? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AtRightBottomIn = function(self, parent, right, bottom)
        return self
            :AtRightIn(parent, right)
            :AtBottomIn(parent, bottom)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param left? FunctionalNumber
    ---@param bottom? FunctionalNumber
    ---@return ReUI.UI.Layouter
    AtLeftBottomIn = function(self, parent, left, bottom)
        return self
            :AtLeftIn(parent, left)
            :AtBottomIn(parent, bottom)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param left? FunctionalNumber
    ---@param top? FunctionalNumber
    ---@param right? FunctionalNumber
    ---@param bottom? FunctionalNumber
    ---@return ReUI.UI.Layouter
    OffsetIn = function(self, parent, left, top, right, bottom)
        return self
            :AtLeftTopIn(parent, left, top)
            :AtRightBottomIn(parent, right, bottom)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param offset? FunctionalNumber
    ---@return ReUI.UI.Layouter
    FillFixedBorder = function(self, parent, offset)
        return self:OffsetIn(parent, offset, offset, offset, offset)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param topOffset? number
    ---@return ReUI.UI.Layouter
    AtVerticalCenterIn = function(self, parent, topOffset)
        return self:Top(self:AtCenterOffset(parent.Top, parent.Height, self.c.Height, topOffset or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param leftOffset? number
    ---@return ReUI.UI.Layouter
    AtHorizontalCenterIn = function(self, parent, leftOffset)
        return self:Left(self:AtCenterOffset(parent.Left, parent.Width, self.c.Width, leftOffset or 0))
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param top? number
    ---@param left? number
    ---@return ReUI.UI.Layouter
    AtCenterIn = function(self, parent, top, left)
        return self
            :AtHorizontalCenterIn(parent, left)
            :AtVerticalCenterIn(parent, top)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param padding? FunctionalNumber
    ---@return ReUI.UI.Layouter
    LeftOf = function(self, parent, padding)
        return self
            :AnchorToLeft(parent, padding)
            :AtTopIn(parent)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param padding? FunctionalNumber
    ---@return ReUI.UI.Layouter
    RightOf = function(self, parent, padding)
        return self
            :AnchorToRight(parent, padding)
            :AtTopIn(parent)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param padding? FunctionalNumber
    ---@return ReUI.UI.Layouter
    Above = function(self, parent, padding)
        return self
            :AtLeftIn(parent)
            :AnchorToTop(parent, padding)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param padding? FunctionalNumber
    ---@return ReUI.UI.Layouter
    Below = function(self, parent, padding)
        return self
            :AtLeftIn(parent)
            :AnchorToBottom(parent, padding)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param leftOffset? FunctionalNumber
    ---@param topOffset? number
    ---@return ReUI.UI.Layouter
    AtLeftCenterIn = function(self, parent, leftOffset, topOffset)
        return self
            :AtLeftIn(parent, leftOffset)
            :AtVerticalCenterIn(parent, topOffset)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param topOffset? FunctionalNumber
    ---@param leftOffset? number
    ---@return ReUI.UI.Layouter
    AtTopCenterIn = function(self, parent, topOffset, leftOffset)
        return self
            :AtTopIn(parent, topOffset)
            :AtHorizontalCenterIn(parent, leftOffset)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param rightOffset? FunctionalNumber
    ---@param topOffset? number
    ---@return ReUI.UI.Layouter
    AtRightCenterIn = function(self, parent, rightOffset, topOffset)
        return self
            :AtRightIn(parent, rightOffset)
            :AtVerticalCenterIn(parent, topOffset)
    end,

    ---@param self ReUI.UI.Layouter
    ---@param parent Control
    ---@param bottomOffset? FunctionalNumber
    ---@param leftOffset? number
    ---@return ReUI.UI.Layouter
    AtBottomCenterIn = function(self, parent, bottomOffset, leftOffset)
        return self
            :AtBottomIn(parent, bottomOffset)
            :AtHorizontalCenterIn(parent, leftOffset)
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    ResetLeft = function(self)
        return self:Left(Functions.Diff(self.c.Right, self.c.Width))
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    ResetTop = function(self)
        return self:Top(Functions.Diff(self.c.Bottom, self.c.Height))
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    ResetRight = function(self)
        return self:Right(Functions.Sum(self.c.Left, self.c.Width))
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    ResetBottom = function(self)
        return self:Bottom(Functions.Sum(self.c.Top, self.c.Height))
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    ResetWidth = function(self)
        return self:Width(Functions.Diff(self.c.Right, self.c.Left))
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    ResetHeight = function(self)
        return self:Height(Functions.Diff(self.c.Bottom, self.c.Top))
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    ResetLayout = function(self)
        return self
            :ResetTop()
            :ResetLeft()
            :ResetRight()
            :ResetBottom()
            :ResetWidth()
            :ResetHeight()
    end,

    ---Reset position of the control, keeps width and height
    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    ResetPosition = function(self)
        return self
            :ResetTop()
            :ResetLeft()
            :ResetRight()
            :ResetBottom()
    end,

    ---applies default scale in callback function
    ---@param self ReUI.UI.Layouter
    ---@param callback fun(layouter: ReUI.UI.Layouter)
    ---@return ReUI.UI.Layouter
    NoScale = function(self, callback)
        local scale = self._scale
        self._scale = false
        callback(self)
        self._scale = scale
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param color Color
    ---@return ReUI.UI.Layouter
    Color = function(self, color)
        if type(color) == "string" and string.len(color) == 6 then
            color = "ff" .. color
        end

        if self.c.SetSolidColor then
            self.c:SetSolidColor(color)
        elseif self.c.SetColor then
            self.c:SetColor(color)
        else
            error "Unable to set color for control"
        end
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param state boolean
    ---@return ReUI.UI.Layouter
    DropShadow = function(self, state)
        self.c:SetDropShadow(state)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param texture LazyOrValue<FileName>
    ---@param border? number
    ---@return ReUI.UI.Layouter
    Texture = function(self, texture, border)
        self.c:SetTexture(texture, border)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param recursive? boolean
    ---@return ReUI.UI.Layouter
    EnableHitTest = function(self, recursive)
        self.c:EnableHitTest(recursive)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param recursive? boolean
    ---@return ReUI.UI.Layouter
    DisableHitTest = function(self, recursive)
        self.c:DisableHitTest(recursive)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param state boolean
    ---@return ReUI.UI.Layouter
    NeedsFrameUpdate = function(self, state)
        self.c:SetNeedsFrameUpdate(state)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@param alpha number
    ---@param applyToChildren? boolean
    ---@return ReUI.UI.Layouter
    Alpha = function(self, alpha, applyToChildren)
        self.c:SetAlpha(alpha, applyToChildren)
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    Disable = function(self)
        self.c:Disable()
        return self
    end,

    ---@param self ReUI.UI.Layouter
    ---@return ReUI.UI.Layouter
    Hide = function(self)
        self.c:Hide()
        return self
    end,

}

local FuncFloor = Functions.Floor

---@class ReUI.UI.FloorLayouter : ReUI.UI.Layouter
FloorLayouter = ReUI.Core.Class(Layouter)
{
    ---@param self ReUI.UI.FloorLayouter
    ---@param base FunctionalNumber
    ---@param baseLen FunctionalNumber
    ---@param len FunctionalNumber
    ---@param offset number
    ---@return FunctionalNumber
    AtCenterOffset = function(self, base, baseLen, len, offset)
        return FuncFloor(Layouter.AtCenterOffset(self, base, baseLen, len, offset))
    end,
    ---Scales given number / Numbervar
    ---@param self ReUI.UI.FloorLayouter
    ---@param value FunctionalNumber
    ---@return FunctionalNumber
    ScaleVar = function(self, value)
        return FuncFloor(Layouter.ScaleVar(self, value))
    end,

    ---Scales given number
    ---@param self ReUI.UI.FloorLayouter
    ---@param value number
    ---@return number
    ScaleNumber = function(self, value)
        return FuncFloor(Layouter.ScaleNumber(self, value))
    end,

    ---@param self ReUI.UI.FloorLayouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Sum = function(self, n1, n2)
        return FuncFloor(Layouter.Sum(self, n1, n2))
    end,

    ---@param self ReUI.UI.FloorLayouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Diff = function(self, n1, n2)
        return FuncFloor(Layouter.Diff(self, n1, n2))
    end,

    ---@param self ReUI.UI.FloorLayouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Max = function(self, n1, n2)
        return FuncFloor(Layouter.Max(self, n1, n2))
    end,

    ---@param self ReUI.UI.FloorLayouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Min = function(self, n1, n2)
        return FuncFloor(Layouter.Min(self, n1, n2))
    end,
}

local FuncRound = Functions.Round

---@class ReUI.UI.RoundLayouter:ReUI.UI.Layouter
RoundLayouter = ReUI.Core.Class(Layouter)
{
    ---@param self ReUI.UI.RoundLayouter
    ---@param base FunctionalNumber
    ---@param baseLen FunctionalNumber
    ---@param len FunctionalNumber
    ---@param offset number
    ---@return FunctionalNumber
    AtCenterOffset = function(self, base, baseLen, len, offset)
        return FuncRound(Layouter.AtCenterOffset(self, base, baseLen, len, offset))
    end,
    ---Scales given number / Numbervar
    ---@param self ReUI.UI.RoundLayouter
    ---@param value FunctionalNumber
    ---@return FunctionalNumber
    ScaleVar = function(self, value)
        return FuncRound(Layouter.ScaleVar(self, value))
    end,

    ---Scales given number
    ---@param self ReUI.UI.RoundLayouter
    ---@param value number
    ---@return number
    ScaleNumber = function(self, value)
        return FuncRound(Layouter.ScaleNumber(self, value))
    end,

    ---@param self ReUI.UI.RoundLayouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Sum = function(self, n1, n2)
        return FuncRound(Layouter.Sum(self, n1, n2))
    end,

    ---@param self ReUI.UI.RoundLayouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Diff = function(self, n1, n2)
        return FuncRound(Layouter.Diff(self, n1, n2))
    end,

    ---@param self ReUI.UI.RoundLayouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Max = function(self, n1, n2)
        return FuncRound(Layouter.Max(self, n1, n2))
    end,

    ---@param self ReUI.UI.RoundLayouter
    ---@param n1 FunctionalNumber
    ---@param n2 FunctionalNumber
    ---@return FunctionalNumber
    Min = function(self, n1, n2)
        return FuncRound(Layouter.Min(self, n1, n2))
    end,
}


---@type ReUI.UI.Layouter
FloorLayoutFor = FloorLayouter()

---@type ReUI.UI.Layouter
RoundLayoutFor = RoundLayouter()
