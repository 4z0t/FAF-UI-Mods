local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local LayoutFor = ReUI.UI.FloorLayoutFor

local Quick = ReUI.UI.Quick
local QuickContainer = Quick.Container
local QuickContext = Quick.Context
local QuickWindow = Quick.Window

local BlueprintItem = import('BlueprintItem.lua').BlueprintItem
local ViewModel = import('../viewmodel.lua')
local Model = import('../model.lua')

local skins = { 'cybran', 'seraphim', 'aeon', 'uef' }
local singleCategories = { 'Land', 'Air', 'Naval', 'Gate' }

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
    local windowTitle = string.format("Select %s (%s)", tostring(skinName), tostring(category))

    pickerWindow = Quick.Window(windowTitle, function(pq)
        local pctx = pq:Context()
        if pctx.searchText == nil then
            pctx.searchText = ""
        end
        if pctx.selectedTier == nil then
            pctx.selectedTier = "All"
        end

        -- Search & Filter Bar
        pq:PushItemWidth(160)
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
        pq:Button("Clear", function()
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
            local tier = "T1"
            local mass = 0

            if isTemplate then
                name = item.name or "Template"
                tier = "TMPL"
            else
                local bp = __blueprints[id]
                if bp then
                    name = bp.Interface and LOC(bp.Interface.HelpText)
                    if not name or name == "" then
                        name = bp.Description and LOC(bp.Description) or id
                    end
                    if EntityCategoryContains(categories.TECH1, id) then tier = "T1"
                    elseif EntityCategoryContains(categories.TECH2, id) then tier = "T2"
                    elseif EntityCategoryContains(categories.TECH3, id) then tier = "T3"
                    elseif EntityCategoryContains(categories.EXPERIMENTAL, id) then tier = "EXP"
                    end
                    if bp.Economy and bp.Economy.BuildCostMass then
                        mass = bp.Economy.BuildCostMass
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
                    tier = tier,
                    mass = mass,
                    isTemplate = isTemplate,
                })
            end
        end

        local count = table.getn(filtered)
        if count == 0 then
            pq:Text("No matching blueprints found.", 12, UIUtil.bodyFont, "ff888888")
        else
            pq:ScrollableList(0, 320, count, 44, function(row, index)
                local entry = filtered[index]
                if not entry then return end
                local isCurrent = (entry.raw == currentBlueprint)

                row:Group(0, 42, function(g)
                    local iconFile = UIUtil.UIFile('/icons/units/' .. entry.id .. '_icon.dds', true)
                    g:Image(iconFile, 38, 38)
                    g:SameLine(8)
                    g:Group(260, 38, function(info)
                        local titleCol = isCurrent and UIUtil.highlightColor or "ffffffff"
                        info:Text(entry.name, 12, UIUtil.titleFont, titleCol)
                        local sub = entry.id .. " • " .. entry.tier
                        if entry.mass > 0 then
                            sub = sub .. " • " .. entry.mass .. "m"
                        end
                        info:Text(sub, 10, UIUtil.bodyFont, "ffaaaaaa")
                    end)
                    g:SameLine(10)
                    local selectedEntry = entry
                    g:Button(isCurrent and "Selected" or "Select", function()
                        if onSelect then
                            onSelect(selectedEntry.raw)
                        end
                        CloseBlueprintPicker()
                    end, 11)
                end)
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
                ViewModel.SaveActive() -- deletes activeName
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

        q:Splitter()

        -- Factory & Gate Cycles
        if q:Collapsible("Factory & Gate Cycles (Land, Air, Naval, Gate)", true, "hb_sec_factories") then
            RenderFactionHeaders("Category")

            for _, category in ipairs(singleCategories) do
                local currentCat = category
                q:Group(65, 52, function(g)
                    g:Title(currentCat, 13)
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
