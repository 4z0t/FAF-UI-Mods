local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local GetUnits = import("/mods/UMT/modules/units.lua").Get

local Exp = import('exp.lua')
local Nuke = import('nuke.lua')
local Smd = import('smd.lua')
local Data = import('data.lua')

local ScaleNumber = LayoutHelpers.ScaleNumber
local MathFloor = math.floor

function AtCenterInOffset(control, parent)
    control.Left:Set(function()
        return MathFloor(parent.Left() + (parent.Width() - control.Width()) * 0.5 + ScaleNumber(control.offsetX()))
    end)
    control.Top:Set(function()
        return MathFloor(parent.Top() + (parent.Height() - control.Height()) * 0.5 + ScaleNumber(control.offsetY()))
    end)
end

local listeners = {}
local function UpdateUnitsListeners()
    local units = GetUnits()
    for _, unit in units do
        if (not unit:IsDead()) then
            if not listeners[unit:GetEntityId()] then
                if unit:IsInCategory("EXPERIMENTAL") then
                    listeners[unit:GetEntityId()] = true
                    Exp.Add(unit)
                    -- elseif unit:IsInCategory("ANTIMISSILE") then
                    --     listeners[unit:GetEntityId()] = true
                    --     Smd.Add(unit)
                elseif unit:IsInCategory("SILO") and (unit:IsInCategory("NUKE") or unit:IsInCategory("ANTIMISSILE")) and
                    not unit:IsInCategory("NAVAL") then
                    listeners[unit:GetEntityId()] = true
                    Nuke.Add(unit)
                end
            end
            -- elseif listeners[unit:GetEntityId()] then
            --     listeners[unit:GetEntityId()] = nil
        end
    end
end

function Remove(id)
    listeners[id] = nil
end

function init(isReplay)
    -- Smd.init(isReplay)
    import('/lua/ui/game/gamemain.lua').AddBeatFunction(UpdateUnitsListeners, true)
end
