local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")
local worldView = import("/lua/ui/game/worldview.lua").viewLeft
local LazyVar = import("/lua/lazyvar.lua")

local overlays = {}

local Options = import("options.lua")

local showOverlay = Options.overlayOption()

local function Remove(id)
    overlays[id]:Destroy()
    overlays[id] = nil
end

function init()

    Options.overlayOption.OnChange = function (var)
        showOverlay = var()
    end

    
end

local function CreateOverlay(mex)
    local id = mex:GetEntityId()
    local overlay = Bitmap(worldView)
    overlay:Hide()
    overlay:DisableHitTest()
    overlay.id = mex:GetEntityId()
    overlay.mex = mex
    overlay.offsetX = 5
    overlay.offsetY = 6
    overlay:SetTexture("/mods/EUT/textures/upgrade.dds")
    LayoutHelpers.SetDimensions(overlay, 8, 8)
    overlay.PosX = LazyVar.Create()
    overlay.PosY = LazyVar.Create()
    overlay.Left:Set(function()
        return worldView.Left() + overlay.PosX() - overlay.Width() / 2 + overlay.offsetX
    end)
    overlay.Top:Set(function()
        return worldView.Top() + overlay.PosY() - overlay.Height() / 2 + overlay.offsetY
    end)
    overlay:SetNeedsFrameUpdate(true)
    overlay.Update = function(self)
        local pos = worldView:GetScreenPos(self.mex)
        if pos then
            self:Show()
            self.PosX:Set(pos.x)
            self.PosY:Set(pos.y)
        else
            self:Hide()
        end
    end

    overlay.OnFrame = function(self, delta)
        if not self.mex:IsDead() and showOverlay then
            if self.mex:GetWorkProgress() > 0 then
                self:Update()
            else
                self:Hide()
            end
        else
            Remove(self.id)
        end
    end

    return overlay

end

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
                overlays[mex:GetEntityId()] = CreateOverlay(mex)
            end
        end
    end
end
