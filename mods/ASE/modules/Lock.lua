local locked = UMT.Weak.Key {}
local overlays = UMT.Weak.Value {}
local isReplay

local UOverlay = UMT.Views.UnitOverlay

---@class LockOverlay : UnitOverlay
local Overlay = Class(UOverlay)
{
    ---@param self LockOverlay
    ---@param parent WorldView
    ---@param unit UserUnit
    __init = function(self, parent, unit)
        UOverlay.__init(self, parent, unit)

        self.offsetX = 5
        self.offsetY = 5

        self:SetTexture("/mods/ASE/textures/lock_icon.dds", 0)
    end,

    ---@param self UnitOverlay
    GetUnitPosition = function(self)
        local view = self:GetParent()
        local pos = view:Project(self.unit:GetInterpolatedPosition())
        if view.Left() > pos.x or view.Right() < pos.x or view.Top() > pos.y or view.Bottom() < pos.y then
            return
        end
        return pos
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

local LuaQ = UMT.LuaQ
function ToggleUnits()
    if isReplay then return end
    local selection = GetSelectedUnits()
    if not selection then return end

    local allIsLocked = selection | LuaQ.all(function(_, unit) return IsLocked(unit) end)
    if allIsLocked then
        for _, unit in selection do
            UnLock(unit)
        end
        print "Unlocked"
    else
        for _, unit in selection do
            Lock(unit)
        end
        print "Locked"
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
