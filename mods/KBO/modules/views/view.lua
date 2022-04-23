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
local From = import('/mods/UMT/modules/linq.lua').From
local Edit = import('/lua/maui/edit.lua').Edit
local Combo = import('/lua/ui/controls/combo.lua').Combo

local LazyVar = import('/lua/lazyvar.lua')
local IScrollable = import('IScrollable.lua').IScrollable
local BPItem = import('BlueprintItem.lua')
local BlueprintItem = BPItem.BlueprintItem
local BPITEM_WIDTH = BPItem.BPITEM_WIDTH
local BPITEM_HEIGHT = BPItem.BPITEM_HEIGHT
local Presenter = import('/mods/KBO/modules/presenter.lua')

local skins = {'cybran', 'seraphim', 'aeon', 'uef'}

local divisions = {{
    name = 'Construction',
    all = {},
    any = {'BUILTBYTIER3ENGINEER'}
}, {
    name = 'Land',
    all = {'LAND'},
    any = {'BUILTBYTIER3FACTORY', 'BUILTBYLANDTIER3FACTORY'}
}, {
    name = 'Air',
    all = {'AIR'},
    any = {'BUILTBYTIER3FACTORY', 'TRANSPORTBUILTBYTIER3FACTORY'}
}, {
    name = 'Naval',
    all = {'NAVAL'},
    any = {'BUILTBYTIER3FACTORY'}
}, {
    name = 'Gate',
    all = {},
    any = {'BUILTBYQUANTUMGATE'}
}}

local GUI
function init()
    if IsDestroyed(GUI) then
        GUI = CreateUI(GetFrame(0))
    end
end

function CreateUI(parent)
    Presenter.SetActive()
    local group = Group(parent)
    LayoutHelpers.SetDimensions(group, 1000, 800)
    LayoutHelpers.AtCenterIn(group, parent)

    group.popup = Popup(parent, group)
    LayoutHelpers.DepthOverParent(group, group.popup, 10)

    group.Title = UIUtil.CreateText(group, 'KeyBinds Overhaul', 16, UIUtil.titleFont, true)
    LayoutHelpers.AtHorizontalCenterIn(group.Title, group)
    LayoutHelpers.AtTopIn(group.Title, group, 5)

    group.QuitButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Close>Close"))
    LayoutHelpers.AtHorizontalCenterIn(group.QuitButton, group, 150)
    LayoutHelpers.AtBottomIn(group.QuitButton, group, 5)
    LayoutHelpers.DepthOverParent(group.QuitButton, group)

    group.QuitButton.OnClick = function(control, modifiers)
        group.popup:Destroy()
        group:Destroy()
    end

    group.DelButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Delete>Delete"))
    LayoutHelpers.AtHorizontalCenterIn(group.DelButton, group)
    LayoutHelpers.AtBottomIn(group.DelButton, group, 5)
    LayoutHelpers.DepthOverParent(group.DelButton, group)

    group.DelButton.OnClick = function(control, modifiers)
        Presenter.SaveActive()
        Presenter.SetActive()
        group.edit:ClearText()
        group.combo:ClearItems()
        group.combo:AddItems(Presenter.FetchHotBuilds(true), 1)
        UpdateUI()
    end

    group.SaveButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Save>Save"))
    LayoutHelpers.AtHorizontalCenterIn(group.SaveButton, group, -150)
    LayoutHelpers.AtBottomIn(group.SaveButton, group, 5)
    LayoutHelpers.DepthOverParent(group.SaveButton, group)

    group.SaveButton.OnClick = function(control, modifiers)
        local text = group.edit:GetText()
        Presenter.SaveActive(text)
        group.combo:ClearItems()
        local newItems = Presenter.FetchHotBuilds(true)
        local index = 1
        for k, v in newItems do
            if v == text then
                index = k
                break
            end
        end
        group.combo:AddItems(newItems, index)
    end

    group.edit = Edit(group)
    LayoutHelpers.AtLeftTopIn(group.edit, group, 100, 40)
    UIUtil.SetupEditStd(group.edit, UIUtil.factionTextColor, nil, UIUtil.highlightColor, UIUtil.consoleBGColor, nil,
        nil, 20)
    LayoutHelpers.SetDimensions(group.edit, 200, 20)
    group.edit.OnEnterPressed = function(self, text)
        return true
    end

    group.combo = Combo(group, 16, 10)
    group.combo:AddItems(Presenter.FetchHotBuilds(true), 1)
    group.combo.OnClick = function(self, index, text)
        self:SetItem(index)
        group.edit:SetText(text)
        Presenter.SetActive(text)
        UpdateUI()
    end

    LayoutHelpers.AtLeftTopIn(group.combo, group, 50, 20)
    LayoutHelpers.SetWidth(group.combo, 200)

    group.construction = ConstructionScrollArea(group, Presenter.FetchConstructionBlueprints(), 5)
    LayoutHelpers.AtLeftTopIn(group.construction, group, 100, 100)
    group.categories = {}

    From(divisions):Foreach(function(i, div)
        if i == 1 then
            return
        end
        local name = UIUtil.CreateText(group, div.name, 14, UIUtil.bodyFont, true)
        group.categories[div.name] = {}
        group.categories[div.name].selectors = {}
        LayoutHelpers.AtLeftTopIn(name, group, 100, 200 + i * 80)
        From(skins):Foreach(function(k, skin)

            local selector = BlueprintItem(group, skin)
            selector:SetBlueprint(Presenter.FetchBlueprint(div.name, skin))
            selector.bps = Presenter.FetchBlueprints(div.name, skin)
            LayoutHelpers.AtLeftTopIn(selector, group, 100 + 200 * (k - 1), 200 + i * 80 + 20)
            selector.OnClick = function(self, modifiers, bluprint)
                if modifiers.Left then
                    -- if IsDestroyed(self.menu) then
                    local menu = BlueprintSelector(self, self.bps, skin)
                    menu.OnItemClick = function(control, bluprint)
                        self:SetBlueprint(bluprint)
                        Presenter.SetBlueprint(div.name, skin, bluprint)
                        control:Destroy()
                    end
                    self.menu = menu
                    -- end
                elseif modifiers.Right then
                    self:SetBlueprint()
                    Presenter.SetBlueprint(div.name, skin)
                end
            end
            group.categories[div.name].selectors[skin] = selector

        end)
        local fillButton = UIUtil.CreateButtonStd(group, '/widgets02/small', 'fill', 16)
        LayoutHelpers.AtLeftTopIn(fillButton, group, 900, 200 + i * 80 + 30)
        LayoutHelpers.SetDimensions(fillButton, 100, 30)
        LayoutHelpers.DepthOverParent(fillButton, group)
        fillButton.OnClick = function(control, modifiers)
            -- logic for filling alias blueprints
            if modifiers.Left then
                Presenter.FillBlueprints(div.name)
                for selectorSkin, selector in group.categories[div.name].selectors do
                    selector:SetBlueprint(Presenter.FetchBlueprint(div.name, selectorSkin))
                end
            elseif modifiers.Right then
                for selectorSkin, selector in group.categories[div.name].selectors do
                    selector:SetBlueprint()
                    Presenter.SetBlueprint(div.name, selectorSkin)
                end
            end
        end
    end)

    return group
