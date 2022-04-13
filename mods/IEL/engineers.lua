local getUnits = import('/mods/common/units.lua').Get
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')

local AddBeatFunction = import('/lua/ui/game/gamemain.lua').AddBeatFunction
local worldView = import('/lua/ui/game/worldview.lua').viewLeft

local overlays = {}

local engineersOverlay = true
local factoriesOverlay = true
local supportCommanderOverlay = false
local tacticalNukesOverlay = true
local massExtractorsOverlay = true

function init(isReplay, parent)
    AddBeatFunction(CreateUnitOverlays, true)
end

function CreateUnitOverlayControl(unit)
    -- creates an empty overlay control for a unit
    local id = unit:GetEntityId()
    local overlay = Bitmap(worldView)
    overlay:Hide()
    overlay:DisableHitTest()
    overlay.id = unit:GetEntityId()
    overlay.unit = unit
    overlay.destroy = false
    overlay.offsetX = 0
    overlay.offsetY = 0
    overlay:SetNeedsFrameUpdate(true)
    overlay.Update = function(self)
        local pos = worldView:Project(self.unit:GetPosition())
        LayoutHelpers.AtLeftTopIn(self, worldView, pos.x - self.Width() / 2 + 1 + self.offsetX,
            pos.y - self.Height() / 2 + 1 + self.offsetY)
    end
    return overlay
end

-- function (self, delta)

-- end
-- Engineers
function CreateEngineerOverlay(unit)
    local id = unit:GetEntityId()
    overlays[id] = CreateUnitOverlayControl(unit)
    local overlay = overlays[id]
    if (unit:IsInCategory("TECH1")) then
        overlay:SetTexture('/mods/IEL/textures/t1_idle_bold.dds', 0)
    elseif (unit:IsInCategory("TECH2")) then
        overlay:SetTexture('/mods/IEL/textures/t2_idle_bold.dds', 0)
    elseif (unit:IsInCategory("TECH3")) then
        overlay:SetTexture('/mods/IEL/textures/t3_idle_bold.dds', 0)
    end
    overlay.OnFrame = OnFrameEngineer
end

function OnFrameEngineer(self, delta)
    if (not self.unit:IsDead()) then
        if (self.unit:IsIdle()) then
            self:Show()
            self:Update()
        else
            self:Hide()
        end
    else
        self.destroy = true
        self:Hide()
    end
end

function CreateFactoryOverlay(unit)
    local id = unit:GetEntityId()
    overlays[id] = CreateUnitOverlayControl(unit)
    local overlay = overlays[id]

    overlay.offsetX = 5
    overlay.offsetY = -10
    overlay.idleTexture = 1
    overlay.repeatTexture = 2
    -- LayoutHelpers.SetDimensions(overlay,12,12)
    -- overlay.Width:Set(12)
    -- overlay.Height:Set(12)
    overlay:SetTexture({'/mods/IEL/textures/repeat.dds', '/mods/IEL/textures/idle_fac.dds',
                        '/mods/IEL/textures/upgrading.dds'})
    LayoutHelpers.SetDimensions(overlay, 8, 8)
    overlay.OnFrame = OnFrameFactory
end
function OnFrameFactory(self, delta)
    if (not self.unit:IsDead()) then
        if (self.unit:IsIdle()) then
            self:Show()
            self:SetFrame(1)
            -- LayoutHelpers.SetDimensions(self,8,8)
            self:Update()
        elseif (self.unit:IsRepeatQueue()) then
            self:Show()
            self:SetFrame(0)
            -- LayoutHelpers.SetDimensions(self,8,8)
            self:Update()
        elseif self.unit:GetFocus() and self.unit:GetFocus():IsInCategory("FACTORY") then
            self:Show()
            self:SetFrame(2)
            -- LayoutHelpers.SetDimensions(self,8,8)
            self:Update()
        else
            self:Hide()
        end
    else
        self.destroy = true
        self:Hide()
    end
end

function CreateSiloOverlay(unit)
    local id = unit:GetEntityId()
    overlays[id] = CreateUnitOverlayControl(unit)
    local overlay = overlays[id]

    overlay.offsetX = 4
    overlay.offsetY = 0
    -- LayoutHelpers.SetDimensions(overlay,12,12)
    -- overlay.Width:Set(12)
    -- overlay.Height:Set(12)
    overlay:SetTexture('/mods/IEL/textures/loaded.dds', 0)
    LayoutHelpers.SetDimensions(overlay, 12, 12)
    overlay.OnFrame = OnFrameSilo
end

function OnFrameSilo(self, delta)
    if (not self.unit:IsDead()) then
        local mi = self.unit:GetMissileInfo()
        if (mi.nukeSiloStorageCount > 0) or (mi.tacticalSiloStorageCount > 0) then
            self:Show()
            self:Update()
        else
            self:Hide()
        end
    else
        self.destroy = true
        self:Hide()
    end
end

function CreateMexOverlay(unit)
    local id = unit:GetEntityId()
    overlays[id] = CreateUnitOverlayControl(unit)
    local overlay = overlays[id]

    overlay.offsetX = 4
    overlay.offsetY = -8
    overlay:SetTexture('/mods/IEL/textures/up.dds', 0)
    LayoutHelpers.SetDimensions(overlay, 12, 16)
    overlay.OnFrame = OnFrameMex
end

function OnFrameMex(self, delta)
    if (not self.unit:IsDead()) then
        if self.unit:GetWorkProgress() > 0 then
            self:Show()
            self:Update()
        else
            self:Hide()
        end
    else
        self.destroy = true
        self:Hide()
    end
end

function VerifyWV()
    if IsDestroyed(worldView) -- ~= import('/lua/ui/game/worldview.lua').viewLeft 
    then
        worldView = import('/lua/ui/game/worldview.lua').viewLeft
        overlays = {}
    end
end

function CreateUnitOverlays()
    local allunits = getUnits()
    VerifyWV()
    for _, unit in allunits do
        if (not unit:IsDead()) and not overlays[unit:GetEntityId()] then
            if engineersOverlay and unit:IsInCategory("ENGINEER") then
                CreateEngineerOverlay(unit)
            elseif factoriesOverlay and unit:IsInCategory("FACTORY") then
                CreateFactoryOverlay(unit)
            elseif supportCommanderOverlay and unit:IsInCategory("SUBCOMMANDER") then

            elseif tacticalNukesOverlay and unit:IsInCategory("SILO") then
                CreateSiloOverlay(unit)
            elseif massExtractorsOverlay and unit:IsInCategory("MASSEXTRACTION") and (unit:IsInCategory("STRUCTURE")) then
                CreateMexOverlay(unit)
            end
            -- elseif overlays[unit:GetEntityId()] and overlays[unit:GetEntityId()].destroy then
            --     overlays[unit:GetEntityId()]:Destroy()
            --     overlays[unit:GetEntityId()] = nil
        end
    end

    for id, overlay in overlays do
        if (not overlay or overlay.destroy) then
            overlay:Destroy()
            overlays[id] = nil
        end
    end
end

