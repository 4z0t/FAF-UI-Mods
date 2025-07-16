local Border = import("Border.lua").Border
local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap
local Text = ReUI.UI.Controls.Text

---@class BorderedText : BorderColored
BorderedText = ReUI.Core.Class(Border)
{
    __init = function(self, parent, color, borderWidth)
        Border.__init(self, parent, color, borderWidth)
        self._text = Text(self)

        if color then
            self:SetTextColor(color)
        end

        self.Layouter(self._text)
            :AtCenterIn(self)
            :DisableHitTest()
    end,

    SetText = function(self, text)
        self._text:SetText(text)
    end,

    GetText = function (self)
        return self._text:GetText()
    end,

    SetFont = function(self, fontFamily, pointSize)
        self._text:SetFont(fontFamily, pointSize)
    end,

    SetTextColor = function(self, color)
        self._text:SetColor(color)
    end,

    SetColor = function(self, color)
        Border.SetColor(self, color)
        self:SetTextColor(color)
    end,

    SetAlpha = function(self, alpha, applyToChildren)
        Border.SetAlpha(self, alpha, applyToChildren)
        self._text:SetAlpha(alpha, applyToChildren)
    end

}
