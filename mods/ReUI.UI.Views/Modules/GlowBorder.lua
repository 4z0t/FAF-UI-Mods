local UIUtil = import('/lua/ui/uiutil.lua')
local LazyVar = import('/lua/lazyvar.lua').Create

local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap

local textures = {
    tl = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_ul.dds'),
    tr = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_ur.dds'),
    tm = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_horz_um.dds'),
    ml = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_vert_l.dds'),
    m = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_m.dds'),
    mr = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_vert_r.dds'),
    bl = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_ll.dds'),
    bm = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_lm.dds'),
    br = UIUtil.SkinnableFile('/game/mini-map-glow-brd/mini-map-glow_brd_lr.dds'),
}

---@class ReUI.UI.Views.GlowBorder : ReUI.UI.Controls.Group
GlowBorder = ReUI.Core.Class(Group)
{
    ---@param self ReUI.UI.Views.GlowBorder
    ---@param parent ReUI.UI.Controls.Control
    __init = function(self, parent)
        Group.__init(self, parent)
        self.Layouter = ReUI.UI.Layouter(LazyVar(1))
        self.Layouter.Scale = parent.Layouter.Scale

        self.tl = Bitmap(self, textures.tl)
        self.tr = Bitmap(self, textures.tr)
        self.tm = Bitmap(self, textures.tm)
        self.ml = Bitmap(self, textures.ml)

        self.mr = Bitmap(self, textures.mr)
        self.bl = Bitmap(self, textures.bl)
        self.bm = Bitmap(self, textures.bm)
        self.br = Bitmap(self, textures.br)
    end,

    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)

        layouter(self.tl)
            :Left(self.Left)
            :Top(self.Top)

        layouter(self.tr)
            :Top(self.Top)
            :Right(self.Right)

        layouter(self.bl)
            :Left(self.Left)
            :Bottom(self.Bottom)

        layouter(self.br)
            :Bottom(self.Bottom)
            :Right(self.Right)

        layouter(self.tm)
            :Left(self.tl.Right)
            :Right(self.tr.Left)
            :AtTopIn(self, 1)

        layouter(self.bm)
            :Left(self.bl.Right)
            :Right(self.br.Left)
            :AtBottomIn(self, 1)

        layouter(self.mr)
            :Top(self.tr.Bottom)
            :Bottom(self.br.Top)
            :Right(UMT.Layouter.Functions.Diff(self.br.Right, 2, layouter.Scale))

        layouter(self.ml)
            :Top(self.tl.Bottom)
            :Bottom(self.bl.Top)
            :Left(UMT.Layouter.Functions.Sum(self.bl.Left, 2, layouter.Scale))
    end,

}
