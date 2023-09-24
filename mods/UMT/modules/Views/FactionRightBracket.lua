local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = UMT.Layouter.ReusedLayoutFor

---@class FactionRightBracket: Group, ILayoutable
FactionRightBracket = Class(Group, UMT.Interfaces.ILayoutable)
{
    ---@param self FactionRightBracket
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)
        self:InitLayouter(parent)

        self.top = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_t.dds"))
        self.middle = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_m.dds"))
        self.bottom = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_b.dds"))
    end,

    __post_init = function(self)
        self:Layout()
    end,

    _Layout = function(self, layouter)

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
