local ISelectionHandler = import("/mods/AGP/modules/ISelectionHandler.lua").ISelectionHandler
local IItemComponent = import("/mods/AGP/modules/IItemComponent.lua").IItemComponent
local UIUtil = import("/lua/ui/uiutil.lua")

local GetEnhancementTextures = import("/lua/ui/game/construction.lua").GetEnhancementTextures
local Enhancements = import("Enhancements.lua")
local Button = import('/lua/maui/button.lua').Button

---@class EnhancementIconInfo
---@field bpID string
---@field name string

local bpIDtoUpgradeChains = {
    ["url0001"] = {
        { "CoolingUpgrade", },
        { "AdvancedEngineering", "T3Engineering", },
        { "StealthGenerator", "FAF_SelfRepairSystem", "CloakingGenerator", },
        { "ResourceAllocation" },
        { "NaniteTorpedoTube" },
        { "MicrowaveLaserGenerator", },
        { "Teleporter" },
    },
    ["uel0001"] = {
        { "HeavyAntiMatterCannon", },
        { "DamageStabilization" },
        { "AdvancedEngineering", "T3Engineering", },
        { "Shield", "ShieldGeneratorField", },
        { "ResourceAllocation" },
        { "TacticalMissile", "TacticalNukeMissile" },
        { "Teleporter" },
    },
    ["xsl0001"] = {
        { "RateOfFire", },
        { "AdvancedEngineering", "T3Engineering", },
        { "RegenAura", "AdvancedRegenAura" },
        { "DamageStabilization", "DamageStabilizationAdvanced", },
        { "Missile" },
        { "ResourceAllocation", "ResourceAllocationAdvanced" },
        { "BlastAttack" },
        { "Teleporter" },
    },
    ["ual0001"] = {
        { "HeatSink", },
        { "CrysalisBeam", "FAF_CrysalisBeamAdvanced" },
        { "AdvancedEngineering", "T3Engineering", },
        { "Shield", "ShieldHeavy", },
        { "EnhancedSensors" },
        { "ResourceAllocation", "ResourceAllocationAdvanced" },
        { "ChronoDampener" },
        { "Teleporter" },
    },
}

---@param unit  UserUnit
---@return string[]?
local function GetAvailableUpgrades(unit)
    local bpID = unit:GetBlueprint().BlueprintId:lower()
    local chains = bpIDtoUpgradeChains[bpID]

    if not chains then
        return
    end

    local upgrades = {}
    for _, chain in chains do
        for _, upgrade in chain do
            if not Enhancements.HasPrerequisite(unit, upgrade) then
                table.insert(upgrades, upgrade)
                break
            end
        end
    end
    return upgrades
end

---@class EnhancementsHandler : ISelectionHandler
EnhancementsHandler = Class(ISelectionHandler)
{
    Name = "ACU Enhancements",
    Description = "Extension providing ACU enhancements",
    Enabled = true,
    ---@param self ExampleHandler
    ---@param selection UserUnit[]
    ---@return EnhancementIconInfo[]?
    OnSelectionChanged = function(self, selection)
        if table.empty(selection) then
            return
        end
        if table.getn(selection) ~= 1 then
            return
        end
        if table.empty(EntityCategoryFilterDown(categories.COMMAND, selection)) then
            return
        end

        ---@type UserUnit
        local unit = selection[1]
        local bp = unit:GetBlueprint().BlueprintId
        local upgrades = GetAvailableUpgrades(unit)

        if not upgrades then return end

        return upgrades | UMT.LuaQ.select(function(upgrade)
            return {
                bpID = bp,
                name = upgrade,
            }
        end)
    end,

    ---@class EnhComponent : IItemComponent
    ---@field btn Button
    ---@field bpID string
    ---@field name string
    ComponentClass = Class(IItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self EnhComponent
        ---@param item Item
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
                local occupiedEnhName = Enhancements.IsOccupiedSlotFor(GetSelectedUnits()[1], self.name)
                if occupiedEnhName then
                    UIUtil.QuickDialog(GetFrame(0),
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
                Enhancements.OrderEnhancement(self.name, modifiers.Shift)
                item:UpdatePanel()
            end
        end,

        ---Called when grid item receives an event
        ---@param self EnhComponent
        ---@param item Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
        end,

        ---Called when item is activated with this component event handling
        ---@param self EnhComponent
        ---@param item Item
        Enable = function(self, item)
            self.btn:Enable()
            self.btn:Show()
        end,

        ---@param self EnhComponent
        ---@param action EnhancementIconInfo
        SetAction = function(self, action)
            self.bpID = action.bpID
            self.name = action.name
            self.btn:SetNewTextures(GetEnhancementTextures(self.bpID,
                __blueprints[self.bpID].Enhancements[self.name].Icon))
            self.btn:ApplyTextures()
        end,

        ---Called when item is changing event handler
        ---@param self EnhComponent
        ---@param item Item
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
