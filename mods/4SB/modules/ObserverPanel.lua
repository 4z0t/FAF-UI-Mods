local Group = UMT.Controls.Group
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = UMT.Controls.Bitmap
local Text = UMT.Controls.Text
local Options = import("Options.lua")

local ColoredIntegerSlider = import("Views/ColoredSlider.lua").ColoredIntegerSlider

local obsTextFont = Options.observer.font:Raw()
local obsTextSize = 12

local bgColor = Options.player.color.bg:Raw()

local sliderColor = Options.observer.color.line:Raw()


local width = 300
local height = 20

---@class ObserverPanel : UMT.Group
---@field _bg Bitmap
ObserverPanel = UMT.Class(Group)
{
    ---@param self ObserverPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self._bg = Bitmap(self)

        self._slider = ColoredIntegerSlider(self, false, -10, 10, 1,
            sliderColor,
            "ffeeee00",
            "ffffff00",
            "ffffbb00",
            2
        )

        self._slider.OnValueSet = function(slider, newValue)
            ConExecute("WLD_GameSpeed " .. tostring(newValue))
        end

        self._speed = Text(self)
        self._speed:SetFont(obsTextFont, obsTextSize)

        self._slider.OnValueChanged = function(slider, newValue)
            self._speed:SetText(tostring(newValue))
        end

        self._slider:SetValue(0)

        self._observerText = Text(self)
        self._observerText:SetText(LOC "<LOC score_0003>Observer")
        self._observerText:SetFont(obsTextFont, obsTextSize)
    end,

    ---@param self ObserverPanel
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)

        layouter(self._bg)
            :Fill(self)
            :Color(bgColor)
            :DisableHitTest()


        layouter(self._observerText)
            :AtLeftTopIn(self, 10, 2)
            :Over(self, 10)
            :DisableHitTest()

        layouter(self._slider)
            :AtVerticalCenterIn(self)
            :AtRightIn(self, 25)
            :RightOf(self._observerText, 5)
            :Height(height - 4)
            :Over(self, 10)

        layouter(self._speed)
            :AtVerticalCenterIn(self)
            :RightOf(self._slider, 5)
            :Over(self, 10)
            :DisableHitTest()

        layouter(self)
            :Width(layouter:Min(self:GetParent().Width, width))
            :Height(height)

    end,

    SetGameSpeed = function(self, newSpeed)
        self._slider:SetValue(newSpeed)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' and not event.Modifiers.Shift and not event.Modifiers.Ctrl then
            ConExecute 'SetFocusArmy -1'
        end
    end,


}
