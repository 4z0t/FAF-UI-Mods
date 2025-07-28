local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local UIUtil = import("/lua/ui/uiutil.lua")

local Enumerate = ReUI.LINQ.Enumerate

---@class SelectedUnitsData
---@field [1] string # bp ID
---@field [2] number # number of units

local sortOrder = {
    categories.SORTCONSTRUCTION,
    categories.STRUCTURE,
    categories.NAVAL,
    categories.AIR,
    categories.LAND,
    categories.LAND - categories.ENGINEER,
    categories.ENGINEER,
    categories.ALLUNITS,
}

local UnitViewDetail = import("/lua/ui/game/unitviewdetail.lua")

---@param bp string
---@return integer
local function FirstMatch(bp)
    for i, category in sortOrder do
        if EntityCategoryContains(category, bp) then
            return i
        end
    end
    return 10
end

local techCatOrder = {
    ["TECH1"] = 1,
    ["TECH2"] = 2,
    ["TECH3"] = 3,
    ["EXPERIMENTAL"] = 4,
}

---@class SelectedUnitsListHandler : ASelectionHandler
---@field _blueprintSortOrder table<string, integer>
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

    ---@param self SelectedUnitsListHandler
    ---@param context ConstructionContext
    ---@return string[]?
    Update = function(self, context)
        local selection = context.selection
        if table.empty(selection) then
            return
        end
        ---@cast selection -nil

        ---@type table<string, number>
        local bpIds = Enumerate(selection)
            :CountBy(function(unit)
                return unit:GetBlueprint().BlueprintId
            end)
            :ToTable()

        local sectionOrder = Enumerate(bpIds, next)
            :ToTable(function(bpId)
                return bpId, FirstMatch(bpId)
            end)

        local bpSortOrder = Enumerate(bpIds, next)
            :ToTable(function(bpId)
                local bp = __blueprints[bpId]
                return bpId, techCatOrder[bp.TechCategory] or 5
            end)

        ---@type SelectedUnitsData[]
        local bpIdToCount = Enumerate(bpIds, next)
            ---@param bpId string
            ---@param count number
            ---@return SelectedUnitsData
            :Select(function(count, bpId)
                return { bpId, count }
            end)
            :OrderByDescending(function(value) return value[1] end, function(bp1, bp2)
                local n1, n2 = sectionOrder[bp1], sectionOrder[bp2]
                if n1 ~= n2 then
                    return n1 < n2
                end

                n1, n2 = bpSortOrder[bp1], bpSortOrder[bp2]
                if n1 ~= n2 then
                    return n1 > n2
                end

                return bp1 < bp2

            end)
            :ToArray()

        return bpIdToCount
    end,

    ---@param self SelectedUnitsListHandler
    OnDestroy = function(self)
    end,

    ---@class SelectedUnitsListItem : AItemComponent
    ---@field data SelectedUnitsData
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self SelectedUnitsListItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
        end,

        ---Called when grid item receives an event
        ---@param self SelectedUnitsListItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                if event.Modifiers.Right then
                    local selection = GetSelectedUnits()
                    local units = EntityCategoryFilterOut(categories[self.data[1]:lower()], selection)
                    SelectUnits(units)
                elseif event.Modifiers.Left then
                    local selection = GetSelectedUnits()
                    local units = EntityCategoryFilterDown(categories[self.data[1]:lower()], selection)
                    SelectUnits(units)
                end
                PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
            elseif event.Type == "MouseEnter" then
                local id = self.data[1]
                UnitViewDetail.Show(__blueprints[id], nil, id)
            elseif event.Type == "MouseExit" then
                UnitViewDetail.Hide()
            end
        end,

        ---Called when item is activated with this component event handling
        ---@param self SelectedUnitsListItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action SelectedUnitsData
        Enable = function(self, item, action)
            self.data = action
            local id = self.data[1]
            item:DisplayBPID(id)
            item.Text = self.data[2]
        end,

        ---Called when item is changing event handler
        ---@param self SelectedUnitsListItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self SelectedUnitsListItem
        Destroy = function(self)

        end,
    },
}
