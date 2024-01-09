local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")
local AddBeatFunction = import("/lua/ui/game/gamemain.lua").AddBeatFunction
local LazyVar = import("/lua/lazyvar.lua").Create


local GetUnits = UMT.Units.GetFast
local Options = UMT.Options.Mods["IEL"]
local LayoutFor = UMT.Layouter.ReusedLayoutFor

local engineersOverlay
local engineersOverlayWithNumbers
local factoryOverlayWithText
local factoriesOverlay
local commanderOverlay
local supportCommanderOverlay
local tacticalNukesOverlay
local massExtractorsOverlay

local function InitOptions()
    Options.engineersOption:Bind(function(var)
        engineersOverlay = var()
    end)
    Options.commanderOverlayOption:Bind(function(var)
        commanderOverlay = var()
    end)
    Options.engineersWithNumbersOption:Bind(function(var)
        engineersOverlayWithNumbers = var()
    end)
    Options.factoryOverlayWithTextOption:Bind(function(var)
        factoryOverlayWithText = var()
    end)
    Options.factoriesOption:Bind(function(var)
        factoriesOverlay = var()
    end)
    Options.supportCommanderOption:Bind(function(var)
        supportCommanderOverlay = var()
    end)
    Options.tacticalNukesOption:Bind(function(var)
        tacticalNukesOverlay = var()
    end)
    Options.massExtractorsOption:Bind(function(var)
        massExtractorsOverlay = var()
    end)
end

local overlays = UMT.Weak.Value {}

local Overlay = UMT.Views.UnitOverlay

local EngineerOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 1
        self.offsetY = 1
        self.isIdle = false
        if unit:IsInCategory("TECH1") then
            self:SetTexture("/mods/IEL/textures/t1_active_bold.dds", 0)
        elseif unit:IsInCategory("TECH2") then
            self:SetTexture("/mods/IEL/textures/t2_active_bold.dds", 0)
        elseif unit:IsInCategory("TECH3") then
            self:SetTexture("/mods/IEL/textures/t3_active_bold.dds", 0)
        end

        self.color = LazyVar()
        self.color.OnDirty = function(var)
            self:SetColorMask(var())
        end
        self.color:Set(Options.overlayColor:Raw())
    end,

    OnFrame = function(self, delta)
        if self.isIdle then
            self:Update()
        else
            self:Hide()
        end
    end,


    UpdateState = function(self)
        if self.unit:IsDead() or not engineersOverlay then
            self:Destroy()
            return
        end
        self.isIdle = self.unit:IsIdle()
    end

}

local EngineerOverlayWithNumber = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)

        local text = "0"
        if unit:IsInCategory("TECH1") then
            text = "1"
        elseif unit:IsInCategory("TECH2") then
            text = "2"
        elseif unit:IsInCategory("TECH3") then
            text = "3"
        end

        self.text = UIUtil.CreateText(self, text, 10, "Arial")
        LayoutFor(self.text)
            :AtCenterIn(self)
            :DisableHitTest()

        LayoutFor(self)
            :Color("ff000000")
            :Width(10)
            :Height(10)
    end,

    OnFrame = function(self, delta)
        self:Update()
    end,

    UpdateState = function(self)
        if self.unit:IsDead() or not engineersOverlay then
            self:Destroy()
            return
        end
        if self.unit:IsIdle() then
            self.text:SetColor("ffff0000")
        else
            self.text:SetColor("ffffffff")
        end
    end
}

local CommanderOverlayWithText = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)

        self.text = UIUtil.CreateText(self, "C", 10, "Arial")
        LayoutFor(self.text)
            :AtCenterIn(self)
            :DisableHitTest()

        LayoutFor(self)
            :Color("ff000000")
            :Width(10)
            :Height(10)
    end,

    OnFrame = function(self, delta)
        self:Update()
    end,

    UpdateState = function(self)
        if self.unit:IsDead() or not commanderOverlay then
            self:Destroy()
            return
        end
        if self.unit:IsIdle() then
            self.text:SetColor("ffff0000")
        else
            self.text:SetColor("ffffffff")
        end
    end
}

local FactoryOverlayWithText = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)

        self.offsetY = -2

        self.text = UIUtil.CreateText(self, "FAC", 10, "Arial")
        LayoutFor(self.text)
            :Color("ffffffff")
            :AtCenterIn(self)
            :DisableHitTest()

        LayoutFor(self)
            :Color("ff000000")
            :Width(20)
            :Height(10)
    end,

    OnFrame = function(self, delta)
        self:Update()
    end,

    UpdateState = function(self)
        if self.unit:IsDead() or not self.unit:IsIdle() or not factoriesOverlay then
            self:Destroy()
        end
    end
}

local FactoryOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 6
        self.offsetY = -9
        self.showState = false
        self:SetTexture {
            "/mods/IEL/textures/repeat.dds",
            "/mods/IEL/textures/idle_fac.dds",
            "/mods/IEL/textures/upgrading.dds",
            "/mods/IEL/textures/engi.dds"
        }
        LayoutHelpers.SetDimensions(self, 8, 8)
    end,

    OnFrame = function(self, delta)
        if self.showState then
            self:Update()
        else
            self:Hide()
        end
    end,

    UpdateState = function(self)
        if self.unit:IsDead() or not factoriesOverlay then
            self:Destroy()
            return
        end
        if self.unit:IsIdle() then
            self:SetFrame(1)
            self.showState = true
        elseif self.unit:IsRepeatQueue() and self.unit:GetFocus() and self.unit:GetFocus():IsInCategory("ENGINEER") then
            self:SetFrame(3)
            self.showState = true
        elseif self.unit:IsRepeatQueue() then
            self:SetFrame(0)
            self.showState = true
        elseif self.unit:GetFocus() and self.unit:GetFocus():IsInCategory("FACTORY") then
            self:SetFrame(2)
            self.showState = true
        else
            self.showState = false
        end
    end
}


local SiloOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 5
        self.offsetY = 1
        self.hasSilo = false
        self:SetTexture("/mods/IEL/textures/loaded.dds", 0)
        LayoutHelpers.SetDimensions(self, 12, 12)
    end,

    OnFrame = function(self, delta)
        if self.hasSilo then
            self:Update()
        else
            self:Hide()
        end
    end,

    UpdateState = function(self)
        if self.unit:IsDead() or not tacticalNukesOverlay then
            self:Destroy()
            return
        end
        local mi = self.unit:GetMissileInfo()
        self.hasSilo = (mi.nukeSiloStorageCount > 0) or (mi.tacticalSiloStorageCount > 0)
    end
}
local MexOverlay = Class(Overlay)
{
    __init = function(self, parent, unit)
        Overlay.__init(self, parent, unit)
        self.offsetX = 5
        self.offsetY = -7
        self.isUpgrading = false
        self:SetTexture("/mods/IEL/textures/up.dds", 0)
        LayoutHelpers.SetDimensions(self, 12, 16)
    end,

    OnFrame = function(self, delta)
        if self.isUpgrading then
            self:Update()
        else
            self:Hide()
        end
    end,

    UpdateState = function(self)
        if self.unit:IsDead() or not massExtractorsOverlay then
            self:Destroy()
            return
        end
        self.isUpgrading = self.unit:GetWorkProgress() > 0
    end
}

local function UpdateOverlays()
    for _, overlay in overlays do
        if IsDestroyed(overlay) then
            continue
        end
        overlay:UpdateState()
    end
end

local function CreateUnitOverlays()
    local allunits = GetUnits()
    local worldView = import("/lua/ui/game/worldview.lua").viewLeft
    for id, unit in allunits do
        if IsDestroyed(overlays[id]) and not unit:IsDead() then
            if supportCommanderOverlay and unit:IsInCategory("SUBCOMMANDER") then

            elseif unit:IsInCategory("COMMAND") then
                if commanderOverlay then
                    overlays[id] = CommanderOverlayWithText(worldView, unit)
                end
            elseif engineersOverlay and unit:IsInCategory("ENGINEER") then
                if engineersOverlayWithNumbers then
                    overlays[id] = EngineerOverlayWithNumber(worldView, unit)
                else
                    overlays[id] = EngineerOverlay(worldView, unit)
                end
            elseif factoriesOverlay and unit:IsInCategory("FACTORY") then
                if factoryOverlayWithText then
                    overlays[id] = FactoryOverlayWithText(worldView, unit)
                else
                    overlays[id] = FactoryOverlay(worldView, unit)
                end
            elseif tacticalNukesOverlay and unit:IsInCategory("SILO") then
                overlays[id] = SiloOverlay(worldView, unit)
            elseif massExtractorsOverlay and unit:IsInCategory("MASSEXTRACTION") and unit:IsInCategory("STRUCTURE") then
                overlays[id] = MexOverlay(worldView, unit)
            end
        end
    end

    UpdateOverlays()
end

function Main(isReplay)
    if isReplay and not Options.activeInReplays() then
        return
    end
    InitOptions()
    AddBeatFunction(CreateUnitOverlays, true)
end
