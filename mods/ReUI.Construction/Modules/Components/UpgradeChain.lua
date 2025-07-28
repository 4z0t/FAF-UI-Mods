local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local Enumerate = ReUI.LINQ.Enumerate

local GetEnhancementTextures = import("/lua/ui/game/construction.lua").GetEnhancementTextures
local UnitViewDetail = import("/lua/ui/game/unitviewdetail.lua")
local UIUtil = import('/lua/ui/uiutil.lua')

---@class UpgradeChainData
---@field type "arrow"|"split"|"item"
---@field id string


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

---@class UpgradeChainHandler : ASelectionHandler
UpgradeChainHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "UpgradeChain",

    ---@param self UpgradeChainHandler
    OnInit = function(self)
    end,

    ---@param self UpgradeChainHandler
    ---@param context ConstructionContext
    ---@return string[]?
    Update = function(self, context)
        local selection = context.selection
        if table.empty(selection) then
            return
        end
        ---@cast selection -nil

        ---@type UnitBlueprint?
        local bp = Enumerate(selection)
            ---@param unit UserUnit
            :Select(function(unit)
                return unit:GetBlueprint()
            end)
            :Distinct()
            :Single()

        if not bp then
            return
        end

        local isStructure = EntityCategoryContains(categories.STRUCTURE -
            (categories.FACTORY + categories.EXTERNALFACTORY), bp.BlueprintId)

        if not isStructure then
            return
        end

        local commandQueue
        if table.getn(selection) == 1 then
            commandQueue = SetCurrentFactoryForQueueDisplay(selection[1])
        end

        local inQueue = {}
        if commandQueue then
            ---@param v UIBuildQueueItem
            for _, v in commandQueue do
                inQueue[v.id] = true
            end
        end

        local buildableUnits = { {
            id = commandQueue and commandQueue[table.getn(commandQueue)].id or bp.BlueprintId,
            type = "arrow"
        } }
        local bpid = bp.General.UpgradesTo
        if bpid then
            while bpid and bpid ~= '' do
                if not inQueue[bpid] then
                    table.insert(buildableUnits, {
                        id = bpid,
                        type = "arrow"
                    })
                end
                bpid = __blueprints[bpid].General.UpgradesTo
            end
        end
        if table.getn(buildableUnits) > 1 then
            buildableUnits[table.getn(buildableUnits)].type = "none"
            return buildableUnits
        end

        --TODO what to display when queue leads to final upgrade?
        return
    end,

    ---@param self UpgradeChainHandler
    OnDestroy = function(self)
    end,

    ---@class UpgradeChainItem : AItemComponent
    ---@field _arrow ReUI.UI.Controls.Bitmap
    ---@field data UpgradeChainData
    ---@field context ConstructionContext
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self UpgradeChainItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
            self._arrow = ReUI.UI.Controls.Bitmap(item)
            item.Layouter(self._arrow)
                :AnchorToRight(item, -2)
                :AtVerticalCenterIn(item)
                :Over(item, 10)
                :Texture(UIUtil.UIFile('/game/c-q-e-panel/arrow_bmp.dds'))
                :DisableHitTest()
                :Hide()
        end,

        ---Called when grid item receives an event
        ---@param self UpgradeChainItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                local selection = GetSelectedUnits()
                IssueUpgradeOrders(GetSelectedUnits(), self.data.id)
                SelectUnits(selection) -- This forces panel to update with new selection
            elseif event.Type == "MouseEnter" then
                local id = self.data.id
                UnitViewDetail.Show(__blueprints[id], self.context.selection[1], id)
            elseif event.Type == "MouseExit" then
                UnitViewDetail.Hide()
            end
        end,

        ---Called when item is activated with this component event handling
        ---@param self UpgradeChainItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action UpgradeChainData
        ---@param context ConstructionContext
        Enable = function(self, item, action, context)
            self.data = action
            self.context = context
            item:DisplayBPID(action.id, "rest")

            if action.type == "arrow" then
                self._arrow:Show()
            else
                self._arrow:Hide()
            end
            item.Text = nil
        end,

        ---Called when item is changing event handler
        ---@param self UpgradeChainItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            self._arrow:Hide()
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self UpgradeChainItem
        Destroy = function(self)
            self._arrow:Destroy()
            self._arrow = nil
        end,
    },
}
