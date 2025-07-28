local categories = categories
local EntityCategoryContains = EntityCategoryContains

local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local Enhancements = ReUI.Units.Enhancements

local UIUtil = import("/lua/ui/uiutil.lua")
local UnitViewDetail = import("/lua/ui/game/unitviewdetail.lua")
local IsRestricted = import("/lua/game.lua").IsRestricted

local Enumerate = ReUI.LINQ.Enumerate

---@class BuildOptionData
---@field id string

local sortCategoriesOrder = {
    categories.SORTCONSTRUCTION,
    categories.SORTECONOMY,
    categories.SORTDEFENSE,
    categories.SORTSTRATEGIC,
    categories.SORTINTEL,
    categories.SORTOTHER,
}

---@param bp string
---@return integer
local function FirstMatch(bp)
    ---@param category EntityCategory
    for i, category in sortCategoriesOrder do
        if EntityCategoryContains(category, bp) then
            return i
        end
    end
    return 10
end

local techToCategory = {
    ["TECH1"] = categories.TECH1,
    ["TECH2"] = categories.TECH2,
    ["TECH3"] = categories.TECH3,
    ["EXPERIMENTAL"] = categories.EXPERIMENTAL,
}

---@param acus UserUnit[]
---@return EntityCategory
local function CheckACUBuildOptions(acus)
    local foundUpgrading = false
    ---@type EntityCategory
    local buildableCategories
    for _, acu in acus do
        local bp = acu:GetBlueprint()
        local buildCat = bp.Economy.BuildableCategory

        local tech = 1
        if Enhancements.IsQueued(acu, "AdvancedEngineering") and not Enhancements.IsInstalled(acu, "AdvancedEngineering") then
            tech = 2
            foundUpgrading = true
        end
        if Enhancements.IsQueued(acu, "T3Engineering") and not Enhancements.IsInstalled(acu, "T3Engineering") then
            tech = 3
            foundUpgrading = true
        end

        local buildable = ParseEntityCategory(buildCat[1])
        if tech >= 2 then
            buildable = buildable + ParseEntityCategory(buildCat[2])
        end
        if tech >= 3 then
            buildable = buildable + ParseEntityCategory(buildCat[3])
        end

        if not buildableCategories then
            buildableCategories = buildable
        else
            buildableCategories = buildableCategories * buildable
        end
    end

    if not foundUpgrading then
        local _, _, buildableCategories = GetUnitCommandData(acus)
        return buildableCategories
    end

    local supportFactories = buildableCategories - categories.SUPPORTFACTORY
    ReUI.Units.HiddenSelect(function(currentSelection)
        UISelectionByCategory("RESEARCH", false, false, false, false)
        local hqs = GetSelectedUnits()
        if table.empty(hqs) then
            return
        end

        ---@param hq UserUnit
        for _, hq in hqs do
            local faction = string.upper(hq:GetBlueprint().General.FactionName)
            local factionCategory = categories[faction]

            local supportCategory = categories.SUPPORTFACTORY * factionCategory

            if EntityCategoryContains(categories.TECH3, hq) then
                supportCategory = supportCategory * (categories.TECH3 + categories.TECH2)
            elseif EntityCategoryContains(categories.TECH2, hq) then
                supportCategory = supportCategory * categories.TECH2
            end

            if EntityCategoryContains(categories.LAND, hq) then
                supportCategory = supportCategory * categories.LAND
            elseif EntityCategoryContains(categories.AIR, hq) then
                supportCategory = supportCategory * categories.AIR
            elseif EntityCategoryContains(categories.NAVAL, hq) then
                supportCategory = supportCategory * categories.NAVAL
            end
            supportFactories = supportFactories + supportCategory
        end
    end)

    return buildableCategories * supportFactories
end

