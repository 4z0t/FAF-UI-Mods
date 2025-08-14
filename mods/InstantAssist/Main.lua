ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.Options >= 1.0.0",
    "ReUI.Units >= 1.0.0",
}

function Main(isReplay)
    if isReplay then
        return
    end

    local EntityCategoryContains = EntityCategoryContains
    local MathMax = math.max
    local VDist3 = VDist3

    ---@param targetUnit UserUnit
    ---@param unit UserUnit
    ---@return boolean
    local function IsWithinBuildRange(targetUnit, unit)
        local targetSkirtSize = 1
        local bpPhysics = targetUnit:GetBlueprint().Physics
        if bpPhysics then
            targetSkirtSize = MathMax(bpPhysics.SkirtSizeX, bpPhysics.SkirtSizeZ)
        end

        local bp = unit:GetBlueprint()
        local bpFoot = bp.Footprint
        local buildRadius = (bp.Economy.MaxBuildDistance or 5) + MathMax(bpFoot.SizeX or 0, bpFoot.SizeZ or 0) +
            targetSkirtSize

        return buildRadius > VDist3(targetUnit:GetPosition(), unit:GetPosition())
    end

    ReUI.Core.Hook("/lua/ui/game/commandmode.lua", "OnCommandIssued", function(field)
        local options = ReUI.Options.Mods["InstantAssist"]
        local enabled
        options.enabled:Bind(function(opt)
            enabled = opt()
        end)

        ---@param command UserCommand
        return function(command)
            field(command)

            if not enabled then
                return
            end

            if (command.CommandType == "Guard" or command.CommandType == "Repair") and command.Target.EntityId and
                command.Clear and command.Units then

                local targetUnit = GetUnitById(command.Target.EntityId) --[[@as UserUnit]]

                if targetUnit == nil then
                    return
                end

                local fraction = targetUnit:GetFractionComplete()

                local isStructure = targetUnit:IsInCategory "STRUCTURE"
                local isMassExtractor = EntityCategoryContains(categories.MASSEXTRACTION * categories.STRUCTURE,
                    targetUnit)

                if not isStructure or isMassExtractor and fraction >= 1 then
                    return
                end

                local engineers = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
                if table.empty(engineers) then
                    return
                end

                local withInRangeEngineers = {}
                for _, engy in engineers do
                    if IsWithinBuildRange(targetUnit, engy) then
                        table.insert(withInRangeEngineers, engy)
                    end
                end

                if table.empty(withInRangeEngineers) then
                    return
                end

                ForkThread(function()
                    WaitTicks(1)
                    ReUI.Units.HiddenSelect(function()
                        SelectUnits(withInRangeEngineers)
                        SimCallback({ Func = 'AbortNavigation', Args = {} }, true)
                    end)
                end)
            end
        end
    end)
end
