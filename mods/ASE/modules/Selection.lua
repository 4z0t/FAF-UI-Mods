local Lock = import("Lock.lua")
local IsLocked = Lock.IsLocked
local IsLockEmpty = Lock.IsEmpty
local ContainsLocked = Lock.ContainsLocked
local EntityCategoryFilterDown = EntityCategoryFilterDown
local EntityCategoryFilterOut = EntityCategoryFilterOut
local TableGetN = table.getn
local TableEmpty = table.empty
local TableInsert = table.insert

local layers = { "NAVAL", "LAND", "AIR" }
local activeLayer = "LAND"

local domainColors = {
    NAVAL = "ff00ABC9",
    AIR = "ffffffff",
    LAND = "ff005E0C",
}

local Bitmap = UMT.Controls.Bitmap

---@class CursorDomains : UMT.Bitmap
---@field top UMT.Bitmap
---@field middle UMT.Bitmap
---@field bottom UMT.Bitmap
local CursorDomains = UMT.Class(Bitmap)
{

    ---@param self CursorDomains
    ---@param cursor UICursor
    __init = function(self, parent)
        Bitmap.__init(self, parent)

        self.top = Bitmap(self)
        self.middle = Bitmap(self)
        self.bottom = Bitmap(self)
    end,

    ---@param self CursorDomains
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)
        local size = 8
        local padding = 1
        local blockSize = size - padding * 2
        layouter(self)
            :AtLeftTopIn(self:GetParent())
            :DisableHitTest(true)
            :Width(size)
            :Height(size * 3 - padding * 4)
            :Color("black")
            :NeedsFrameUpdate(true)

        layouter(self.top)
            :Color("white")
            :AtTopCenterIn(self, padding)
            :Width(blockSize)
            :Height(blockSize)

        layouter(self.middle)
            :Color("white")
            :AtCenterIn(self)
            :Width(blockSize)
            :Height(blockSize)

        layouter(self.bottom)
            :Color("white")
            :AtBottomCenterIn(self, padding)
            :Width(blockSize)
            :Height(blockSize)
    end,

    ---@param self CursorDomains
    OnFrame = function(self, delta)
        if IsKeyDown("Control") then
            self:Show()
            local v = GetMouseScreenPos()
            self:Layouter()
                :Top(v[2])
                :Left(v[1] + 30)
        else
            self:Hide()
        end
    end,

    ---@param self CursorDomains
    SetDomainsOrder = function(self, domainOrder)
        local top = domainOrder[1]
        local middle = domainOrder[2]
        local bottom = domainOrder[3]

        self.top:SetSolidColor(domainColors[top])
        self.middle:SetSolidColor(domainColors[middle])
        self.bottom:SetSolidColor(domainColors[bottom])
    end,

    OnDestroy = function(self)
        Bitmap.OnDestroy(self)
        self.top = nil
        self.middle = nil
        self.bottom = nil
    end
}


-- determines whether last selected units not containing active category replace active actegory
local isAuto

local assistCategory

-- double click only selects assisters with the same target
local doubleClickSimilarAssisters

local layerCategory = {
    NAVAL = categories.NAVAL, -- + categories.LAND * categories.HOVER,
    AIR = categories.AIR,
    LAND = categories.LAND,
}

function SetActiveLayer(layer)
    activeLayer = layer
    print("Active layer is " .. layer)
end

local isDoubleClick = false
local clickedAssisterTarget

function FilterAssisters(selection)
    local possibleAssisters = EntityCategoryFilterDown(assistCategory, selection)
    if TableEmpty(possibleAssisters) then
        return selection, false
    end
    local changed = false
    local newSelection = EntityCategoryFilterOut(assistCategory, selection)
    for _, unit in possibleAssisters do
        local unitTarget = unit:GetGuardedEntity()
        if not unitTarget then
            -- check for instant shield assist target
            local unitQueue = unit:GetCommandQueue()
            if unitQueue[1].type == "Repair" and unitQueue[2].type == "Guard" then
                local pos1 = unitQueue[1].position
                local pos2 = unitQueue[2].position
                if pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z then
                    unitTarget = unit:GetFocus()
                end
            end
        end
        if not isDoubleClick then
            clickedAssisterTarget = unitTarget
        end
        if isDoubleClick and clickedAssisterTarget and
            (
                not doubleClickSimilarAssisters and unitTarget ~= nil
                or doubleClickSimilarAssisters and clickedAssisterTarget == unitTarget
            )
            or (not isDoubleClick or not clickedAssisterTarget) and unitTarget == nil
        then
            TableInsert(newSelection, unit)
        else
            changed = true
        end
    end

    if TableEmpty(newSelection) then
        return selection, false
    end
    return newSelection, changed
