local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

local Enumerate = ReUI.LINQ.Enumerate
local Enhancements = ReUI.Units.Enhancements

local GetEnhancementTextures = import("/lua/ui/game/construction.lua").GetEnhancementTextures
local GetEnhancementPrefix = import("/lua/ui/game/construction.lua").GetEnhancementPrefix
local UnitViewDetail = import("/lua/ui/game/unitviewdetail.lua")
local EnhanceCommon = import("/lua/enhancementcommon.lua")
local UIUtil = import('/lua/ui/uiutil.lua')

---@class EnhancementData
---@field type "arrow"|"split"|"item"
---@field state "installed"|"uninstalled"|"disabled"
---@field name string


---@class EnhancementContext
---@field bpID string
local EnhancementContext = ReUI.Core.Class()
{

}

---@class EnhancementsHandler : ASelectionHandler
---@field _context EnhancementContext
EnhancementsHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "Enhancements",

    ---@param self EnhancementsHandler
    ---@param grid ReUI.Construction.Grid
    OnInit = function(self, grid)
        self._context = EnhancementContext()
    end,

    ---@param self EnhancementsHandler
    ---@param context ConstructionContext
    ---@return string[]?
    ---@return EnhancementContext?
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

        local enhancementsForBP = ReUI.Units.Enhancements.ResolveUpgradeChains(bp)
        if not enhancementsForBP then
            return
        end


        local bpEnhancements = bp.Enhancements
        ---@cast bpEnhancements -nil

        self._context.bpID = bp.BlueprintId
        local slot = context.slot

        local enhancements = Enumerate(enhancementsForBP)
            :Where(function(chain)
                return Enumerate(chain)
                    :All(function(enhancement)
                        return bpEnhancements[enhancement].Slot == slot
                    end)
            end)
            ---@param chain string[]
            :SelectMany(function(chain)
                local data = {}
                for i, enhancement in chain do
                    data[i] = { type = "arrow", name = enhancement, state = "uninstalled" }
                end
                data[table.getn(data)].type = "split"
                return data
            end)
            -- :SelectMany()
            -- :Where(function(enhancement)
            --     return bpEnhancements[enhancement].Slot == slot
            -- end)
            :ToArray()

        if table.getn(selection) == 1 then
            local unit = selection[1]
            local installedEnhancements = EnhanceCommon.GetEnhancements(unit:GetEntityId())
            local hasAnyQueued = Enumerate(enhancements)
                :Any(function(enhancement)
                    return Enhancements.IsQueued(unit, enhancement.name)
                end)

            ---@param enhancement EnhancementData
            for i, enhancement in enhancements do
                if hasAnyQueued and not installedEnhancements[slot] then
                    enhancement.state = "disabled"
                elseif installedEnhancements[slot] == enhancement.name then
                    enhancement.state = "installed"
                end
            end
        end

        return enhancements, self._context
    end,

    ---@param self EnhancementsHandler
    OnDestroy = function(self)
        self._context = nil
    end,

    ---@class EnhancementItem : AItemComponent
    ---@field _arrow ReUI.UI.Controls.Bitmap
    ---@field data EnhancementData
    ---@field context EnhancementContext
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self EnhancementItem
        ---@param item ReUI.Construction.Grid.Item
        Create = function(self, item)
            self._arrow = ReUI.UI.Controls.Bitmap(item)
            item.Layouter(self._arrow)
                :AnchorToRight(item, -5)
                :AtVerticalCenterIn(item)
                :Over(item, 10)
                :DisableHitTest()
                :Hide()
        end,

        ---Called when grid item receives an event
        ---@param self EnhancementItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            local id = self.context.bpID
            local name = self.data.name
            local modifiers = event.Modifiers
            local selection = GetSelectedUnits()
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" and self.data.state == 'uninstalled' then
                if table.getn(selection) == 1 then
                    local occupiedEnhName = Enhancements.IsOccupiedSlotFor(selection[1], name)
                    if occupiedEnhName then
                        UIUtil.QuickDialog(GetFrame(0)--[[@as Frame]] ,
                            ("Choosing this enhancement will destroy '%s' in this slot. Are you sure?"):format(LOC(occupiedEnhName))
                            ,
                            "<LOC _Yes>", function()
                                safecall("Enhancements.OrderEnhancement", Enhancements.OrderEnhancement, name,
                                    modifiers.Shift)
                                item:UpdatePanel()
                            end,
                            "<LOC _No>", function() end,
                            nil, nil,
                            true, { worldCover = true, enterButton = 1, escapeButton = 2 }
                        )
                        return
                    end
                end
                Enhancements.OrderEnhancement(name, modifiers.Shift)
                item:UpdatePanel()
            elseif event.Type == "MouseEnter" then
                local enh = __blueprints[id].Enhancements[name]
                UnitViewDetail.ShowEnhancement(enh, id, enh.Icon, GetEnhancementPrefix(id, enh.Icon), selection[1])
                local up, down, over, _, sel = GetEnhancementTextures(id, enh.Icon)
                item.BackGround = over
            elseif event.Type == "MouseExit" then
                UnitViewDetail.Hide()
                local up, down, over, _, sel = GetEnhancementTextures(id, __blueprints[id].Enhancements[name].Icon)
                item.BackGround = up
            end
        end,

        ---Called when item is activated with this component event handling
        ---@param self EnhancementItem
        ---@param item ReUI.Construction.Grid.Item
        ---@param action EnhancementData
        ---@param context EnhancementContext
        Enable = function(self, item, action, context)
            self.data = action
            self.context = context
            local id = context.bpID
            local up, down, over, _, sel = GetEnhancementTextures(id, __blueprints[id].Enhancements[self.data.name].Icon)

            if action.state == "installed" then
                item.BackGround = sel
                item.Icon = nil
            elseif action.state == "uninstalled" then
                item.BackGround = up
                item.Icon = nil
            elseif action.state == "disabled" then
                item.BackGround = up
                item.IconColor = "aa000000"
            end

            self._arrow:Show()
            if action.type == "arrow" then
                self._arrow:Layouter()
                    :AnchorToRight(item, -2)
                    :Texture(UIUtil.UIFile('/game/c-q-e-panel/arrow_bmp.dds'))
            elseif action.type == "split" then
                self._arrow:Layouter()
                    :AnchorToRight(item, 5)
                    :Texture(UIUtil.UIFile('/game/c-q-e-panel/divider_bmp.dds'))
            end

            item.StrategicIcon = nil
            item.Text = nil
        end,

        ---Called when item is changing event handler
        ---@param self EnhancementItem
        ---@param item ReUI.Construction.Grid.Item
        Disable = function(self, item)
            self._arrow:Hide()
            item:ClearDisplay()
        end,

        ---Called when component is being destroyed
        ---@param self EnhancementItem
        Destroy = function(self)
            self._arrow:Destroy()
            self._arrow = nil
        end,
    },
}
