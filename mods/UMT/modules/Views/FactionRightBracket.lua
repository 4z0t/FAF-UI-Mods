local Group = UMT.Controls.Group
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = UMT.Controls.Bitmap
local LayoutFor = UMT.Layouter.ReusedLayoutFor

---@class FactionRightBracket: UMT.Group
FactionRightBracket = UMT.Class(Group)
{
    ---@param self FactionRightBracket
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.top = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_t.dds"))
        self.middle = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_m.dds"))
        self.bottom = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_b.dds"))
    end,

    InitLayout = function(self, layouter)

        layouter(self.top)
            :Right(self.Right)
            :Top(self.Top)
            :DisableHitTest()

        layouter(self.bottom)
            :Right(self.Right)
            :Bottom(self.Bottom)
            :DisableHitTest()

        layouter(self.middle)
            :AtRightIn(self, 7)
            :Top(self.top.Bottom)
            :Bottom(self.bottom.Top)
            :DisableHitTest()

        layouter(self)
            :Width(0)
            :DisableHitTest()
    end,

}
