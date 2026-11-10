local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local LayoutFor = ReUI.UI.FloorLayoutFor
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group

local Quick = ReUI.UI.Quick
local QuickContainer = Quick.Container
local QuickContext = Quick.Context
local QuickWindow = Quick.Window

local BlueprintItem = import('BlueprintItem.lua').BlueprintItem
local ViewModel = import('../viewmodel.lua')
local Model = import('../model.lua')

local skins = { 'cybran', 'seraphim', 'aeon', 'uef' }

local factionColors = {
    cybran   = "ffff4040",
    seraphim = "ff66ff66",
    aeon     = "ff40e0d0",
    uef      = "ff4da6ff",
}

local factionTitles = {
    cybran   = "Cybran",
    seraphim = "Seraphim",
    aeon     = "Aeon",
    uef      = "UEF",
}

local tierColors = {
    T1   = "ff88ccff",
    T2   = "ff88ff88",
    T3   = "ffffcc44",
    EXP  = "ffff4444",
    TMPL = "ffff88ff",
}

local factoryDivisions = {
    {
        id = "hb_sec_land",
        title = "Land Layer",
        categories = {
            { cat = "Land_T1", label = "Land T1" },
            { cat = "Land_T2", label = "Land T2" },
            { cat = "Land_T3", label = "Land T3" },
        }
    },
    {
        id = "hb_sec_air",
        title = "Air Layer",
        categories = {
            { cat = "Air_T1", label = "Air T1" },
            { cat = "Air_T2", label = "Air T2" },
            { cat = "Air_T3", label = "Air T3" },
        }
    },
    {
        id = "hb_sec_naval",
        title = "Naval Layer",
        categories = {
            { cat = "Naval_T1", label = "Naval T1" },
            { cat = "Naval_T2", label = "Naval T2" },
            { cat = "Naval_T3", label = "Naval T3" },
        }
    },
    {
        id = "hb_sec_gate",
        title = "Quantum Gate",
        categories = {
            { cat = "Gate", label = "Gate" },
        }
    }
}

---@class GridItem : Group
local GridItem = Class(Group) {
    ---@param self GridItem
    ---@param parent Control
    ---@param entry table
    ---@param isCurrent boolean
    ---@param onSelect fun(entry:any)
    __init = function(self, parent, entry, isCurrent, onSelect)
        Group.__init(self, parent)
        LayoutFor(self):Width(54):Height(54)

        self._bg = Bitmap(self)
        self._bg:SetSolidColor(isCurrent and "ff665500" or "ff1a1a1a")
        LayoutFor(self._bg):Fill(self):DisableHitTest()

        self._border = Bitmap(self)
        self._border:SetSolidColor(isCurrent and "ffffcc00" or "ff3a3a3a")
        LayoutFor(self._border):Fill(self):OffsetIn(self, 1, 1, 1, 1):DisableHitTest()

        local inner = Bitmap(self)
        inner:SetSolidColor(isCurrent and "ff2a2200" or "ff121212")
        LayoutFor(inner):Fill(self):OffsetIn(self, 2, 2, 2, 2):DisableHitTest()

        local iconFile = UIUtil.UIFile('/icons/units/' .. entry.id .. '_icon.dds', true)
        self._icon = Bitmap(self, iconFile)
        LayoutFor(self._icon):AtCenterIn(self):Width(46):Height(46):DisableHitTest()

        self._badge = UIUtil.CreateText(self, entry.tier, 9, UIUtil.bodyFont, true)
        self._badge:SetColor(tierColors[entry.tier] or "ffffffff")
        LayoutFor(self._badge):AtRightBottomIn(self, 3, 2):DisableHitTest()

        self.HandleEvent = function(s, event)
            if event.Type == 'MouseEnter' then
                self._border:SetSolidColor("ffffffff")
                return true
            elseif event.Type == 'MouseExit' then
                self._border:SetSolidColor(isCurrent and "ffffcc00" or "ff3a3a3a")
                return true
            elseif event.Type == 'ButtonPress' then
                onSelect(entry.raw)
                return true
            end
            return false
        end

        local costText = ""
        if entry.mass > 0 or entry.energy > 0 then
            costText = string.format("\nCost: %d Mass • %d Energy", entry.mass, entry.energy)
        end

        Tooltip.AddControlTooltipManual(self, entry.name,
            string.format("ID: %s\nTier: %s%s\n\n%s\n\nClick to select",
                entry.id, entry.tier, costText, entry.desc))
    end
}

