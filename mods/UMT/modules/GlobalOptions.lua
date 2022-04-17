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
local OptionsWindow = import('OptionsWindow.lua').OptionsWindow
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local CheckBox = import('/lua/maui/checkbox.lua').Checkbox

local globalOptions = {}
local optionsSelector = nil
local optionsWindows = {}

--- adds options window builder for a mod
---@param option string
---@param title string
---@param buildTable table
---@return nil
function AddOptions(option, title, buildTable)
    globalOptions[option] = {title, buildTable}
end

local function CreateUI(parent)
    if IsDestroyed(optionsSelector) then
        optionsSelector = CreateOptionsSelector(parent)
    end
end

function main() 
    CreateUI(GetFrame(0))
end

function CreateOptionsSelector(parent)
    local group = Group(parent)
    LayoutHelpers.SetDimensions(group, 500, 500)
    LayoutHelpers.AtCenterIn(group, parent)

    group.popup = Popup(parent, group)
    LayoutHelpers.DepthOverParent(group, group.popup, 10)

    group.TopLine = 1
    group.SizeLine = table.getsize(globalOptions)

    group.Title = UIUtil.CreateText(group, 'UI Mods Options', 16, UIUtil.titleFont, true)
    LayoutHelpers.AtHorizontalCenterIn(group.Title, group)
    LayoutHelpers.AtTopIn(group.Title, group, 5)

    group.scroll = UIUtil.CreateLobbyVertScrollbar(group, -20, 10, 25) -- scroller
    LayoutHelpers.DepthOverParent(group.scroll, group, 10)

    group.QuitButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Close>Close"))
    LayoutHelpers.AtHorizontalCenterIn(group.QuitButton, group, 0)
    LayoutHelpers.AtBottomIn(group.QuitButton, group, 5)
    LayoutHelpers.DepthOverParent(group.QuitButton, group, 50)

    group.QuitButton.OnClick = function(self)
        group.popup:Destroy()
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    group.GetScrollValues = function(self, axis)
        return 1, self.SizeLine, self.TopLine, math.min(self.TopLine + self.numLines, self.SizeLine)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    group.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.TopLine + delta)
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    group.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.TopLine + math.floor(delta) * self.numLines)
    end

    -- called when the scrollbar wants to set a new visible top line
    group.ScrollSetTop = function(self, axis, top)
        if top == self.TopLine then
            return
        end
        self.TopLine = math.max(math.min(self.SizeLine - self.numLines + 1, top), 1)
        self:CalcVisible()
    end

    -- determines what controls should be visible or not
    group.CalcVisible = function(self)
        local index = 1
        local lineIndex = 1
        local dorender = false
        for id, opt in globalOptions do
            if index == self.TopLine then
                dorender = true
            end
            if dorender then
                self.LineGroup.Lines[lineIndex]:render(opt, id)
                if self.numLines == lineIndex then
                    return
                end
                lineIndex = lineIndex + 1
            end
            index = index + 1
        end
        for ind = lineIndex, self.numLines do
            self.LineGroup.Lines[ind]:render()
        end
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    group.IsScrollable = function(self, axis)
        return true
    end

    -- scrolling
    group.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            if event.WheelRotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
            return true
        end
        return false
    end

    group.LineGroup = Group(group) -- group that contains opt data lines
    LayoutHelpers.AtLeftIn(group.LineGroup, group, 5)
    LayoutHelpers.LeftOf(group.LineGroup, group.scroll, 5)
    LayoutHelpers.AtTopIn(group.LineGroup, group, 25)
    LayoutHelpers.AtBottomIn(group.LineGroup, group, 5)
    LayoutHelpers.DepthOverParent(group.LineGroup, group, 10)
    group.LineGroup.Lines = {}

    local function CreateOptionsSelectorLines()
        local function CreateOptionsSelectorLine()
            local line = Group(group.LineGroup)
            LayoutHelpers.DepthOverParent(line, group.LineGroup, 1)
            line.bg = CheckBox(line, UIUtil.SkinnableFile('/MODS/blank.dds'), UIUtil.SkinnableFile('/MODS/single.dds'),
                UIUtil.SkinnableFile('/MODS/single.dds'), UIUtil.SkinnableFile('/MODS/double.dds'),
                UIUtil.SkinnableFile('/MODS/disabled.dds'), UIUtil.SkinnableFile('/MODS/disabled.dds'),
                'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
            LayoutHelpers.SetDimensions(line, 80, 30)
            LayoutHelpers.FillParent(line.bg, line)
            LayoutHelpers.DepthOverParent(line.bg, line, 1)
            line.bg:Disable()

            line.name = UIUtil.CreateText(line, '', 14, UIUtil.bodyFont, true)
            line.name:SetColor('FFE9ECE9')
            line.name:DisableHitTest()
            LayoutHelpers.AtLeftIn(line.name, line, 5)
            LayoutHelpers.AtVerticalCenterIn(line.name, line)

            line.render = function(self, data, id)
                if data then
                    self.bg.id = id
                    self.bg.data = data
                    self.name:SetText(data[1])
                    self.bg:Enable()
                    self.bg:SetCheck(false, true)
                else
                    self.name:SetText('')
                    self.bg:Disable()
                end

            end

            line.bg.OnCheck = function(self, checked)
                group.popup:Destroy()
                if IsDestroyed(optionsWindows[self.id]) then
                    optionsWindows[self.id] = OptionsWindow(parent, self.data[1], self.id, self.data[2])
                end
            end
            return line
        end

        local index = 1
        group.LineGroup.Lines[index] = CreateOptionsSelectorLine()
        local parent = group.LineGroup.Lines[index]
        LayoutHelpers.AtLeftTopIn(parent, group.LineGroup, 5, 5)
        LayoutHelpers.AtRightIn(parent, group.LineGroup, 5)
        while group.LineGroup.Bottom() - parent.Bottom() > 85 do
            index = index + 1
            group.LineGroup.Lines[index] = CreateOptionsSelectorLine()
            LayoutHelpers.Below(group.LineGroup.Lines[index], parent, 5)
            LayoutHelpers.AtRightIn(group.LineGroup.Lines[index], parent)
            parent = group.LineGroup.Lines[index]
        end
        group.numLines = index
    end
    CreateOptionsSelectorLines()
    group:CalcVisible()
    return group
end

