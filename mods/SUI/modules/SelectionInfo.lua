local Group = import("/lua/maui/group.lua").Group
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import('/lua/user/prefs.lua')
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = UMT.Layouter.ReusedLayoutFor

local GetEnhancements = import('/lua/enhancementcommon.lua').GetEnhancements


local VERTICAL_OFFSET = 10


SelectionInfo = Class(Bitmap) {
    __init = function(self, parent)
        Bitmap.__init(self, parent)
        local pos = self:_LoadPosition()

        LayoutFor(self)
            :Width(110)
            :Height(72)
            :Over(parent, 500)
            :Color('33000000')
            :AtLeftTopIn(parent, pos.left, VERTICAL_OFFSET)

        self._massCost = UIUtil.CreateText(self, "0", 14, UIUtil.bodyFont, true)
        self._massCost:SetColor("FFB8F400")
        LayoutHelpers.AtRightTopIn(self._massCost, self, 2, 2)
        self._massCost:DisableHitTest(true)


        self._energyCost = UIUtil.CreateText(self, "0", 14, UIUtil.bodyFont, true)
        self._energyCost:SetColor("FFF8C000")
        LayoutHelpers.AnchorToBottom(self._energyCost, self._massCost, 2)
        LayoutHelpers.AtRightIn(self._energyCost, self._massCost)
        self._energyCost:DisableHitTest(true)


        self._massRate = UIUtil.CreateText(self, "0", 14, UIUtil.bodyFont, true)
        self._massRate:SetColor("FFB8F400")
        LayoutHelpers.AtLeftTopIn(self._massRate, self, 2, 2)
        self._massRate:DisableHitTest(true)

        self._energyRate = UIUtil.CreateText(self, "0", 14, UIUtil.bodyFont, true)
        self._energyRate:SetColor("FFF8C000")
        LayoutHelpers.Below(self._energyRate, self._massRate, 2)
        self._energyRate:DisableHitTest(true)


        self._buildRate = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont, true)
        self._buildRate:SetColor("FFFFFF00")
        LayoutHelpers.Below(self._buildRate, self._energyRate, 2)
        self._buildRate:DisableHitTest(true)

        self._massKilled = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont, true)
        self._massKilled:SetColor("FFFF0000")
        LayoutHelpers.AnchorToBottom(self._massKilled, self._energyCost, 2)
        LayoutHelpers.AtRightIn(self._massKilled, self._energyCost)
        self._massKilled:DisableHitTest(true)

        self._siloCount = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont, true)
        LayoutFor(self._siloCount)
            :Below(self._buildRate, 2)
            :Color("ffffffff")
            :DisableHitTest()

    end,

    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' and event.Modifiers.Middle then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                GetCursor():SetTexture(UIUtil.GetCursor('W_E'))
            end
            drag.OnRelease = function(dragself)
                self:_SavePosition()
                GetCursor():Reset()
                drag:Destroy()
            end
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
            return true
        end
        return false
    end,

    Update = function(self, units)
        self._units = units or self._units
        if table.empty(self._units) then
            self:Hide()
            return
        end
        self:Show()
        local massRate = 0
        local energyRate = 0
        local massCost = 0
        local energyCost = 0
        local totalbr = 0
        local totalMassKilled = 0
        local totalSilo = 0
        local totalUnitsLoaded = 0

        for _, unit in self._units do
            if not unit:IsDead() then
                local econData = unit:GetEconData()
                local bp = unit:GetBlueprint()

                massRate = massRate - econData["massRequested"] + econData["massProduced"]
                energyRate = energyRate - econData["energyRequested"] + econData["energyProduced"]


                if unit:IsInCategory("COMMAND") or unit:IsInCategory('SUBCOMMANDER') then
                    totalbr = totalbr + unit:GetBuildRate()
                    local enhancements = GetEnhancements(unit:GetEntityId())
                    if enhancements then
                        for _, ench in enhancements do
                            if not bp.CategoriesHash[ench] then
                                local enhancementBp = bp.Enhancements[ench]
                                massCost = massCost + enhancementBp.BuildCostMass
                                energyCost = energyCost + enhancementBp.BuildCostEnergy
                            end
                        end
                    end
                elseif unit:IsInCategory("ENGINEER") or unit:IsInCategory("FACTORY") or unit:IsInCategory("SILO") then
                    totalbr = totalbr + bp.Economy.BuildRate
                end



                if not unit:IsInCategory("COMMAND") then
                    massCost = massCost + bp.Economy.BuildCostMass
                    energyCost = energyCost + bp.Economy.BuildCostEnergy
                end

                totalMassKilled = totalMassKilled + unit:GetStat('VetExperience', 0).Value

                local siloInfo = unit:GetMissileInfo()
                local s = siloInfo.nukeSiloStorageCount + siloInfo.tacticalSiloStorageCount
                if s > 0 then
                    totalSilo = totalSilo + s
                    totalUnitsLoaded = totalUnitsLoaded + 1
                end



            end
        end
        self._massCost:SetText(string.format("%d", massCost))
        self._energyCost:SetText(string.format("%d", energyCost))

        if massRate < 0 then
            self._massRate:SetText(string.format("%d", massRate))
            self._massRate:SetColor("fff30017")
        else
            self._massRate:SetText(string.format("+%d", massRate))
            self._massRate:SetColor("FFB8F400")
        end

        if energyRate < 0 then
            self._energyRate:SetText(string.format("%d", energyRate))
            self._energyRate:SetColor("fff30017")
        else
            self._energyRate:SetText(string.format("+%d", energyRate))
            self._energyRate:SetColor("FFF8C000")
        end


        if totalbr ~= 0 then
            self._buildRate:SetText(string.format("%d", totalbr))

        else
            self._buildRate:Hide()
        end

        if totalMassKilled ~= 0 then
            self._massKilled:SetText(string.format("%d", totalMassKilled))
        else
            self._massKilled:Hide()
        end

        if totalSilo ~= 0 then
            self._siloCount:SetText(string.format("%d / %d", totalSilo, totalUnitsLoaded))
        else
            self._siloCount:Hide()
        end

    end,

    _LoadPosition = function(self)
        return Prefs.GetFromCurrentProfile('SUIpos') or {
            left = 500,
        }
    end,

    _SavePosition = function(self)
        Prefs.SetToCurrentProfile("SUIpos", {
            left = self.Left(),
        })
    end

}
