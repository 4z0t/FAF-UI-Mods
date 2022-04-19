local Prefs = import('/lua/user/prefs.lua')
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
local UIMain = import('/lua/ui/uimain.lua')
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local From = import('/mods/UMT/modules/linq.lua').From

local GUI
function init()
    if IsDestroyed(GUI) then
        GUI = CreateUI(GetFrame(0))
    end
end

local skins = {'cybran', 'seraphim', 'aeon', 'uef'}

local divisions = {{'BUILTBYTIER3ENGINEER'}, -- structures
{'BUILTBYTIER3FACTORY', 'LAND'}, -- land units
{'BUILTBYTIER3FACTORY', 'AIR'}, -- air units
{'BUILTBYTIER3FACTORY', 'NAVAL'} -- naval units
}

function CreateUI(parent)
    local group = Group(parent)
    LayoutHelpers.SetDimensions(group, 1000, 800)
    LayoutHelpers.AtCenterIn(group, parent)

    group.popup = Popup(parent, group)
    LayoutHelpers.DepthOverParent(group, group.popup, 10)

    group.Title = UIUtil.CreateText(group, 'KeyBinds Overhaul', 16, UIUtil.titleFont, true)
    LayoutHelpers.AtHorizontalCenterIn(group.Title, group)
    LayoutHelpers.AtTopIn(group.Title, group, 5)

    group.QuitButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Close>Close"))
    LayoutHelpers.AtHorizontalCenterIn(group.QuitButton, group, 100)
    LayoutHelpers.AtBottomIn(group.QuitButton, group, 5)
    LayoutHelpers.DepthOverParent(group.QuitButton, group)

    group.QuitButton.OnClick = function(control, modifiers)
        group.popup:Destroy()
        group:Destroy()
    end

    group.OkButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Ok>Ok"))
    LayoutHelpers.AtHorizontalCenterIn(group.OkButton, group, -100)
    LayoutHelpers.AtBottomIn(group.OkButton, group, 5)
    LayoutHelpers.DepthOverParent(group.OkButton, group)

    group.OkButton.OnClick = function(control, modifiers)

    end
    local strLen = string.len
    LOG(repr(__blueprints['urb3103'].Categories))
    local legalCategories = From({'BUILTBYTIER1FACTORY', 'BUILTBYTIER2FACTORY', 'BUILTBYTIER3FACTORY',
                                  'BUILTBYTIER1ENGINEER', 'BUILTBYTIER2ENGINEER', 'BUILTBYTIER3ENGINEER',
                                  'BUILTBYCOMMANDER', 'BUILTBYQUANTUMGATE'})
    local bps = From(__blueprints):Where(function(id, bp)
        if strLen(id) == 7 then
            local bpf = From(bp.Categories)
            return bpf:Any(function(i, cat)
                return legalCategories:Contains(cat)
            end)
        end
        return false
    end)
    From(divisions):Foreach(function(i, div)

        From(skins):Foreach(function(k, skin)
            local test = BlueprintItem(group, skin)
            LayoutHelpers.AtLeftTopIn(test, group, 100 + 130 * k, i * 70 + 20)
            test.OnClick = function(self, event, bluprint)
                local upperSkin = string.upper(skin)
                local menu = BlueprintSelector(self, bps:Where(function(id, bp)
                    local categories = From(bp.Categories)
                    return categories:Contains(upperSkin) and From(div):All(function(_, cat)
                        return categories:Contains(cat)
                    end)
                end):Keys():Sort(function(a, b)
                    return string.sub(a, 4) > string.sub(b, 4)
                end):ToDictionary(), skin)
                LayoutHelpers.Below(menu, self)
                menu.OnItemClick = function(control, bluprint)
                    self:SetBlueprint(bluprint)
                    control:Destroy()
                end
            end
        end)
    end)

    return group
end

MAX_ITEMS = 10