---@class BuildOptionsHandler : ASelectionHandler
BuildOptionsHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "BuildOptions",

    OnInit = function(self)
    end,

    ---@param self BuildOptionsHandler
    ---@param context ConstructionContext
    ---@return string[]?
    Update = function(self, context)
        local selection = context.selection
        if table.empty(selection) then
            return
        end
        ---@cast selection -nil

        local isAllEngineers = table.empty(EntityCategoryFilterOut(categories.ENGINEER, selection))
        if not isAllEngineers then
            return
        end

        local acus = EntityCategoryFilterDown(categories.COMMAND, selection)
        local others = EntityCategoryFilterOut(categories.COMMAND, selection)
        local buildableCategories
        if not table.empty(acus) then
            buildableCategories = CheckACUBuildOptions(acus)
        end
        if not table.empty(others) then
            local _, _, buildableCategoriesOthers = GetUnitCommandData(others)
            if not buildableCategories then
                buildableCategories = buildableCategoriesOthers
            else
                buildableCategories = buildableCategories * buildableCategoriesOthers
            end
        end

        local tech = context.tech

        ---@type table<TechLevel, boolean>
        local techs = Enumerate(techToCategory, next)
            ---@param category EntityCategory
            :Select(function(category)
                return not EntityCategoryEmpty(category * buildableCategories)
            end)
            :ToTable()

        context.panel:SetAvailableTech(techs)

        if tech == "NONE" then
            ---@param t TechLevel
            for _, t in { "TECH3", "TECH2", "TECH1" } do
                if techs[t] then
                    tech = t
                    break
                end
            end
        end

        if tech == "NONE" then
            return
        end

        context.panel:SetActiveTech(tech)

        local techCategory = categories[tech]
        local buildableUnits = EntityCategoryGetUnitList(buildableCategories * techCategory)

        if table.empty(buildableUnits) then
            return
        end

        return Enumerate(buildableUnits)
            :OrderBy(function(value)
                return value
            end, function(bp1, bp2)
                local n1, n2 = FirstMatch(bp1), FirstMatch(bp2)
                if n1 ~= n2 then
                    return n1 < n2
                end

                n1, n2 = __blueprints[bp1], __blueprints[bp2]
                n1 = n1.BuildIconSortPriority or n1.StrategicIconSortPriority
                n2 = n2.BuildIconSortPriority or n2.StrategicIconSortPriority

                if n1 ~= n2 then
                    return n1 < n2
                end

                return bp1 < bp2
            end)
            :Select(function(bpID)
                return { id = bpID }
            end)
            :ToArray()
    end,

    ---@param self BuildOptionsHandler
    OnDestroy = function(self)
    end,

    ---@class BuildOptionsItem : AItemComponent
    ---@field data BuildOptionData
    ---@field context ConstructionContext
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self BuildOptionsItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
        end,

        ---Called when grid item receives an event
        ---@param self BuildOptionsItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                import("/lua/ui/game/commandmode.lua").StartCommandMode("build", { name = self.data.id })
                PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
            elseif event.Type == "MouseEnter" then
                local id = self.data.id
                UnitViewDetail.Show(__blueprints[id], self.context.selection[1], id)
            elseif event.Type == "MouseExit" then
                UnitViewDetail.Hide()
            end
        end,

        ---Called when item is activated with this component event handling
        ---@param self BuildOptionsItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action BuildOptionData
        ---@param context ConstructionContext
        Enable = function(self, item, action, context)
            self.data = action
            self.context = context
            local id = self.data.id
            item:DisplayBPID(id)
            item.Text = nil
        end,

        ---Called when item is changing event handler
        ---@param self BuildOptionsFactoryItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            item.StrategicIcon = nil
            item.BackGround = nil
            item.Icon = nil
        end,

        ---Called when component is being destroyed
        ---@param self BuildOptionsItem
        Destroy = function(self)
            self.context = nil
        end,
    },
}

---@param units UserUnit[]
---@param bpId string
local function IssueUpgradeOrders(units, bpId)
    local bp = __blueprints[bpId]
    local upgrades = {}
    local chain = {}
    local from = bp.General.UpgradesFrom
    local to = bpId

    if table.empty(units) then
        return
    end

    while from and from ~= 'none' and from ~= to do
        table.insert(chain, 1, to)
        upgrades[from] = table.deepcopy(chain)
        to = from
        from = __blueprints[to].General.UpgradesFrom
    end

    local unitId = units[1]:GetUnitId()
    if not upgrades[unitId] then
        return
    end

    for _, o in upgrades[unitId] do
        IssueBlueprintCommand("UNITCOMMAND_Upgrade", o, 1, false)
    end