end

function FilterLocked(selection)
    if IsLockEmpty() or not ContainsLocked(selection) then
        return selection, false
    end
    local newSelection = {}
    local changed = false
    for _, unit in selection do
        if not IsLocked(unit) then
            TableInsert(newSelection, unit)
        else
            changed = true
        end
    end
    if TableEmpty(newSelection) then
        return selection, false
    end
    return newSelection, changed
end

function AutoLayer(selection)
    local newLayer
    for layer, cat in layerCategory do
        if layer ~= activeLayer then
            local units = EntityCategoryFilterDown(cat, selection)
            if not TableEmpty(units) then
                if newLayer == nil then
                    newLayer = layer
                else
                    return
                end
            end
        end
    end
    if newLayer then
        SetActiveLayer(newLayer)
    end
end

---@type EntityCategory
local exoticUnitsCategory = categories.ALLUNITS - categories.ALLUNITS

function FilterExotic(selection)
    local filtered = EntityCategoryFilterOut(exoticUnitsCategory, selection)
    if TableEmpty(filtered) or TableGetN(filtered) == TableGetN(selection) then
        return selection, false
    end
    return filtered, true
end

local currentDomainOrderOption = UMT.OptionVar.Create("ASE", "currentDomainOrderOption", 3)
local currentDomainOrder = currentDomainOrderOption()
local domainsOrders =
{
    { key = "NAVAL > LAND  > AIR", value = { "NAVAL", "LAND", "AIR" } },
    { key = "NAVAL > AIR   > LAND", value = { "NAVAL", "AIR", "LAND" } },
    { key = "LAND  > AIR   > NAVAL", value = { "LAND", "AIR", "NAVAL" } },
    { key = "LAND  > NAVAL > AIR", value = { "LAND", "NAVAL", "AIR" } },
    { key = "AIR   > LAND  > NAVAL", value = { "AIR", "LAND", "NAVAL" } },
    { key = "AIR   > NAVAL > LAND", value = { "AIR", "NAVAL", "LAND" } },
}

local includeHoverInNavy
local hoverUnitsCategory = categories.LAND * categories.HOVER - categories.ENGINEER

local function UpdateDomainsCursor()
    if isAuto then
        return
    end

    local cursor = GetCursor()
    if not cursor.domains then
        cursor.domains = CursorDomains(GetFrame(0))
    end
    cursor.domains:SetDomainsOrder(domainsOrders[currentDomainOrder].value)
end

function SetDomain(i)
    currentDomainOrder = i
    print(domainsOrders[i].key)
    currentDomainOrderOption:Set(i)
    currentDomainOrderOption:Save()

    -- UpdateDomainsCursor()
end

function RotateDomains()
    local k, v = next(domainsOrders, currentDomainOrder)
    SetDomain(k or 1)
end

function FilterLayer(selection)
    local domainOrder = domainsOrders[currentDomainOrder].value
    local filtered

    if isAuto then
        filtered = EntityCategoryFilterDown(layerCategory[activeLayer], selection)
    else
        for _, domain in domainOrder do
            filtered = EntityCategoryFilterDown(layerCategory[domain], selection)
            if not TableEmpty(filtered) then
                if domain == "NAVAL" and includeHoverInNavy then
                    filtered = EntityCategoryFilterDown(layerCategory[domain] + hoverUnitsCategory, selection)
                end
                break
            end
        end
    end

    if TableEmpty(filtered) then
        if isAuto then
            AutoLayer(selection)
        end
        return selection, false
    end
    return filtered, (TableGetN(filtered) ~= TableGetN(selection))
end