end

function UpdateUI()
    if not IsDestroyed(GUI) then
        GUI.construction:CalcVisible()
        for name, category in GUI.categories do
            for faction, selector in category.selectors do
                selector:SetBlueprint(Presenter.FetchBlueprint(name, faction))
            end
        end
    end
end

local swapColor = LazyVar.Create("ff00ffff")
MAX_ITEMS = 7

BlueprintSelector = Class(IScrollable) {
    __init = function(self, parent, blueprintArray, skin, maxItems)
        IScrollable.__init(self, parent)
        LayoutHelpers.DepthOverParent(self, parent, 20)
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
        LayoutHelpers.SetDimensions(self, BPITEM_WIDTH + 4, (BPITEM_HEIGHT + 2) * self._numLines + 2)
        if parent.Bottom() + self.Height() > self._cover.Bottom() then
            LayoutHelpers.Above(self, parent, 2)
        else
            LayoutHelpers.Below(self, parent, 2)
        end
        self:CreateItems()
        self:CalcVisible()
    end,

    RenderLine = function(self, lineIndex, scrollIndex)
        self._lineGroup._lines[lineIndex]:SetBlueprint(self._blueprints[scrollIndex])
    end,

    CreateItems = function(self, skin)
        self._lineGroup = Bitmap(self)
        self._lineGroup:SetSolidColor('ff111111')
        self._lineGroup:DisableHitTest()
        LayoutHelpers.FillParent(self._lineGroup, self)
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
            line.OnClick = function(control, modifiers, blueprint)
                if blueprint then
                    self:OnItemClick(blueprint)
                end
            end
            self._lineGroup._lines[index] = line
            prev = line
        end
    end,

    -- overloadable
    OnItemClick = function(self, blueprint)

    end

}
DEFAULT_CONSTRUCTION_ITEM_COUNT = 4