end

local CONSTRUCTIONSORTDOWN = categories.CONSTRUCTIONSORTDOWN

local techBuildables = {
    ["TECH1"] = (categories.TECH1 - CONSTRUCTIONSORTDOWN + categories.TECH2 * CONSTRUCTIONSORTDOWN),
    ["TECH2"] = (categories.TECH2 - CONSTRUCTIONSORTDOWN + categories.TECH3 * CONSTRUCTIONSORTDOWN),
    ["TECH3"] = (categories.TECH3 - CONSTRUCTIONSORTDOWN + categories.EXPERIMENTAL * CONSTRUCTIONSORTDOWN),
    ["EXPERIMENTAL"] = (categories.EXPERIMENTAL - CONSTRUCTIONSORTDOWN),
}

---@class BuildOptionsFactoryHandler : ASelectionHandler
BuildOptionsFactoryHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "BuildOptionsFactory",

    OnInit = function(self)
    end,

    ---@param self BuildOptionsFactoryHandler
    ---@param context ConstructionContext
    ---@return string[]?
    Update = function(self, context)
        local selection = context.selection
        if table.empty(selection) then
            return
        end
        ---@cast selection -nil

        local isAllFactories = table.empty(EntityCategoryFilterOut(categories.FACTORY + categories.EXTERNALFACTORY,
            selection))
        if not isAllFactories then
            return
        end

        local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(selection)

        local tech = context.tech

        ---@type table<TechLevel, boolean>
        local techs = Enumerate(techBuildables, next)
            ---@param category EntityCategory
            :Select(function(category)
                return not EntityCategoryEmpty(category * buildableCategories)
            end)
            :ToTable()

        context.panel:SetAvailableTech(techs)

        if tech == "NONE" then
            ---@param t TechLevel
            for _, t in { "TECH3", "TECH2", "TECH1" } do
                if techs[t] then
                    tech = t
                    break
                end
            end
        end

        if tech == "NONE" then
            return
        end

        context.panel:SetActiveTech(tech)

        local buildableUnits = EntityCategoryGetUnitList(buildableCategories *
            (techBuildables[tech] or categories.ALLUNITS))

        if table.empty(buildableUnits) then
            return
        end

        local focusArmy = GetFocusArmy()

        return Enumerate(buildableUnits)
            :Where(function(bpID)
                return not IsRestricted(bpID, focusArmy)
            end)
            :OrderBy(function(value)
                return value
            end, function(bp1, bp2)
                local n1, n2 = FirstMatch(bp1), FirstMatch(bp2)
                if n1 ~= n2 then
                    return n1 < n2
                end

                n1, n2 = __blueprints[bp1], __blueprints[bp2]
                n1 = n1.BuildIconSortPriority or n1.StrategicIconSortPriority
                n2 = n2.BuildIconSortPriority or n2.StrategicIconSortPriority

                if n1 ~= n2 then
                    return n1 < n2
                end

                return bp1 < bp2
            end)
            :Select(function(bpID)
                return { id = bpID }
            end)
            :ToArray()
    end,

    ---@param self BuildOptionsFactoryHandler
    OnDestroy = function(self)
    end,

    ---@class BuildOptionsFactoryItem : AItemComponent
    ---@field data BuildOptionData
    ---@field context ConstructionContext
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self BuildOptionsFactoryItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
        end,


        ---@param self BuildOptionsFactoryItem
        ---@param selection UserUnit[]
        ---@param id string
        ---@param count number
        OrderConstruction = function(self, selection, id, count)
            local bpGeneral = __blueprints[id].General

            local performUpgrade = bpGeneral.UpgradesFrom ~= 'none' and Enumerate(selection)
                :All(function(unit)
                    local unitBp = unit:GetBlueprint()
                    if bpGeneral.UpgradesFrom == unitBp.BlueprintId then
                        return true
                    elseif bpGeneral.UpgradesFrom == unitBp.General.UpgradesTo then
                        return true
                    elseif bpGeneral.UpgradesFromBase ~= "none" then
                        -- Try testing against the base
                        if bpGeneral.UpgradesFromBase == unitBp.BlueprintId then
                            return true
                        elseif bpGeneral.UpgradesFromBase == unitBp.General.UpgradesFromBase then
                            return true
                        end
                    end
                    return false
                end)
            if performUpgrade then
                IssueUpgradeOrders(selection, id)
                return
            end

            local exFacs = EntityCategoryFilterDown(categories.EXTERNALFACTORY, selection)
            if not table.empty(exFacs) then
                local exFacUnits = EntityCategoryFilterOut(categories.EXTERNALFACTORY, selection)

                for _, exFac in exFacs do
                    table.insert(exFacUnits, exFac:GetCreator())
                end

                -- in case we've somehow selected both the platform and the factory, only put the fac in once
                exFacUnits = table.unique(exFacUnits)
                IssueBlueprintCommandToUnits(exFacUnits, "UNITCOMMAND_BuildFactory", id, count)
            else
                IssueBlueprintCommand("UNITCOMMAND_BuildFactory", id, count)
            end
        end,

        ---@param self BuildOptionsFactoryItem
        ---@param selection UserUnit[]
        ---@param id string
        ---@param count number
        InsertFrontQueue = function(self, selection, id, count)
            local factory = selection[1]
            local queue = SetCurrentFactoryForQueueDisplay(factory)
            if table.empty(queue) then
                self:OrderConstruction(selection, id, count)
                return
            end

            if queue[1].id == id then
                IncreaseBuildCountInQueue(1, count)
                return
            end

            local queueToRestore = {}
            -- Unstable
            -- for index = table.getn(queue), 1, -1 do
            --     local c = queue[index].count
            --     if index == 1 then
            --         c = c - 1
            --     end
            --     DecreaseBuildCountInQueue(index, c)
            --     table.insert(queueToRestore, { id = queue[index].id, count = c })
            -- end

            for index = table.getn(queue), 2, -1 do
                local c = queue[index].count
                DecreaseBuildCountInQueue(index, c)
                table.insert(queueToRestore, { id = queue[index].id, count = c })
            end
            self:OrderConstruction(selection, id, count)

            for i = table.getn(queueToRestore), 1, -1 do
                self:OrderConstruction(selection, queueToRestore[i].id, queueToRestore[i].count)
            end
        end,

        ---Called when grid item receives an event
        ---@param self BuildOptionsFactoryItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                local modifiers = event.Modifiers
                local count = 1
                if modifiers.Shift or modifiers.Ctrl then
                    count = 5
                end

                if modifiers.Alt and table.getn(self.context.selection) == 1 then
                    self:InsertFrontQueue(self.context.selection, self.data.id, count)
                else
                    self:OrderConstruction(self.context.selection, self.data.id, count)
                end

                PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
            elseif event.Type == "MouseEnter" then
                local id = self.data.id
                UnitViewDetail.Show(__blueprints[id], self.context.selection[1], id)
            elseif event.Type == "MouseExit" then
                UnitViewDetail.Hide()
            end
        end,

        ---Called when item is activated with this component event handling
        ---@param self BuildOptionsFactoryItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action BuildOptionData
        ---@param context ConstructionContext
        Enable = function(self, item, action, context)
            self.data = action
            self.context = context
            local id = self.data.id
            item:DisplayBPID(id)
            item.Text = nil
        end,

        ---Called when item is changing event handler
        ---@param self BuildOptionsFactoryItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            item.StrategicIcon = nil
            item.BackGround = nil
            item.Icon = nil
        end,

        ---Called when component is being destroyed
        ---@param self BuildOptionsFactoryItem
        Destroy = function(self)
            self.context = nil
        end,
    },
}
