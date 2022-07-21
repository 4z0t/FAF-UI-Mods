local Border = import("Border.lua").Border
local LayoutFor = import("/lua/maui/layouthelpers.lua").ReusedLayoutFor
local Text = import("/lua/maui/text.lua").Text



BorderedText = Class(Border)
{
    __init = function(self, parent, color, borderWidth)
        Border.__init(self, parent, color, borderWidth)
        self._text = Text(self)

        if color then
            self:SetTextColor(color)
        end

        LayoutFor(self._text)
            :AtCenterIn(self)
            :DisableHitTest()
    end,

    SetText = function(self, text)
        self._text:SetText(text)
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

}
