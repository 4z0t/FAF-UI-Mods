local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local UIUtil = import("/lua/ui/uiutil.lua")
local LazyVar = import("/lua/lazyvar.lua").Create

local Options = import("options.lua")

local worldView = import("/lua/ui/game/worldview.lua").viewLeft

local overlays = {}

local showOverlay = Options.overlayOption()
local useNumberOverlay = Options.useNumberOverlay()

local function Remove(id)
    overlays[id] = nil
end

function init()

    Options.overlayOption.OnChange = function(var)
        showOverlay = var()
    end

    Options.useNumberOverlay.OnChange = function(var)
        useNumberOverlay = var()
    end


end

local upgradeColor = "ff00ff00"
local idleColor = "ffffffff"

local Overlay = Class(Bitmap)
{
    __init = function(self, parent, unit)
        Bitmap.__init(self, parent)
        self:Hide()
        self:DisableHitTest()
        self.id = unit:GetEntityId()
        self.unit = unit
        self.offsetX = 0
        self.offsetY = 0
        self.PosX = LazyVar()
        self.PosY = LazyVar()
        self.Left:Set(function()
            return worldView.Left() + self.PosX() - self.Width() / 2 + self.offsetX
        end)
        self.Top:Set(function()
            return worldView.Top() + self.PosY() - self.Height() / 2 + self.offsetY
        end)
        self:SetNeedsFrameUpdate(true)
    end,


    Update = function(self)
        local pos = worldView:GetScreenPos(self.unit)
        if pos then
            self:Show()
            self.PosX:Set(pos.x)
            self.PosY:Set(pos.y)
        else
            self:Hide()
        end
    end,

    OnDestroy = function(self)
        Remove(self.id)
    end
}

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
        LayoutHelpers.SetDimensions(self, 10, 10)
        self:SetSolidColor("black")
        local text = "0"
        if unit:IsInCategory("TECH1") then
            text = "1"
        elseif unit:IsInCategory("TECH2") then
            text = "2"
        elseif unit:IsInCategory("TECH3") then
            text = "3"
        end
        self.text = UIUtil.CreateText(self, text, 10, UIUtil.bodyFont)
        LayoutHelpers.AtCenterIn(self.text, self)
    end,

    OnFrame = function(self, delta)
        if not self.unit:IsDead() and showOverlay then
            if self.unit.isUpgraded then
                self:Hide()
                return
            end
            if self.unit.isUpgrader then
                self.text:SetColor(upgradeColor)
            else
                self.text:SetColor(idleColor)
            end
            self:Update()
        else
            self:Destroy()
        end
    end


}

local function VerifyWV()
    if IsDestroyed(worldView)
    then
        worldView = import("/lua/ui/game/worldview.lua").viewLeft
        overlays = {}
    end
end

function UpdateOverlays(mexes)
    if showOverlay then
        VerifyWV()
        local id
        for _, mex in mexes do
            id = mex:GetEntityId()
            if not overlays[id] then
                if useNumberOverlay then
                    overlays[id] = NumberMexOverlay(worldView, mex)
                else
                    overlays[id] = MexOverlay(worldView, mex)
                end
            end
        end
    end
end
