local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local LayouterMetaTable = {}
LayouterMetaTable.__index = LayouterMetaTable

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

function LayouterMetaTable:Alpha(alpha)
    self.c:SetAlpha(alpha)
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

function ReusedLayoutFor(control)
    layouter.c = control or false
    return layouter
end
