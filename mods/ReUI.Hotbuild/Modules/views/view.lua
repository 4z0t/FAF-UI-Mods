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
local Edit = import('/lua/maui/edit.lua').Edit
local Combo = import('/lua/ui/controls/combo.lua').Combo

local Contains = ReUI.LINQ.IPairsEnumerator:Contains()
local LayoutFor = ReUI.UI.FloorLayoutFor
local LazyVar = import('/lua/lazyvar.lua')
local Scrollable = import('Scrollable.lua').Scrollable
local BPItem = import('BlueprintItem.lua')
local BlueprintItem = BPItem.BlueprintItem
local BPITEM_WIDTH = BPItem.BPITEM_WIDTH
local BPITEM_HEIGHT = BPItem.BPITEM_HEIGHT
local ViewModel = import('../viewmodel.lua')

local skins = { 'cybran', 'seraphim', 'aeon', 'uef' }

local singleCategories = { 'Land', 'Air', 'Naval', 'Gate' }

local GUI
function init(parent)
    if IsDestroyed(GUI) then
        GUI = CreateUI(parent)
    end
end

function IsActiveUI()
    return not IsDestroyed(GUI)
end

function CreateUI(parent)
    ViewModel.SetActive()
    local group = Group(parent)

    LayoutFor(group)
        :Width(1300)
        :Height(900)
        :AtCenterIn(parent)

    group.popup = Popup(parent, group)
    LayoutFor(group)
        :Over(group.popup, 10)


    group.Title = UIUtil.CreateText(group, 'HotBuild Overhaul', 16, UIUtil.titleFont, true)
    LayoutFor(group.Title)
        :AtHorizontalCenterIn(group)
        :AtTopIn(group, 5)


    group.QuitButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Close>Close"))
    LayoutFor(group.QuitButton)
        :AtHorizontalCenterIn(group, 150)
        :AtBottomIn(group, 5)
        :Over(group)


    group.QuitButton.OnClick = function(control, modifiers)
        group.popup:Destroy()
        group:Destroy()
    end

    group.DelButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Delete>Delete"))
    LayoutHelpers.AtHorizontalCenterIn(group.DelButton, group)
    LayoutHelpers.AtBottomIn(group.DelButton, group, 5)
    LayoutHelpers.DepthOverParent(group.DelButton, group)

    group.DelButton.OnClick = function(control, modifiers)
        ViewModel.SaveActive()
        ViewModel.SetActive()
        group.edit:ClearText()
        group.combo:ClearItems()
        group.combo:AddItems(ViewModel.FetchHotBuilds(true), 1)
        UpdateUI()
    end

    group.SaveButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Save>Save"))

    LayoutFor(group.SaveButton)
        :AtHorizontalCenterIn(group, -150)
        :AtBottomIn(group, 5)
        :Over(group)


    group.SaveButton.OnClick = function(control, modifiers)
        local text = group.edit:GetText()
        ViewModel.SaveActive(text)
        UpdateItems(text)
    end


    group.ShareButton = UIUtil.CreateButtonWithDropshadow(group, '/BUTTON/medium/', LOC("<LOC _Share>Share"))

    LayoutFor(group.ShareButton)
        :AtHorizontalCenterIn(group, -300)
        :AtBottomIn(group, 5)
        :Over(group)

    group.ShareButton.OnClick = function(control, modifiers)
        ViewModel.SendActiveBuildTable()
    end

    ---@type Edit
    group.edit = Edit(group)
    LayoutFor(group.edit)
        :AtTopCenterIn(group, 40)
        :Width(700)
        :Height(30)

    UIUtil.SetupEditStd(group.edit,
        UIUtil.factionTextColor,
        nil,
        UIUtil.highlightColor,
        UIUtil.consoleBGColor,
        "Arial", 24, 50
    )

    group.edit.OnEnterPressed = function(self, text)
        return true
    end

    group.combo = Combo(group, 16, 10)
    group.combo:AddItems(ViewModel.FetchHotBuilds(true), 1)
    group.combo.OnClick = function(self, index, text)
        self:SetItem(index)
        group.edit:SetText(text)
        ViewModel.SetActive(text)
        UpdateUI()
    end
    LayoutFor(group.combo)
        :LeftOf(group.edit, 20)
        :Width(200)

    group.construction = ConstructionScrollArea(group, ViewModel.FetchConstructionBlueprints(), 5)
    LayoutHelpers.AtLeftTopIn(group.construction, group, 100, 100)
    group.categories = {}
    group.single = Group(group)
    LayoutFor(group.single)
        :Below(group.construction, 10)
        :Height(500)
        :Width(group.construction.Width)

    local function CreateSingleCategory(category, catParent)
        local categoryGroup = Group(catParent)
        local name = UIUtil.CreateText(categoryGroup, category, 20, UIUtil.titleFont, true)
        LayoutHelpers.SetDimensions(categoryGroup, 1000, 80)
        LayoutHelpers.AtLeftTopIn(name, categoryGroup, 0, -15)

        categoryGroup.selectors = {}
        for k, skin in skins do
            local selector = BlueprintItem(categoryGroup, skin)
            selector:SetBlueprint(ViewModel.FetchBlueprint(category, skin))
            selector.bps = ViewModel.FetchBlueprints(category, skin)
            LayoutHelpers.AtLeftTopIn(selector, categoryGroup, 50 + 200 * (k - 1), 10)
            selector.OnClick = function(self, modifiers, bluprint)
                if modifiers.Left then
                    -- if IsDestroyed(self.menu) then
                    local menu = BlueprintSelector(self, self.bps, self._skin)
                    menu.OnItemClick = function(control, bluprint)
                        self:SetBlueprint(bluprint)
                        ViewModel.SetBlueprint(category, self._skin, bluprint)
                        control:Destroy()
                    end
                    self.menu = menu
                    -- end
                elseif modifiers.Right then
                    self:SetBlueprint()
                    ViewModel.SetBlueprint(category, self._skin)
                end
            end
            categoryGroup.selectors[skin] = selector
        end

        local fillButton = UIUtil.CreateButtonStd(categoryGroup, '/widgets02/small', 'fill', 16)
        LayoutFor(fillButton)
            :AtRightIn(categoryGroup, 50)
            :Width(100)
            :Height(30)
            :AtVerticalCenterIn(categoryGroup)
            :Over(categoryGroup)

        fillButton.OnClick = function(control, modifiers)
            -- logic for filling alias blueprints
            if modifiers.Left then
                ViewModel.FillBlueprints(category)
                for selectorSkin, selector in categoryGroup.selectors do
                    selector:SetBlueprint(ViewModel.FetchBlueprint(category, selectorSkin))
                end
            elseif modifiers.Right then
                for selectorSkin, selector in categoryGroup.selectors do
                    selector:SetBlueprint()
                    ViewModel.SetBlueprint(category, selectorSkin)
                end
            end
        end
        return categoryGroup
    end

    local prev
    for i, category in singleCategories do
        local categoryGroup = CreateSingleCategory(category, group.single)
        if prev then
            LayoutHelpers.Below(categoryGroup, prev, 10)
        else
            LayoutHelpers.AtLeftTopIn(categoryGroup, group.single, 0, 10)
        end
        group.categories[category] = categoryGroup
        prev = categoryGroup
    end

    return group
