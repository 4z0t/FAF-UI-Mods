local Checkbox = ReUI.UI.Controls.CheckBox
local UIUtil = import('/lua/ui/uiutil.lua')

---@class ReUI.UI.Views.VerticalCollapseArrow : ReUI.UI.Controls.CheckBox
VerticalCollapseArrow = ReUI.Core.Class(Checkbox)
{
    ---@param self ReUI.UI.Views.VerticalCollapseArrow
    ---@param parent Control
    __init = function(self, parent)
        Checkbox.__init(self, parent)
        self:SetNewTextures(
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_up.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_up.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_over.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_over.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-close_btn_dis.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-r-btn/tab-open_btn_dis.dds'--[[@as FileName]]
        )
    end
}

---@class ReUI.UI.Views.HorizontalCollapseArrow : ReUI.UI.Controls.CheckBox
HorizontalCollapseArrow = ReUI.Core.Class(Checkbox)
{
    ---@param self ReUI.UI.Views.HorizontalCollapseArrow
    ---@param parent Control
    __init = function(self, parent)
        Checkbox.__init(self, parent)
        self:SetNewTextures(
            UIUtil.SkinnableFile '/game/tab-t-btn/tab-close_btn_up.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-t-btn/tab-open_btn_up.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-t-btn/tab-close_btn_over.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-t-btn/tab-open_btn_over.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-t-btn/tab-close_btn_dis.dds'--[[@as FileName]] ,
            UIUtil.SkinnableFile '/game/tab-t-btn/tab-open_btn_dis.dds'--[[@as FileName]]
        )
    end
}
