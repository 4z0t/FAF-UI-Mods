local Group = import('/lua/maui/group.lua').Group
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import("/lua/maui/text.lua").Text
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor = LayoutHelpers.ReusedLayoutFor

local obsTextFont = "Zeroes Three"
local obsTextSize = 12

local bgColor = "ff000000"

local width = 300
local height = 30

ObserverPanel = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self._bg = Bitmap(self)

        self._slider = IntegerSlider(self, false, -10, 10, 1,
            UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
            UIUtil.SkinnableFile('/dialogs/options/slider-back_bmp.dds'))

        self._slider.OnValueSet = function(slider, newValue)
            ConExecute("WLD_GameSpeed " .. tostring(newValue))
        end

        self._slider:SetValue(0)


        self._observerText = Text(self)
        self._observerText:SetText(LOC("<LOC score_0003>Observer"))
        self._observerText:SetFont(obsTextFont, obsTextSize)
    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)

        LayoutFor(self._bg)
            :Fill(self)
            :Color(bgColor)
            :Alpha(0.4)
            :DisableHitTest()


        LayoutFor(self._observerText)
            :AtLeftTopIn(self, 10, 2)
            :DisableHitTest()

        LayoutFor(self._slider)
            :AtHorizontalCenterIn(self)
            :Bottom(self.Bottom)

        LayoutFor(self)
            :Width(width)
            :Height(height)

    end,

    SetGameSpeed = function(self, newSpeed)
        self._slider:SetValue(newSpeed)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' and not event.Modifiers.Shift and not event.Modifiers.Ctrl then
            ConExecute('SetFocusArmy -1')
        end
    end,


}
