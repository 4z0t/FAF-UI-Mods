local TableInsert = table.insert
local GetFocusArmy = GetFocusArmy
local GameTick = GameTick

local SelectHidden = UMT.Select.Hidden

local currentArmy
local units = setmetatable({}, UMT.WeakMeta.Value)
--local assisting = {}
local cached = {}

local prevReset = 0
local prevCache = 0

local function ProcessAllUnits()
    UISelectionByCategory("ALLUNITS", false, false, false, false)
    for _, unit in GetSelectedUnits() or {} do
        units[unit:GetEntityId()] = unit
    end
end

local function UpdateAllUnits()
    SelectHidden(ProcessAllUnits)
end

local function UpdateCache()
    cached = {}
    --    assisting = {}
    local focused = {}

    for id, unit in units do
        if not unit:IsDead() then
            TableInsert(cached, unit)
            local focus = unit:GetFocus()
            if focus and not focus:IsDead() then
                local focusId = focus:GetEntityId()
                if not focused[focusId] then
                    focused[focusId] = focus
                    TableInsert(cached, focus)
                end
                -- if EntityCategoryContains(categories.ENGINEER, unit) then
                --     if not assisting[focusId] then
                --         assisting[focusId] = {
                --             engineers = {},
                --             build_rate = 0
                --         }
                --     end

                --     TableInsert(assisting[focusId]['engineers'], unit)
                --     assisting[focusId]['build_rate'] = assisting[focusId]['build_rate'] + u:GetBuildRate()
                -- end
            end
        else
            units[id] = nil
        end
    end
    for id, unit in focused do
        units[id] = unit
    end
end

local changedArmyCallbacks = {}

function AddOnArmyChanged(callback)
    TableInsert(changedArmyCallbacks, callback)
end

local function OnArmyChanged()
    for _, callback in changedArmyCallbacks do
        if callback then
            callback()
        end
    end
end

local function CheckCache()
    local currentTick = GameTick()
    local army = GetFocusArmy()

    if army ~= currentArmy then
        prevReset = 0
        prevCache = 0
        currentArmy = army
        cached = {}
        units = {}
        OnArmyChanged()
    end

    if army ~= -1 and currentTick - 10 >= prevCache then
        -- local score = Score.Get()
        -- local n = score[army].general.currentunits.count

        if currentTick - 50 > prevReset
        --and (not n or n > table.getsize(cached))
        then
            UpdateAllUnits()
            prevReset = currentTick
        end

        UpdateCache()
        prevCache = currentTick
    end
end

-- function Data(unit)
--     local bp = unit:GetBlueprint()
--     local data = {
--         is_idle = unit:IsIdle(),
--         econ = unit:GetEconData()
--     }

--     if bp.Economy.ProductionPerSecondMass > 0 and data['econ']['massProduced'] > bp.Economy.ProductionPerSecondMass then
--         data['bonus'] = data['econ']['massProduced'] / bp.Economy.ProductionPerSecondMass
--     else
--         data['bonus'] = 1
--     end

--     if not data['is_idle'] then
--         local focus = unit:GetFocus()
--         data['assisters'] = 0
--         data['build_rate'] = bp.Economy.BuildRate

--         if focus then
--             local focus_id = focus:GetEntityId();

--             if assisting[focus_id] then
--                 data['assisting'] = table.getsize(assisting[focus_id]['engineers'])
--                 data['build_rate'] = data['build_rate'] + assisting[focus_id]['build_rate']
--             end
--         end
--     end

--     return data
-- end

function Get(filter)
    CheckCache()
    cached = ValidateUnitsList(cached)

    if filter then
        return EntityCategoryFilterDown(filter, cached) or {}
    else
        return cached
    end
end

-- local current_tick = 0
-- local prev_tick = 0
-- local current_army = nil
-- local prev_update = 0
-- local units = {}
-- local added = {}

-- --[[
--     checker : nil | function(unit : unit ) -> bool
--     passer : function( units : table | unit : unit  ) -> nil

-- ]]

-- local callbacks = {}

-- function AddCallback(checker, passer)
--     table.insert(callbacks, {
--         checker = checker,
--         passer = passer
--     })
-- end

-- function ProcessCallbacks()
--     for _, callback in callbacks do
--         if callback.checker == nil then -- for all units
--             callback.passer(added)
--         else -- for each unit

--         end
--     end
-- end

-- function UpdateUnits()
--     current_tick = GameTick()
--     if current_tick ~= prev_tick then

--         local army = GetFocusArmy()

--         if army ~= current_army then
--             prev_update = 0
--             current_army = army
--             units = {}
--             added = {}
--         end

--         prev_tick = current_tick
--     end
-- end

-- function init(isReplay)

-- end
