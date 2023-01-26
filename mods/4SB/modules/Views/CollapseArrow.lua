local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local UIUtil = import('/lua/ui/uiutil.lua')

VerticalCollapseArrow = Class(Checkbox)
{
    __init = function(self, parent)
        Checkbox.__init(self, parent)
        self:SetTexture(UIUtil.UIFile '/game/tab-r-btn/tab-close_btn_up.dds')
        self:SetNewTextures(
            UIUtil.UIFile '/game/tab-r-btn/tab-close_btn_up.dds',
            UIUtil.UIFile '/game/tab-r-btn/tab-open_btn_up.dds',
            UIUtil.UIFile '/game/tab-r-btn/tab-close_btn_over.dds',
            UIUtil.UIFile '/game/tab-r-btn/tab-open_btn_over.dds',
            UIUtil.UIFile '/game/tab-r-btn/tab-close_btn_dis.dds',
            UIUtil.UIFile '/game/tab-r-btn/tab-open_btn_dis.dds'
        )
    end
}
