local Checkbox = ReUI.UI.Controls.CheckBox
local UIUtil = import('/lua/ui/uiutil.lua')

---@class ReUI.UI.Views.VerticalCollapseArrow : ReUI.UI.Controls.CheckBox
VerticalCollapseArrow = UMT.Class(Checkbox)
{
    ---@param self ReUI.UI.Views.VerticalCollapseArrow
    ---@param parent Control
    __init = function(self, parent)
        Checkbox.__init(self, parent)
        self:SetNewTextures(
            ---@diagnostic disable-next-line:param-type-mismatch
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_up.dds',
            ---@diagnostic disable-next-line:param-type-mismatch
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_up.dds',
            ---@diagnostic disable-next-line:param-type-mismatch
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_over.dds',
            ---@diagnostic disable-next-line:param-type-mismatch
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_over.dds',
            ---@diagnostic disable-next-line:param-type-mismatch
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_dis.dds',
            ---@diagnostic disable-next-line:param-type-mismatch
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_dis.dds'
        )
    end
}
