local Dragger = import('/lua/maui/dragger.lua').Dragger
local Prefs = import('/lua/user/prefs.lua')
local Window = import('/lua/maui/window.lua').Window
local Edit = import('/lua/maui/edit.lua').Edit
local Text = import('/lua/maui/text.lua').Text
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Control = import('/lua/maui/control.lua').Control
local Tooltip = import('/lua/ui/game/tooltip.lua')
local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local LazyVar = import('/lua/lazyvar.lua')

local LayoutFor = import('Layouter.lua').ReusedLayoutFor

local colors = {'ffffffff', 'ffff4242', 'ffefff42', 'ff4fff42', 'ff42fff8', 'ff424fff', 'ffff42eb', 'ffff9f42'}

local splitterTable = {
    type = 'splitter'
}
function Splitter()
    return splitterTable
end

function Title(name, fontSize, fontFamily, fontColor, indent)
    return {
        type = 'title',
        name = name,
        size = fontSize or 16,
        family = fontFamily or UIUtil.titleFont,
        color = fontColor or UIUtil.highlightColor,
        indent = indent or 0
    }
end

function Color(name, option, lazyVar, indent)
    return {
        type = 'color',
        name = name,
        option = option,
        lazyVar = lazyVar,
        indent = indent or 0
    }
end

function Filter(name, option, lazyVar, indent)
    return {
        type = 'filter',
        name = name,
        option = option,
        lazyVar = lazyVar,
        indent = indent or 0
    }
end

function Slider(name, option, min, max, inc, lazyVar, indent)
    return {
        type = 'slider',
        name = name,
        option = option,
        lazyVar = lazyVar,
        min = min,
        max = max,
        inc = inc,
        indent = indent or 0
    }
end


-- TODO
function TextEdit(name, option, lazyVar, indent)
    return {
        type = 'edit',
        name = name,
        option = option,
        lazyVar = lazyVar,
        indent = indent or 0
    }
end

function ColorSlider(name, option, lazyVar, indent)
    return {
        type = 'colorslider',
        name = name,
        option = option,
        lazyVar = lazyVar,
        indent = indent or 0
    }
end

-- extend group for options 
-- TODO:
function Extend()
    return nil
end


local function norm(s)
    if string.len(s) == 1 then
        return '0' .. s
    end
    return s
end

local function setRed(color, red)
    return string.sub(color, 1, 2) .. norm(STR_itox(red)) .. string.sub(color, 5)
end

local function setGreen(color, green)
    return string.sub(color, 1, 4) .. norm(STR_itox(green)) .. string.sub(color, 7)
end

local function setBlue(color, blue)
    return string.sub(color, 1, 6) .. norm(STR_itox(blue))
end

local function getRed(color)
    return STR_xtoi(string.sub(color, 3, 4))
end

local function getGreen(color)
    return STR_xtoi(string.sub(color, 5, 6))
end

local function getBlue(color)
    return STR_xtoi(string.sub(color, 7, 8))
end



