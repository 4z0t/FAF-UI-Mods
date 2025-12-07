local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler


local UIUtil = import("/lua/ui/uiutil.lua")
local UnitViewDetail = import("/lua/ui/game/unitviewdetail.lua")

local Enumerate = ReUI.LINQ.Enumerate
local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator

local Contains = IPairsEnumerator:Contains()

local options = ReUI.Options.Mods["ReUI.Construction"]

local showGroups
options.selection.showGroups:Bind(function(opt)
    showGroups = opt()
end)

---@type table<TechCategory, integer>
local techCatOrder = {
    ["TECH1"] = 1,
    ["TECH2"] = 2,
    ["TECH3"] = 3,
    ["EXPERIMENTAL"] = 4,
    ['SUBCOMMANDER'] = 5,
    ['COMMAND'] = 6,
}

---@class SelectedUnitsData
---@field [1] string # bp ID
---@field [2] number # number of units

---@class SelectedUnitsGroup
---@field matcher UnitGroupMatcher
---@field idsCount table<BlueprintId, integer>
---@field sortedIds SelectedUnitsData[]
---@field units UserUnit[]

---@class SelectedUnitsAction
---@field type "item" | "group"
---@field group SelectedUnitsGroup
---@field id BlueprintId?



--[[
Sort order of selected units:
Groups:
    1. first goes any units that do not fit into any other category
    2. Engineers
    3. Land units
    4. Air units
    5. Naval units
    6. Structures
    7. Units with SORTCONSTRUCTION category
    8. air units with low fuel

inside groups units are sorted by tech category:
    0. Any other unit that does not fit into any category below
    1. COMMAND
    2. SUBCOMMANDER
    3. EXPERIMENTAL
    4. TECH3
    5. TECH2
    6. TECH1

]]

---@class UnitGroupMatcher
---@field name string
---@field icon FileName
local UnitGroupMatcher = Class()
{

    ---@param self UnitGroupMatcher
    ---@param name string
    ---@param icon FileName
    __init = function(self, name, icon)
        self.name = name
        self.icon = icon
    end,

    ---@param self UnitGroupMatcher
    ---@param unit UserUnit
    ---@return boolean
    Match = function(self, unit)
        return false
    end,

    ---@param self UnitGroupMatcher
    ---@param component SelectedUnitsListItem
    ---@param item ReUI.Construction.Grid.Item
    ---@param action SelectedUnitsAction
    Display = function(self, component, item, action)
    end
}

---@class CategoryGroupMatcher : UnitGroupMatcher
---@field category EntityCategory
CategoryGroupMatcher = Class(UnitGroupMatcher)
{
    ---@param self CategoryGroupMatcher
    ---@param name string
    ---@param icon FileName
    ---@param category EntityCategory
    __init = function(self, name, icon, category)
        UnitGroupMatcher.__init(self, name, icon)
        self.category = category
    end,

    ---@param self CategoryGroupMatcher
    ---@param unit UserUnit
    ---@return boolean
    Match = function(self, unit)
        return EntityCategoryContains(self.category, unit)
    end,
}

---@class AirFuelGroupMatcher : UnitGroupMatcher
AirFuelGroupMatcher = Class(UnitGroupMatcher)
{
    ---@param self AirFuelGroupMatcher
    ---@param unit UserUnit
    ---@return boolean
    Match = function(self, unit)
        if not EntityCategoryContains(categories.AIR, unit) then
            return false
        end

        local fuel = unit:GetFuelRatio()

        return not (fuel > 0.2 or fuel <= -1)
    end,

    ---@param self AirFuelGroupMatcher
    ---@param component SelectedUnitsListItem
    ---@param item ReUI.Construction.Grid.Item
    ---@param action SelectedUnitsAction
    Display = function(self, component, item, action)
        component.icon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/fuel.dds'))
        component.icon:Show()
    end,
}

---@param name string
---@return FileName
local function IconPath(name)
    return "/game/strategicicons/icon_" .. name .. "_rest.dds"
end

