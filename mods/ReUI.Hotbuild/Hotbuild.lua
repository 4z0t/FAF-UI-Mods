ReUI.Require
{
    "ReUI.Core >= 1.2.0",
    "ReUI.Actions >= 1.3.0",
    "ReUI.LINQ >= 1.4.0",
    "ReUI.UI >= 1.4.0",
    "ReUI.UI.Animation >= 1.0.0",
    "ReUI.UI.Controls >= 1.0.0",
    "ReUI.UI.Views >= 1.2.0",
    "ReUI.UI.Views.Grid >= 1.0.0",
    "ReUI.Options >= 1.0.0"
}

function Main(isReplay)
    local type = type
    local TableEmpty = table.empty

    local ToSet = ReUI.LINQ.IPairsEnumerator:ToSet()
    local Layouter = ReUI.UI.FloorLayoutFor

    local Construction = import("/lua/ui/game/construction.lua")
    local CommandMode = import("/lua/ui/game/commandmode.lua")

    local CycleMap = import('Modules/CycleMap.lua').CycleMap

    local cycleMap
    ---@return CycleMap
    local function GetCycleMap()
        if not IsDestroyed(cycleMap) then
            return cycleMap
        end
        local frame = GetFrame(0) --[[@as Frame]]

        ---@type CycleMap
        cycleMap = CycleMap(frame)

        Layouter(cycleMap)
            :Top(ReUI.UI.LayoutFunctions.Mult(frame.Bottom, 0.75))
            :AtHorizontalCenterIn(frame)

        local function ResetCycle(commandMode, modeData)
            if commandMode == false or (not modeData) or not (modeData.isCancel) then
                if not IsDestroyed(cycleMap) then
                    cycleMap:ResetCycle()
                end
            end
        end

        local function OnSelectionChanged(info)
            if not TableEmpty(info.added) and
                not TableEmpty(info.removed) and
                not IsDestroyed(cycleMap) then
                cycleMap:ResetCycle()
            end
        end

        CommandMode.AddEndBehavior(ResetCycle)
        import("/lua/ui/game/gamemain.lua").ObserveSelection:AddObserver(OnSelectionChanged)
        return cycleMap
    end

    local hotbuilds = {}

    ---@param template any
    ---@param buildableUnits any
    ---@return boolean
    local function CanBuildTemplate(template, buildableUnits)
        local templateData = template.templateData
        if type(templateData[1]) ~= "number" or
            type(templateData[2]) ~= "number" then
            return false
        end
        for i = 3, table.getn(templateData) do
            local entry = templateData[i]
            local id = entry[1]
            if not id or not buildableUnits[id] then
                return false
            end
        end
        return true
    end

    ---@param template any
    ---@param buildableUnits any
    ---@return boolean
    local function CanBuildFactoryTemplate(template, buildableUnits)
        local templateData = template.templateData
        if type(templateData[1]) ~= "table" then
            return false
        end
        for _, entry in ipairs(templateData) do
            local id = entry.id
            if not id or not buildableUnits[id] then
                return false
            end
        end
        return true
    end

    ---@param selection UserUnit[]
    ---@param name string
    ---@param data string[]
    ---@param modifier any
    ---@return boolean
    local function BuildUnit(selection, name, data, modifier)

        GetCycleMap():HideCycle()
        local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(selection)
        local buildable = ToSet(EntityCategoryGetUnitList(buildableCategories))

        if table.empty(buildable) then
            return false
        end

        local items = {}
        local icons = {}
        for _, entry in ipairs(data) do
            if type(entry) == "string" then
                if buildable[entry] then
                    table.insert(items, entry)
                    table.insert(icons, entry)
                end
            elseif CanBuildFactoryTemplate(entry, buildable) then
                table.insert(items, entry)
                table.insert(icons, entry.icon)
            end
        end

        local maxPos = table.getn(items)
        if maxPos == 0 then
            return false
        end

        GetCycleMap():Cycle(1, name, icons, modifier)

        local item = items[1]

        local count = 1
        if modifier == "Shift" then
            count = 5
        end

        local exFacs = EntityCategoryFilterDown(categories.EXTERNALFACTORY, selection)
        if not table.empty(exFacs) then
            local exFacUnits = EntityCategoryFilterOut(categories.EXTERNALFACTORY, selection)

            for _, exFac in exFacs do
                table.insert(exFacUnits, exFac:GetCreator())
            end

            exFacUnits = table.unique(exFacUnits) --[[@as UserUnit[] ]]

            if type(item) == "string" then
                IssueBlueprintCommandToUnits(exFacUnits, "UNITCOMMAND_BuildFactory", item, count)
            else
                for _, entry in ipairs(item.templateData) do
                    IssueBlueprintCommandToUnits(exFacUnits, "UNITCOMMAND_BuildFactory", entry.id, entry.count)
                end
            end
        else
            if type(item) == "string" then
                IssueBlueprintCommand("UNITCOMMAND_BuildFactory", item, count)
            else
                for _, entry in ipairs(item.templateData) do
                    IssueBlueprintCommand("UNITCOMMAND_BuildFactory", entry.id, entry.count)
                end
            end
        end
        Construction.RefreshUI()
        return true
    end

    ---@param selection UserUnit[]
    ---@param name string
    ---@param data string[]
    ---@param modifier any
    ---@return boolean
    local function BuildStructure(selection, name, data, modifier)

        GetCycleMap():HideCycle()
        local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(selection)
        local buildable = ToSet(EntityCategoryGetUnitList(buildableCategories))

        if table.empty(buildable) then
            return false
        end

        local items = {}
        local icons = {}
        for _, entry in ipairs(data) do
            if type(entry) == "string" then
                if buildable[entry] then
                    table.insert(items, entry)
                    table.insert(icons, entry)
                end
            elseif CanBuildTemplate(entry, buildable) then
                table.insert(items, entry)
                table.insert(icons, entry.icon)
            end
        end

        local maxPos = table.getn(items)
        if maxPos == 0 then
            return false
        end

        local pos = GetCycleMap():Cycle(maxPos, name, icons, modifier)

        local item = items[pos]
        ClearBuildTemplates()
        if type(item) == "string" then
            CommandMode.StartCommandMode("build", { name = item })
        else
            local cmd = item.templateData[3][1]
            CommandMode.StartCommandMode("build", { name = cmd })
            SetActiveBuildTemplate(item.templateData)
        end
        return true
    end

    ---@param name string
    ---@return boolean
    local function ProcessHotbuild(name)
        local data = hotbuilds[name]

        if not data then
            WARN("Hotbuild " .. name .. " doesn't exist")
            return false
        end

        local modifier = ""
        if IsKeyDown("Shift") then modifier = "Shift"
        elseif IsKeyDown("MENU") then modifier = "Alt"
        end

        local selection = GetSelectedUnits()
        if not selection then
            return false
        end

        if not
            table.empty(EntityCategoryFilterDown(categories.ENGINEER - categories.STRUCTURE + categories.xrl0403,
                selection)) then
            return BuildStructure(selection, name, data, modifier)
        else
            return BuildUnit(selection, name, data, modifier)
        end
    end

    ReUI.Core.OnPostCreateUI(function(isReplay)
        local ViewModel = import('Modules/viewmodel.lua')
        local Model = import('Modules/model.lua')
        local View = import("Modules/views/view.lua")

        Model.init()
        ViewModel.init()

        ReUI.Options.Builder.AddOptions("ReUI.Hotbuild", "ReUI.Hotbuild", View.init)
    end)

    ---@param name string
    ---@param data string[]|table[]
    local function AddHotbuild(name, data)
        hotbuilds[name] = data
    end

    return {
        ProcessHotbuild = ProcessHotbuild,
        GetCycleMap = GetCycleMap,
        AddHotbuild = AddHotbuild,
    }
end
