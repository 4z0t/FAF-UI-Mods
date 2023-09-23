local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
Functions = import("LayoutFunctions.lua")

---@class Layouter
---@field c Control
local LayouterMetaTable = {}
LayouterMetaTable.__index = LayouterMetaTable


---@class Layouter
---@field c Control|boolean
---@field _scale NumberVar
Layouter = ClassSimple
{
    ---@param self Layouter
    ---@param scale NumberVar
    __init = function(self, scale)
        self.c = false
        self._scale = scale
    end,

    SetScale = function(self, scale)
        assert(self._scale, "No scale LazyVar provided during contruction!")
        self._scale:Set(scale)
        return self
    end,

    ---@param self Layouter
    ---@param control Control
    __call = function(self, control)
        self.c = control or false
    end,

    ScaleNumber = function(self, value)
        return Functions.Mult(value, self._scale)
    end,

    Sum = function(self, n1, n2)
        return Functions.Sum(n1, n2, self._scale)
    end,

    Diff = function(self, n1, n2)
        return Functions.Diff(n1, n2, self._scale)
    end,

    Max = function(self, n1, n2)
        return Functions.Max(n1, n2, self._scale)
    end,

    Min = function(self, n1, n2)
        return Functions.Min(n1, n2, self._scale)
    end,

    _ScaleValue = function(self, value)
        if iscallable(value) then
            return value
        else
            return self:ScaleNumber(value)
        end
    end,

    Width = function(self, width)
        self.c.Width:Set(self:_ScaleValue(width))
        return self
    end,

    Height = function(self, height)
        self.c.Height:Set(self:_ScaleValue(height))
        return self
    end,

    AtLeftIn = function(self, parent, leftOffset)
        self.c.Left:Set(self:Sum(parent.Left, leftOffset or 0))
        return self
    end,

    AtTopIn = function(self, parent, topOffset)
        self.c.Top:Set(self:Sum(parent.Top, topOffset or 0))
        return self
    end,

    AtRightIn = function(self, parent, rightOffset)
        self.c.Right:Set(self:Diff(parent.Right, rightOffset or 0))
        return self
    end,

    AtBottomIn = function(self, parent, bottomOffset)
        self.c.Bottom:Set(self:Diff(parent.Bottom, bottomOffset or 0))
        return self
    end,

    FillHorizontally = function(self, parent)
        return self
            :AtLeftIn(parent)
            :AtRightIn(parent)
    end,

    FillVertically = function(self, parent)
        return self
            :AtTopIn(parent)
            :AtBottomIn(parent)
    end,

    Fill = function(self, parent)
        return self
            :FillHorizontally(parent)
            :FillVertically(parent)
    end,

    AtLeftTopIn = function(self, parent, left, top)
        return self
            :AtLeftIn(parent, left)
            :AtTopIn(parent, top)
    end,

    AtRightTopIn = function(self, parent, right, top)
        return self
            :AtRightIn(parent, right)
            :AtTopIn(parent, top)
    end,

    AtRightBottomIn = function(self, parent, right, bottom)
        return self
            :AtRightIn(parent, right)
            :AtBottomIn(parent, bottom)
    end,

    AtLeftBottomIn = function(self, parent, left, bottom)
        return self
            :AtLeftIn(parent, left)
            :AtBottomIn(parent, bottom)
    end,

    OffsetIn = function(self, parent, left, top, right, bottom)
        return self
            :AtLeftTopIn(parent, left, top)
            :AtRightBottomIn(parent, right, bottom)
    end,

    AtVerticalCenterIn = function(self, parent, topOffset)
        self.c.Top:Set(Functions.AtCenterOffset(parent.Top, parent.Height, self.c.Height, topOffset or 0, self._scale))
        return self
    end,

    AtHorizontalCenterIn = function(self, parent, leftOffset)
        self.c.Left:Set(Functions.AtCenterOffset(parent.Left, parent.Width, self.c.Width, leftOffset or 0, self._scale))
        return self
    end,

    AtCenterIn = function(self, parent, top, left)
        return self
            :AtHorizontalCenterIn(parent, left)
            :AtVerticalCenterIn(parent, top)
    end,

    Disable = function(self)
        self.c:Disable()
        return self
    end,

    Hide = function(self)
        self.c:Hide()
        return self
    end,
}

---Disables control
---@return Layouter
function LayouterMetaTable:Disable()
    self.c:Disable()
    return self
end

function LayouterMetaTable:Hide()
    self.c:Hide()
    return self
end

