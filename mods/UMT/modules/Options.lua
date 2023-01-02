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
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local CheckBox = import('/lua/maui/checkbox.lua').Checkbox

local OptionsWindow = import('OptionsWindow.lua').OptionsWindow
local LayoutFor = UMT.Layout.ReusedLayoutFor
local DynamicScrollable = UMT.Views.DynamicScrollable
local EscapeCover = UMT.Views.EscapeCover




---@class ControlConfig
---@field type  "splitter"|"title"|"color"|"slider"|"filter"|"edit"|"colorslider"|"strings"
---@field name string
---@field optionVar OptionVar
---@field indent number


local splitterTable = {
    type = "splitter"
}

---comment
---@return ControlConfig
function Splitter()
    return splitterTable
end

---comment
---@return ControlConfig
function Title(name, fontSize, fontFamily, fontColor, indent)
    return {
        type = "title",
        name = name,
        size = fontSize or 16,
        family = fontFamily or UIUtil.titleFont,
        color = fontColor or UIUtil.highlightColor,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function Color(name, optionVar, indent)
    return {
        type = "color",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function Filter(name, optionVar, indent)
    return {
        type = "filter",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function Slider(name, min, max, inc, optionVar, indent)
    return {
        type = "slider",
        name = name,
        optionVar = optionVar,
        min = min,
        max = max,
        inc = inc,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function TextEdit(name, optionVar, indent)
    return {
        type = "edit",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function ColorSlider(name, optionVar, indent)
    return {
        type = "colorslider",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }
end

---@return ControlConfig
function Strings(name, items, optionVar, indent)
    return {
        type      = "strings",
        name      = name,
        optionVar = optionVar,
        items     = items,
        indent    = indent or 0
    }
end

function Fonts(name, optionVar, indent)
    return Strings(name,
        {
            "Arial",
            "Arial Black",
            "Arial Narrow",
            "Zeros Three",
            "Butterbelly",
            "Arial Rounded MT Bold",
            "VDub",
            "Wintermute"
        }, optionVar, indent)
end

local globalOptions = {}
local optionsSelector = nil
local optionsWindows = UMT.Weak.Value {}

local OptionLine = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self._bg = CheckBox(self,
            UIUtil.SkinnableFile('/MODS/blank.dds'),
            UIUtil.SkinnableFile('/MODS/single.dds'),
            UIUtil.SkinnableFile('/MODS/single.dds'),
            UIUtil.SkinnableFile('/MODS/double.dds'),
            UIUtil.SkinnableFile('/MODS/disabled.dds'),
            UIUtil.SkinnableFile('/MODS/disabled.dds'),
            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')

        self._name = UIUtil.CreateText(self, '', 14, UIUtil.bodyFont, true)

        self._bg.OnCheck = function(bg, checked)
            if IsDestroyed(optionsWindows[self.id]) then
                optionsWindows[self.id] = OptionsWindow(GetFrame(parent:GetRootFrame():GetTargetHead()), self.data[1],
                    self.id, self.data[2])
                optionsSelector:Destroy()
            end
        end
    end,
    __post_init = function(self, parent)
        self:_Layout(parent)
    end,

    _Layout = function(self, parent)

        LayoutFor(self._bg)
            :Fill(self)
            :Over(self)
            :Disable()

        LayoutFor(self._name)
            :TextColor('FFE9ECE9')
            :HitTest(false)
            :AtLeftIn(self, 5)
            :AtVerticalCenterIn(self)
        LayoutFor(self)
            :Height(30)
            :Over(parent)
    end,

    Render = function(self, data, id)
        if data then
            self.id = id
            self.data = data
            self._name:SetText(data[1])
            self._bg:Enable()
            self._bg:SetCheck(false, true)
        else
            self._name:SetText('')
            self._bg:Disable()
        end
    end,

}

local OptionSelector = Class(DynamicScrollable)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self._cover = EscapeCover(self)
        self._title = UIUtil.CreateText(self, 'UI Mods Options', 16, UIUtil.titleFont, true)
        self._scroll = UIUtil.CreateLobbyVertScrollbar(self, -20, 10, 25)
        self._quitButton = UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', LOC("<LOC _Close>Close"))

        self._lineGroup = Group(self)
        self._lineGroup.lines = {}

        self._bg = UIUtil.CreateNinePatchStd(self, '/scx_menu/lan-game-lobby/dialog/background/')

        self._quitButton.OnClick = function(button, modifiers)
            self:Destroy()
        end

        self._cover.OnClose = function(cover)
            self:Destroy()
        end
    end,

    __post_init = function(self, parent)
        self:_Layout(parent)
        self:_InitLines()
        self:CalcVisible()
    end,

    GetData = function(self)
        return globalOptions
    end,

    _InitLines = function(self)

        local index = 1
        self._lineGroup.lines[index] = OptionLine(self._lineGroup)
        local line = self._lineGroup.lines[index]

        LayoutFor(line)
            :AtLeftTopIn(self._lineGroup, 5, 5)
            :AtRightIn(self._lineGroup, 5)

        while self._lineGroup.Bottom() - line.Bottom() > 85 do
            index = index + 1
            self._lineGroup.lines[index] = OptionLine(self._lineGroup)
            LayoutFor(self._lineGroup.lines[index])
                :Below(line, 5)
                :AtRightIn(line)

            line = self._lineGroup.lines[index]
        end
        self:Setup(1, index)
    end,

    _Layout = function(self, parent)


        LayoutFor(self._title)
            :AtHorizontalCenterIn(self)
            :AtTopIn(self, 5)

        LayoutFor(self._scroll)
            :Over(self, 10)

        LayoutFor(self._quitButton)
            :AtHorizontalCenterIn(self)
            :AtBottomIn(self, 5)
            :Over(self, 20)

        LayoutFor(self._lineGroup)
            :AtLeftIn(self, 5)
            :LeftOf(self._scroll, 5)
            :AtTopIn(self, 25)
            :AtBottomIn(self, 5)
            :Over(self, 10)

        LayoutFor(self._bg)
            :FillFixedBorder(self, 64)
            :Under(self)


        LayoutFor(self)
            :Height(500)
            :Width(500)
            :Over(self._cover, 10)
            :AtCenterIn(parent)
    end,

    RenderLine = function(self, lineIndex, scrollIndex, key, value)
        self._lineGroup.lines[lineIndex]:Render(value, key)
    end,

    DataIter = function(self, key, data)
        return next(data, key)
    end,

    OnDestroy = function(self)
        optionsSelector = nil
    end

}


--- adds options window builder for a mod
---@param option string
---@param title string
---@param buildTable table
---@return nil
function AddOptions(option, title, buildTable)
    globalOptions[option] = { title, buildTable }
end

local function CreateUI(parent)
    if IsDestroyed(optionsSelector) then
        optionsSelector = OptionSelector(parent)
    end
end

function Main()
    CreateUI(GetFrame(0))
end
