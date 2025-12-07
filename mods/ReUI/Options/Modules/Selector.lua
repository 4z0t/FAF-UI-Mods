local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local CheckBox = import('/lua/maui/checkbox.lua').Checkbox

local OptionsWindow = import('OptionsWindow.lua').OptionsWindow
local LayoutFor = ReUI.UI.FloorLayoutFor
local DynamicScrollable = ReUI.UI.Views.DynamicScrollable
local EscapeCover = ReUI.UI.Views.EscapeCover


---@class ControlConfig
---@field type  "splitter"|"title"|"color"|"slider"|"filter"|"edit"|"colorslider"|"strings"|"column"
---@field name string
---@field optionVar OptionVar
---@field indent number

---@class OptionsInfo
---@field name string
---@field title string
---@field builder (fun(frame:Frame):Control)|ControlConfig[]

---#region Options build items

local splitterTable = {
    type = "splitter"
}

---comment
---@return ControlConfig
function Splitter()
    return splitterTable
end

function Column(index)
    return {
        type = "column",
        index = index
    }
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
function TextEdit(name, optionVar, charLimit, indent)
    return {
        type = "edit",
        name = name,
        optionVar = optionVar,
        charLimit = charLimit or 100,
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
            "Zeroes Three",
            "Butterbelly",
            "Arial Rounded MT Bold",
            "VDub",
            "Wintermute"
        }, optionVar, indent)
end

---#endregion

---@type OptionsInfo[]
local globalOptions = {}
local optionsSelector = nil
local optionsWindows = ReUI.Core.Weak.Value {}

---@class OptionLine : Group
---@field data OptionsInfo
---@field id integer
local OptionLine = Class(Group)
{
    ---@param self OptionLine
    ---@param parent Control
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
            if not IsDestroyed(optionsWindows[self.id]) then return end

            if iscallable(self.data.builder) then
                optionsWindows[self.id] = self.data.builder(parent:GetRootFrame())
            else
                optionsWindows[self.id] = OptionsWindow(
                    parent:GetRootFrame(),
                    self.data.title,
                    self.id,
                    self.data.builder
                )
            end

            optionsSelector:Destroy()
        end
    end,
    __post_init = function(self, parent)
        self:InitLayout(parent)
    end,

    InitLayout = function(self, parent)

        LayoutFor(self._bg)
            :Fill(self)
            :Over(self)
            :Disable()

        LayoutFor(self._name)
            :Color('FFE9ECE9')
            :DisableHitTest()
            :AtLeftIn(self, 5)
            :AtVerticalCenterIn(self)
        LayoutFor(self)
            :Height(30)
            :Over(parent)
    end,

    ---@param self OptionLine
    ---@param data OptionsInfo?
    ---@param id integer
    Render = function(self, data, id)
        if data then
            self.id = id
            self.data = data
            self._name:SetText(data.title)
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

        table.sort(globalOptions, function(a, b)
            return a.name < b.name
        end)
    end,

    __post_init = function(self, parent)
        self:InitLayout(parent)
        self:_InitLines()
        self:CalcVisible()
    end,

    GetData = function(self)
        return globalOptions
    end,

    DataIter = function(self, key, data)
        return next(data, key)
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

    InitLayout = function(self, parent)


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

    OnDestroy = function(self)
        optionsSelector = nil
    end

}


--- adds options window builder for a mod
---@param option string
---@param title string
---@param buildTable table|fun(frame:Frame):Control
function AddOptions(option, title, buildTable)
    option = (option:gsub("[^A-Za-z0-9]+", "_"))
    table.insert(globalOptions, {
        name = option,
        title = title,
        builder = buildTable
    })
end

local function CreateUI(parent)
    if IsDestroyed(optionsSelector) then
        optionsSelector = OptionSelector(parent)
    end
end

function Main()
    CreateUI(GetFrame(0))
end
