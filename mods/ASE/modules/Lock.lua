local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local LazyVar = import("/lua/lazyvar.lua").Create


local locked = setmetatable({}, { __mode = 'k' })
local overlays = setmetatable({}, { __mode = 'v' })
local isReplay

local Overlay = Class(Bitmap)
{
    __init = function(self, parent, unit)
        Bitmap.__init(self, parent)

        self:Hide()
        self:DisableHitTest()
        self.id = unit:GetEntityId()
        self.unit = unit
        self.view = parent
        self.offsetX = 5
        self.offsetY = 5
        self.PosX = LazyVar()
        self.PosY = LazyVar()
        self.Left:Set(function()
            return parent.Left() + self.PosX() - self.Width() / 2 + self.offsetX + 1
        end)
        self.Top:Set(function()
            return parent.Top() + self.PosY() - self.Height() / 2 + self.offsetY + 1
        end)
        self:SetTexture("/mods/ASE/textures/lock_icon.dds", 0)
        self:SetNeedsFrameUpdate(true)

    end,

    Update = function(self)
        local pos = self.view:GetScreenPos(self.unit)
        if pos then
            self:Show()
            self.PosX:Set(pos.x)
            self.PosY:Set(pos.y)
        else
            self:Hide()
        end
    end,

    OnFrame = function(self, delta)
        if not self.unit:IsDead() then
            self:Update()
        else
            self:Destroy()
        end
    end
}

function IsEmpty()
    return table.empty(locked)
end

function ContainsLocked(units)
    for _, unit in units do
        if locked[unit] ~= nil then
            return true
        end
    end
    return false
end

function IsLocked(unit)
    return locked[unit] ~= nil
end

local function Lock(unit)
    locked[unit] = true
    if IsDestroyed(overlays[unit]) then
        overlays[unit] = Overlay(import("/lua/ui/game/worldview.lua").viewLeft, unit)
    end
end

local function UnLock(unit)
    locked[unit] = nil
    if overlays[unit] then
        overlays[unit]:Destroy()
    end
end

local function Toggle(unit)
    if IsLocked(unit) then
        UnLock(unit)
        print "Unlocked"
    else
        Lock(unit)
        print "Locked"
    end
end

function ToggleUnits()
    if isReplay then return end
    local selection = GetSelectedUnits()
    if selection then
        for _, unit in selection do
            Toggle(unit)
        end
    end
end

function ToggleUnit()
    if isReplay then return end
    local selection = GetSelectedUnits()
    if selection and table.getn(selection) == 1 then
        Toggle(selection[1])
    end
end

function Main(_isReplay)
    isReplay = _isReplay
end