end

function UpdateUI()
    if IsDestroyed(GUI) then return end

    GUI.construction:SetSize(ViewModel.FetchConstructionCount())
    GUI.construction:CalcVisible()
    for name, category in GUI.categories do
        for faction, selector in category.selectors do
            selector:SetBlueprint(ViewModel.FetchBlueprint(name, faction))
        end
    end

end

function UpdateItems(item)
    if IsDestroyed(GUI) then return end

    local curItem
    if item then
        curItem = item
    else
        _, curItem = GUI.combo:GetItem()
    end
    GUI.combo:ClearItems()
    local items = ViewModel.FetchHotBuilds(true)
    local index = Contains(items, curItem) or 1
    GUI.combo:AddItems(items, index)
end

local swapColor = LazyVar.Create("ff00ffff")
MAX_ITEMS = 7

BlueprintSelector = Class(Scrollable) {
    __init = function(self, parent, blueprintArray, skin, maxItems)
        Scrollable.__init(self, parent)
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

---@class ConstructionScrollArea : Scrollable
---@field _title Text
ConstructionScrollArea = Class(Scrollable) {
    ---@param self ConstructionScrollArea
    ---@param parent Control
    ---@param blueprints any
    ---@param itemCount number
    __init = function(self, parent, blueprints, itemCount)
        Scrollable.__init(self, parent)
        LayoutHelpers.DepthOverParent(self, parent, 10)

        self:Setup(1, itemCount or DEFAULT_CONSTRUCTION_ITEM_COUNT, DEFAULT_CONSTRUCTION_ITEM_COUNT)
        self._blueprints = blueprints
        self._swapIndex = false

        self._title = UIUtil.CreateText(self, 'Construction', 20, UIUtil.titleFont, true)
        LayoutHelpers.AtLeftTopIn(self._title, self, 2, -20)
        self:CreateItems()
        self:CalcVisible()
    end,

    SetSize = function(self, size)
        self._dataSize = math.max(size, DEFAULT_CONSTRUCTION_ITEM_COUNT)
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
                LayoutHelpers.AtLeftTopIn(line, self._lineGroup, 0, 2)
            end
            self._lineGroup._lines[index] = line
            prev = line
        end
        LayoutHelpers.AtRightBottomIn(self._lineGroup, prev, -2, -2)
        LayoutHelpers.AtRightBottomIn(self, self._lineGroup)
    end,

    CreateItem = function(self, parent, index)
        local group = Group(parent)
        LayoutHelpers.SetDimensions(group, 1000, 70)
        group.selectors = {}
        group.id = index

        group.indexText = UIUtil.CreateText(group, tostring(index), 20, UIUtil.titleFont, true)
        LayoutHelpers.AtLeftIn(group.indexText, group, 4)
        LayoutHelpers.AtVerticalCenterIn(group.indexText, group)
        group.indexText:SetColor(UIUtil.fontOverColor)

        group.indexText.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then -- swap logic for lines
                if self._swapIndex and self._swapIndex ~= group.id then
                    ViewModel.Swap(self._swapIndex, group.id)
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

        for k, skin in skins do
            local selector = BlueprintItem(group, skin)
            selector.bps = self._blueprints[skin]
            selector.id = index
            LayoutHelpers.AtLeftTopIn(selector, group, 50 + 200 * (k - 1), 2)
            ---@param control BlueprintItem
            selector.OnClick = function(control, modifiers, bluprint)
                if modifiers.Left then
                    -- if IsDestroyed(self.menu) then
                    local menu = BlueprintSelector(control, control.bps, control._skin)
                    menu.OnItemClick = function(item, bluprint)
                        control:SetBlueprint(bluprint)
                        ViewModel.SetConstructionBlueprint(control.id, control._skin, bluprint)
                        self:IncreaseSize()
                        item:Destroy()
                    end
                    control.menu = menu
                    -- end
                elseif modifiers.Right then
                    ViewModel.SetConstructionBlueprint(control.id, control._skin)
                    control:SetBlueprint()
                    self:DecreaseSize()
                end
            end

            group.selectors[skin] = selector
        end

        local fillButton = UIUtil.CreateButtonStd(group, '/widgets02/small', 'fill', 16)
        LayoutHelpers.AtRightIn(fillButton, group, 50)
        LayoutHelpers.AtVerticalCenterIn(fillButton, group)
        LayoutHelpers.SetDimensions(fillButton, 100, 30)
        LayoutHelpers.DepthOverParent(fillButton, group)
        fillButton.OnClick = function(control, modifiers)
            -- logic for filling alias blueprints
            if modifiers.Left then
                ViewModel.FillConstructionBlueprints(group.id)
                self:CalcVisible()
            elseif modifiers.Right then
                for skin, selector in group.selectors do
                    selector:SetBlueprint()
                    ViewModel.SetConstructionBlueprint(selector.id, skin)
                end
                self:DecreaseSize()
            end
        end

        return group
    end,

    RenderLine = function(self, lineIndex, scrollIndex)
        local line = self._lineGroup._lines[lineIndex]
        if scrollIndex == self._swapIndex then
            line.indexText:SetColor(swapColor)
        else
            line.indexText:SetColor(UIUtil.fontOverColor)
        end
        line.indexText:SetText(tostring(scrollIndex))
        line.id = scrollIndex
        for skin, selector in line.selectors do
            local bp = ViewModel.FetchConstructionBlueprint(scrollIndex, skin)
            selector.id = scrollIndex
            selector:SetBlueprint(bp)
        end
    end,

    OnEvent = function(self, event)
        return true
    end,

    IncreaseSize = function(self)
        if not ViewModel.IsEmpty(self._dataSize) then
            self._dataSize = self._dataSize + 1
        end
        self:CalcVisible()
    end,

    DecreaseSize = function(self)
        if ViewModel.IsEmpty(self._dataSize) and
            ViewModel.IsEmpty(self._dataSize - 1) and
            self._dataSize > DEFAULT_CONSTRUCTION_ITEM_COUNT
        then
            self._dataSize = self._dataSize - 1
            self._topLine = math.max(math.min(self._dataSize - self._numLines + 1, self._topLine), 1)
        end
        self:CalcVisible()
    end

}
