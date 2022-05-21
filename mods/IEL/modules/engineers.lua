local getUnits = import('/mods/common/units.lua').Get
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local AddBeatFunction = import('/lua/ui/game/gamemain.lua').AddBeatFunction
local worldView = import('/lua/ui/game/worldview.lua').viewLeft

local GlobalOptions = import('/mods/UMT/modules/GlobalOptions.lua')
local OptionsUtils = import('/mods/UMT/modules/OptionsWindow.lua')
local LazyVar = import('/lua/lazyvar.lua')

local options = Prefs.GetFromCurrentProfile('IEL') or {
    engineersOverlay = 1,
    factoriesOverlay = 1,
    supportCommanderOverlay = 1,
    tacticalNukesOverlay = 1,
    massExtractorsOverlay = 1
}

local engineersOverlay = options['engineersOverlay'] or 1
local factoriesOverlay = options['factoriesOverlay'] or 1
local supportCommanderOverlay = options['supportCommanderOverlay'] or 1
local tacticalNukesOverlay = options['tacticalNukesOverlay'] or 1
local massExtractorsOverlay = options['massExtractorsOverlay'] or 1

local engineersOption = LazyVar.Create(engineersOverlay)
local factoriesOption = LazyVar.Create(factoriesOverlay)
local supportCommanderOption = LazyVar.Create(supportCommanderOverlay)
local tacticalNukesOption = LazyVar.Create(tacticalNukesOverlay)
local massExtractorsOption = LazyVar.Create(massExtractorsOverlay)

local overlays = {}
local overlayGroup 


function CreateUnitOverlayControl(unit)
    -- creates an empty overlay control for a unit
    local id = unit:GetEntityId()
    local overlay = Bitmap(worldView)
    overlay:Hide()
    overlay:DisableHitTest()
    overlay.id = unit:GetEntityId()
    overlay.unit = unit
    overlay.offsetX = 0
    overlay.offsetY = 0
    overlay.PosX = LazyVar.Create()
    overlay.PosY = LazyVar.Create()
    overlay.Left:Set(function()
        return worldView.Left() + overlay.PosX() - overlay.Width() / 2 + 1 + overlay.offsetX
    end)
    overlay.Top:Set(function()
        return worldView.Top() + overlay.PosY() - overlay.Height() / 2 + 1 + overlay.offsetY
    end)
    overlay:SetNeedsFrameUpdate(true)
    overlay.Update = function(self)
        local pos = worldView:GetScreenPos(self.unit)
        if pos then
            self:Show()
            self.PosX:Set(pos.x)
            self.PosY:Set(pos.y)
        else
            self:Hide()
        end
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
    if (not self.unit:IsDead()) and engineersOverlay ~= 0 then
        if (self.unit:IsIdle()) then
            self:Update()
        else
            self:Hide()
        end
    else
        Remove(self.id)
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
    if (not self.unit:IsDead()) and factoriesOverlay ~= 0 then
        if (self.unit:IsIdle()) then
            self:SetFrame(1)
            -- LayoutHelpers.SetDimensions(self,8,8)
            self:Update()
        elseif (self.unit:IsRepeatQueue()) then
            self:SetFrame(0)
            -- LayoutHelpers.SetDimensions(self,8,8)
            self:Update()
        elseif self.unit:GetFocus() and self.unit:GetFocus():IsInCategory("FACTORY") then
            self:SetFrame(2)
            -- LayoutHelpers.SetDimensions(self,8,8)
            self:Update()
        else
            self:Hide()
        end
    else
        Remove(self.id)
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
    if (not self.unit:IsDead()) and tacticalNukesOverlay ~= 0 then
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
    if (not self.unit:IsDead()) and massExtractorsOverlay ~= 0 then
        if self.unit:GetWorkProgress() > 0 then
            self:Update()
        else
            self:Hide()
        end
    else
        Remove(self.id)
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
            if engineersOverlay ~= 0 and unit:IsInCategory("ENGINEER") then
                CreateEngineerOverlay(unit)
            elseif factoriesOverlay ~= 0 and unit:IsInCategory("FACTORY") then
                CreateFactoryOverlay(unit)
            elseif supportCommanderOverlay ~= 0 and unit:IsInCategory("SUBCOMMANDER") then

            elseif tacticalNukesOverlay ~= 0 and unit:IsInCategory("SILO") then
                CreateSiloOverlay(unit)
            elseif massExtractorsOverlay ~= 0 and unit:IsInCategory("MASSEXTRACTION") and
                (unit:IsInCategory("STRUCTURE")) then
                CreateMexOverlay(unit)
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

function init(isReplay, parent)
    

    initOverlayGroup()
    AddBeatFunction(CreateUnitOverlays, true)
    engineersOption.OnDirty = function(self)
        engineersOverlay = self()
    end
    factoriesOption.OnDirty = function(self)
        factoriesOverlay = self()
    end
    supportCommanderOption.OnDirty = function(self)
        supportCommanderOverlay = self()
    end
    tacticalNukesOption.OnDirty = function(self)
        tacticalNukesOverlay = self()
    end
    massExtractorsOption.OnDirty = function(self)
        massExtractorsOverlay = self()
    end

    GlobalOptions.AddOptions('IEL', 'Idle Engineers Light',
        {OptionsUtils.Filter('Show engineers ovelays', 'engineersOverlay', engineersOption),
         OptionsUtils.Filter('Show factories ovelays', 'factoriesOverlay', factoriesOption),
         OptionsUtils.Filter('Show Nukes and TMLs ovelays', 'tacticalNukesOverlay', tacticalNukesOption),
         OptionsUtils.Filter('Show Mex ovelays', 'massExtractorsOverlay', massExtractorsOption)})

end

function Remove(id)
    overlays[id]:Destroy()
    overlays[id] = nil
end
