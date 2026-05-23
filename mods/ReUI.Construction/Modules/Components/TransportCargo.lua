local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local UIUtil = import("/lua/ui/uiutil.lua")

local Enumerate = ReUI.LINQ.Enumerate
local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator
local ToSet = IPairsEnumerator:ToSet()

local function EqualSets(s1, s2)
    local c = 0
    for k in s1 do
        c = c + 1
        if s2[k] == nil then
            return false
        end
    end
    return c == table.getsize(s2)
end

---@class CargoData
---@field id string
---@field index integer

---@class TransportCargoContext
---@field mode "manual"|"auto"
---@field index integer
---@field units table<UserUnit, boolean>
---@field cargoUnits UserUnit[]
---@field lastEnabled integer
local TransportCargoContext = ReUI.Core.Class()
{
    ---@param self TransportCargoContext
    __init = function(self)
        self.units = {}
        self.mode = "manual"
        self.index = 1
    end,

    ---@param self TransportCargoContext
    ---@param cargo UserUnit[]
    CargoChanged = function(self, cargo)
        local n1 = self.cargoUnits == nil and 0 or table.getn(self.cargoUnits)
        local n2 = cargo == nil and 0 or table.getn(cargo)
        return n1 ~= n2 or self.cargoUnits and cargo and not EqualSets(ToSet(self.cargoUnits), ToSet(cargo))
    end,

    ---@param self TransportCargoContext
    ---@param cargo UserUnit[]
    SetCargo = function(self, cargo)

        local cargoChanged = self:CargoChanged(cargo)

        self.cargoUnits = cargo
        local firstToDrop = nil
        for i, unit in cargo do
            if unit:HasUnloadCommandQueuedUp() then
                self:AddUnit(unit)
            else
                firstToDrop = firstToDrop or i
            end
        end
        if cargoChanged then
            self.index = firstToDrop
        end


        -- ReUI.Construction.Misc.OnCommandIssuedEvent:AddByKey("TransportCargoContext",
        --     ---@param command UserCommand
        --     function(module, command)
        --         if command.CommandType == 'TransportUnloadSpecificUnits' and self.mode == "auto" then
        --             local unit = self.cargoUnits[self.index]
        --             if unit then
        --                 self:AddUnit(unit)
        --                 self.index = self.index + 1
        --             else
        --                 self.mode = "manual"
        --                 module.EndCommandMode(true)
        --                 PlaySound(Sound { Cue = 'UI_Menu_Error_01', Bank = 'Interface', })
        --             end
        --         end
        --     end)
    end,

    ---@param self TransportCargoContext
    AppendNextUnit = function(self)
        if self.index == nil then
            self.index = 1
        end
        local unit = self.cargoUnits[self.index]
        if unit then
            self:AddUnit(unit)
            self.index = self.index + 1
            PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
        else
            PlaySound(Sound { Cue = 'UI_Menu_Error_01', Bank = 'Interface', })
        end
    end,

    ---@param self TransportCargoContext
    StartAutoMode = function(self)
        self.index = 1
        local unit = self.cargoUnits[self.index]
        if unit then
            self.mode = "auto"
            self:AddUnit(unit)
            self.index = self.index + 1
        else
            self.mode = "manual"
        end
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
    IsActive = function(self)
        return self.cargoUnits ~= nil
    end,

    ---@param self TransportCargoContext
    Clear = function(self)
        -- This check is done to prevent us from breaking other handlers' SessionExtraSelectList
        if self.cargoUnits == nil then
            return
        end

        -- ReUI.Construction.Misc.OnCommandIssuedEvent:RemoveByKey("TransportCargoContext")
        self.index = 1
        self.mode = "manual"
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

    ---@param self TransportCargoHandler
    OnInit = function(self)
        self._context = TransportCargoContext()
    end,

    ---@param self TransportCargoHandler
    ---@return boolean
    AppendNextUnitForDrop = function(self)
        if not self._context:IsActive() then
            return false
        end

        self._context:AppendNextUnit()

        return true
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
        self._context:Clear()
        self._context = nil
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
                    if event.Modifiers.Left then

                        if event.Modifiers.Ctrl then
                            self.context:AddRange(self.data.index)
                            item:UpdatePanel()
                        else
                            self.context:ToggleUnit(self.data.index)
                            item:UpdatePanel()
                        end
                    elseif event.Modifiers.Right then
                        -- self.context:StartAutoMode()
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


--[[
   CreateUnitAtMouse('ual0105', 0,    0.85,   -0.37,  2.31069)
   CreateUnitAtMouse('ual0105', 0,   -0.34,    1.02,  0.21479)
   CreateUnitAtMouse('uaa0107', 0,   -0.15,   -0.17,  2.31285)
   CreateUnitAtMouse('ual0105', 0,   -0.92,    0.11, -1.85973)
   CreateUnitAtMouse('ual0105', 0,   -0.85,   -0.56, -1.86647)
   CreateUnitAtMouse('ual0105', 0,    0.60,   -0.84,  2.30749)
   CreateUnitAtMouse('ual0105', 0,    0.82,    0.80,  0.21269)

]]