local function InitOptionAssisterCategories()
    local Options = UMT.Options.Mods["ASE"]
    local categories = categories

    local onlySupportCategory = categories.ALLUNITS
        -- units with support capability that also have weapons, such as ML or fatboy
        - categories.DIRECTFIRE - categories.INDIRECTFIRE - categories.ANTIAIR - categories.ANTINAVY
        -- air units have special attack categories
        - categories.GROUNDATTACK - categories.STRATEGICBOMBER - categories.BOMBER
        -- continental
        - categories.TRANSPORTATION

    local originalAssistcategory =
        categories.SCOUT * categories.LAND
        + (categories.MOBILE * categories.SHIELD * onlySupportCategory)
        -- shouldn't use overlay categories but its the best way to include both stealthfields and cloakfields
        + (categories.MOBILE * categories.COUNTERINTELLIGENCE * categories.OVERLAYCOUNTERINTEL * onlySupportCategory)

    local engiStationAssistCategory = originalAssistcategory + categories.ENGINEERSTATION + categories.POD
    local engiAssistCategory = originalAssistcategory + categories.ENGINEER

    local assistCategories = {
        ["Disabled"] = originalAssistcategory,
        ["Engi stations & drones"] = engiStationAssistCategory,
        ["All engineers"] = engiAssistCategory
    }

    Options.filterAssistingEngineers:Bind(function(var)
        assistCategory = assistCategories[var()]
    end)
end

local function InitOptionsExoticCategories()
    local filters = UMT.Options.Mods["ASE"].filters
    local categories = categories

    local filttersTable = {
        [filters.MMLs] = categories.LAND * categories.MOBILE * categories.SILO * categories.TECH2
            + categories.xel0306, -- mmls
        [filters.Snipers] = categories.xsl0305 + categories.xal0305 -- sniper bots
            + categories.dal0310, -- absolver
        [filters.T3MobileArty] = categories.MOBILE * categories.ARTILLERY * categories.TECH3, -- mobile arty
        [filters.Torps] = categories.uaa0204 + -- Skimmer
            categories.ura0204 + -- Cormorant
            categories.xsa0204 + -- Uosioz
            categories.uea0204 + -- Stork
            categories.xaa0306, -- Solace
        [filters.Carriers] = categories.uas0303 + -- Keefer Class
            categories.urs0303 + -- Command Class
            categories.xss0303, -- Iavish
        [filters.Strats] = categories.uaa0304 + -- Shocker
            categories.ura0304 + -- Revenant
            categories.xsa0304 + -- Sinntha
            categories.uea0304, -- Ambassador
        [filters.StrategicSubs] = categories.uas0304 + -- Silencer
            categories.urs0304 + -- Plan B
            categories.ues0304, -- Ace
        [filters.T3Sonar] = categories.uas0305 + -- aeon
            categories.urs0305 + -- Flood XR
            categories.ues0305, -- SP3 - 3000
        [filters.FireBeetle] = categories.xrl0302, -- fire beetle
    }

    local UpdateExotics = function()
        exoticUnitsCategory = categories.ALLUNITS - categories.ALLUNITS

        for filter, category in filttersTable do
            if filter() then
                exoticUnitsCategory = exoticUnitsCategory + category
            end
        end

    end

    for filter in filttersTable do
        filter.OnChange = UpdateExotics
    end

    UpdateExotics()
end

local function checkForDoubleClick(mouseEvent)
    if mouseEvent.Type == "ButtonDClick" then
        isDoubleClick = true
    else
        isDoubleClick = false
    end
end

function Main(_isReplay)
    local Options = UMT.Options.Mods["ASE"]
    Options.autoLayer:Bind(function(var)
        isAuto = var()
    end)

    Options.includeHovers:Bind(function(var)
        includeHoverInNavy = var()
    end)

    InitOptionAssisterCategories()

    Options.doubleClickSimilarAssisters:Bind(function(var)
        doubleClickSimilarAssisters = var()
    end)

    InitOptionsExoticCategories()

    import("/lua/ui/uimain.lua").AddOnMouseClickedFunc(checkForDoubleClick)

    -- UpdateDomainsCursor()
end

__moduleinfo.OnDirty = function()
    import("/lua/ui/uimain.lua").RemoveOnMouseClickedFunc(checkForDoubleClick)
end
