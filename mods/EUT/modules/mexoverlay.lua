local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local UIUtil = import("/lua/ui/uiutil.lua")
local LazyVar = import("/lua/lazyvar.lua").Create
local LayoutFor = UMT.Layouter.ReusedLayoutFor

local Options = import("options.lua")

---@type WorldView
local worldView = import("/lua/ui/game/worldview.lua").viewLeft

local overlays = UMT.Weak.Value {}

local showOverlay = Options.overlayOption()
local useNumberOverlay = Options.useNumberOverlay()

local overlaySize = Options.overlaySize:Raw()

function init()
    Options.overlayOption.OnChange = function(var)
        showOverlay = var()
    end

    Options.useNumberOverlay.OnChange = function(var)
        useNumberOverlay = var()
    end
end

local upgradeColor = "ff00ff00"
local idleCappedColor = "ffffffff"
local idleNotCappedColor = "FFE21313"

local progressColor = "3300ff00"

local Overlay = UMT.Views.UnitOverlay

local MexOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 5
        self.offsetY = 6
        self:SetTexture("/mods/EUT/textures/upgrade.dds")
        LayoutHelpers.SetDimensions(self, 8, 8)
    end,

    OnFrame = function(self, delta)
        if not self.unit:IsDead() and showOverlay then
            if self.unit:GetWorkProgress() > 0 then
                self:Update()
            else
                self:Hide()
            end
        else
            self:Destroy()
        end
    end


}

local NumberMexOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 0
        self.offsetY = 0


        local text = "0"
        if unit:IsInCategory("TECH1") then
            text = "1"
        elseif unit:IsInCategory("TECH2") then
            text = "2"
        elseif unit:IsInCategory("TECH3") then
            text = "3"
        end

        self.text = UIUtil.CreateText(self, text, 10, UIUtil.bodyFont)
        self.progress = Bitmap(self)

        LayoutFor(self)
            :Width(overlaySize)
            :Height(overlaySize)
            :Color("black")

        LayoutFor(self.text)
            :AtCenterIn(self)

        LayoutFor(self.progress)
            :Bottom(self.Bottom)
            :Left(self.Left)
            :Right(self.Right)
            :Height(0)
            :Color(progressColor)
    end,

    OnFrame = function(self, delta)
        local unit = self.unit
        if not unit:IsDead() and showOverlay then
            if unit.isUpgraded then
                self:Hide()
                return
            end
            if unit.isUpgrader then
                self.text:SetColor(upgradeColor)
            elseif unit.isCapped == nil or unit.isCapped then
                self.text:SetColor(idleCappedColor)
            else
                self.text:SetColor(idleNotCappedColor)
            end

            if unit.progress then
                self.progress.Height:Set(unit.progress * self.Height())
            end

            self:Update()
        else
            self:Destroy()
        end
    end


}

local function VerifyWV()
    if IsDestroyed(worldView) then
        worldView = import("/lua/ui/game/worldview.lua").viewLeft
    end
end

function UpdateOverlays(mexes)
    if not showOverlay then
        return
    end
    VerifyWV()
    for _, mex in mexes do
        local id = mex:GetEntityId()
        if IsDestroyed(overlays[id]) then
            if useNumberOverlay then
                overlays[id] = NumberMexOverlay(worldView, mex)
            else
                overlays[id] = MexOverlay(worldView, mex)
            end
        end
    end
end
