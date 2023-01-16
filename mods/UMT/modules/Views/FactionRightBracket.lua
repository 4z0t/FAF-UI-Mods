local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = UMT.Layouter.ReusedLayoutFor

FactionRightBracket = Class(Group)
{

    __init = function(self, parent)
        Group.__init(self, parent)

        self.top = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_t.dds"))
        self.middle = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_m.dds"))
        self.bottom = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_b.dds"))
    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)



        LayoutFor(self.top)
            :Right(self.Right)
            :Top(self.Top)
            :DisableHitTest()

        LayoutFor(self.bottom)
            :Right(self.Right)
            :Bottom(self.bottom)
            :DisableHitTest()

        LayoutFor(self.middle)
            :AtRightIn(self, 9)
            :Top(self.top.Bottom)
            :Bottom(self.bottom.Top)
            :DisableHitTest()

        LayoutFor(self)
            :Width(0)
            :DisableHitTest()
    end,

}
