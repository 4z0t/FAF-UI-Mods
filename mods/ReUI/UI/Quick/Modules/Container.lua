local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local Edit = import("/lua/maui/edit.lua").Edit
local Combo = import('/lua/ui/controls/combo.lua').Combo
local Tooltip = import('/lua/ui/game/tooltip.lua')

local StaticScrollable = ReUI.UI.Views.StaticScrollable

local LayoutFor = ReUI.UI.FloorLayoutFor
local LF = ReUI.UI.LayoutFunctions

local sliderTextures = {
    UIUtil.SkinnableFile("/slider02/slider_btn_up.dds"),
    UIUtil.SkinnableFile("/slider02/slider_btn_over.dds"),
    UIUtil.SkinnableFile("/slider02/slider_btn_down.dds"),
    UIUtil.SkinnableFile("/dialogs/options-02/slider-back_bmp.dds"),
}

---@class Quick.Settings
---@field width number
---@field height number


---@class Quick.Builder
---@field _content Control
---@field _cursorX number
---@field _cursorY number
---@field _lineHeight number
---@field _indent number
---@field _maxWidth number
---@field _maxHeight number
---@field _sameLine boolean
---@field _terminatedLine boolean
---@field _prevControl Control?
local Builder = Class()
{
    ---@param self Quick.Builder
    ---@param content Control
    __init = function(self, content)
        self._content = content

        self._cursorX = 0
        self._cursorY = 0

        self._lineHeight = 0
        self._indent = 0

        self._maxWidth = 0
        self._maxHeight = 0

        self._sameLine = false
        self._terminatedLine = false

        self._prevControl = nil
    end,

    ---@param self Quick.Builder
    ---@param control Control
    ---@param settings Quick.Settings
    _AddOnSameLine = function(self, control, settings)
        local content = self._content

        local width = settings.width
        local height = settings.height

        self._terminatedLine = width <= 0
        LayoutFor(control)
            :AtLeftTopIn(content, self._cursorX, self._cursorY)
            :Width(LF.Conditional(width <= 0,
                LayoutFor:Diff(content.Width, self._cursorX - width),
                width))
            :Height(height)


        self._lineHeight = math.max(height, self._lineHeight)
        self._cursorX = self._cursorX + width
    end,

    ---@param self Quick.Builder
    ---@param control Control
    ---@param settings Quick.Settings
    _AddOnNextLine = function(self, control, settings)
        local content = self._content

        self._cursorX = self._indent
        self._cursorY = self._cursorY + self._lineHeight

        local width = settings.width
        local height = settings.height

        self._terminatedLine = width <= 0
        LayoutFor(control)
            :AtLeftTopIn(content, self._cursorX, self._cursorY)
            :Width(LF.Conditional(width <= 0,
                LayoutFor:Diff(content.Width, self._cursorX - width),
                width))
            :Height(height)

        self._lineHeight = height
        self._cursorX = self._cursorX + width
    end,

    ---@param self Quick.Builder
    ---@param control Control
    ---@param settings Quick.Settings
    AddControl = function(self, control, settings)
        if self._sameLine then
            self._sameLine = false
            self:_AddOnSameLine(control, settings)
        else
            self:_AddOnNextLine(control, settings)
        end

        self._maxWidth  = math.max(self._maxWidth, self._cursorX)
        self._maxHeight = math.max(self._maxHeight, self._cursorY + self._lineHeight)

        self._prevControl = control
    end,

    ---@param self Quick.Builder
    ---@return Control?
    PrevControl = function(self)
        return self._prevControl
    end,

    ---@param self Quick.Builder
    ---@param spacing? number
    SameLine = function(self, spacing)
        if self._terminatedLine then
            error("attempt to add control on terminated line")
        end
        self._sameLine = true
        self._cursorX = self._cursorX + (spacing or 0)
    end,

    ---@param self Quick.Builder
    ---@param amount? number
    Indent = function(self, amount)
        self._indent = self._indent + (amount or 16)
    end,

    ---@param self Quick.Builder
    ---@param amount? number
    Unindent = function(self, amount)
        self._indent = math.max(0, self._indent - (amount or 16))
    end,
}

