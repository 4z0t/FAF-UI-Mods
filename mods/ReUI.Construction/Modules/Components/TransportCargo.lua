local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local UIUtil = import("/lua/ui/uiutil.lua")

local Enumerate = ReUI.LINQ.Enumerate

---@class CargoData
---@field id string
---@field index integer

---@class TransportCargoContext
---@field units table<UserUnit, boolean>
---@field cargoUnits UserUnit[]
---@field lastEnabled integer
local TransportCargoContext = ReUI.Core.Class()
{
    ---@param self TransportCargoContext
    __init = function(self)
        self.units = {}
    end,

    ---@param self TransportCargoContext
    SetCargo = function(self, cargo)
        self.cargoUnits = cargo
    end,

    ---@param self TransportCargoContext
    ---@param unit UserUnit
    AddUnit = function(self, unit)
        self.units = self.units or {}
        if self.units[unit] then
            return
        end

        self.units[unit] = true
        AddToSessionExtraSelectList(unit)
    end,

    ---@param self TransportCargoContext
    ---@param unit UserUnit
    RemoveUnit = function(self, unit)
        if not self.units or not self.units[unit] then
            return
        end

        self.units[unit] = nil
        RemoveFromSessionExtraSelectList(unit)
    end,

    ---@param self TransportCargoContext
    ---@param index integer
    ToggleUnit = function(self, index)
        local unit = self.cargoUnits[index]
        if self:Enabled(index) then
            self:RemoveUnit(unit)
            self.lastEnabled = nil
        else
            self:AddUnit(unit)
            self.lastEnabled = index
        end
    end,

    ---@param self TransportCargoContext
    ---@param index integer
    AddRange = function(self, index)
        local lastIndex = self.lastEnabled
        if not lastIndex then
            local unit = self.cargoUnits[index]
            self:AddUnit(unit)
            self.lastEnabled = index
            return
        end

        local startI = math.min(index, lastIndex)
        local endI = math.max(index, lastIndex)
        for i = startI, endI do
            local unit = self.cargoUnits[i]
            self:AddUnit(unit)
        end
        self.lastEnabled = nil
    end,

    ---@param self TransportCargoContext
    ---@param index integer
    ---@return boolean
    Enabled = function(self, index)
        if not self.units then
            return false
        end
        local unit = self.cargoUnits[index]
        return self.units[unit] or false
    end,

    ---@param self TransportCargoContext
    Clear = function(self)
        -- This check is done to prevent us from breaking other handlers' SessionExtraSelectList
        if self.cargoUnits == nil then
            return
        end
        self.units = nil
        self.cargoUnits = nil
        self.lastEnabled = nil
        ClearSessionExtraSelectList()
    end,
}


---@class TransportCargoHandler : ASelectionHandler
---@field _context TransportCargoContext
TransportCargoHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "TransportCargo",

    OnInit = function(self)
        self._context = TransportCargoContext()
    end,

    ---@param self TransportCargoHandler
    ---@param context ConstructionContext
    ---@return string[]?
    ---@return TransportCargoContext?
    Update = function(self, context)
        local selection = context.selection
        local transportContext = self._context
        if table.empty(selection) then
            transportContext:Clear()
            return
        end
        ---@cast selection -nil

        if table.empty(EntityCategoryFilterDown(categories.TRANSPORTATION, selection)) then
            transportContext:Clear()
            return
        end
        ---@cast selection -nil

        local attachedUnits = EntityCategoryFilterDown(categories.MOBILE, GetAttachedUnitsList(selection))

        if table.empty(attachedUnits) then
            transportContext:Clear()
            return
        end

        transportContext:SetCargo(attachedUnits)

        return Enumerate(attachedUnits)
            ---@param unit UserUnit
            :Select(function(unit, i)
                return { id = unit:GetBlueprint().BlueprintId, index = i }
            end)
            :ToArray(), transportContext
    end,

    ---@param self TransportCargoHandler
    OnDestroy = function(self)
    end,

    ---@class TransportCargoItem : AItemComponent
    ---@field data CargoData
    ---@field context TransportCargoContext
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self TransportCargoItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
        end,

        ---Called when grid item receives an event
        ---@param self TransportCargoItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then

                if self.context then
                    if event.Modifiers.Shift then
                        self.context:AddRange(self.data.index)
                        item:UpdatePanel()
                    else
                        self.context:ToggleUnit(self.data.index)
                        item:UpdatePanel()
                    end
                end

                PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
            end
        end,

        ---Called when item is activated with this component event handling
        ---@param self TransportCargoItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action CargoData
        ---@param context TransportCargoContext
        Enable = function(self, item, action, context)
            self.context = context
            self.data = action
            local id = self.data.id

            local mode = "rest"

            if self.context and self.context:Enabled(self.data.index) then
                mode = "down"
            end

            item:DisplayBPID(id, mode)
            item.Text = nil
        end,

        ---Called when item is changing event handler
        ---@param self TransportCargoItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self TransportCargoItem
        Destroy = function(self)

        end,
    },
}