---@class SelectedUnitsListHandler : ASelectionHandler
---@field _blueprintSortOrder table<BlueprintId, integer>
SelectedUnitsListHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "Selection",

    OnInit = function(self)
        -- local bps = __blueprints
        -- self._blueprintSortOrder = Enumerate(bps, next)
        --     :Select(function(bp, bpId)
        --         return { bpId, bp }
        --     end)
        --     :OrderBy(function(value)
        --         return value[1]
        --     end, function(id1, id2)
        --         local n1, n2 = FirstMatch(id1), FirstMatch(id2)
        --         if n1 ~= n2 then
        --             return n1 < n2
        --         end

        --         n1, n2 = techCatOrder[bps[id1].TechCategory] or 0, techCatOrder[bps[id2].TechCategory] or 0
        --         if n1 ~= n2 then
        --             return n1 < n2
        --         end

        --         return id1 < id2
        --     end)
        --     :ToTable(function(key, value)
        --         return value, key
        --     end)
    end,

    --These are scanned from top to bottom to match group
    UnitGroupMatchers =
    {
        CategoryGroupMatcher("ALLUNITS", IconPath "experimental_generic", categories.ALLUNITS),
        CategoryGroupMatcher("ENGINEER", IconPath "land_engineer", categories.ENGINEER),
        CategoryGroupMatcher("LAND", IconPath "land_generic", categories.LAND - categories.ENGINEER),
        CategoryGroupMatcher("AIR", IconPath "fighter_generic", categories.AIR - categories.ENGINEER),
        CategoryGroupMatcher("NAVAL", IconPath "ship_generic", categories.NAVAL),
        CategoryGroupMatcher("STRUCTURE", IconPath "structure_generic", categories.STRUCTURE),
        CategoryGroupMatcher("CONSTRUCTION", IconPath "factory_generic", categories.SORTCONSTRUCTION),
        AirFuelGroupMatcher("LOWFUEL", '/game/unit_view_icons/fuel.dds'),
    },

    ---@param self SelectedUnitsListHandler
    ---@param selection UserUnit[]
    ---@return SelectedUnitsGroup[]
    SplitSelectionIntoGroups = function(self, selection)
        local matchers = self.UnitGroupMatchers

        ---@type SelectedUnitsGroup[]
        local result = Enumerate(matchers)
            ---@param matcher UnitGroupMatcher
            :Select(function(matcher)
                return {
                    matcher = matcher,
                    units = {},
                    idsCount = {},
                }
            end)
            :ToArray()

        for _, unit in selection do
            for i = table.getn(matchers), 1, -1 do
                local matcher = matchers[i]
                if matcher:Match(unit) then
                    table.insert(result[i].units, unit)
                    break
                end
            end
        end

        for _, group in ipairs(result) do
            group.idsCount = Enumerate(group.units)
                :CountBy(function(unit)
                    return unit:GetBlueprint().BlueprintId
                end)
                :ToTable()
        end

        return result
    end,

    ---@param self SelectedUnitsListHandler
    ---@param idsCount table<BlueprintId, integer>
    ---@return SelectedUnitsData[]
    SortIds = function(self, idsCount)

        local bpSortOrder = Enumerate(idsCount, next)
            :ToTable(function(bpId)
                local bp = __blueprints[bpId]
                return bpId, techCatOrder[bp.TechCategory] or 0
            end)


        local ids = Enumerate(idsCount, next)
            :Select(function(count, bpId) return { bpId, count } end)
            :OrderBy(function(value) return value[1] end,
                function(id1, id2)
                    local n1, n2 = bpSortOrder[id1], bpSortOrder[id2]
                    if n1 ~= n2 then
                        return n1 > n2
                    end

                    return id1 < id2
                end)
            :ToArray()

        return ids

    end,


    ---@param self SelectedUnitsListHandler
    ---@param context ConstructionContext
    ---@return string[]?
    Update = function(self, context)
        local selection = context.selection
        if table.empty(selection) then
            return
        end
        ---@cast selection -nil

        local unitGroups = self:SplitSelectionIntoGroups(selection)


        for _, group in ipairs(unitGroups) do
            group.sortedIds = self:SortIds(group.idsCount)
        end


        local sortedData = {}
        for _, group in ipairs(unitGroups) do
            if not table.empty(group.sortedIds) then
                if showGroups then
                    table.insert(sortedData, {
                        type = "group",
                        group = group,
                    })
                end
                for _, data in ipairs(group.sortedIds) do
                    table.insert(sortedData, {
                        type = "item",
                        group = group,
                        id = data[1],
                    })
                end
            end
        end

        return sortedData
    end,

    ---@param self SelectedUnitsListHandler
    OnDestroy = function(self)
    end,

    ---@class SelectedUnitsListItem : AItemComponent
    ---@field icon ReUI.UI.Controls.Bitmap
    ---@field data SelectedUnitsAction
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self SelectedUnitsListItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
            self.icon = ReUI.UI.Controls.Bitmap(item)
            item.Layouter(self.icon)
                :AtLeftBottomIn(item, 2, 2)
                :DisableHitTest()
                :Hide()
        end,

        ---Called when grid item receives an event
        ---@param self SelectedUnitsListItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                if event.Modifiers.Right then

                    if self.data.type == "item" then
                        local selection = GetSelectedUnits()
                        local id = self.data.id
                        local excludedUnits = EntityCategoryFilterDown(categories[id], self.data.group.units)
                        local units = {}
                        for _, unit in selection do
                            if not Contains(excludedUnits, unit) then
                                table.insert(units, unit)
                            end
                        end

                        SelectUnits(units)
                    elseif self.data.type == "group" then
                        local selection = GetSelectedUnits()
                        local excludedUnits = self.data.group.units
                        local units = {}
                        for _, unit in selection do
                            if not Contains(excludedUnits, unit) then
                                table.insert(units, unit)
                            end
                        end

                        SelectUnits(units)
                    end
                elseif event.Modifiers.Left then
                    if self.data.type == "item" then
                        local id = self.data.id
                        local units = EntityCategoryFilterDown(categories[id], self.data.group.units)
                        SelectUnits(units)
                    elseif self.data.type == "group" then
                        SelectUnits(self.data.group.units)
                    end
                end
                PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
            elseif event.Type == "MouseEnter" then
                if self.data.type == "item" then
                    local id = self.data.id
                    UnitViewDetail.Show(__blueprints[id], nil, id)
                end
            elseif event.Type == "MouseExit" then
                UnitViewDetail.Hide()
            end
        end,

        ---Called when item is activated with this component event handling
        ---@param self SelectedUnitsListItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action SelectedUnitsAction
        Enable = function(self, item, action)
            self.data = action
            if action.type == "item" then
                local id = action.id
                item:DisplayBPID(id)
                item.Text = self.data.group.idsCount[id]
                self.data.group.matcher:Display(self, item, action)
            elseif action.type == "group" then
                item.TextSize = 8
                item.Text = action.group.matcher.name
                self.icon:SetTexture(UIUtil.UIFile(action.group.matcher.icon))
                self.icon:Show()
            end
        end,

        ---Called when item is changing event handler
        ---@param self SelectedUnitsListItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            self.icon:Hide()
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self SelectedUnitsListItem
        Destroy = function(self)
            self.icon = nil
            self.data = nil
        end,
    },
}
