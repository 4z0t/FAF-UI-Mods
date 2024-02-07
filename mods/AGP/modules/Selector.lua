local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local CheckBox = import('/lua/maui/checkbox.lua').Checkbox

local LayoutFor = UMT.Layouter.ReusedLayoutFor
local DynamicScrollable = UMT.Views.DynamicScrollable
local EscapeCover = UMT.Views.EscapeCover

---@class SelectorLine : Group
---@field data ExtensionInfo
---@field id string
---@field selector Selector
local SelectorLine = Class(Group)
{
    ---@param self SelectorLine
    ---@param parent Control
    __init = function(self, parent, selector)
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
        self.selector = selector
        self._bg.OnCheck = function(bg, checked)
            LOG(self.data.name)
            self.selector:OnSelect(self.id, checked)
            -- if IsDestroyed(optionsWindows[self.id]) then
            --     optionsWindows[self.id] = OptionsWindow(parent:GetRootFrame(), self.data[1],
            --         self.id, self.data[2])
            --     optionsSelector:Destroy()
            -- end
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

    ---@param self SelectorLine
    ---@param data ExtensionInfo
    ---@param id string
    Render = function(self, data, id)
        if data then
            self.id = id
            self.data = data
            self._name:SetText(data.name)
            self._bg:Enable()
            self._bg:SetCheck(data.enabled, true)
        else
            self._name:SetText('')
            self._bg:Disable()
        end
    end,

}

---@class Selector : DynamicScrollable
Selector = Class(DynamicScrollable)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        self._cover = EscapeCover(self)
        self._title = UIUtil.CreateText(self, 'Actions Grid Extensions', 16, UIUtil.titleFont, true)
        self._scroll = UIUtil.CreateLobbyVertScrollbar(self, -20, 10, 25)
        self._quitButton = UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', LOC("<LOC _Close>Close"))

        self._lineGroup = Group(self)
        self._lineGroup.lines = {}

        self._bg = UIUtil.CreateNinePatchStd(self, '/scx_menu/lan-game-lobby/dialog/background/')

        self._quitButton.OnClick = function(button, modifiers)
            self:OnClose()
            self:Destroy()
        end

        self._cover.OnClose = function(cover)
            self:OnClose()
            self:Destroy()
        end

        self._data = {}
    end,

    SetData = function(self, data)
        self._data = data
    end,

    ---@param self Selector
    ---@param id string
    OnSelect = function(self, id, enabled)
        LOG(id)
    end,

    __post_init = function(self, parent)
        self:InitLayout(parent)
        self:_InitLines()
        self:CalcVisible()
    end,

    GetData = function(self)
        return self._data
    end,

    _InitLines = function(self)

        local index = 1
        self._lineGroup.lines[index] = SelectorLine(self._lineGroup, self)
        local line = self._lineGroup.lines[index]

        LayoutFor(line)
            :AtLeftTopIn(self._lineGroup, 5, 5)
            :AtRightIn(self._lineGroup, 5)

        while self._lineGroup.Bottom() - line.Bottom() > 85 do
            index = index + 1
            self._lineGroup.lines[index] = SelectorLine(self._lineGroup, self)
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

    DataIter = function(self, key, data)
        return next(data, key)
    end,

    OnClose = function(self)
    end,

    OnDestroy = function(self)
        self._lineGroup = nil
    end

}
