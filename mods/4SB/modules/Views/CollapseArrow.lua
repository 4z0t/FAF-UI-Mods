local Checkbox = UMT.Controls.Checkbox
local UIUtil = import('/lua/ui/uiutil.lua')

VerticalCollapseArrow = UMT.Class(Checkbox)
{
    __init = function(self, parent)
        Checkbox.__init(self, parent)
        self:SetNewTextures(
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_up.dds',
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_up.dds',
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_over.dds',
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_over.dds',
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_dis.dds',
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_dis.dds'
        )
    end
}