---@class HotbuildContainer : Quick.Container
local HotbuildContainer = Class(QuickContainer)
{
    ---@param self HotbuildContainer
    ---@param blueprint any
    ---@param skin SkinName
    ---@param onClick? fun(control:BlueprintItem, modifiers:KeyModifiers, blueprint:any)
    ---@param width? number
    ---@param height? number
    ---@param id? number
    ---@param category? string
    ---@return BlueprintItem
    BlueprintSlot = function(self, blueprint, skin, onClick, width, height, id, category)
        width = width or 175
        height = height or 52
        local item = BlueprintItem(self._control, skin, width, height)
        item.id = id
        item.category = category
        item:SetBlueprint(blueprint)
        if onClick then
            item.OnClick = onClick
        end
        self:Builder():AddControl(item, {
            width = width,
            height = height
        })
        return item
    end,

    ---@param self HotbuildContainer
    ---@param width number
    ---@param height number
    ---@param itemCount number
    ---@param itemHeight number
    ---@param renderFn fun(row:HotbuildContainer, index:number)
    ---@param getTop? fun():number
    ---@param setTop? fun(top:number)
    ---@return Quick.ScrollableList
    ScrollableListPreserved = function(self, width, height, itemCount, itemHeight, renderFn, getTop, setTop)
        local list = self:ScrollableList(width, height, itemCount, itemHeight, renderFn)
        if getTop then
            local top = getTop()
            if top and top >= 1 then
                list._topLine = top
            end
        end
        if setTop then
            local oldScrollSetTop = list.ScrollSetTop
            list.ScrollSetTop = function(s, axis, top)
                oldScrollSetTop(s, axis, top)
                setTop(s._topLine)
            end
        end
        list:CalcVisible()
        return list
    end,
}

---@class HotbuildContext : Quick.Context
local HotbuildContext = Class(QuickContext)
{
    ContainerClass = HotbuildContainer,
}

local pickerWindow = nil

---Closes the blueprint picker window if open
function CloseBlueprintPicker()
    if not IsDestroyed(pickerWindow) then
        pickerWindow:Destroy()
        pickerWindow = nil
    end
end

