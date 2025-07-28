local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local UIUtil = import("/lua/ui/uiutil.lua")

local Enumerate = ReUI.LINQ.Enumerate

---@class CarrierCargoData
---@field [1] string
---@field [2] UserUnit[]

---@class CarrierCargoContext
---@field bps table<string, boolean>
---@field cargoUnits table<string, UserUnit[]>
---@field lastEnabled integer
local CarrierCargoContext = ReUI.Core.Class()
{
    ---@param self CarrierCargoContext
    __init = function(self)
        self.bps = {}
    end,

    ---@param self CarrierCargoContext
    ---@param cargo table<string, UserUnit[]>
    SetCargo = function(self, cargo)
        self.cargoUnits = cargo
    end,

    ---@param self CarrierCargoContext
    ---@param bp string
    AddBP = function(self, bp)
        self.bps = self.bps or {}
        if self.bps[bp] then
            return
        end

        self.bps[bp] = true

        local units = self.cargoUnits[bp]

        for _, unit in units do
            AddToSessionExtraSelectList(unit)
        end
    end,

    ---@param self CarrierCargoContext
    ---@param bp string
    RemoveBP = function(self, bp)
        if not self.bps or not self.bps[bp] then
            return
        end

        self.bps[bp] = nil

        local units = self.cargoUnits[bp]

        for _, unit in units do
            RemoveFromSessionExtraSelectList(unit)
        end
    end,

    ---@param self CarrierCargoContext
    ---@param bp string
    ToggleUnit = function(self, bp)
        if self:Enabled(bp) then
            self:RemoveBP(bp)
            self.lastEnabled = nil
        else
            self:AddBP(bp)
            -- self.lastEnabled = index
        end
    end,

    ---@param self CarrierCargoContext
    ---@param index integer
    AddRange = function(self, index)
        local lastIndex = self.lastEnabled
        if not lastIndex then
            local unit = self.cargoUnits[index]
            self:AddBP(unit)
            self.lastEnabled = index
            return
        end

        local startI = math.min(index, lastIndex)
        local endI = math.max(index, lastIndex)
        for i = startI, endI do
            local unit = self.cargoUnits[i]
            self:AddBP(unit)
        end
        self.lastEnabled = nil
    end,

    ---@param self CarrierCargoContext
    ---@param id string
    ---@return boolean
    Enabled = function(self, id)
        if not self.bps then
            return false
        end
        return self.bps[id]
    end,

    ---@param self CarrierCargoContext
    Clear = function(self)
        -- This check is done to prevent us from breaking other handlers' SessionExtraSelectList
        if self.cargoUnits == nil then
            return
        end
        self.bps = nil
        self.cargoUnits = nil
        self.lastEnabled = nil
        ClearSessionExtraSelectList()
    end,
}

---@class CarrierCargoHandler : ASelectionHandler
---@field _context CarrierCargoContext
CarrierCargoHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "CarrierCargo",

    OnInit = function(self)
        self._context = CarrierCargoContext()
    end,

    ---@param self CarrierCargoHandler
    ---@param context ConstructionContext
    ---@return string[]?
    ---@return CarrierCargoContext?
    Update = function(self, context)
        local selection = context.selection
        if table.empty(selection) then
            self._context:Clear()
            return
        end
        ---@cast selection -nil

        local isAllAirStaging = table.empty(EntityCategoryFilterOut(categories.AIRSTAGINGPLATFORM, selection))
        if not isAllAirStaging then
            self._context:Clear()
            return
        end
        ---@cast selection -nil

        local attachedUnits = EntityCategoryFilterDown(categories.MOBILE, GetAttachedUnitsList(selection))

        if table.empty(attachedUnits) then
            self._context:Clear()
            return
        end

        local groupedUnits = Enumerate(attachedUnits)
            ---@param unit UserUnit
            :GroupBy(function(unit)
                return unit:GetBlueprint().BlueprintId
            end)
            :ToTable()

        local sortedUnits = Enumerate(groupedUnits, next)
            :Select(function(value, key)
                return { key, value }
            end)
            :OrderBy(function(value)
                return value[1]
            end)
            :ToArray()

        self._context:SetCargo(groupedUnits)

        return sortedUnits, self._context
    end,

    ---@param self CarrierCargoHandler
    OnDestroy = function(self)
    end,

    ---@class CarrierCargoItem : AItemComponent
    ---@field data CarrierCargoData
    ---@field context CarrierCargoContext
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self CarrierCargoItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
        end,

        ---Called when grid item receives an event
        ---@param self CarrierCargoItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then

                if self.context then
                    if event.Modifiers.Shift then
                        -- self.context:AddRange(self.data.index)
                        -- item:UpdatePanel()
                    else
                        self.context:ToggleUnit(self.data[1])
                        item:UpdatePanel()
                    end
                end

                PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
            end
        end,

        ---Called when item is activated with this component event handling
        ---@param self CarrierCargoItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action CarrierCargoData
        ---@param context CarrierCargoContext
        Enable = function(self, item, action, context)
            self.context = context
            self.data = action
            local id = self.data[1]

            local mode = "rest"

            if self.context and self.context:Enabled(self.data[1]) then
                mode = "down"
            end

            item:DisplayBPID(id, mode)
            item.Text = table.getn(self.data[2])
        end,

        ---Called when item is changing event handler
        ---@param self CarrierCargoItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self CarrierCargoItem
        Destroy = function(self)

        end,
    },
}
