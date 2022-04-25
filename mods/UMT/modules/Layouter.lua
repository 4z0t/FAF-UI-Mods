local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local LayouterMetaTable = {}
LayouterMetaTable.__index = LayouterMetaTable

function LayouterMetaTable:Disable()
    self.c:Disable()
    return self
end

function LayouterMetaTable:Color(color)
    self.c:SetColor(color)
    return self
end

function LayouterMetaTable:DropShadow(state)
    self.c:SetDropShadow(state)
    return self
end

function LayouterMetaTable:SolidColor(color)
    self.c:SetSolidColor(color)
    return self
end

function LayouterMetaTable:Texture(texture)
    self.c:SetTexture(texture)
    return self
end

function LayouterMetaTable:HitTest(state)
    if state == nil then
        error(':HitTest requires 1 positional argument "state"')
    end
    if state then
        self.c:EnableHitTest()
    else
        self.c:DisableHitTest()
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
        self.c.Width:Set(width)
    else
        self.c.Width:Set(LayoutHelpers.ScaleNumber(width))
    end
    return self
end

function LayouterMetaTable:Height(height)
    if iscallable(height) then
        self.c.Height:Set(height)
    else
        self.c.Height:Set(LayoutHelpers.ScaleNumber(height))
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

-- depth

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

function LayouterMetaTable:Get()
    return self.c
end

function LayouterMetaTable:__newindex(key, value)
    error('attempt to set new index for a Layouter object')
end

function LayoutFor(control)
    local result = {
        c = control
    }
    setmetatable(result, LayouterMetaTable)
    return result
end
