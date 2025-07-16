local Bitmap = UMT.Controls.Bitmap
local Group = UMT.Controls.Group
local LazyVar = import('/lua/lazyvar.lua').Create

---@class BorderColored : UMT.Group
Border = UMT.Class(Group)
{
    __init = function(self, parent, color, borderWidth)
        borderWidth = borderWidth or 1
        Group.__init(self, parent)

        self._leftBitmap = Bitmap(self)
        self._topBitmap = Bitmap(self)
        self._rightBitmap = Bitmap(self)
        self._bottomBitmap = Bitmap(self)


        self._color = LazyVar()
        self._color.OnDirty = function(var)
            local color = var()
            self._leftBitmap:SetSolidColor(color)
            self._topBitmap:SetSolidColor(color)
            self._rightBitmap:SetSolidColor(color)
            self._bottomBitmap:SetSolidColor(color)
        end
        if color then
            self._color:Set(color)
        end

        local layouter = self.Layouter
        layouter(self._leftBitmap)
            :Left(self.Left)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Width(borderWidth)
            :DisableHitTest()

        layouter(self._topBitmap)
            :Left(self.Left)
            :Top(self.Top)
            :Right(self.Right)
            :Height(borderWidth)
            :DisableHitTest()

        layouter(self._rightBitmap)
            :Right(self.Right)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Width(borderWidth)
            :DisableHitTest()

        layouter(self._bottomBitmap)
            :Left(self.Left)
            :Bottom(self.Bottom)
            :Right(self.Right)
            :Height(borderWidth)
            :DisableHitTest()
    end,

    SetColor = function(self, color)
        self._color:Set(color)
    end,

    GetColor = function(self)
        return self._color()
    end,

    SetAlpha = function(self, alpha, applyToChildren)
        Group.SetAlpha(self, alpha, applyToChildren)
        self._leftBitmap:SetAlpha(alpha, applyToChildren)
        self._topBitmap:SetAlpha(alpha, applyToChildren)
        self._rightBitmap:SetAlpha(alpha, applyToChildren)
        self._bottomBitmap:SetAlpha(alpha, applyToChildren)
    end,



    OnDestroy = function(self)
        self._color:Destroy()
        self._color = nil
    end
}
