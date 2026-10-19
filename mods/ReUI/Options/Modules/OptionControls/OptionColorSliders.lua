local UIUtil = import('/lua/ui/uiutil.lua')

local OptionControl = import("OptionControl.lua").OptionControl

local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider


local Bitmap = ReUI.UI.Controls.Bitmap

local sliderTextures = {
    UIUtil.SkinnableFile("/slider02/slider_btn_up.dds"),
    UIUtil.SkinnableFile("/slider02/slider_btn_over.dds"),
    UIUtil.SkinnableFile("/slider02/slider_btn_down.dds"),
    UIUtil.SkinnableFile("/dialogs/options-02/slider-back_bmp.dds"),
}

local Color = ReUI.UI.Color
local LF = ReUI.UI.LayoutFunctions

---@class ReUI.Options.OptionColorSliders :  ReUI.Options.OptionControl
---@field _mode "RGB"|"ARGB"
OptionColorSliders = ReUI.Core.Class(OptionControl) {

    ---@param self ReUI.Options.OptionColorSliders
    ---@param parent Control
    ---@param option ReUI.Options.ReactiveOption
    __init = function(self, parent, option, name, mode)
        OptionControl.__init(self, parent, option)

        self._mode = mode or "ARGB"

        self._name = ReUI.UI.Controls.Text:Make(self, name, 14, UIUtil.bodyFont)

        self._color = Bitmap(self)

        if self._mode == "ARGB" then
            self._alphaSlider = self:MakeSlider("A", "white")
        end

        self._redSlider   = self:MakeSlider("R", "red")
        self._greenSlider = self:MakeSlider("G", "green")
        self._blueSlider  = self:MakeSlider("B", "blue")

        if self._mode == "ARGB" then
            self._alphaSlider.OnValueSet = function(control, newValue)
                option:Set(Color.SetAlpha(option:Get(), newValue))
            end
        end

        self._redSlider.OnValueSet = function(control, newValue)
            option:Set(Color.SetRed(option:Get(), newValue))
        end
        self._greenSlider.OnValueSet = function(control, newValue)
            option:Set(Color.SetGreen(option:Get(), newValue))
        end
        self._blueSlider.OnValueSet = function(control, newValue)
            option:Set(Color.SetBlue(option:Get(), newValue))
        end

        self:ValueChanged(option, option:Get())
    end,

    ---@param self ReUI.Options.OptionColorSliders
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self._name)
            :AtLeftTopIn(self)

        layouter(self._color)
            :AnchorToBottom(self._name)
            :Left(self.Left)
            :Right(self.Right)
            :Height(5)
            :Color(self.Option:Raw())

        local height = 0
        if self._alphaSlider then
            layouter(self._alphaSlider)
                :AnchorToBottom(self._color)
                :AtLeftIn(self._color, 15)

            layouter(self._redSlider)
                :Below(self._alphaSlider)
            height = 110
        else
            layouter(self._redSlider)
                :AnchorToBottom(self._color)
                :AtLeftIn(self._color, 15)
            height = 85
        end

        layouter(self._greenSlider)
            :Below(self._redSlider)

        layouter(self._blueSlider)
            :Below(self._greenSlider)

        layouter(self)
            :Width(240)
            :Height(height)
    end,

    ---@param self ReUI.Options.OptionColorSliders
    ---@param label string
    ---@param color Color
    MakeSlider = function(self, label, color)
        local layouter = self.Layouter

        local slider = IntegerSlider(self, false, 0, 255, 1, sliderTextures[1], sliderTextures[2], sliderTextures[3],
            sliderTextures[4])

        local labelText = ReUI.UI.Controls.Text:Make(self, label, 14, UIUtil.bodyFont, color)

        local valueText = ReUI.UI.Controls.Text:Make(self, "", 14, UIUtil.bodyFont)
        slider.OnValueChanged = function(slider_, newValue)
            valueText:SetText(string.format("%3d", newValue))
        end

        layouter(valueText)
            :RightOf(slider)
            :DisableHitTest()

        layouter(labelText)
            :LeftOf(slider, 1)
            :DisableHitTest()

        return slider
    end,

    ---@param self ReUI.Options.OptionColorSliders
    ---@param newValue string
    ValueChanged = function(self, option, newValue)
        if self._alphaSlider then
            self._alphaSlider:SetValue(Color.GetAlpha(newValue))
        end
        self._redSlider:SetValue(Color.GetRed(newValue))
        self._greenSlider:SetValue(Color.GetGreen(newValue))
        self._blueSlider:SetValue(Color.GetBlue(newValue))
    end
}