---@param category string
---@param skin SkinName
---@param currentBlueprint any
---@param onSelect fun(selected:any)
---@param onClear fun()
function OpenBlueprintPicker(category, skin, currentBlueprint, onSelect, onClear)
    CloseBlueprintPicker()

    skin = skin or "uef"
    category = category or "Construction"

    local allBps
    if category == "Construction" then
        local cbps = ViewModel.FetchConstructionBlueprints()
        allBps = cbps and cbps[skin] or {}
    else
        allBps = ViewModel.FetchBlueprints(category, skin) or {}
    end

    local skinName = factionTitles[skin] or (type(skin) == "string" and (skin:sub(1,1):upper() .. skin:sub(2))) or tostring(skin)
    local catDisplay = tostring(category):gsub("_", " ")
    local windowTitle = string.format("Select Blueprint: %s (%s)", tostring(skinName), tostring(catDisplay))

    pickerWindow = Quick.Window(windowTitle, function(pq)
        local pctx = pq:Context()
        if pctx.searchText == nil then
            pctx.searchText = ""
        end
        if pctx.selectedTier == nil then
            pctx.selectedTier = "All"
        end

        -- Search & Filter Bar
        pq:PushItemWidth(150)
        local searchEdit = pq:Edit("Search", function(text)
            pctx.searchText = string.lower(text or "")
            pctx:UpdateWindow()
        end, 40, pctx.searchText)
        pq:PopItemWidth()

        pq:SameLine(10)
        pq:Text("Tier:", 12)
        pq:SameLine(4)
        local tiers = { "All", "T1", "T2", "T3", "EXP" }
        for _, tier in ipairs(tiers) do
            local currentTier = tier
            if pctx.selectedTier == currentTier then
                pq:Text("[" .. currentTier .. "]", 12, UIUtil.titleFont, UIUtil.highlightColor)
            else
                pq:Button(currentTier, function()
                    pctx.selectedTier = currentTier
                    pctx:UpdateWindow()
                end, 11)
            end
            pq:SameLine(3)
        end

        pq:SameLine(10)
        pq:Button("Clear Slot", function()
            if onClear then onClear() end
            CloseBlueprintPicker()
        end, 11)
        pq:Tooltip("Clear", "Remove blueprint from this slot")

        pq:Splitter()

        -- Filter candidate blueprints
        local search = pctx.searchText
        local filterTier = pctx.selectedTier
        local filtered = {}

        for _, item in ipairs(allBps) do
            local isTemplate = (type(item) == "table")
            local id = isTemplate and (item.icon or "template") or item
            local name = ""
            local desc = ""
            local tier = "T1"
            local mass = 0
            local energy = 0

            if isTemplate then
                name = item.name or "Template"
                desc = "Custom Build Template"
                tier = "TMPL"
            else
                local bp = __blueprints[id]
                if bp then
                    name = bp.Interface and LOC(bp.Interface.HelpText)
                    if not name or name == "" then
                        name = bp.Description and LOC(bp.Description) or id
                    end
                    desc = bp.Description and LOC(bp.Description) or ""
                    if EntityCategoryContains(categories.TECH1, id) then tier = "T1"
                    elseif EntityCategoryContains(categories.TECH2, id) then tier = "T2"
                    elseif EntityCategoryContains(categories.TECH3, id) then tier = "T3"
                    elseif EntityCategoryContains(categories.EXPERIMENTAL, id) then tier = "EXP"
                    end
                    if bp.Economy then
                        mass = bp.Economy.BuildCostMass or 0
                        energy = bp.Economy.BuildCostEnergy or 0
                    end
                else
                    name = id
                end
            end

            local matchTier = (filterTier == "All") or (filterTier == tier) or (isTemplate and filterTier == "All")
            local matchSearch = (search == "")
                or (string.find(string.lower(name), search, 1, true) ~= nil)
                or (string.find(string.lower(id), search, 1, true) ~= nil)

            if matchTier and matchSearch then
                table.insert(filtered, {
                    raw = item,
                    id = id,
                    name = name,
                    desc = desc,
                    tier = tier,
                    mass = mass,
                    energy = energy,
                    isTemplate = isTemplate,
                })
            end
        end

        local count = table.getn(filtered)
        if count == 0 then
            pq:Text("No matching blueprints found.", 12, UIUtil.bodyFont, "ff888888")
        else
            -- 8-column grid layout
            local COLUMNS = 8
            local numRows = math.ceil(count / COLUMNS)
            if numRows < 1 then numRows = 1 end

            pq:ScrollableList(0, 270, numRows, 58, function(row, rowIndex)
                for col = 1, COLUMNS do
                    local itemIndex = (rowIndex - 1) * COLUMNS + col
                    if itemIndex <= count then
                        local entry = filtered[itemIndex]
                        if col > 1 then
                            row:SameLine(4)
                        end
                        local isCurrent = (entry.raw == currentBlueprint)
                        local item = GridItem(row._control, entry, isCurrent, function(chosen)
                            if onSelect then
                                onSelect(chosen)
                            end
                            CloseBlueprintPicker()
                        end)
                        row:Builder():AddControl(item, {
                            width = 54,
                            height = 54,
                        })
                    end
                end
            end)
        end
    end, "hotbuild_bp_picker")
end

---@class HotbuildWindow : Quick.Window
local HotbuildWindow = ReUI.Core.Class(QuickWindow)
{
    Prefix = "ReUI.Hotbuild.Window",
    DefaultPos = { 240, 80 },
    ContextClass = HotbuildContext,

    ---@param self HotbuildWindow
    OnClose = function(self)
        CloseBlueprintPicker()
        QuickWindow.OnClose(self)
    end,
}

local mainWindow = nil