BlueprintSelector = Class(Group) {
    __init = function(self, parent, blueprintArray, skin, maxItems)
        Group.__init(self, parent)
        LayoutHelpers.DepthOverParent(self, parent, 10)
        self._topLine = 1
        self._blueprints = blueprintArray
        self._numLines = maxItems or MAX_ITEMS
        self._dataSize = table.getn(blueprintArray)
        self._skin = skin

        -- group that covers window
        self._cover = Group(self)
        LayoutHelpers.FillParent(self._cover, GetFrame(self:GetRootFrame():GetTargetHead()))
        LayoutHelpers.DepthUnderParent(self._cover, self)
        self._cover.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                self:Destroy()
            end
        end

        self:CreateItems()
        self:CalcVisible()
    end,

    GetScrollValues = function(self, axis)
        return 1, self._dataSize, self._topLine, math.min(self._topLine + self._numLines - 1, self._dataSize)
    end,

    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + delta)
    end,

    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + math.floor(delta) * self._numLines)
    end,

    ScrollSetTop = function(self, axis, top)
        top = math.floor(math.max(math.min(self._dataSize - self._numLines + 1, top), 1))
        if top == self._topLine then
            return
        end
        self._topLine = top
        self:CalcVisible()
    end,

    ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self._numLines)
    end,

    -- determines what controls should be visible or not
    CalcVisible = function(self)
        local invIndex = 1
        local lineIndex = 1
        local dorender = false
        for index = self._topLine, self._numLines + self._topLine - 1 do
            self._lineGroup._lines[lineIndex]:SetBlueprint(self._blueprints[index])
            lineIndex = lineIndex + 1
        end
    end,

    CreateItems = function(self, skin)
        self._lineGroup = Bitmap(self)
        self._lineGroup:SetSolidColor('ff111111')
        self._lineGroup:DisableHitTest()

        LayoutHelpers.AtLeftTopIn(self._lineGroup, self)
        self._lineGroup._lines = {}
        local line
        local prev
        for index = 1, self._numLines do
            line = BlueprintItem(self._lineGroup, self._skin)
            if prev then
                LayoutHelpers.Below(line, prev, 2)
            else
                LayoutHelpers.AtLeftTopIn(line, self._lineGroup, 2, 2)
            end
            line.OnClick = function(control, event, blueprint)
                self:OnItemClick(blueprint)
            end
            self._lineGroup._lines[index] = line
            prev = line
        end
        LayoutHelpers.AtRightBottomIn(self._lineGroup, prev, -2, -2)
        LayoutHelpers.AtRightBottomIn(self, self._lineGroup)
        self._scroll = UIUtil.CreateVertScrollbarFor(self) -- scroller
    end,

    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            if event.WheelRotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
            return true
        end
        return false
    end,

    SetItem = function(self, index)

        self._curIndex = index
    end,

    GetItem = function(self)
        return self._curIndex
    end,

    OnEvent = function(self)
    end,

    OnItemClick = function(self, blueprint)

    end,

    OnMouseExit = function(self)
    end,

    OnOverItem = function(self, index, name)
    end

}

BlueprintItem = Class(Group) {
    __init = function(self, parent, skin)
        Group.__init(self, parent)
        LayoutHelpers.SetDimensions(self, 120, 50)

        self._icon = Bitmap(self, '/textures/ui/common/icons/units/default_icon.dds')
        LayoutHelpers.AtLeftIn(self._icon, self, 2)
        LayoutHelpers.AtVerticalCenterIn(self._icon, self)

        self._blueprint = 'default'

        self._blueprintText = UIUtil.CreateText(self, '', 12, UIUtil.bodyFont, true)
        LayoutHelpers.AtRightTopIn(self._blueprintText, self, 4, 3)

        self._bg = Bitmap(self)
        self._bg._over = '/textures/ui/' .. skin .. '/MODS/double.dds'
        self._bg._rest = '/textures/ui/' .. skin .. '/MODS/single.dds'
        self._bg:SetTexture(self._bg._rest)
        LayoutHelpers.FillParent(self._bg, self)

        self._icon:DisableHitTest()
        self._bg:DisableHitTest()
        self._blueprintText:DisableHitTest()

    end,

    SetBlueprint = function(self, blueprint)
        if blueprint then
            local icon = UIUtil.UIFile('/icons/units/' .. blueprint .. '_icon.dds', true)
            -- local icon = GameCommon.GetCachedUnitIconFileNames(blueprint)
            self._blueprint = blueprint
            self._icon:SetTexture(icon)
            self._blueprintText:SetText(blueprint)
        else
            self._icon:SetTexture('/textures/ui/common/icons/units/default_icon.dds')
            self._blueprint = 'default'
            self._blueprintText:SetText('')
        end
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            self._bg:SetTexture(self._bg._rest)
            return true
        elseif event.Type == 'MouseEnter' then
            self._bg:SetTexture(self._bg._over)
            return true
        elseif event.Type == 'ButtonPress' then
            self:OnClick(event, self._blueprint)
            return true
        end
        return false
    end,

    -- overloadable
    OnClick = function(self, event, blueprint)

    end

}
