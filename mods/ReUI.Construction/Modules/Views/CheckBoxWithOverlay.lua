local Bitmap = ReUI.UI.Controls.Bitmap
local CheckBox = ReUI.UI.Controls.CheckBox

---@class CheckBoxWithOverlay : ReUI.UI.Controls.CheckBox
---@field _overlay ReUI.UI.Controls.Bitmap
CheckBoxWithOverlay = ReUI.Core.Class(CheckBox)
{
    __init = function(self, parent)
        CheckBox.__init(self, parent)

        self._overlay = Bitmap(self)
    end,

    ---@param self CheckBoxWithOverlay
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self._overlay)
            :Fill(self)
            :Over(self)
            :DisableHitTest()
    end,

    ---@param self CheckBoxWithOverlay
    ---@param off FileName
    ---@param on FileName
    SetOverlayTextures = function(self, off, on)
        self._overlay:SetTexture { off, on }
    end,

    ---@param self CheckBoxWithOverlay
    OnDisable = function(self)
        CheckBox.OnDisable(self)
        self._overlay:SetFrame(0)
    end,

    ---@param self CheckBoxWithOverlay
    OnEnable = function(self)
        CheckBox.OnEnable(self)
        self._overlay:SetFrame(1)
    end,

    OnDestroy = function(self)
        self._overlay = nil
        CheckBox.OnDestroy(self)
    end
}
