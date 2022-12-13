-- upvalue for performance
local TableInsert = table.insert
local EntityCategoryContains = EntityCategoryContains
local categoryMex = categories.MASSEXTRACTION * categories.STRUCTURE
local categoryEngineer = categories.ENGINEER
local GetIsPaused = GetIsPaused

local Select = UMT.Select
local GetUnits = UMT.Units.Get
local From = import("/mods/UMT/modules/linq.lua").From

local UpdateMexOverlays = import("mexoverlay.lua").UpdateOverlays
local UpdateMexPanel = import("mexpanel.lua").Update
local Options = import("options.lua")


local mexCategories = import("mexcategories.lua").mexCategories

local upgradeT1 = Options.upgradeT1Option()
local upgradeT2 = Options.upgradeT2Option()
local unpauseAssisted = Options.unpauseAssisted()
local unpauseAssistedBP = Options.unpauseAssistedBP()
local unpauseOnce = Options.unpauseOnce()

local mexData = {}
local toBePaused = {}
local unPaused = setmetatable({}, { __mode = 'k' })

local function UpgradeMexes(mexes, selector)

    local upgrades = {}
    if not selector then
        for _, m in mexes do
            if not toBePaused[m:GetEntityId()] then
                toBePaused[m:GetEntityId()] = true
                local bp = m:GetBlueprint()
                local upgradesTo = bp.General.UpgradesTo

                if not upgrades[upgradesTo] then
                    upgrades[upgradesTo] = { m }
                else
                    TableInsert(upgrades[upgradesTo], m)
                end

            end
        end
    else
        for _, m in mexes do
            if not toBePaused[m:GetEntityId()] and selector(m) then
                toBePaused[m:GetEntityId()] = true
                local bp = m:GetBlueprint()
                local upgradesTo = bp.General.UpgradesTo

                if not upgrades[upgradesTo] then
                    upgrades[upgradesTo] = { m }
                else
                    TableInsert(upgrades[upgradesTo], m)
                end

            end
        end
    end

    if not table.empty(upgrades) then
        Select.Hidden(function()
            for upgradesTo, upMexes in upgrades do
                SelectUnits(upMexes)
                IssueBlueprintCommand("UNITCOMMAND_Upgrade", upgradesTo, 1, false)
            end
        end)
    end
end

local function MatchCategory(category, unit)
    -- local isUpgrading = unit:GetWorkProgress() > 0

    if unit.isUpgraded then
        return false
    end

    if not EntityCategoryContains(category.categories, unit) then
        return false
    end

    if unit.isUpgrader ~= category.isUpgrading then
        return false
    end

    if category.isPaused ~= nil then
        if GetIsPaused({ unit }) ~= category.isPaused then
            return false
        end
    end

    return true
end

local function GetCappingBonus(mex)
    local productionPerSecondMass = mex:GetBlueprint().Economy.ProductionPerSecondMass
    local massProduced = mex:GetEconData().massProduced

    if productionPerSecondMass > 0 then
        return massProduced / productionPerSecondMass
    else
        return 1
    end
end

local function IsCapped(mex)
    return GetCappingBonus(mex) >= 1.5
end

local function CheckCapped(mexes)
    for _, mex in mexes do
        mex.isCapped = IsCapped(mex)
    end
end

