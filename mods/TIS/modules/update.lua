local AddBeatFunction = import('/lua/ui/game/gamemain.lua').AddBeatFunction
local Prefs = import('/lua/user/prefs.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')


local GetUnits = import("/mods/UMT/modules/units.lua").Get

local Exp = import('exp.lua')
local Nuke = import('nuke.lua')
local Smd = import('smd.lua')
local Data = import('data.lua')



function AtCenterInOffset(control, parent)
    control.Left:Set(function()
        return math.floor(parent.Left() +
            (((parent.Width() / 2) - (control.Width() / 2)) +
                LayoutHelpers.ScaleNumber(control.offsetX())))
    end)
    control.Top:Set(function()
        return math.floor(parent.Top() +
            (((parent.Height() / 2) - (control.Height() / 2)) +
                LayoutHelpers.ScaleNumber(control.offsetY())))
    end)
end


local listeners = {}
local function UpdateUnitsListeners()
    local units =GetUnits()
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
    AddBeatFunction(UpdateUnitsListeners, true)
end
