local Slidable = import("Slidable.lua").Slidable
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

Entry = Class(Slidable)
{
    __init = function(self, parent)
        Slidable.__init(self, parent)

        self._speed = 300
        self._bg = Bitmap(self)
        self._bg:SetSolidColor("ff000000")
        LayoutHelpers.FillParent(self._bg, self)
        LayoutHelpers.SetDimensions(self, 100, 20)
    end,

    --- returns true if reached one of the positions, false if not
    StopAnimation = function(self)
        if self._direction == 1 and self.Right() < self.parent.Right() then
            self.Right:Set(self.parent.Right)
            return true
        end
        if self._direction == -1 and self.Right() - self.parent.Right() > 50 then
            LayoutHelpers.AtRightIn(self, self.parent, -50)
            return true
        end
        return false
    end,

    OnAnimation = function(self, delta)
        self.Right:Set(self.Right() - self._direction * delta * self._speed)
    end,


}
