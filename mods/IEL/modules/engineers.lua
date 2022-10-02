local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")
local AddBeatFunction = import("/lua/ui/game/gamemain.lua").AddBeatFunction
local LazyVar = import("/lua/lazyvar.lua")

local GetUnits = import("/mods/UMT/modules/units.lua").Get
local Options = import("options.lua")

local engineersOption = Options.engineersOption
local factoriesOption = Options.factoriesOption
local supportCommanderOption = Options.supportCommanderOption
local tacticalNukesOption = Options.tacticalNukesOption
local massExtractorsOption = Options.massExtractorsOption

local engineersOverlay = engineersOption()
local factoriesOverlay = factoriesOption()
local supportCommanderOverlay = supportCommanderOption()
local tacticalNukesOverlay = tacticalNukesOption()
local massExtractorsOverlay = massExtractorsOption()

local overlays = {}
local overlayGroup
local worldView

local function Remove(id)
    overlays[id]:Destroy()
    overlays[id] = nil
end

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
        self.PosX = LazyVar.Create()
        self.PosY = LazyVar.Create()
        self.Left:Set(function()
            return worldView.Left() + self.PosX() - self.Width() / 2 + self.offsetX + 1
        end)
        self.Top:Set(function()
            return worldView.Top() + self.PosY() - self.Height() / 2 + self.offsetY + 1
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
    end
}


local EngineerOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        if unit:IsInCategory("TECH1") then
            self:SetTexture("/mods/IEL/textures/t1_idle_bold.dds", 0)
        elseif unit:IsInCategory("TECH2") then
            self:SetTexture("/mods/IEL/textures/t2_idle_bold.dds", 0)
        elseif unit:IsInCategory("TECH3") then
            self:SetTexture("/mods/IEL/textures/t3_idle_bold.dds", 0)
        end
    end,

    OnFrame = function(self, delta)
        if not self.unit:IsDead() and engineersOverlay then
            if self.unit:IsIdle() then
                self:Update()
            else
                self:Hide()
            end
        else
            Remove(self.id)
        end
    end

}

local FactoryOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 5
        self.offsetY = -10
        self:SetTexture({
            "/mods/IEL/textures/repeat.dds",
            "/mods/IEL/textures/idle_fac.dds",
            "/mods/IEL/textures/upgrading.dds",
            "/mods/IEL/textures/engi.dds"
        })
        LayoutHelpers.SetDimensions(self, 8, 8)
    end,

    OnFrame = function(self, delta)
        if not self.unit:IsDead() and factoriesOverlay then
            if self.unit:IsIdle() then
                self:SetFrame(1)
                self:Update()
            elseif self.unit:IsRepeatQueue() and self.unit:GetFocus() and self.unit:GetFocus():IsInCategory("ENGINEER") then
                self:SetFrame(3)
                self:Update()
            elseif self.unit:IsRepeatQueue() then
                self:SetFrame(0)
                self:Update()
            elseif self.unit:GetFocus() and self.unit:GetFocus():IsInCategory("FACTORY") then
                self:SetFrame(2)
                self:Update()
            else
                self:Hide()
            end
        else
            Remove(self.id)
        end
    end

}
local SiloOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 4
        self.offsetY = 0
        self:SetTexture("/mods/IEL/textures/loaded.dds", 0)
        LayoutHelpers.SetDimensions(self, 12, 12)
    end,

    OnFrame = function(self, delta)
        if not self.unit:IsDead() and tacticalNukesOverlay then
            local mi = self.unit:GetMissileInfo()
            if (mi.nukeSiloStorageCount > 0) or (mi.tacticalSiloStorageCount > 0) then
                self:Update()
            else
                self:Hide()
            end
        else
            Remove(self.id)
        end
    end
}
local MexOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 4
        self.offsetY = -8
        self:SetTexture("/mods/IEL/textures/up.dds", 0)
        LayoutHelpers.SetDimensions(self, 12, 16)
    end,

    OnFrame = function(self, delta)
        if not self.unit:IsDead() and massExtractorsOverlay then
            if self.unit:GetWorkProgress() > 0 then
                self:Update()
            else
                self:Hide()
            end
        else
            Remove(self.id)
        end
    end
}


local function VerifyWV()
    if IsDestroyed(worldView) -- ~= import('/lua/ui/game/worldview.lua').viewLeft
    then
        worldView = import("/lua/ui/game/worldview.lua").viewLeft
        overlays = {}
    end
end

local function CreateUnitOverlays()
    local allunits = GetUnits()
    local id
    VerifyWV()
    for _, unit in allunits do
        id = unit:GetEntityId()
        if not overlays[id] then
            if supportCommanderOverlay and unit:IsInCategory("SUBCOMMANDER") then

            elseif engineersOverlay and unit:IsInCategory("ENGINEER") then
                overlays[id] = EngineerOverlay(worldView, unit)
            elseif factoriesOverlay and unit:IsInCategory("FACTORY") then
                overlays[id] = FactoryOverlay(worldView, unit)
            elseif tacticalNukesOverlay and unit:IsInCategory("SILO") then
                overlays[id] = SiloOverlay(worldView, unit)
            elseif massExtractorsOverlay and unit:IsInCategory("MASSEXTRACTION") and unit:IsInCategory("STRUCTURE") then
                overlays[id] = MexOverlay(worldView, unit)
            end
        end
    end
end

function UpdateOverlays()

end

function initOverlayGroup()
    overlayGroup = Group(worldView)
    LayoutHelpers.FillParent(overlayGroup, worldView)
    -- overlayGroup.OnDestroy = function(self)
    --    ForkThread(initOverlayGroup)
    -- end
    -- prepare for updating overlays
end

function Init(isReplay)

    --initOverlayGroup()
    AddBeatFunction(CreateUnitOverlays, true)
    engineersOption.OnChange = function(self)
        engineersOverlay = self()
    end
    factoriesOption.OnChange = function(self)
        factoriesOverlay = self()
    end
    supportCommanderOption.OnChange = function(self)
        supportCommanderOverlay = self()
    end
    tacticalNukesOption.OnChange = function(self)
        tacticalNukesOverlay = self()
    end
    massExtractorsOption.OnChange = function(self)
        massExtractorsOverlay = self()
    end
end