function LayouterMetaTable:Color(color)
    if type(color) == "string" and string.len(color) == 6 then
        color = "ff" .. color
    end

    if self.c.SetSolidColor then
        self.c:SetSolidColor(color)
    elseif self.c.SetColor then
        self.c:SetColor(color)
    else
        error("Unable to set color for control")
    end
    return self
end

function LayouterMetaTable:TextColor(color)
    self.c:SetColor(color)
    return self
end

function LayouterMetaTable:BitmapColor(color)
    self.c:SetSolidColor(color)
    return self
end

function LayouterMetaTable:DropShadow(state)
    self.c:SetDropShadow(state)
    return self
end

function LayouterMetaTable:Texture(texture, border)
    self.c:SetTexture(texture, border)
    return self
end

function LayouterMetaTable:EnableHitTest(recursive)
    self.c:EnableHitTest(recursive)
    return self
end

function LayouterMetaTable:DisableHitTest(recursive)
    self.c:DisableHitTest(recursive)
    return self
end

function LayouterMetaTable:HitTest(state, recursive)
    if state == nil then
        error(":HitTest requires 1 positional argument \"state\"")
    end
    if state then
        self.c:EnableHitTest(recursive)
    else
        self.c:DisableHitTest(recursive)
    end
    return self
end

function LayouterMetaTable:NeedsFrameUpdate(state)
    self.c:SetNeedsFrameUpdate(state)
    return self
end

function LayouterMetaTable:Alpha(alpha, applyToChildren)
    self.c:SetAlpha(alpha, applyToChildren)
    return self
end

-- raw setting

function LayouterMetaTable:Left(left)
    self.c.Left:Set(left)
    return self
end

function LayouterMetaTable:Right(right)
    self.c.Right:Set(right)
    return self
end

function LayouterMetaTable:Top(top)
    self.c.Top:Set(top)
    return self
end

function LayouterMetaTable:Bottom(bottom)
    self.c.Bottom:Set(bottom)
    return self
end

function LayouterMetaTable:Width(width)
    if iscallable(width) then
        self.c.Width:SetFunction(width)
    else
        self.c.Width:SetValue(LayoutHelpers.ScaleNumber(width))
    end
    return self
end

function LayouterMetaTable:Height(height)
    if iscallable(height) then
        self.c.Height:SetFunction(height)
    else
        self.c.Height:SetValue(LayoutHelpers.ScaleNumber(height))
    end
    return self
end

function LayouterMetaTable:Fill(parent)
    LayoutHelpers.FillParent(self.c, parent)
    return self
end

function LayouterMetaTable:FillFixedBorder(parent, offset)
    LayoutHelpers.FillParentFixedBorder(self.c, parent, offset)
    return self
end

-- double-based positioning

function LayouterMetaTable:AtLeftTopIn(parent, leftOffset, topOffset)
    LayoutHelpers.AtLeftTopIn(self.c, parent, leftOffset, topOffset)
    return self
end

function LayouterMetaTable:AtRightBottomIn(parent, rightOffset, bottomOffset)
    LayoutHelpers.AtRightBottomIn(self.c, parent, rightOffset, bottomOffset)
    return self
end

function LayouterMetaTable:AtLeftBottomIn(parent, leftOffset, bottomOffset)
    LayoutHelpers.AtLeftBottomIn(self.c, parent, leftOffset, bottomOffset)
    return self
end

function LayouterMetaTable:AtRightTopIn(parent, rightOffset, topOffset)
    LayoutHelpers.AtRightTopIn(self.c, parent, rightOffset, topOffset)
    return self
end

-- centered--

function LayouterMetaTable:CenteredLeftOf(parent, offset)
    LayoutHelpers.CenteredLeftOf(self.c, parent, offset)
    return self
end

function LayouterMetaTable:CenteredRightOf(parent, offset)
    LayoutHelpers.CenteredRightOf(self.c, parent, offset)
    return self
end

function LayouterMetaTable:CenteredAbove(parent, offset)
    LayoutHelpers.CenteredAbove(self.c, parent, offset)
    return self
end

