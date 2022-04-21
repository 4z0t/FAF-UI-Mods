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
local LazyVar = import('/lua/lazyvar.lua')
local IScrollable = import('IScrollable.lua').IScrollable
local BPItem = import('BlueprintItem.lua')
local BlueprintItem = BPItem.BlueprintItem
local BPITEM_WIDTH = BPItem.BPITEM_WIDTH
local BPITEM_HEIGHT = BPItem.BPITEM_HEIGHT



local GUI
function init()
    if IsDestroyed(GUI) then
        GUI = CreateUI(GetFrame(0))
    end
end

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
}}

local prefixes = {
    ["aeon"] = {"ua", "xa", "da"},
    ["uef"] = {"ue", "xe", "de"},
    ["cybran"] = {"ur", "xr", "dr"},
    ["seraphim"] = {"xs", "us", "ds"}
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

    local legalCategories = From({'BUILTBYTIER1FACTORY', 'BUILTBYTIER2FACTORY', 'BUILTBYTIER3FACTORY',
                                  'BUILTBYTIER1ENGINEER', 'BUILTBYTIER2ENGINEER', 'BUILTBYTIER3ENGINEER',
                                  'BUILTBYCOMMANDER', 'BUILTBYQUANTUMGATE', 'BUILTBYLANDTIER3FACTORY', -- special for sparky
                                  'TRANSPORTBUILTBYTIER3FACTORY' -- all transports and mercy
    })
    local bps = From(__blueprints):Where(function(id, bp)
        if strLen(id) == 7 then
            return From(bp.Categories):Any(function(i, cat)
                return legalCategories:Contains(cat)
            end)
        end
        return false
    end)
    local constructionBPs = {}
    From(skins):Foreach(function(k, skin)
        local upperSkin = string.upper(skin)
        constructionBPs[skin] = bps:Where(function(id, bp)
            local categories = From(bp.Categories)
            return categories:Contains(upperSkin) and From(divisions[1].all):All(function(_, cat)
                return categories:Contains(cat)
            end) and From(divisions[1].any):Any(function(_, cat)
                return categories:Contains(cat)
            end)
        end):Keys():Sort(function(a, b)
            return string.sub(a, 4) < string.sub(b, 4)
        end):ToDictionary()
    end)
    group.construction = ConstructionScrollArea(group, constructionBPs, 5)
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

            local upperSkin = string.upper(skin)
            local selector = BlueprintItem(group, skin)
            selector.bps = bps:Where(function(id, bp)
                local categories = From(bp.Categories)
                return categories:Contains(upperSkin) and From(div.all):All(function(_, cat)
                    return categories:Contains(cat)
                end) and From(div.any):Any(function(_, cat)
                    return categories:Contains(cat)
                end)
            end):Keys():Sort(function(a, b)
                return string.sub(a, 4) < string.sub(b, 4)
            end)
            LayoutHelpers.AtLeftTopIn(selector, group, 100 + 200 * (k - 1), 200 + i * 80 + 20)
            selector.OnClick = function(self, modifiers, bluprint)
                if modifiers.Left then
                    -- if IsDestroyed(self.menu) then
                    local menu = BlueprintSelector(self, self.bps:ToDictionary(), skin)
                    menu.OnItemClick = function(control, bluprint)
                        self:SetBlueprint(bluprint)
                        control:Destroy()
                    end
                    self.menu = menu
                    -- end
                elseif modifiers.Right then
                    self:SetBlueprint()
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
                local bp
                local skin
                for selectorSkin, selector in group.categories[div.name].selectors do
                    if selector:GetBlueprint() then
                        if bp then
                            return
                        end
                        bp = selector:GetBlueprint()
                        skin = selectorSkin
                    end
                end
                if bp then
                    local suffix = string.sub(bp, 3)
                    local pref = string.sub(bp, 1, 2)
                    local prefixId = 1
                    for id, prefix in prefixes[skin] do
                        if pref == prefix then
                            prefixId = id
                            break
                        end
                    end
                    for prefixSkin, prefix in prefixes do
                        if group.categories[div.name].selectors[prefixSkin].bps:Contains(prefix[prefixId] .. suffix) then
                            group.categories[div.name].selectors[prefixSkin]:SetBlueprint(prefix[prefixId] .. suffix)
                        end
                    end
                end
            elseif modifiers.Right then
                for _, selector in group.categories[div.name].selectors do
                    selector:SetBlueprint()
                end
            end
        end
    end)

    return group
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
        self._data = {}
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
                    local temp = self._data[group.id]
                    self._data[group.id] = self._data[self._swapIndex]
                    self._data[self._swapIndex] = temp
                    self._swapIndex = false
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
                        self._data[control.id] = self._data[control.id] or {}
                        self._data[control.id][skin] = bluprint
                        item:Destroy()
                    end
                    control.menu = menu
                    -- end
                elseif modifiers.Right then
                    self._data[control.id] = self._data[control.id] or {}
                    self._data[control.id][skin] = nil
                    control:SetBlueprint()
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
                local bp
                local skin
                for selectorSkin, selector in group.selectors do
                    if selector:GetBlueprint() then
                        if bp then
                            return
                        end
                        bp = selector:GetBlueprint()
                        skin = selectorSkin
                    end
                end
                if bp then
                    local suffix = string.sub(bp, 3)
                    local pref = string.sub(bp, 1, 2)
                    local prefixId = 1
                    for id, prefix in prefixes[skin] do
                        if pref == prefix then
                            prefixId = id
                            break
                        end
                    end
                    for prefixSkin, prefix in prefixes do
                        if group.selectors[prefixSkin].bps:Contains(prefix[prefixId] .. suffix) then
                            group.selectors[prefixSkin]:SetBlueprint(prefix[prefixId] .. suffix)
                            self._data[group.selectors[prefixSkin].id][prefixSkin] = prefix[prefixId] .. suffix
                        end
                    end
                end
            elseif modifiers.Right then
                for skin, selector in group.selectors do
                    selector:SetBlueprint()
                    self._data[selector.id][skin] = false
                end
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
            local bp
            if self._data[scrollIndex] then
                bp = self._data[scrollIndex][skin]
            end
            selector.id = scrollIndex
            selector:SetBlueprint(bp)
        end
    end,

    OnEvent = function(self, event)
        return true
    end

}