OptionsWindow = Class(Window) {
    __init = function(self, parent, title, options, buildTable)
        local windowTextures = {
            tl = UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'),
            tr = UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'),
            tm = UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'),
            ml = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'),
            m = UIUtil.SkinnableFile('/game/panel/panel_brd_m.dds'),
            mr = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'),
            bl = UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'),
            bm = UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'),
            br = UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'),
            borderColor = '00415055'
        }
        Window.__init(self, parent, title, nil, false, false, true, false, options .. 'window', {
            Left = 100,
            Right = 600,
            Top = 100,
            Bottom = 800
        }, windowTextures)
        self._optionsGroup = Group(self)
        LayoutFor(self._optionsGroup)
            :FillFixedBorder(self.ClientGroup, 5)
            :Height(10)
            :ResetBottom()
            :Over(self.ClientGroup)

        local okBtn = UIUtil.CreateButtonStd(self, '/widgets02/small', '<LOC _Ok>', 16)
        LayoutFor(okBtn)
            :Below(self._optionsGroup, 4)
            :AtLeftIn(self._optionsGroup)
            :Over(self._optionsGroup)

        okBtn.OnClick = function(control)
            self:OnClose(true)
        end
        self._okBtn = okBtn
        self._colors = colors

        local cancelBtn = UIUtil.CreateButtonStd(self, '/widgets02/small', '<LOC _Cancel>', 16)
        LayoutFor(cancelBtn)
            :Below(self._optionsGroup, 4)
            :AtRightIn(self._optionsGroup)
            :ResetLeft()
            :Over(self._optionsGroup)

        cancelBtn.OnClick = function(control)
            self:OnClose()
        end
        self._tempOptions = {}
        self._lazyVars = {}
        self._options = options
        self._optionsTable = Prefs.GetFromCurrentProfile(options)
        self._previous = false
        if buildTable then
            for _, entry in buildTable do
                self:Add(entry, true)
            end
            if self._previous then
                self._optionsGroup.Bottom:Set(self._previous.Bottom)
            end
        end
        self:SizeToContents()
    end,

    SizeToContents = function(self)
        self.Bottom:Set(self._okBtn.Bottom)
        LayoutHelpers.ResetHeight(self)
        local tempHeight = self.Height()
        self.Height:Set(tempHeight + 10)
        LayoutHelpers.ResetBottom(self)
    end,

    ExtendColorSet = function(self, colorSet)
        self._colors = table.cat(self._colors, colorSet)
        -- LOG(repr(self._colors))
        return self
    end,

    Add = function(self, data, passSizing)
        local function CreateSplitter()
            local splitter = Bitmap(self._optionsGroup)
            LayoutFor(splitter)
                :BitmapColor('ff000000')
                :Left(self._optionsGroup.Left)
                :Right(self._optionsGroup.Right)
                :Height(2)
            return splitter
        end
        local function CreateEntry(data)
            local group = Group(self._optionsGroup)
            if data.type == 'filter' then
                group.check = UIUtil.CreateCheckbox(group, '/dialogs/check-box_btn/', data.name, true)
                LayoutHelpers.AtLeftTopIn(group.check, group)
                group.check.key = data.option
                group.Height:Set(group.check.Height)
                group.Width:Set(group.check.Width)
                group.check.OnCheck = function(control, checked)
                    if checked then
                        self:SetOption(control.key, 1)
                    else 
                        self:SetOption(control.key, 0)
                    end
                end
                group.check:SetCheck(self._optionsTable[data.option] ~= 0 or false, true)
            elseif data.type == 'color' then
                group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
                group.color = BitmapCombo(group, self._colors,
                    self:GetColorIndex(self._colors, self._optionsTable[data.option]) or 1, true, nil,
                    "UI_Tab_Rollover_01", "UI_Tab_Click_01")
                LayoutHelpers.AtLeftTopIn(group.color, group)
                LayoutHelpers.RightOf(group.name, group.color, 5)
                LayoutHelpers.AtVerticalCenterIn(group.name, group.color)
                LayoutHelpers.SetWidth(group.color, 55)
                LayoutHelpers.DepthOverParent(group.color, group)
                group.color.key = data.option
                group.Height:Set(group.color.Height)
                group.Width:Set(group.color.Width)
                group.color.OnClick = function(control, index)
                    self:SetOption(control.key, self._colors[index])
                end
            elseif data.type == 'slider' then
                group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
                LayoutHelpers.AtLeftTopIn(group.name, group)
                group.slider = IntegerSlider(group, false, data.min, data.max, data.inc,
                    UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
                    UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
                LayoutHelpers.Below(group.slider, group.name)
                group.slider.key = data.option
                group.Height:Set(function()
                    return group.name.Height() + group.slider.Height()
                end)
                group.slider.OnValueSet = function(control, newValue)
                    self:SetOption(control.key, newValue)
                end
                group.value = UIUtil.CreateText(group, '', 14, "Arial")
                LayoutHelpers.RightOf(group.value, group.slider)
                group.slider.OnValueChanged = function(self, newValue)
                    group.value:SetText(string.format('%3d', newValue))
                end
                group.slider:SetValue(self._optionsTable[data.option] or 1)
                LayoutHelpers.SetWidth(group, 200)
            elseif data.type == 'colorslider' then
                group.key = data.option
                group.colorValue = LazyVar.Create(self._optionsTable[data.option] or 'ffffffff')
                group.colorValue.OnDirty = function(var)
                    self:SetOption(group.key, var())
                end

                group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
                LayoutHelpers.AtLeftTopIn(group.name, group)

                group.colorBitmap = Bitmap(group)
                LayoutFor(group.colorBitmap)
                    :Below(group.name, 1)
                    :Height(2)
                    :Right(group.Right)
                    :BitmapColor(group.colorValue)

                
                group.redSlider = IntegerSlider(group, false, 0, 255, 1,
                    UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
                    UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
                group.greenSlider = IntegerSlider(group, false, 0, 255, 1,
                    UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
                    UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
                group.blueSlider = IntegerSlider(group, false, 0, 255, 1,
                    UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
                    UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
                LayoutHelpers.Below(group.redSlider, group.colorBitmap, 1)
                LayoutHelpers.Below(group.greenSlider, group.redSlider, 1)
                LayoutHelpers.Below(group.blueSlider, group.greenSlider, 1)


                group.redValue.OnValueSet = function(control, newValue)
                    group.colorValue:Set(setRed(group.colorValue(), newValue))
                end
                group.greenValue.OnValueSet = function(control, newValue)
                    group.colorValue:Set(setGreen(group.colorValue(), newValue))
                end
                group.blueValue.OnValueSet = function(control, newValue)
                    group.colorValue:Set(setBlue(group.colorValue(), newValue))
                end

                group.redValue = UIUtil.CreateText(group, '', 14, "Arial")
                group.greenValue = UIUtil.CreateText(group, '', 14, "Arial")
                group.blueValue = UIUtil.CreateText(group, '', 14, "Arial")
                LayoutHelpers.RightOf(group.redValue, group.redSlider)
                LayoutHelpers.RightOf(group.greenValue, group.greenSlider)
                LayoutHelpers.RightOf(group.blueValue, group.blueSlider)

                group.redSlider.OnValueChanged = function(self, newValue)
                    group.redValue:SetText(string.format('%3d', newValue))
                end

                group.greenSlider.OnValueChanged = function(self, newValue)
                    group.greenValue:SetText(string.format("%3d", newValue))
                end

                group.blueSlider.OnValueChanged = function(self, newValue)
                    group.blueValue:SetText(string.format("%3d", newValue))
                end

                group.Height:Set(function()
                    return group.name.Height() + group.colorBitmap.Height() + group.redSlider.Height() + group.greenSlider.Height() + group.blueSlider.Height()
                end)

                group.redSlider:SetValue(getRed(group.colorValue()))
                group.greenSlider:SetValue(getGreen(group.colorValue()))
                group.blueSlider:SetValue(getBlue(group.colorValue()))

                LayoutHelpers.SetWidth(group, 200)
            elseif data.type == 'title' then
                group.name = UIUtil.CreateText(group, data.name, data.size, data.family)
                group.name:SetColor(data.color)
                LayoutHelpers.AtLeftTopIn(group.name, group)
                LayoutHelpers.SetWidth(group, 200)
                group.Height:Set(group.name.Height)
            elseif data.type == 'splitter' then
                group.split = CreateSplitter()
                LayoutHelpers.AtTopIn(group.split, group)
                group.Width:Set(group.split.Width)
                group.Height:Set(group.split.Height)
            end
            return group
        end

        local entry = CreateEntry(data)
        self:_addEntry(entry, data.lazyVar, data.option, data.indent)
        if not passSizing then
            self._optionsGroup.Bottom:Set(self._previous.Bottom)
            self:SizeToContents()
        end
        return self
    end,

    _addEntry = function(self, entry, lazyvar, option, indent)
        if self._previous then
            LayoutHelpers.Below(entry, self._previous, 5)
            LayoutHelpers.AtLeftIn(entry, self._optionsGroup, indent)
        else
            LayoutHelpers.AtLeftTopIn(entry, self._optionsGroup, indent)
        end
        LayoutHelpers.DepthOverParent(entry, self._optionsGroup)
        self._previous = entry
        if lazyvar then
            self._lazyVars[option] = lazyvar
        end
    end,

    AddSplitter = function(self)
        return self:Add(Splitter())
    end,

    AddColor = function(self, name, option, lazyVar)
        return self:Add(Color(name, option, lazyVar))
    end,

    AddTitle = function(self, name, fontSize, fontFamily, fontColor)
        return self:Add(Title(name, fontSize, fontFamily, fontColor))
    end,

    AddSlider = function(self, name, option, min, max, inc, lazyVar)
        return self:Add(Slider(name, option, min, max, inc, lazyVar))
    end,

    AddFilter = function(self, name, option, lazyVar)
        return self:Add(Filter(name, option, lazyVar))
    end,

    AddColorSlider = function(self, name, option, lazyVar)
        return self:Add(ColorSlider(name, option, lazyVar))
    end,

    GetColorIndex = function(self, colorsTable, color)
        for id, c in colorsTable do
            if c == color then
                return id
            end
        end
    end,

    SetOption = function(self, option, value)
        self._tempOptions[option] = value
        self._lazyVars[option]:Set(value)
    end,

    SaveOptions = function(self)
        self._optionsTable = table.merged(self._optionsTable, self._tempOptions)
        Prefs.SetToCurrentProfile(self._options, self._optionsTable)
    end,

    RestoreOptions = function(self)
        for id, var in self._lazyVars do
            if self._optionsTable[id] then
                var:Set(self._optionsTable[id])
            end
        end
    end,

    OnClose = function(self, doSave)
        if doSave then
            self:SaveOptions()
        else
            self:RestoreOptions()
        end
        self._manually_destroyed = true
        self:Destroy()
    end,

    OnDestroy = function(self)
        if not self._manually_destroyed then
            self:RestoreOptions()
        end
        Window.OnDestroy(self)
    end
}