local _QuickContainer


---@class Quick.ScrollableList : ReUI.UI.Views.StaticScrollable
---@field _itemCount number
---@field _itemHeight number
---@field _lines Group
local QuickScrollableList = Class(StaticScrollable) {
    ---@param self Quick.ScrollableList
    ---@param parent Control
    ---@param itemCount number
    ---@param itemHeight number
    ---@param renderFn fun(q:Quick.Container, index:number)
    __init = function(self, parent, itemCount, itemHeight, renderFn)
        StaticScrollable.__init(self, parent)
        self._itemCount = itemCount
        self._itemHeight = itemHeight
        self._renderFn = renderFn

        self._lines = Group(self)
        LayoutFor(self._lines)
            :Fill(self)

        self._scroll = UIUtil.CreateVertScrollbarFor(self, -30)
        LayoutFor(self._scroll)
            :Over(self, 10)

        self._topLine = 1
    end,

    ---@param self Quick.ScrollableList
    CalcVisible = function(self)
        local h = LayoutFor:UnscaleNumber(self.Height())
        local numLines = math.floor(h / self._itemHeight)
        if numLines < 1 then numLines = 1 end
        self._numLines = numLines
        self._dataSize = self._itemCount

        self._lines:ClearChildren()
        local lineIndex = 1
        for index = self._topLine, self._numLines + self._topLine - 1 do
            local currentLineIndex = lineIndex
            self:RenderLine(currentLineIndex, index)
            lineIndex = lineIndex + 1
        end
    end,

    ---@param self Quick.ScrollableList
    GetScrollValues = function(self, axis)
        local h = LayoutFor:UnscaleNumber(self.Height())
        local numLines = math.floor(h / self._itemHeight)
        if numLines < 1 then numLines = 1 end
        self._numLines = numLines
        self._dataSize = self._itemCount
        return 1, self._dataSize, self._topLine, math.min(self._topLine + self._numLines - 1, self._dataSize)
    end,

    ---@param self Quick.ScrollableList
    ---@param lineIndex integer
    ---@param scrollIndex integer
    RenderLine = function(self, lineIndex, scrollIndex)
        local parent = self._lines
        local lineGroup = Group(parent)

        LayoutFor(lineGroup)
            :Height(self._itemHeight)
            :AtLeftIn(parent)
            :AtRightIn(parent, 30)-- Leave space for scrollbar
            :AtTopIn(parent, (lineIndex - 1) * self._itemHeight)
            :DisableHitTest(false)

        if scrollIndex <= self._itemCount then
            local container = _QuickContainer(lineGroup)
            container:Build(function(q)
                self._renderFn(q, scrollIndex)
            end)
        end
    end,
}

