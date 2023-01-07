local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutFor = UMT.Layouter.ReusedLayoutFor

local textures = {
    tl = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_ul.dds'),
    tr = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_ur.dds'),
    tm = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_horz_um.dds'),
    ml = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_vert_l.dds'),
    m = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_m.dds'),
    mr = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_vert_r.dds'),
    bl = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_ll.dds'),
    bm = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_lm.dds'),
    br = UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_lr.dds'),
}


GlowBorder = Class(Group)
{

    __init = function(self, parent)
        Group.__init(self, parent)

        self.tl = Bitmap(self, textures.tl)
        self.tr = Bitmap(self, textures.tr)
        self.tm = Bitmap(self, textures.tm)
        self.ml = Bitmap(self, textures.ml)

        self.mr = Bitmap(self, textures.mr)
        self.bl = Bitmap(self, textures.bl)
        self.bm = Bitmap(self, textures.bm)
        self.br = Bitmap(self, textures.br)
    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)

        LayoutFor(self.tl)
            :Left(self.Left)
            :Top(self.Top)

        LayoutFor(self.tr)
            :Top(self.Top)
            :Right(self.Right)

        LayoutFor(self.bl)
            :Left(self.Left)
            :Bottom(self.Bottom)

        LayoutFor(self.br)
            :Bottom(self.Bottom)
            :Right(self.Right)

        LayoutFor(self.tm)
            :Left(self.tl.Right)
            :Right(self.tr.Left)
            :AtTopIn(self, 1)


        LayoutFor(self.bm)
            :Left(self.bl.Right)
            :Right(self.br.Left)
            :AtBottomIn(self, 1)



        LayoutFor(self.mr)
            :Top(self.tr.Bottom)
            :Bottom(self.br.Top)
            :AtRightIn(self, 2)


        LayoutFor(self.ml)
            :Top(self.tl.Bottom)
            :Bottom(self.bl.Top)
            :AtLeftIn(self, 2)


    end,

}