ConstructionScrollArea = Class(IScrollable) {
    __init = function(self, parent, blueprints, itemCount)
        IScrollable.__init(self, parent)
        LayoutHelpers.DepthOverParent(self, parent, 10)

        self._blueprints = blueprints
        self._topLine = 1
        self._numLines = DEFAULT_CONSTRUCTION_ITEM_COUNT
        self._dataSize = itemCount or DEFAULT_CONSTRUCTION_ITEM_COUNT
        self._swapIndex = false

        self._title = UIUtil.CreateText(self, 'Construction', 14, UIUtil.bodyFont, true)
        LayoutHelpers.AtLeftTopIn(self._title, self, 2, 2)
        self:CreateItems()
        self:CalcVisible()
    end,

    CreateItems = function(self, skin)
        self._lineGroup = Group(self)
        self._lineGroup:DisableHitTest()

        LayoutHelpers.AtLeftTopIn(self._lineGroup, self)
        self._lineGroup._lines = {}
        local line
        local prev
        for index = 1, self._numLines do
            line = self:CreateItem(self._lineGroup, index)
            if prev then
                LayoutHelpers.Below(line, prev, 2)
            else
                LayoutHelpers.AtLeftTopIn(line, self._lineGroup, 2, 2)
            end
            self._lineGroup._lines[index] = line
            prev = line
        end
        LayoutHelpers.AtRightBottomIn(self._lineGroup, prev, -2, -2)
        LayoutHelpers.AtRightBottomIn(self, self._lineGroup)
    end,

    CreateItem = function(self, parent, index)
        local group = Group(parent)
        LayoutHelpers.SetDimensions(group, 800, 70)
        group.selectors = {}
        group.id = index

        group.indexText = UIUtil.CreateText(group, tostring(index), 20, UIUtil.titleFont, true)
        LayoutHelpers.AtLeftIn(group.indexText, group, 4)
        LayoutHelpers.AtVerticalCenterIn(group.indexText, group)
        group.indexText:SetColor(UIUtil.fontOverColor)

        group.indexText.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then -- swap logic for lines
                if self._swapIndex and self._swapIndex ~= group.id then
                    Presenter.Swap(self._swapIndex, group.id)
                    self._swapIndex = false
                    self:IncreaseSize()
                    self:DecreaseSize()
                    self:CalcVisible()
                    return true
                else
                    self._swapIndex = group.id
                end
                return false
            elseif event.Type == 'MouseExit' then
                if group.id == self._swapIndex then
                    control:SetColor(swapColor)
                else
                    control:SetColor(UIUtil.fontOverColor)
                end
                return true
            elseif event.Type == 'MouseEnter' then
                control:SetColor(UIUtil.highlightColor)
                return true
            end
        end

        From(skins):Foreach(function(k, skin)
            local selector = BlueprintItem(group, skin)
            selector.bps = From(self._blueprints[skin])
            selector.id = index
            LayoutHelpers.AtLeftTopIn(selector, group, 20 + 200 * (k - 1), 2)
            selector.OnClick = function(control, modifiers, bluprint)
                if modifiers.Left then
                    -- if IsDestroyed(self.menu) then
                    local menu = BlueprintSelector(control, control.bps:ToDictionary(), skin)
                    menu.OnItemClick = function(item, bluprint)
                        control:SetBlueprint(bluprint)
                        Presenter.SetConstructionBlueprint(control.id, skin, bluprint)
                        self:IncreaseSize()
                        item:Destroy()
                    end
                    control.menu = menu
                    -- end
                elseif modifiers.Right then
                    Presenter.SetConstructionBlueprint(control.id, skin)
                    control:SetBlueprint()
                    self:DecreaseSize()
                end
            end

            group.selectors[skin] = selector

        end)
        local fillButton = UIUtil.CreateButtonStd(group, '/widgets02/small', 'fill', 16)
        LayoutHelpers.AtLeftTopIn(fillButton, group, 900, 35)
        LayoutHelpers.SetDimensions(fillButton, 100, 30)
        LayoutHelpers.DepthOverParent(fillButton, group)
        fillButton.OnClick = function(control, modifiers)
            -- logic for filling alias blueprints
            if modifiers.Left then
                Presenter.FillConstructionBlueprints(group.id)
                self:CalcVisible()
            elseif modifiers.Right then
                for skin, selector in group.selectors do
                    selector:SetBlueprint()
                    Presenter.SetConstructionBlueprint(selector.id, skin)
                end
                self:DecreaseSize()
            end
        end

        return group
    end,

    RenderLine = function(self, lineIndex, scrollIndex)
        if scrollIndex == self._swapIndex then
            self._lineGroup._lines[lineIndex].indexText:SetColor(swapColor)
        else
            self._lineGroup._lines[lineIndex].indexText:SetColor(UIUtil.fontOverColor)
        end
        self._lineGroup._lines[lineIndex].indexText:SetText(tostring(scrollIndex))
        self._lineGroup._lines[lineIndex].id = scrollIndex
        for skin, selector in self._lineGroup._lines[lineIndex].selectors do
            local bp = Presenter.FetchConstructionBlueprint(scrollIndex, skin)
            selector.id = scrollIndex
            selector:SetBlueprint(bp)
        end
    end,

    OnEvent = function(self, event)
        return true
    end,

    IncreaseSize = function(self)
        if not Presenter.IsEmpty(self._dataSize) then
            self._dataSize = self._dataSize + 1
        end
        self:CalcVisible()
    end,

    DecreaseSize = function(self)
        if Presenter.IsEmpty(self._dataSize) and Presenter.IsEmpty(self._dataSize - 1) and
            (self._dataSize > DEFAULT_CONSTRUCTION_ITEM_COUNT) then
            self._dataSize = self._dataSize - 1
            self._topLine = math.max(math.min(self._dataSize - self._numLines + 1, self._topLine), 1)
        end
        self:CalcVisible()
    end

}

