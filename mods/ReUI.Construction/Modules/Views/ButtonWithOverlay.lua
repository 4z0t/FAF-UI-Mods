local Button = ReUI.UI.Views.Button
local Bitmap = ReUI.UI.Controls.Bitmap

---@class ButtonWithOverlay : ReUI.UI.Views.Button
---@field _overlay ReUI.UI.Controls.Bitmap
ButtonWithOverlay = ReUI.Core.Class(Button)
{
    __init = function(self, parent)
        Button.__init(self, parent)

        self._overlay = Bitmap(self)
    end,

    ---@param self ButtonWithOverlay
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self._overlay)
            :Fill(self)
            :Over(self)
            :DisableHitTest()
    end,

    ---@param self ButtonWithOverlay
    ---@param off FileName
    ---@param on FileName
    SetOverlayTextures = function(self, off, on)
        self._overlay:SetTexture { off, on }
    end,

    ---@param self ButtonWithOverlay
    OnDisable = function(self)
        Button.OnDisable(self)
        self._overlay:SetFrame(0)
    end,

    ---@param self ButtonWithOverlay
    OnEnable = function(self)
        Button.OnEnable(self)
        self._overlay:SetFrame(1)
    end,

    OnDestroy = function(self)
        self._overlay = nil
        Button.OnDestroy(self)
    end
}