local function UpdateUI()
    local mexes = GetUnits(categoryMex)


    for id, category in mexCategories do
        mexData[id] = {
            mexes = {},
        }
    end

    for _, mex in mexes do
        mex.isUpgraded = false
        mex.isUpgrader = false
        mex.assistBP   = 0
    end


    if unpauseAssisted then
        local engies = GetUnits(categoryEngineer)
        for _, engy in engies do
            local assistedUnit = engy:GetGuardedEntity()
            local focusedUnit = engy:GetFocus()
            if assistedUnit and
                focusedUnit and --check if we are really assisiting mex now
                EntityCategoryContains(categoryMex, assistedUnit) and
                not GetIsPaused { engy }
            then
                assistedUnit.assistBP = (assistedUnit.assistBP or 0) + engy:GetBlueprint().Economy.BuildRate
            end
        end
    end


    for _, mex in mexes do
        local f = mex:GetFocus()
        if f ~= nil and f:IsInCategory("STRUCTURE") then
            mex.isUpgrader = true
            f.isUpgraded = true
            if toBePaused[mex:GetEntityId()] then
                toBePaused[mex:GetEntityId()] = nil
                SetPaused({ mex }, true)
            end

            if unpauseAssisted and
                not (unpauseOnce and unPaused[mex]) and
                mex.assistBP > unpauseAssistedBP and
                GetIsPaused { mex }
            then
                SetPaused({ mex }, false)
                unPaused[mex] = true
            end
        end
    end

    for _, mex in mexes do
        for id, category in mexCategories do
            if MatchCategory(category, mex) then
                TableInsert(mexData[id].mexes, mex)
                break
            end
        end
    end

    if upgradeT1 and not table.empty(mexData[1].mexes) then
        UpgradeMexes(mexData[1].mexes)
    end
    if upgradeT2 and not table.empty(mexData[4].mexes) then
        UpgradeMexes(mexData[4].mexes, IsCapped)
    end

    -- T2 mexes
    if not table.empty(mexData[4].mexes) then
        CheckCapped(mexData[4].mexes)
    end

    -- T3 mexes
    if not table.empty(mexData[7].mexes) then
        CheckCapped(mexData[7].mexes)
    end

    for id, category in mexCategories do

        if id == 1 and upgradeT1 and not table.empty(mexData[id].mexes) then
            UpgradeMexes(mexData[id].mexes)
        end


        if category.isUpgrading and not table.empty(mexData[id].mexes) then
            local sortedMexes = From(mexData[id].mexes):Sort(function(a, b)
                return a:GetWorkProgress() > b:GetWorkProgress()
            end)

            local sorted = sortedMexes:Map(function(k, m)
                return m:GetWorkProgress()
            end):ToDictionary()

            mexData[id].progress = sorted

            mexData[id].mexes = sortedMexes:ToDictionary()
        end
    end

    UpdateMexPanel(mexData)
    UpdateMexOverlays(mexes)
end

function UpgradeAll(id)
    UpgradeMexes(mexData[id].mexes)
end

function UpgradeOnScreen(id)
    Select.Hidden(function()
        local mexes = mexData[id].mexes
        mexes = From(mexes)
        UISelectionByCategory("MASSEXTRACTION STRUCTURE", false, true, false, false)
        local mexesOnScreen = From(GetSelectedUnits())
        local result = mexes:Where(function(k, mex)
            return mexesOnScreen:Contains(mex)
        end):ToArray()
        UpgradeMexes(result)
    end)
end

function PauseWorst(id)
    local mexes = mexData[id].mexes
    if table.empty(mexes) then
        return
    end
    SetPaused({ mexes[table.getn(mexes)] }, true)
    UpdateUI()
end

function GetMexes(id)
    return mexData[id].mexes
end

function UnPauseBest(id)
    local mexes = mexData[id].mexes
    if table.empty(mexes) then
        return
    end
    SetPaused({ mexes[1] }, false)
    UpdateUI()
end

function SelectBest(id)
    local mexes = mexData[id].mexes
    SelectUnits({ mexes[1] })
end

function SelectAll(id)
    local mexes = mexData[id].mexes
    SelectUnits(mexes)
end

function SetPausedAll(id, state)
    local mexes = mexData[id].mexes
    SetPaused(mexes, state)
    UpdateUI()
end

function SelectOnScreen(id)
    local mexes = mexData[id].mexes
    mexes = From(mexes)
    UISelectionByCategory("MASSEXTRACTION STRUCTURE", false, true, false, false)
    local mexesOnScreen = From(GetSelectedUnits())
    local result = mexes:Where(function(k, mex)
        return mexesOnScreen:Contains(mex)
    end):ToArray()
    SelectUnits(result)
end

function init()

    Options.upgradeT1Option.OnChange = function(var)
        upgradeT1 = var()
    end
    Options.upgradeT2Option.OnChange = function(var)
        upgradeT2 = var()
    end

    Options.unpauseAssisted.OnChange = function(var)
        unpauseAssisted = var()
    end
    Options.unpauseAssistedBP.OnChange = function(var)
        unpauseAssistedBP = var()
    end
    Options.unpauseOnce.OnChange = function(var)
        unpauseOnce = var()
    end
    import("/lua/ui/game/gamemain.lua").AddBeatFunction(UpdateUI, true)
end
