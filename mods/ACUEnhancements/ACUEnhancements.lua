ReUI.Require
{
    "ReUI.LINQ >= 1.4.0",
    "ReUI.UI.Views.Grid >= 1.0.0",
    "ReUI.ActionsPanel >= 1.1.0",
    "ReUI.Units.Enhancements >= 1.1.0",
}

function Main(isReplay)
    local Enumerate = ReUI.LINQ.Enumerate
    local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator
    local PairsEnumerator = ReUI.LINQ.PairsEnumerator

    local TableInsert = table.insert

    local UIUtil = import("/lua/ui/uiutil.lua")
    local GetEnhancementTextures = import("/lua/ui/game/construction.lua").GetEnhancementTextures
    local GetEnhancementPrefix = import("/lua/ui/game/construction.lua").GetEnhancementPrefix
    local UnitViewDetail = import("/lua/ui/game/unitviewdetail.lua")

    local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler
    local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent

    local Enhancements = ReUI.Units.Enhancements
    local Button = import('/lua/maui/button.lua').Button

    ---@class EnhancementIconInfo
    ---@field bpID string
    ---@field name string

    ---@class ACUEnhancementsHandler : ASelectionHandler
    ---@field _cachedUpgrades table<string, table<string, EnhancementIconInfo>>
    local ACUEnhancementsHandler = Class(ASelectionHandler)
    {
        Name = "ACU Enhancements",
        Description = "Extension providing ACU enhancements",
        Enabled = true,

        ---@param self ACUEnhancementsHandler
        OnInit = function(self)
            self._cachedUpgrades = {}
        end,

        ---@param self ACUEnhancementsHandler
        OnDestroy = function(self)
            self._cachedUpgrades = nil
        end,

        ---@param self ACUEnhancementsHandler
        ---@param bpId string
        ---@param upgrade string
        GetCachedUpgrade = function(self, bpId, upgrade)
            local cached = self._cachedUpgrades
            local upgrades = cached[bpId]
            if not upgrades then
                upgrades = {}
                cached[bpId] = upgrades
            end
            local upgradeData = upgrades[upgrade]
            if not upgradeData then
                upgradeData = {
                    bpID = bpId,
                    name = upgrade,
                }
                upgrades[upgrade] = upgradeData
            end
            return upgradeData
        end,

        ---@param self ACUEnhancementsHandler
        ---@param unit UserUnit
        ---@return EnhancementIconInfo[]?
        GetAvailableUpgrades = function(self, unit)
            local bpID = unit:GetBlueprint().BlueprintId:lower()
            local chains = ReUI.Units.Enhancements.ResolveUpgradeChains(unit:GetBlueprint())

            if not chains then
                return
            end

            local upgrades = {}
            for _, chain in chains do
                for _, upgrade in chain do
                    if not Enhancements.HasPrerequisite(unit, upgrade) then
                        TableInsert(upgrades, self:GetCachedUpgrade(bpID, upgrade))
                        break
                    end
                end
            end
            return upgrades
        end,

        ---@param self ACUEnhancementsHandler
        ---@param bp UnitBlueprint
        ---@return EnhancementIconInfo[]?
        GetAvailableUpgradesForBP = function(self, bp)
            local chains = ReUI.Units.Enhancements.ResolveUpgradeChains(bp)
            local bpID = bp.BlueprintId:lower()

            if not chains then
                return
            end

            local upgrades = {}
            for _, chain in chains do
                for _, upgrade in chain do
                    TableInsert(upgrades, self:GetCachedUpgrade(bpID, upgrade))
                    break
                end
            end
            return upgrades
        end,

        ---@param self ACUEnhancementsHandler
        ---@param selection UserUnit[]
        ---@return EnhancementIconInfo[]?
        Update = function(self, selection)
            if table.empty(selection) then
                return
            end

            ---@type UnitBlueprint?
            local bp = Enumerate(selection)
                ---@param unit UserUnit
                :Select(function(unit) return unit:GetBlueprint() end)
                :Distinct()
                :Single()

            if not bp then
                return
            end

            if not EntityCategoryContains(categories.COMMAND + categories.SUBCOMMANDER, bp.BlueprintId) then
                return
            end

            if table.getn(selection) == 1 then
                ---@type UserUnit
                local unit = selection[1]
                local upgrades = self:GetAvailableUpgrades(unit)

                return upgrades
            else
                return self:GetAvailableUpgradesForBP(bp)
            end
        end,

        ---@class EnhComponent : AItemComponent
        ---@field btn Button
        ---@field bpID string
        ---@field name string
        ComponentClass = Class(AItemComponent)
        {
            ---Called when component is bond to an item
            ---@param self EnhComponent
            ---@param item ActionsGridItem
            Create = function(self, item)
                self.btn = Button(item)
                self.bpID = nil
                self.name = nil
                item.Layouter(self.btn)
                    :Fill(item)
                    :Disable()
                self.btn.mClickCue = "UI_MFD_Click"
                self.btn.mRolloverCue = "UI_MFD_Rollover"
                ---@param button Button
                ---@param modifiers EventModifiers
                self.btn.OnClick = function(button, modifiers)
                    local selection = GetSelectedUnits()
                    if table.getn(selection) == 1 then
                        local occupiedEnhName = Enhancements.IsOccupiedSlotFor(selection[1], self.name)
                        if occupiedEnhName then
                            UIUtil.QuickDialog(GetFrame(0)--[[@as Frame]] ,
                                ("Choosing this enhancement will destroy '%s' in this slot. Are you sure?"):format(LOC(occupiedEnhName))
                                ,
                                "<LOC _Yes>", function()
                                    safecall("Enhancements.OrderEnhancement",
                                        Enhancements.OrderEnhancement, self.name, modifiers.Shift)
                                    item:UpdatePanel()
                                end,
                                "<LOC _No>", function() end,
                                nil, nil,
                                true, { worldCover = true, enterButton = 1, escapeButton = 2 }
                            )
                            return
                        end
                    end
                    Enhancements.OrderEnhancement(self.name, modifiers.Shift)
                    item:UpdatePanel()
                end

                self.btn.OnRolloverEvent = function(btn, state)
                    if state == 'enter' or state == "down" then
                        local selection = GetSelectedUnits()
                        local enh       = __blueprints[self.bpID].Enhancements[self.name]
                        UnitViewDetail.ShowEnhancement(enh, self.bpID, enh.Icon,
                            GetEnhancementPrefix(self.bpID, enh.Icon),
                            selection[1])
                    else
                        UnitViewDetail.Hide()
                    end
                end
            end,

            ---Called when grid item receives an event
            ---@param self EnhComponent
            ---@param item ActionsGridItem
            ---@param event KeyEvent
            HandleEvent = function(self, item, event)
            end,

            ---Called when item is activated with this component event handling
            ---@param self EnhComponent
            ---@param item ActionsGridItem
            ---@param action EnhancementIconInfo
            Enable = function(self, item, action)
                self.btn:Enable()
                self.btn:Show()
                self.bpID = action.bpID
                self.name = action.name

                self.btn:SetNewTextures(GetEnhancementTextures(self.bpID,
                    __blueprints[self.bpID].Enhancements[self.name].Icon))
                if self.btn.mMouseOver then
                    self.btn:OnRolloverEvent("enter")
                end
                self.btn:ApplyTextures()
            end,

            ---Called when item is changing event handler
            ---@param self EnhComponent
            ---@param item ActionsGridItem
            Disable = function(self, item)
                self.btn:Disable()
                self.btn:Hide()
            end,

            ---Called when component is being destroyed
            ---@param self EnhComponent
            Destroy = function(self)
                self.btn:Destroy()
                self.btn = nil
            end,
        },
    }

    ReUI.ActionsPanel.AddExtension("ACUEnhancements", ACUEnhancementsHandler)
end