---Opens or brings to front the Hotbuild Quick Window
---@param parent? Control
---@return Quick.Window
function OpenWindow(parent)
    if not IsDestroyed(mainWindow) then
        mainWindow:Show()
        return mainWindow
    end

    ViewModel.SetActive()

    mainWindow = HotbuildWindow("Hotbuild Overhaul", function(q)
        local ctx = q:Context()

        if ctx.activeName == nil then
            ctx.activeName = ""
        end
        if ctx.swapIndex == nil then
            ctx.swapIndex = false
        end

        -- Header / Management toolbar
        local hotbuilds = ViewModel.FetchHotBuilds(true)
        local currentIdx = 1
        for i, hName in ipairs(hotbuilds) do
            if hName == ctx.activeName then
                currentIdx = i
                break
            end
        end

        q:PushItemWidth(170)
        q:Combo("Hotbuild Set", hotbuilds, function(idx, text)
            ctx.activeName = text
            ctx.swapIndex = false
            ViewModel.SetActive(text)
            ctx:UpdateWindow()
        end, currentIdx)
        q:PopItemWidth()

        q:SameLine(10)

        q:PushItemWidth(180)
        local nameEdit = q:Edit("Set Name", function(text)
            ctx.activeName = text
        end, 40, ctx.activeName)
        q:PopItemWidth()

        q:SameLine(10)
        q:Button("Save", function()
            local text = (nameEdit and nameEdit:GetText()) or ctx.activeName
            if text and text ~= "" then
                ViewModel.SaveActive(text)
                ctx.activeName = text
                ctx:UpdateWindow()
            end
        end)
        q:Tooltip("Save Set", "Save active hotbuild under this name and register keybind")

        q:SameLine(6)
        q:Button("New", function()
            ViewModel.SetActive("")
            ctx.activeName = ""
            ctx.swapIndex = false
            ctx:UpdateWindow()
        end)
        q:Tooltip("New Set", "Create a new empty hotbuild set")

        q:SameLine(6)
        q:Button("Delete", function()
            if ctx.activeName and ctx.activeName ~= "" then
                ViewModel.SaveActive() -- deletes activeName in Model
                ViewModel.SetActive("")
                ctx.activeName = ""
                ctx.swapIndex = false
                ctx:UpdateWindow()
            end
        end)
        q:Tooltip("Delete Set", "Delete the active hotbuild set")

        q:Splitter()

        -- Column Headers
        local function RenderFactionHeaders(labelTitle)
            q:Group(0, 20, function(hg)
                hg:Group(65, 18, function(lbl)
                    lbl:Text(labelTitle or "Step", 11, UIUtil.bodyFont, "ff888888")
                end)
                for i, skin in ipairs(skins) do
                    local curSkin = skin
                    hg:SameLine(i == 1 and 8 or 6)
                    hg:Group(175, 18, function(col)
                        local sName = factionTitles[curSkin] or curSkin
                        local sCol = factionColors[curSkin] or "ffffffff"
                        col:Text(sName, 12, UIUtil.titleFont, sCol)
                    end)
                end
                hg:SameLine(8)
                hg:Group(95, 18, function(act)
                    act:Text("Actions", 11, UIUtil.bodyFont, "ff888888")
                end)
            end)
        end

        -- Construction Section
        if q:Collapsible("Construction Cycle (Engineers)", true, "hb_sec_construction") then
            RenderFactionHeaders("Step")

            local constCount = ViewModel.FetchConstructionCount()
            q:ScrollableListPreserved(0, 240, constCount, 58, function(row, index)
                local isSwap = (ctx.swapIndex == index)
                local stepLabel = isSwap and ("[" .. index .. "*]") or ("#" .. index)
                local currentIndex = index

                -- 1. Index / Swap
                row:Group(65, 52, function(g)
                    g:Button(stepLabel, function()
                        if ctx.swapIndex then
                            if ctx.swapIndex ~= currentIndex then
                                ViewModel.Swap(ctx.swapIndex, currentIndex)
                                ctx.swapIndex = false
                                ctx:UpdateWindow()
                            else
                                ctx.swapIndex = false
                                ctx:UpdateWindow()
                            end
                        else
                            ctx.swapIndex = currentIndex
                            ctx:UpdateWindow()
                        end
                    end, 12)
                    g:Tooltip("Swap Step", isSwap and "Selected for swap! Click another step to swap." or "Click to swap with another step")
                end)

                -- 2. Four faction slots
                for sIdx, skin in ipairs(skins) do
                    row:SameLine(sIdx == 1 and 8 or 6)
                    local currentSkin = skin
                    local bp = ViewModel.FetchConstructionBlueprint(currentIndex, currentSkin)
                    row:BlueprintSlot(bp, currentSkin, function(control, modifiers, clickedBp)
                        if modifiers and modifiers.Left then
                            OpenBlueprintPicker("Construction", control._skin, clickedBp, function(newBp)
                                ViewModel.SetConstructionBlueprint(control.id, control._skin, newBp)
                                ctx:UpdateWindow()
                            end, function()
                                ViewModel.SetConstructionBlueprint(control.id, control._skin, nil)
                                ctx:UpdateWindow()
                            end)
                        elseif modifiers and modifiers.Right then
                            ViewModel.SetConstructionBlueprint(control.id, control._skin, nil)
                            ctx:UpdateWindow()
                        end
                    end, 175, 52, currentIndex, "Construction")
                end

                -- 3. Row Actions: Fill & Clear
                row:SameLine(8)
                row:Group(95, 52, function(ag)
                    local rowIndex = currentIndex
                    ag:Button("Fill", function(modifiers)
                        if modifiers and modifiers.Right then
                            for _, s in ipairs(skins) do
                                ViewModel.SetConstructionBlueprint(rowIndex, s, nil)
                            end
                        else
                            ViewModel.FillConstructionBlueprints(rowIndex)
                        end
                        ctx:UpdateWindow()
                    end, 11)
                    ag:Tooltip("Fill Row", "Left-click: auto-fill other factions\nRight-click: clear all slots in step")

                    ag:SameLine(4)
                    ag:Button("X", function()
                        for _, s in ipairs(skins) do
                            ViewModel.SetConstructionBlueprint(rowIndex, s, nil)
                        end
                        ctx:UpdateWindow()
                    end, 11)
                    ag:Tooltip("Clear Row", "Clear all blueprints in this step")
                end)
            end, function()
                return ctx.constTopLine
            end, function(top)
                ctx.constTopLine = top
            end)

            q:Button("+ Add Step", function()
                local count = ViewModel.FetchConstructionCount()
                ViewModel.SetConstructionBlueprint(count + 1, "uef", nil)
                ctx:UpdateWindow()
            end, 12)
            q:Tooltip("Add Step", "Add another step to the construction cycle")
        end

        -- Factory & Gate Layer Cycles
        for _, div in ipairs(factoryDivisions) do
            q:Splitter()

            if q:Collapsible(div.title, true, div.id) then
                RenderFactionHeaders("Category")

                for _, catData in ipairs(div.categories) do
                    local currentCat = catData.cat
                    local currentLabel = catData.label

                    q:Group(65, 52, function(g)
                        g:Title(currentLabel, 12)
                    end)

                    for sIdx, skin in ipairs(skins) do
                        q:SameLine(sIdx == 1 and 8 or 6)
                        local currentSkin = skin
                        local bp = ViewModel.FetchBlueprint(currentCat, currentSkin)
                        q:BlueprintSlot(bp, currentSkin, function(control, modifiers, clickedBp)
                            if modifiers and modifiers.Left then
                                OpenBlueprintPicker(control.category, control._skin, clickedBp, function(newBp)
                                    ViewModel.SetBlueprint(control.category, control._skin, newBp)
                                    ctx:UpdateWindow()
                                end, function()
                                    ViewModel.SetBlueprint(control.category, control._skin, nil)
                                    ctx:UpdateWindow()
                                end)
                            elseif modifiers and modifiers.Right then
                                ViewModel.SetBlueprint(control.category, control._skin, nil)
                                ctx:UpdateWindow()
                            end
                        end, 175, 52, nil, currentCat)
                    end

                    q:SameLine(8)
                    q:Group(95, 52, function(ag)
                        local catToFill = currentCat
                        ag:Button("Fill", function(modifiers)
                            if modifiers and modifiers.Right then
                                for _, s in ipairs(skins) do
                                    ViewModel.SetBlueprint(catToFill, s, nil)
                                end
                            else
                                ViewModel.FillBlueprints(catToFill)
                            end
                            ctx:UpdateWindow()
                        end, 11)
                        ag:Tooltip("Fill Category", "Left-click: auto-fill other factions\nRight-click: clear all slots in category")

                        ag:SameLine(4)
                        ag:Button("X", function()
                            for _, s in ipairs(skins) do
                                ViewModel.SetBlueprint(catToFill, s, nil)
                            end
                            ctx:UpdateWindow()
                        end, 11)
                        ag:Tooltip("Clear Category", "Clear all blueprints in this category")
                    end)
                end
            end
        end

        q:Splitter()
        q:Text("Tips: Left-click slot to pick unit • Right-click slot to clear • Click # to swap steps • 'Fill' auto-matches across factions", 11, UIUtil.bodyFont, "ff888888")
    end, "reui_hotbuild_window")

    return mainWindow
end

---@param parent? Control
---@return Quick.Window
function CreateWindow(parent)
    return OpenWindow(parent)
end

---Backwards compatibility entrypoint
---@param parent? Control
---@return Quick.Window
function init(parent)
    return OpenWindow(parent)
end

---@return boolean
function IsActiveUI()
    return not IsDestroyed(mainWindow)
end

function UpdateUI()
    if not IsDestroyed(mainWindow) then
        mainWindow:Rebuild()
    end
end

---@param item? string
function UpdateItems(item)
    if not IsDestroyed(mainWindow) then
        mainWindow:Rebuild()
    end
end
