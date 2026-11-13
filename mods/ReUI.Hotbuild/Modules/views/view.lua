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
    seraphim = "FFffd700",
    aeon     = "6BF32B",
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
local pickerColumns = 10

---Closes the blueprint picker window if open
function CloseBlueprintPicker()
    if not IsDestroyed(pickerWindow) then
        pickerWindow:Destroy()
        pickerWindow = nil
    end
end

---@class HotbuildBaseWindow : Quick.Window
local HotbuildBaseWindow = ReUI.Core.Class(QuickWindow)
{
    BorderClass = Quick.NinePatchBorder,
}

---@class BlueprintPickerWindow : HotbuildBaseWindow
local BlueprintPickerWindow = ReUI.Core.Class(HotbuildBaseWindow)
{
    Prefix = "ReUI.Hotbuild.PickerWindow",
    DefaultPos = { 300, 120 },

    ---@param self BlueprintPickerWindow
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        HotbuildBaseWindow.InitLayout(self, layouter)
        LayoutFor(self._resizeGrip):Hide()
    end,

    ---@param self BlueprintPickerWindow
    OnClose = function(self)
        pickerWindow = nil
        HotbuildBaseWindow.OnClose(self)
    end,
}

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

    local skinName = factionTitles[skin] or (type(skin) == "string" and (skin:sub(1, 1):upper() .. skin:sub(2))) or
        tostring(skin)
    local catDisplay = tostring(category):gsub("_", " ")
    local windowTitle = string.format("Select Blueprint: %s (%s)", tostring(skinName), tostring(catDisplay))

    pickerWindow = BlueprintPickerWindow(windowTitle, function(pq)
        local COLUMNS = 10
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

        local count = table.getn(filtered)
        if count == 0 then
            pq:Text("No matching blueprints found.", 12, UIUtil.bodyFont, "ff888888")
        else
            local numRows = math.ceil(count / COLUMNS)
            local rowWidth = COLUMNS * 54 + (COLUMNS - 1) * 4

            for r = 1, numRows do
                local isLastRow = (r == numRows)
                pq:Group(rowWidth, isLastRow and 54 or 58, function(row)
                    for col = 1, COLUMNS do
                        local itemIndex = (r - 1) * COLUMNS + col
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
        end
    end, "hotbuild_bp_picker")
end

local actionPickerWindow = nil

---Closes the action picker window if open
function CloseActionPicker()
    if not IsDestroyed(actionPickerWindow) then
        actionPickerWindow:Destroy()
        actionPickerWindow = nil
    end
end

---@class ActionListItem : Group
local ActionListItem = Class(Group) {
    ---@param self ActionListItem
    ---@param parent Control
    ---@param entry table
    ---@param isCurrent boolean
    ---@param onSelect fun(key:string)
    __init = function(self, parent, entry, isCurrent, onSelect)
        Group.__init(self, parent)
        LayoutFor(self):Width(520):Height(38)

        self._bg = Bitmap(self)
        self._bg:SetSolidColor(isCurrent and "ff443311" or "ff1a1a1a")
        LayoutFor(self._bg):Fill(self):DisableHitTest()

        self._border = Bitmap(self)
        self._border:SetSolidColor(isCurrent and "ffffcc00" or "ff333333")
        LayoutFor(self._border):Fill(self):OffsetIn(self, 1, 1, 1, 1):DisableHitTest()

        local inner = Bitmap(self)
        inner:SetSolidColor(isCurrent and "ff2a2000" or "ff141414")
        LayoutFor(inner):Fill(self):OffsetIn(self, 2, 2, 2, 2):DisableHitTest()

        -- Title text: Name
        local title = UIUtil.CreateText(self, entry.name, 11, UIUtil.bodyFont, true)
        title:SetColor(isCurrent and "ffffcc00" or "ffffffff")
        title:SetClipToWidth(true)
        LayoutFor(title):AtLeftTopIn(self, 8, 3):Width(390):DisableHitTest()

        -- Category badge: [CATEGORY]
        local catText = string.upper(entry.category or "OTHER")
        local catBadge = UIUtil.CreateText(self, "[" .. catText .. "]", 9, UIUtil.bodyFont, true)
        catBadge:SetColor("ff66bbff")
        LayoutFor(catBadge):AtRightTopIn(self, 8, 4):DisableHitTest()

        -- Subtitle: Action key / Command
        local sub = entry.key
        if entry.action and entry.action ~= "" and entry.action ~= entry.key then
            sub = sub .. " • " .. entry.action
        end
        local subtitle = UIUtil.CreateText(self, sub, 9, UIUtil.bodyFont, true)
        subtitle:SetColor("ff888888")
        subtitle:SetClipToWidth(true)
        LayoutFor(subtitle):AtLeftBottomIn(self, 8, 3):Width(504):DisableHitTest()

        self.HandleEvent = function(s, event)
            if event.Type == 'MouseEnter' then
                self._border:SetSolidColor("ffffffff")
                return true
            elseif event.Type == 'MouseExit' then
                self._border:SetSolidColor(isCurrent and "ffffcc00" or "ff333333")
                return true
            elseif event.Type == 'ButtonPress' then
                onSelect(entry.key)
                return true
            end
            return false
        end

        Tooltip.AddControlTooltipManual(self, entry.name,
            string.format("Key: %s\nCategory: %s\nCommand: %s\n\nClick to set as No Selection Action",
                entry.key, entry.category, entry.action or "N/A"))
    end
}

---@class ActionPickerWindow : HotbuildBaseWindow
local ActionPickerWindow = ReUI.Core.Class(HotbuildBaseWindow)
{
    Prefix = "ReUI.Hotbuild.ActionPickerWindow",
    DefaultPos = { 320, 120 },
    ContextClass = HotbuildContext,

    ---@param self ActionPickerWindow
    OnClose = function(self)
        actionPickerWindow = nil
        HotbuildBaseWindow.OnClose(self)
    end,
}

---@param currentAction? string
---@param onSelect fun(action:string)
---@param onClear fun()
function OpenActionPicker(currentAction, onSelect, onClear)
    CloseActionPicker()

    local KeyMapper = import("/lua/keymap/keymapper.lua")
    local allKeyActions = KeyMapper.GetKeyActions() or {}

    local allActionsList = {}
    for k, v in pairs(allKeyActions) do
        if not (v.category and string.find(string.lower(v.category), "hotbuild")) then
            local actionName = KeyMapper.GetActionName(k)
            if not actionName or actionName == "" or string.find(actionName, "<LOC") == 1 then
                actionName = k
            end
            local cat = v.category or "other"
            table.insert(allActionsList, {
                key = k,
                name = actionName,
                category = cat,
                action = v.action or "",
            })
        end
    end

    table.sort(allActionsList, function(a, b)
        if a.category ~= b.category then
            if a.category == "selection" then return true end
            if b.category == "selection" then return false end
            return a.category < b.category
        end
        return a.name < b.name
    end)

    actionPickerWindow = ActionPickerWindow("Select Action (When No Selection)", function(pq)
        local pctx = pq:Context()
        if pctx.searchText == nil then pctx.searchText = "" end
        if pctx.selectedCat == nil then pctx.selectedCat = "selection" end
        if pctx.customCmd == nil then pctx.customCmd = currentAction or "" end
        if pctx.listTop == nil then pctx.listTop = 1 end

        -- 1. Search Bar & Clear
        pq:PushItemWidth(200)
        local searchEdit = pq:Edit("Search", function(text)
            pctx.searchText = string.lower(text or "")
            pctx.listTop = 1
            pctx:UpdateWindow()
        end, 50, pctx.searchText)
        pq:PopItemWidth()

        pq:SameLine(8)
        pq:Button("Search", function()
            pctx.searchText = string.lower(searchEdit and searchEdit:GetText() or "")
            pctx.listTop = 1
            pctx:UpdateWindow()
        end, 11, 60, 24)

        if pctx.searchText ~= "" then
            pq:SameLine(4)
            pq:Button("Clear", function()
                pctx.searchText = ""
                pctx.listTop = 1
                pctx:UpdateWindow()
            end, 11, 50, 24)
        end

        pq:SameLine(10)
        pq:Button("None (Clear Action)", function()
            if onClear then onClear() end
            CloseActionPicker()
        end, 11, 140, 24)
        pq:Tooltip("None", "Set no action (do nothing when nothing selected)")

        -- 2. Category filter buttons
        local cats = { "selection", "orders", "ui", "camera", "all" }
        pq:Group(0, 26, function(cg)
            cg:Text("Category:", 11, UIUtil.bodyFont, "ffaaaaaa")
            for _, cat in ipairs(cats) do
                cg:SameLine(6)
                local isCatActive = (pctx.selectedCat == cat)
                local catLabel = (cat == "all") and "All" or (cat:sub(1, 1):upper() .. cat:sub(2))
                if isCatActive then
                    catLabel = "[" .. catLabel .. "]"
                end
                local currentCat = cat
                cg:Button(catLabel, function()
                    pctx.selectedCat = currentCat
                    pctx.listTop = 1
                    pctx:UpdateWindow()
                end, 10, isCatActive and 75 or 65, 20)
            end
        end)

        -- 3. Custom console command row
        pq:Group(0, 36, function(cg)
            cg:PushItemWidth(380)
            local cmdEdit = cg:Edit("Or custom console command:", function(text)
                pctx.customCmd = text
            end, 150, pctx.customCmd)
            cg:PopItemWidth()

            cg:SameLine(8)
            cg:Button("Use Command", function()
                local cmd = (cmdEdit and cmdEdit:GetText()) or pctx.customCmd
                if cmd and cmd ~= "" then
                    if onSelect then onSelect(cmd) end
                    CloseActionPicker()
                end
            end, 11, 105, 24)
            cg:Tooltip("Use Custom Command", "Use this exact command as the no-selection action")
        end)

        pq:Splitter()

        -- Filter actions list
        local search = pctx.searchText
        local selCat = pctx.selectedCat

        local filtered = {}
        for _, act in ipairs(allActionsList) do
            local catMatch = (selCat == "all") or (act.category == selCat)
            local searchMatch = (search == "")
                or (string.find(string.lower(act.name), search, 1, true) ~= nil)
                or (string.find(string.lower(act.key), search, 1, true) ~= nil)
                or (string.find(string.lower(act.action), search, 1, true) ~= nil)
                or (string.find(string.lower(act.category), search, 1, true) ~= nil)

            if catMatch and searchMatch then
                table.insert(filtered, act)
            end
        end

        local count = table.getn(filtered)
        if count == 0 then
            pq:Text("No matching actions found.", 12, UIUtil.bodyFont, "ff888888")
        else
            pq:ScrollableListPreserved(550, 300, count, 42, function(row, index)
                local entry = filtered[index]
                local isCurrent = (entry.key == currentAction or entry.action == currentAction)
                local item = ActionListItem(row._control, entry, isCurrent, function(chosenKey)
                    if onSelect then onSelect(chosenKey) end
                    CloseActionPicker()
                end)
                row:Builder():AddControl(item, {
                    width = 520,
                    height = 38,
                })
            end, function()
                local maxTop = math.max(count - 7 + 1, 1)
                if pctx.listTop and pctx.listTop > maxTop then
                    pctx.listTop = maxTop
                end
                return pctx.listTop
            end, function(top)
                pctx.listTop = top
            end)
        end
    end, "hotbuild_action_picker")
end

---@class HotbuildWindow : HotbuildBaseWindow
local HotbuildWindow = ReUI.Core.Class(HotbuildBaseWindow)
{
    Prefix = "ReUI.Hotbuild.Window",
    DefaultPos = { 240, 80 },
    ContextClass = HotbuildContext,

    ---@param self HotbuildWindow
    OnClose = function(self)
        CloseBlueprintPicker()
        CloseActionPicker()
        HotbuildBaseWindow.OnClose(self)
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
            ctx.constTopLine = 1
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
            ctx.constTopLine = 1
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

        -- No Selection Action row
        q:Group(0, 26, function(ag)
            ag:Text("When nothing selected:", 11, UIUtil.bodyFont, "ffaaaaaa")
            ag:SameLine(10)
            local currentAction = ViewModel.GetNoSelectionAction()
            local actionTitle = ViewModel.GetNoSelectionActionTitle()
            local isSet = (currentAction and currentAction ~= "")

            ag:Button(actionTitle, function()
                OpenActionPicker(currentAction, function(selectedAction)
                    ViewModel.SetNoSelectionAction(selectedAction)
                    ctx:UpdateWindow()
                end, function()
                    ViewModel.SetNoSelectionAction(nil)
                    ctx:UpdateWindow()
                end)
            end, 11, 320, 24)
            ag:Tooltip("No Selection Action",
                "Action to perform when hotbuild key is pressed with no units selected.\nClick to choose from all available actions or set custom command.")

            if isSet then
                ag:SameLine(6)
                ag:Button("X", function()
                    ViewModel.SetNoSelectionAction(nil)
                    ctx:UpdateWindow()
                end, 11, 26, 24)
                ag:Tooltip("Clear Action", "Remove the no-selection action")
            end
        end)

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
                    end, 12, 65)
                    g:Tooltip("Swap Step",
                        isSwap and "Selected for swap! Click another step to swap." or "Click to swap with another step")
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
                                local newCount = ViewModel.FetchConstructionCount()
                                if control.id >= newCount - 1 and newCount > 4 then
                                    ctx.constTopLine = newCount - 4 + 1
                                end
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
                row:Group(95 + 30, 52, function(ag)
                    local rowIndex = currentIndex
                    ag:Button("Fill", function(modifiers)
                        if modifiers and modifiers.Right then
                            ViewModel.ClearConstructionBlueprints(rowIndex)
                        else
                            ViewModel.FillConstructionBlueprints(rowIndex)
                        end
                        local newCount = ViewModel.FetchConstructionCount()
                        if rowIndex >= newCount - 1 and newCount > 4 then
                            ctx.constTopLine = newCount - 4 + 1
                        end
                        ctx:UpdateWindow()
                    end, 11, 95, 26)
                    ag:Tooltip("Fill Row", "Left-click: auto-fill other factions\nRight-click: clear all slots in step")

                    -- ag:SameLine(4)
                    ag:Button("X", function()
                        ViewModel.ClearConstructionBlueprints(rowIndex)
                        ctx:UpdateWindow()
                    end, 11, 95, 26)
                    ag:Tooltip("Clear Row", "Clear all blueprints in this step")
                end)
            end, function()
                local maxTop = math.max(constCount - 4 + 1, 1)
                if ctx.constTopLine and ctx.constTopLine > maxTop then
                    ctx.constTopLine = maxTop
                end
                return ctx.constTopLine
            end, function(top)
                ctx.constTopLine = top
            end)
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
                        end, 11, 95, 26)
                        ag:Tooltip("Fill Category",
                            "Left-click: auto-fill other factions\nRight-click: clear all slots in category")

                        -- ag:SameLine(4)
                        ag:Button("X", function()
                            for _, s in ipairs(skins) do
                                ViewModel.SetBlueprint(catToFill, s, nil)
                            end
                            ctx:UpdateWindow()
                        end, 11, 95, 26)
                        ag:Tooltip("Clear Category", "Clear all blueprints in this category")
                    end)
                end
            end
        end

        q:Splitter()
        q:Text("Tips: Left-click slot to pick unit • Right-click slot to clear • Click # to swap steps • 'Fill' auto-matches across factions"
            , 11, UIUtil.bodyFont, "ff888888")
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
