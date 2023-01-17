local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local LayoutFor = UMT.Layouter.ReusedLayoutFor
local ColorUtils = UMT.ColorUtils

local function IntColorSlider(parent)
    return IntegerSlider(
        parent,
        false,
        0,
        255,
        1,
        UIUtil.SkinnableFile("/slider02/slider_btn_up.dds"),
        UIUtil.SkinnableFile("/slider02/slider_btn_over.dds"),
        UIUtil.SkinnableFile("/slider02/slider_btn_down.dds"),
        UIUtil.SkinnableFile("/dialogs/options-02/slider-back_bmp.dds")
    )
end

local ColorSlider = Class(Group)
{

    __init = function(self, parent)
        Group.__init(self, parent)
    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)
    end,

}

ColorSliders = Class(Group)
{

    __init = function(self, parent, optionVar, name)
        Group.__init(self, parent)
        self._option = optionVar

        self.name = UIUtil.CreateText(self, name, 14, "Arial")

        self.colorBitmap = Bitmap(self)

        self.alphaText = UIUtil.CreateText(self, "A", 14, "Arial")
        self.redText = UIUtil.CreateText(self, "R", 14, "Arial")
        self.greenText = UIUtil.CreateText(self, "G", 14, "Arial")
        self.blueText = UIUtil.CreateText(self, "B", 14, "Arial")

        self.alphaSlider = IntColorSlider(self)
        self.redSlider = IntColorSlider(self)
        self.greenSlider = IntColorSlider(self)
        self.blueSlider = IntColorSlider(self)


        self.alphaSlider.OnValueSet = function(control, newValue)
            optionVar:Set(ColorUtils.SetAlpha(optionVar(), newValue))
        end
        self.redSlider.OnValueSet = function(control, newValue)
            optionVar:Set(ColorUtils.SetRed(optionVar(), newValue))
        end
        self.greenSlider.OnValueSet = function(control, newValue)
            optionVar:Set(ColorUtils.SetGreen(optionVar(), newValue))
        end
        self.blueSlider.OnValueSet = function(control, newValue)
            optionVar:Set(ColorUtils.SetBlue(optionVar(), newValue))
        end

        self.alphaValue = UIUtil.CreateText(self, "A", 14, "Arial")
        self.redValue = UIUtil.CreateText(self, "R", 14, "Arial")
        self.greenValue = UIUtil.CreateText(self, "G", 14, "Arial")
        self.blueValue = UIUtil.CreateText(self, "B", 14, "Arial")

        self.alphaSlider.OnValueChanged = function(self, newValue)
            self.alphaValue:SetText(string.format("%3d", newValue))
        end

        self.redSlider.OnValueChanged = function(self, newValue)
            self.redValue:SetText(string.format("%3d", newValue))
        end

        self.greenSlider.OnValueChanged = function(self, newValue)
            self.greenValue:SetText(string.format("%3d", newValue))
        end

        self.blueSlider.OnValueChanged = function(self, newValue)
            self.blueValue:SetText(string.format("%3d", newValue))
        end



        self.alphaSlider:SetValue(ColorUtils.GetAlpha(self._option()))
        self.redSlider:SetValue(ColorUtils.GetRed(self._option()))
        self.greenSlider:SetValue(ColorUtils.GetGreen(self._option()))
        self.blueSlider:SetValue(ColorUtils.GetBlue(self._option()))


    end,

    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)
        LayoutFor(self.name)
            :AtLeftTopIn(self)

        LayoutFor(self.colorBitmap)
            :Below(self.name, 1)
            :Height(5)
            :Right(self.Right)
            :Color(self._option:Raw())


        LayoutFor(self.alphaText)
            :Color("white")
            :Below(self.colorBitmap, 1)

        LayoutFor(self.redText)
            :Color("red")
            :Below(self.alphaText, 1)

        LayoutFor(self.greenText)
            :Color("green")
            :Below(self.redText, 1)

        LayoutFor(self.blueText)
            :Color("blue")
            :Below(self.greenText, 1)

        LayoutFor(self.alphaSlider)
            :RightOf(self.alphaText, 1)
            :AtLeftIn(self, 15)

        LayoutFor(self.redSlider)
            :RightOf(self.redText, 1)
            :AtLeftIn(self, 15)

        LayoutFor(self.greenSlider)
            :RightOf(self.greenText, 1)
            :AtLeftIn(self, 15)

        LayoutFor(self.blueSlider)
            :RightOf(self.blueText, 1)
            :AtLeftIn(self, 15)

        LayoutFor(self.alphaValue)
            :RightOf(self.alphaSlider)

        LayoutFor(self.redValue)
            :RightOf(self.redSlider)

        LayoutFor(self.greenValue)
            :RightOf(self.greenSlider)

        LayoutFor(self.blueValue)
            :RightOf(self.blueSlider)


        LayoutFor(self)
            :Height(function()
                return self.blueSlider.Bottom() - self.name.Top()
            end)
            :Width(200)
    end,

    OnDestroy = function(self)
        self._option = nil
    end

}
