local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")
local LazyVar = import("/lua/lazyvar.lua")

local worldView = import("/lua/ui/game/worldview.lua").viewLeft

local overlays = {}

local Options = import("options.lua")

local showOverlay = Options.overlayOption()

local function Remove(id)
    overlays[id]:Destroy()
    overlays[id] = nil
end

function init()

    Options.overlayOption.OnChange = function(var)
        showOverlay = var()
    end


end

local MexOverlay = Class(Bitmap)
{
    __init = function(self, parent, unit)
        Bitmap.__init(self, parent)
        self:Hide()
        self:DisableHitTest()
        self.id = unit:GetEntityId()
        self.unit = unit
        self.offsetX = 5
        self.offsetY = 6
        self:SetTexture("/mods/EUT/textures/upgrade.dds")
        LayoutHelpers.SetDimensions(self, 8, 8)
        self.PosX = LazyVar.Create()
        self.PosY = LazyVar.Create()
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

    OnFrame = function(self, delta)
        if not self.unit:IsDead() and showOverlay then
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
    if IsDestroyed(worldView)
    then
        worldView = import("/lua/ui/game/worldview.lua").viewLeft
        overlays = {}
    end
end

function UpdateOverlays(mexes)
    if showOverlay then
        VerifyWV()
        for _, mex in mexes do
            if not overlays[mex:GetEntityId()] then
                overlays[mex:GetEntityId()] = MexOverlay(worldView, mex)
            end
        end
    end
end
