local UIUtil = import('/lua/ui/uiutil.lua')
local LazyVar = import('/lua/lazyvar.lua').Create

local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap

local textures = {
    tl = UIUtil.SkinnableFile("/game/panel/panel_brd_ul.dds"),
    tr = UIUtil.SkinnableFile("/game/panel/panel_brd_ur.dds"),
    tm = UIUtil.SkinnableFile("/game/panel/panel_brd_horz_um.dds"),
    ml = UIUtil.SkinnableFile("/game/panel/panel_brd_vert_l.dds"),
    m = UIUtil.SkinnableFile("/game/panel/panel_brd_m.dds"),
    mr = UIUtil.SkinnableFile("/game/panel/panel_brd_vert_r.dds"),
    bl = UIUtil.SkinnableFile("/game/panel/panel_brd_ll.dds"),
    bm = UIUtil.SkinnableFile("/game/panel/panel_brd_lm.dds"),
    br = UIUtil.SkinnableFile("/game/panel/panel_brd_lr.dds"),
}

---@class ReUI.UI.Views.WindowFrame : ReUI.UI.Controls.Group
---@field tl ReUI.UI.Controls.Bitmap
---@field tr ReUI.UI.Controls.Bitmap
---@field tm ReUI.UI.Controls.Bitmap
---@field ml ReUI.UI.Controls.Bitmap
---@field m  ReUI.UI.Controls.Bitmap
---@field mr ReUI.UI.Controls.Bitmap
---@field bl ReUI.UI.Controls.Bitmap
---@field bm ReUI.UI.Controls.Bitmap
---@field br ReUI.UI.Controls.Bitmap
WindowFrame = ReUI.Core.Class(Group)
{
    ---@param self ReUI.UI.Views.WindowFrame
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.tl = Bitmap(self, textures.tl)
        self.tr = Bitmap(self, textures.tr)
        self.tm = Bitmap(self, textures.tm)
        self.ml = Bitmap(self, textures.ml)

        self.m = Bitmap(self, textures.m)

        self.mr = Bitmap(self, textures.mr)
        self.bl = Bitmap(self, textures.bl)
        self.bm = Bitmap(self, textures.bm)
        self.br = Bitmap(self, textures.br)
    end,

    ---@param self ReUI.UI.Views.WindowFrame
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
            :AtTopIn(self)

        layouter(self.bm)
            :Left(self.bl.Right)
            :Right(self.br.Left)
            :AtBottomIn(self)

        layouter(self.mr)
            :Top(self.tr.Bottom)
            :Bottom(self.br.Top)
            :AtRightIn(self)

        layouter(self.ml)
            :Top(self.tl.Bottom)
            :Bottom(self.bl.Top)
            :AtLeftIn(self)

        layouter(self.m)
            :Top(self.tm.Bottom)
            :Bottom(self.bm.Top)
            :Left(self.ml.Right)
            :Right(self.mr.Left)
    end,

}