function LayouterMetaTable:CenteredBelow(parent, offset)
    LayoutHelpers.CenteredBelow(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtHorizontalCenterIn(parent, offset)
    LayoutHelpers.AtHorizontalCenterIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtVerticalCenterIn(parent, offset)
    LayoutHelpers.AtVerticalCenterIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtCenterIn(parent, vertOffset, horzOffset)
    LayoutHelpers.AtCenterIn(self.c, parent, vertOffset, horzOffset)
    return self
end

-- single-in positioning

function LayouterMetaTable:AtLeftIn(parent, offset)
    LayoutHelpers.AtLeftIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtRightIn(parent, offset)
    LayoutHelpers.AtRightIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtTopIn(parent, offset)
    LayoutHelpers.AtTopIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtBottomIn(parent, offset)
    LayoutHelpers.AtBottomIn(self.c, parent, offset)
    return self
end

-- center-in positioning

function LayouterMetaTable:AtLeftCenterIn(parent, offset, verticalOffset)
    LayoutHelpers.AtLeftIn(self.c, parent, offset)
    LayoutHelpers.AtVerticalCenterIn(self.c, parent, verticalOffset)
    return self
end

function LayouterMetaTable:AtRightCenterIn(parent, offset, verticalOffset)
    LayoutHelpers.AtRightIn(self.c, parent, offset)
    LayoutHelpers.AtVerticalCenterIn(self.c, parent, verticalOffset)
    return self
end

function LayouterMetaTable:AtTopCenterIn(parent, offset, horizonalOffset)
    LayoutHelpers.AtTopIn(self.c, parent, offset)
    LayoutHelpers.AtHorizontalCenterIn(self.c, parent, horizonalOffset)
    return self
end

function LayouterMetaTable:AtBottomCenterIn(parent, offset, horizonalOffset)
    LayoutHelpers.AtBottomIn(self.c, parent, offset)
    LayoutHelpers.AtHorizontalCenterIn(self.c, parent, horizonalOffset)
    return self
end

-- out-of positioning

function LayouterMetaTable:Below(parent, offset)
    LayoutHelpers.Below(self.c, parent, offset)
    return self
end

function LayouterMetaTable:Above(parent, offset)
    LayoutHelpers.Above(self.c, parent, offset)
    return self
end

function LayouterMetaTable:RightOf(parent, offset)
    LayoutHelpers.RightOf(self.c, parent, offset)
    return self
end

function LayouterMetaTable:LeftOf(parent, offset)
    LayoutHelpers.LeftOf(self.c, parent, offset)
    return self
end

-- depth--

function LayouterMetaTable:Over(parent, depth)
    LayoutHelpers.DepthOverParent(self.c, parent, depth)
    return self
end

function LayouterMetaTable:Under(parent, depth)
    LayoutHelpers.DepthUnderParent(self.c, parent, depth)
    return self
end

-- anchor--

function LayouterMetaTable:AnchorToTop(parent, offset)
    LayoutHelpers.AnchorToTop(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AnchorToLeft(parent, offset)
    LayoutHelpers.AnchorToLeft(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AnchorToRight(parent, offset)
    LayoutHelpers.AnchorToRight(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AnchorToBottom(parent, offset)
    LayoutHelpers.AnchorToBottom(self.c, parent, offset)
    return self
end

-- reset--

function LayouterMetaTable:ResetLeft()
    LayoutHelpers.ResetLeft(self.c)
    return self
end

function LayouterMetaTable:ResetRight()
    LayoutHelpers.ResetRight(self.c)
    return self
end

function LayouterMetaTable:ResetBottom()
    LayoutHelpers.ResetBottom(self.c)
    return self
end

function LayouterMetaTable:ResetHeight()
    LayoutHelpers.ResetHeight(self.c)
    return self
end

function LayouterMetaTable:ResetTop()
    LayoutHelpers.ResetTop(self.c)
    return self
end

function LayouterMetaTable:ResetWidth()
    LayoutHelpers.ResetWidth(self.c)
    return self
end

-- get control --

function LayouterMetaTable:Get()
    return self.c
end

function LayouterMetaTable:__newindex(key, value)
    error("attempt to set new index for a Layouter object")
end

function LayouterMetaTable:End()
    if not pcall(self.c.Top) or not pcall(self.c.Bottom) or not pcall(self.c.Height) then
        WARN("incorrect layout for Top-Height-Bottom")
        WARN(debug.traceback())
    end

    if not pcall(self.c.Left) or not pcall(self.c.Right) or not pcall(self.c.Width) then
        WARN("incorrect layout for Left-Width-Right")
        WARN(debug.traceback())
    end

    return self.c
end

---Creates Layouter for given control
---@param control Control
---@return Layouter
function LayoutFor(control)
    local result = {
        c = control
    }
    setmetatable(result, LayouterMetaTable)
    return result
end

local layouter = {
    c = false
}
setmetatable(layouter, LayouterMetaTable)

---returns Reused Layouter
---@param control Control
---@return Layouter
function ReusedLayoutFor(control)
    layouter.c = control or false
    return layouter
end
