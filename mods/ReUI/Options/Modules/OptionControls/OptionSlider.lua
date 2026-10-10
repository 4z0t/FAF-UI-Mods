local UIUtil = import('/lua/ui/uiutil.lua')

local OptionControl = import("OptionControl.lua").OptionControl

local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider

local sliderTextures = {
    UIUtil.SkinnableFile("/slider02/slider_btn_up.dds"),
    UIUtil.SkinnableFile("/slider02/slider_btn_over.dds"),
    UIUtil.SkinnableFile("/slider02/slider_btn_down.dds"),
    UIUtil.SkinnableFile("/dialogs/options-02/slider-back_bmp.dds"),
}

local LF = ReUI.UI.LayoutFunctions

---@class ReUI.Options.OptionSlider :  ReUI.Options.OptionControl
---@field _name ReUI.UI.Controls.Text
---@field _slider IntegerSlider
OptionSlider = ReUI.Core.Class(OptionControl) {

    ---@param self ReUI.Options.OptionSlider
    ---@param parent Control
    ---@param option ReUI.Options.ReactiveOption
    __init = function(self, parent, option, name, min, max, inc)
        OptionControl.__init(self, parent, option)

        self._name = ReUI.UI.Controls.Text.Create(self, UIUtil.bodyFont, 14)
        self._name:SetText(name)

        self._slider = IntegerSlider(self, false, min, max, inc or 1, sliderTextures[1], sliderTextures[2],
            sliderTextures[3]
            , sliderTextures[4])

        self._valueText = ReUI.UI.Controls.Text.Create(self, UIUtil.bodyFont, 14)

        self._slider.OnValueChanged = function(s, newValue)
            self._valueText:SetText(string.format("%d", newValue))
        end
        self._slider.OnValueSet = function(s, newValue)
            option:Set(newValue)
        end

        self._slider:SetValue(option:Get() or 0)
    end,

    ---@param self ReUI.Options.OptionSlider
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self)
            :Height(40)

        layouter(self._name)
            :AtLeftTopIn(self)
            :DisableHitTest()

        layouter(self._slider)
            :Below(self._name, 2)
            :Width(LF.Mult(self.Width, 3 / 4))
            :Height(20)

        layouter(self._slider._background)
            :Width(self._slider.Width)
            :Height(self._slider.Height)

        layouter(self._valueText)
            :RightOf(self._slider, 4)
            :AtVerticalCenterIn(self._slider)
            :DisableHitTest()

    end,

    ---@param self ReUI.Options.OptionSlider
    ---@param newValue number
    ValueChanged = function(self, option, newValue)
        self._slider:SetValue(newValue)
    end
}