---@class Quick.Container
---@field _control Control
---@field _builder Quick.Builder
_QuickContainer = Class()
{
    ---@param self Quick.Container
    ---@param control Control
    __init = function(self, control)
        self._control = control
    end,

    ---@param self Quick.Container
    ---@param fn fun(q:Quick.Container)
    ---@return number, number
    Build = function(self, fn)
        self._builder = Builder(self._control)

        local ok, err = pcall(fn, self)
        if not ok then
            WARN(err)
        end

        local maxWidth, maxHeight = self._builder._maxWidth, self._builder._maxHeight
        self._builder = nil
        return maxWidth, maxHeight
    end,

    ---@param self Quick.Container
    Builder = function(self)
        assert(self._builder ~= nil, "Building didn't start")
        return self._builder
    end,

    ---@param self Quick.Container
    ---@param spacing? number
    SameLine = function(self, spacing)
        self:Builder():SameLine(spacing)
    end,

    ---@param self Quick.Container
    ---@param text string
    ---@param size? number
    ---@param font? string
    ---@param color? Color
    Text = function(self, text, size, font, color)
        local t = UIUtil.CreateText(self._control, text, size or 14, font or UIUtil.bodyFont)

        if color then t:SetColor(color) end

        self:Builder():AddControl(t, {
            width = LayoutFor:UnscaleNumber(t.Width()),
            height = LayoutFor:UnscaleNumber(t.Height())
        })
    end,

    ---@param self Quick.Container
    ---@param text string
    ---@param size? number
    ---@param font? string
    ---@param color? Color
    Title = function(self, text, size, font, color)
        self:Text(text, size or 16, font or UIUtil.titleFont, color or UIUtil.highlightColor)
    end,

    ---@param self Quick.Container
    ---@param text string
    ---@param onClick? fun(modifiers:KeyModifiers)
    ---@param size? number
    Button = function(self, text, onClick, size)
        local btn = UIUtil.CreateButtonStd(self._control, '/widgets02/small', text, size or 14)
        if onClick then
            btn.OnClick = function(control, modifiers) onClick(modifiers) end
        end
        self:Builder():AddControl(btn, {
            width = LayoutFor:UnscaleNumber(btn.Width()),
            height = LayoutFor:UnscaleNumber(btn.Height()),
        })
    end,

    ---@param self Quick.Container
    ---@param text string
    ---@param onCheck? fun(checked:boolean)
    ---@param checked? boolean
    Checkbox = function(self, text, onCheck, checked)
        local cb = UIUtil.CreateCheckbox(self._control, "/dialogs/check-box_btn/", text, true)
        if onCheck then
            cb.OnCheck = function(control, state) onCheck(state) end
        end
        if checked ~= nil then cb:SetCheck(checked, true) end
        self:Builder():AddControl(cb, {
            width = LayoutFor:UnscaleNumber(cb.Width()),
            height = LayoutFor:UnscaleNumber(cb.Height())
        })
    end,

    ---@param self Quick.Container
    ---@param label string
    ---@param min number
    ---@param max number
    ---@param inc number
    ---@param onValue? fun(value:number)
    ---@param initial? number
    Slider = function(self, label, min, max, inc, onValue, initial)
        local group = Group(self._control)

        LayoutFor(group)
            :Top(0)
            :Left(0)
            :Width(0)
            :Height(0)

        local name = UIUtil.CreateText(group, label, 14, UIUtil.bodyFont)
        LayoutFor(name)
            :AtLeftTopIn(group)
            :DisableHitTest()

        local slider = IntegerSlider(group, false, min, max, inc,
            sliderTextures[1], sliderTextures[2], sliderTextures[3], sliderTextures[4])

        LayoutFor(slider)
            :Below(name, 2)
            :Width(LF.Mult(group.Width, 3 / 4))
            :Height(20)

        LayoutFor(slider._background)
            :Width(slider.Width)
            :Height(slider.Height)

        local valueText = UIUtil.CreateText(group, "", 14, UIUtil.bodyFont)
        LayoutFor(valueText)
            :RightOf(slider, 4)
            :AtVerticalCenterIn(slider)
            :DisableHitTest()

        slider.OnValueChanged = function(s, newValue)
            valueText:SetText(string.format("%d", newValue))
        end
        if onValue then
            slider.OnValueSet = function(s, newValue) onValue(newValue) end
        end

        slider:SetValue(initial or 0)

        group.Slider = slider
        group.Label = name
        group.ValueText = valueText

        self:Builder():AddControl(group, {
            width = 0,
            height = 40
        })
    end,

    ---@param self Quick.Container
    ---@param label string
    ---@param onEdit? fun(text:string)
    ---@param charLimit? number
    ---@param initial? string
    Edit = function(self, label, onEdit, charLimit, initial)
        local group = Group(self._control)

        LayoutFor(group)
            :Top(0)
            :Left(0)
            :Width(0)
            :Height(0)

        local name = UIUtil.CreateText(group, label, 14, UIUtil.bodyFont)
        LayoutFor(name)
            :AtLeftTopIn(group)
            :DisableHitTest()

        local edit = Edit(group)
        LayoutFor(edit)
            :Below(name, 2)
            :Height(18)
            :AtLeftIn(group)
            :AtRightIn(group)

        UIUtil.SetupEditStd(edit, "ff00ff00", 'ff000000', "ffffffff",
            UIUtil.highlightColor, UIUtil.bodyFont, 16, charLimit or 100)
        if initial then edit:SetText(initial) end
        if onEdit then
            edit.OnEnterPressed = function(e, text)
                onEdit(text)
                return true
            end
        end

        group.Edit = edit
        group.Label = name

        self:Builder():AddControl(group, {
            width = 0,
            height = 40
        })
    end,

    ---@param self Quick.Container
    ---@param texture FileName
    ---@param width number
    ---@param height? number
    Image = function(self, texture, width, height)
        local img = Bitmap(self._control, texture)

        if height then
            LayoutFor(img)
                :Width(width)
                :Height(height)
        else
            LayoutFor(img)
                :Width(width)
                :Height(function()
                    return img.Width() / img.BitmapWidth() * img.BitmapHeight()
                end)
        end

        self:Builder():AddControl(img, {
            width = LayoutFor:UnscaleNumber(img.Width()),
            height = LayoutFor:UnscaleNumber(img.Height())
        })
    end,

    ---@param self Quick.Container
    ---@param label string
    ---@param items string[]
    ---@param onSelected? fun(index:number, text:string)
    ---@param selectedIndex? number
    Combo = function(self, label, items, onSelected, selectedIndex)
        selectedIndex = selectedIndex or 1

        local group = Group(self._control)

        LayoutFor(group)
            :Width(0)

        local name = UIUtil.CreateText(group, label, 14, UIUtil.bodyFont)
        LayoutFor(name)
            :AtLeftTopIn(group, 2)
            :DisableHitTest()

        ---@type Combo
        local combo = Combo(group, 13, 16)

        LayoutFor(combo)
            :Below(name, 2)
            :AtLeftIn(group, 2)
            :AtRightIn(group, 2)

        if onSelected then
            combo.OnClick = function(c, i, text) onSelected(i, text) end
        end

        combo:AddItems(items, selectedIndex)

        group.Combo = combo
        group.Label = name

        self:Builder():AddControl(group, {
            width = 0,
            height = 40
        })
    end,

    ---@param self Quick.Container
    ---@param width number
    ---@param height number
    ---@param fn fun(g:Quick.Container)
    Group = function(self, width, height, fn)
        ---@type Group
        local g = Group(self._control)

        local w, h = _QuickContainer(g):Build(fn)

        if height == 0 then
            height = h
        end

        self:Builder():AddControl(g, {
            width = width,
            height = height
        })
    end,

    ---@param self Quick.Container
    ---@param width number
    ---@param height number
    ---@param itemCount number
    ---@param itemHeight number
    ---@param renderFn fun(row:Quick.Container, index:number)
    ScrollableList = function(self, width, height, itemCount, itemHeight, renderFn)
        local list = QuickScrollableList(self._control, itemCount, itemHeight, renderFn)

        self:Builder():AddControl(list, {
            width = width,
            height = height
        })

        -- Force initial render now that height is set
        list:CalcVisible()
    end,

    ---@param self Quick.Container
    ---@param amount? number
    Indent = function(self, amount)
        self:Builder():Indent(amount)
    end,

    ---@param self Quick.Container
    ---@param amount? number
    Unindent = function(self, amount)
        self:Builder():Unindent(amount)
    end,


    ---@param self Quick.Container
    ---@param title string
    ---@param text string
    ---@param delay? number
    Tooltip = function(self, title, text, delay)
        local prev = self:Builder():PrevControl()
        if prev == nil then
            return
        end
        Tooltip.AddControlTooltipManual(prev, title, text, delay)
    end
}

QuickContainer = _QuickContainer
