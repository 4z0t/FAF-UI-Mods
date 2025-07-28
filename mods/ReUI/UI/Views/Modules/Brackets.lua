local UIUtil = import('/lua/ui/uiutil.lua')
local LazyVar = import('/lua/lazyvar.lua').Create

local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap

---@class ReUI.UI.Views.FactionRightBracket: ReUI.UI.Controls.Group
---@field top ReUI.UI.Controls.Bitmap
---@field middle ReUI.UI.Controls.Bitmap
---@field bottom ReUI.UI.Controls.Bitmap
FactionRightBracket = ReUI.Core.Class(Group)
{
    ---@param self ReUI.UI.Views.FactionRightBracket
    ---@param parent ReUI.UI.Controls.Control
    __init = function(self, parent)
        Group.__init(self, parent)
        self.Layouter = ReUI.UI.Layouter(LazyVar(1))
        self.Layouter.Scale = parent.Layouter.Scale

        self.top = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_t.dds"))
        self.middle = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_m.dds"))
        self.bottom = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_b.dds"))
    end,

    ---@param self ReUI.UI.Views.FactionRightBracket
    ---@param layouter ReUI.UI.Layouter
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

---@class ReUI.UI.Views.RightGlow: ReUI.UI.Controls.Group
---@field top ReUI.UI.Controls.Bitmap
---@field middle ReUI.UI.Controls.Bitmap
---@field bottom ReUI.UI.Controls.Bitmap
RightGlow = ReUI.Core.Class(Group)
{
    ---@param self ReUI.UI.Views.RightGlow
    ---@param parent ReUI.UI.Controls.Control
    __init = function(self, parent)
        Group.__init(self, parent)
        self.Layouter = ReUI.UI.Layouter(LazyVar(1))
        self.Layouter.Scale = parent.Layouter.Scale

        self.top = Bitmap(self, UIUtil.SkinnableFile '/game/bracket-right-energy/bracket_bmp_t.dds')
        self.middle = Bitmap(self, UIUtil.SkinnableFile '/game/bracket-right-energy/bracket_bmp_m.dds')
        self.bottom = Bitmap(self, UIUtil.SkinnableFile '/game/bracket-right-energy/bracket_bmp_b.dds')
    end,

    ---@param self ReUI.UI.Views.RightGlow
    ---@param layouter ReUI.UI.Layouter
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
            :AtRightIn(self)
            :Top(self.top.Bottom)
            :Bottom(self.bottom.Top)
            :DisableHitTest()

        layouter(self)
            :Width(0)
            :DisableHitTest()
    end,
}

-- ---@class ReUI.UI.Views.FactionLeftBracket: ReUI.UI.Controls.Group
-- ---@field top ReUI.UI.Controls.Bitmap
-- ---@field middle ReUI.UI.Controls.Bitmap
-- ---@field bottom ReUI.UI.Controls.Bitmap
-- FactionLeftBracket = ReUI.Core.Class(Group)
-- {
--     ---@param self ReUI.UI.Views.FactionLeftBracket
--     ---@param parent ReUI.UI.Controls.Control
--     __init = function(self, parent)
--         Group.__init(self, parent)
--         self.Layouter = ReUI.UI.Layouter(LazyVar(parent.Layouter.Scale))

--         self.top = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_t.dds"))
--         self.middle = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_m.dds"))
--         self.bottom = Bitmap(self, UIUtil.SkinnableFile("/game/bracket-right/bracket_bmp_b.dds"))
--     end,

--     ---@param self ReUI.UI.Views.FactionLeftBracket
--     ---@param layouter ReUI.UI.Layouter
--     InitLayout = function(self, layouter)

--         layouter(self.top)
--             :Right(self.Right)
--             :Top(self.Top)
--             :DisableHitTest()

--         layouter(self.bottom)
--             :Right(self.Right)
--             :Bottom(self.Bottom)
--             :DisableHitTest()

--         layouter(self.middle)
--             :AtRightIn(self, 7)
--             :Top(self.top.Bottom)
--             :Bottom(self.bottom.Top)
--             :DisableHitTest()

--         layouter(self)
--             :Width(0)
--             :DisableHitTest()
--     end,

-- }
