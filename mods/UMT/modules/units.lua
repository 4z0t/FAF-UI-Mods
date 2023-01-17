local TableInsert = table.insert
local EntityCategoryFilterDown = EntityCategoryFilterDown
local EntityCategoryFilterOut = EntityCategoryFilterOut
local GetFocusArmy = GetFocusArmy
local GameTick = GameTick


local SetIgnoreSelection = import("/lua/ui/game/gamemain.lua").SetIgnoreSelection
local CommandMode = import('/lua/ui/game/commandmode.lua')


local currentArmy
local units
--local assisting = {}
local cached = {}

local prevReset = 0
local prevCache = 0

---Performs hidden unit selection callback
---@param callback fun()
function HiddenSelect(callback)
    local currentCommand = CommandMode.GetCommandMode()
    local oldSelection = GetSelectedUnits()
    SetIgnoreSelection(true)
    callback()
    SelectUnits(oldSelection)
    CommandMode.StartCommandMode(currentCommand[1], currentCommand[2])
    SetIgnoreSelection(false)
end

local function ProcessAllUnits()
    UISelectionByCategory("ALLUNITS", false, false, false, false)
    for _, unit in GetSelectedUnits() or {} do
        units[unit:GetEntityId()] = unit
    end
end

local function UpdateAllUnits()
    HiddenSelect(ProcessAllUnits)
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
                if not (unit[focusId] or focused[focusId]) then
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
        units = UMT.Weak.Value {}
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

local function Update()
    local focused = {}
    for id, unit in units do
        if not unit:IsDead() then
            local focus = unit:GetFocus()
            if focus and not focus:IsDead() then
                local focusId = focus:GetEntityId()
                if not (unit[focusId] or focused[focusId]) then
                    focused[focusId] = focus
                end
            end
        else
            units[id] = nil
        end
    end
    for id, unit in focused do
        units[id] = unit
    end
end

local prevUpdate = 0


local function UpdateFast()
    local currentTick = GameTick()
    local army = GetFocusArmy()

    if army ~= currentArmy then
        prevReset = 0
        prevUpdate = 0
        currentArmy = army
        units = UMT.Weak.Value {}
        OnArmyChanged()
    end

    if army ~= -1 and currentTick - 10 >= prevUpdate then
        if currentTick - 50 > prevReset
        then
            UpdateAllUnits()
            prevReset = currentTick
        end

        Update()
        prevUpdate = currentTick
    end
end

function GetFast()
    UpdateFast()
    return units
end

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



---@class EntityCategoryFilterDownTable
local EntityCategoryFilterDownMetaTable = {
    ---returns units that match the given category
    ---@param units UserUnit[]
    ---@param self EntityCategoryFilterDownTable
    ---@return UserUnit[]
    __bor = function(units, self)
        local category = self.__category
        self.__category = nil
        return EntityCategoryFilterDown(category, units) or {}
    end,

    ---sets category for units to match
    ---@param self EntityCategoryFilterDownTable
    ---@param category EntityCategory
    ---@return EntityCategoryFilterDownTable
    __call = function(self, category)
        self.__category = category
        return self
    end
}
---@type EntityCategoryFilterDownTable
entityCategoryFilterDown = setmetatable({}, EntityCategoryFilterDownMetaTable)


---@class EntityCategoryFilterOutTable
local EntityCategoryFilterOutMetaTable = {
    ---returns units that doesnt match the given category
    ---@param units UserUnit[]
    ---@param self EntityCategoryFilterOutTable
    ---@return UserUnit[]
    __bor = function(units, self)
        local category = self.__category
        self.__category = nil
        return EntityCategoryFilterOut(category, units) or {}
    end,

    ---sets category for units to exlude
    ---@param self EntityCategoryFilterOutTable
    ---@param category EntityCategory
    ---@return EntityCategoryFilterOutTable
    __call = function(self, category)
        self.__category = category
        return self
    end
}
---@type EntityCategoryFilterOutTable
entityCategoryFilterOut = setmetatable({}, EntityCategoryFilterOutMetaTable)
