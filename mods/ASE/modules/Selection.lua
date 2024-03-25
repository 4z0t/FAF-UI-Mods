local Lock = import("Lock.lua")
local IsLocked = Lock.IsLocked
local IsLockEmpty = Lock.IsEmpty
local ContainsLocked = Lock.ContainsLocked
local EntityCategoryFilterDown = EntityCategoryFilterDown
local TableGetN = table.getn


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

local assistBPs = {
    -- t1 scouts
    ["ual0101"] = true, --Spirit
    ["url0101"] = true, --Mole
    ["xsl0101"] = true, --Selen
    ["uel0101"] = true, --Snoop
    -- mobile shields
    ["xsl0307"] = true, --Athanah
    ["uel0307"] = true, --Parashield
    ["ual0307"] = true, --Asylum

    ["url0306"] = true --Deceiver
}

local layerCategory = {
    NAVAL = categories.NAVAL, -- + categories.LAND * categories.HOVER,
    AIR = categories.AIR,
    LAND = categories.LAND,
}

function SetActiveLayer(layer)
    activeLayer = layer
    print("Active layer is " .. layer)
end

function FilterAssisters(selection)
    local newSelection = {}
    local changed = false
    for _, unit in selection do
        local guard = unit:GetGuardedEntity()
        if not (assistBPs[unit:GetBlueprint().BlueprintId:lower()] and guard ~= nil) then
            table.insert(newSelection, unit)
        else
            changed = true
        end
    end

    if table.empty(newSelection) then
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
            table.insert(newSelection, unit)
        else
            changed = true
        end
    end
    if table.empty(newSelection) then
        return selection, false
    end
    return newSelection, changed
end

function AutoLayer(selection)
    local newLayer
    for layer, cat in layerCategory do
        if layer ~= activeLayer then
            local units = EntityCategoryFilterDown(cat, selection)
            if not table.empty(units) then
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
local exoticUnitsLandCategory = categories.xsl0305 + categories.xal0305 -- sniper bots
    + categories.LAND * categories.MOBILE * categories.SILO -- mmls
    + categories.MOBILE * categories.ARTILLERY * categories.TECH3 -- mobile arty
    + categories.dal0310

-- ---@type EntityCategory
-- local exoticUnitsAirCategory = categories.


function FilterExotic(selection)
    local filtered = EntityCategoryFilterOut(exoticUnitsLandCategory, selection)
    if TableGetN(filtered) == TableGetN(selection) or table.empty(filtered) then
        return selection, false
    end
    return filtered, true
end

local currentDomainOrder = 3
local domainsOrders =
{
    { key = "NAVAL > LAND  > AIR", value = { "NAVAL", "LAND", "AIR" } },
    { key = "NAVAL > AIR   > LAND", value = { "NAVAL", "AIR", "LAND" } },
    { key = "LAND  > AIR   > NAVAL", value = { "LAND", "AIR", "NAVAL" } },
    { key = "LAND  > NAVAL > AIR", value = { "LAND", "NAVAL", "AIR" } },
    { key = "AIR   > LAND  > NAVAL", value = { "AIR", "LAND", "NAVAL" } },
    { key = "AIR   > NAVAL > LAND", value = { "AIR", "NAVAL", "LAND" } },
}

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

function RotateDomains()
    local k, v = next(domainsOrders, currentDomainOrder)
    if k == nil then
        k = 1
        v = domainsOrders[1]
    end
    print(v.key)
    currentDomainOrder = k

    UpdateDomainsCursor()
end

function FilterLayer(selection)
    local domainOrder = domainsOrders[currentDomainOrder].value
    local filtered

    if isAuto then
        filtered = EntityCategoryFilterDown(layerCategory[activeLayer], selection)
    else
        for _, domain in domainOrder do
            filtered = EntityCategoryFilterDown(layerCategory[domain], selection)
            if not table.empty(filtered) then
                break
            end
        end
    end

    if table.empty(filtered) then
        if isAuto then
            AutoLayer(selection)
        end
        return selection, false
    end
    return filtered, (TableGetN(filtered) ~= TableGetN(selection))
end

function Main(_isReplay)
    local Options = UMT.Options.Mods["ASE"]
    Options.autoLayer:Bind(function(var)
        isAuto = var()
    end)

    UpdateDomainsCursor()
end
