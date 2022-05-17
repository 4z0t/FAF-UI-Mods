-- upvalue for performance
local TableInsert = table.insert
local EntityCategoryFilterDown = EntityCategoryFilterDown
local categoryMex = categories.MASSEXTRACTION * categories.STRUCTURE
local GetIsPaused = GetIsPaused

local AddBeatFunction = import("/lua/ui/game/gamemain.lua").AddBeatFunction
local GetUnits = import("/mods/common/units.lua").Get
local From = import("/mods/UMT/modules/linq.lua").From
local UpdateMexPanel = import("mexpanel.lua").Update
local Select = import("/mods/UMT/modules/select.lua")

local mexCategories = import("mexcategories.lua").mexCategories
local mexData = {}

local toBePaused = {}

local function UpgradeMexes(mexes)

    local upgrades = {}

    for _, m in mexes do
        toBePaused[m:GetEntityId()] = true
        local bp = m:GetBlueprint()
        local upgrades_to = bp.General.UpgradesTo

        upgrades[upgrades_to] = upgrades[upgrades_to] or {}

        table.insert(upgrades[upgrades_to], m)
    end

    if not table.empty(upgrades) then
        Select.Hidden(function()
            for upgrades_to, up_mexes in upgrades do
                SelectUnits(up_mexes)
                IssueBlueprintCommand("UNITCOMMAND_Upgrade", upgrades_to, 1, false)
            end
        end)
    end
end

function UpgradeAll(id)
    UpgradeAndPause(mexData[id].mexes)
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
    local mData = mexData[id]
    local mexes = mData.mexes
    if table.empty(mexes) then
        return
    end
    SetPaused({mexes[mData.currentWorst]}, true)
    mData.currentWorst = mData.currentWorst - 1
end

function UnPauseBest(id)
    local mData = mexData[id]
    local mexes = mData.mexes
    if table.empty(mexes) then
        return
    end
    SetPaused({mexes[mData.currentBest]}, false)
    mData.currentBest = mData.currentBest + 1
end

function SelectBest(id)
    local mexes = mexData[id].mexes
    SelectUnits({mexes[1]})
end

function SelectAll(id)
    local mexes = mexData[id].mexes
    SelectUnits(mexes)
end

function SetPausedAll(id, state)
    local mexes = mexData[id].mexes
    SetPaused(mexes, state)
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
        if GetIsPaused({unit}) ~= category.isPaused then
            return false
        end
    end

    return true
end

local function UpdateUI()
    local mexes = GetUnits()
    mexes = EntityCategoryFilterDown(categoryMex, mexes)

    for id, category in mexCategories do
        mexData[id] = {
            mexes = {},
            currentBest = 1
        }
    end

    for _, mex in mexes do
        mex.isUpgraded = false
        mex.isUpgrader = false
        if toBePaused[mex:GetEntityId()] then
            toBePaused[mex:GetEntityId()] = nil
            SetPaused({mex}, true)
        end
    end
    for _, mex in mexes do
        local f = mex:GetFocus()
        if f ~= nil and f:IsInCategory("STRUCTURE") then
            mex.isUpgrader = true
            f.isUpgraded = true
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

    for id, category in mexCategories do

        if category.isUpgrading and not table.empty(mexData[id].mexes) then
            local sortedMexes = From(mexData[id].mexes):Sort(function(a, b)
                return a:GetWorkProgress() > b:GetWorkProgress()
            end)

            local sorted = sortedMexes:Map(function(k, m)
                return m:GetWorkProgress()
            end):ToDictionary()

            mexData[id].progress = sorted

            mexData[id].mexes = sortedMexes:ToDictionary()
            mexData[id].currentWorst = table.getn(mexData[id].mexes)
        end
    end

    UpdateMexPanel(mexData)

end

function init()
    AddBeatFunction(UpdateUI, true)
end

