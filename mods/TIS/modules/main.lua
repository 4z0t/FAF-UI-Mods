local AddBeatFunction = import('/lua/ui/game/gamemain.lua').AddBeatFunction
local UIUtil = import('/lua/ui/uiutil.lua')
local Exp = import('exp.lua')
local Nuke = import('nuke.lua')
local Smd = import('smd.lua')
local Data = import('data.lua')
local Prefs = import('/lua/user/prefs.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local LazyVar = import('/lua/lazyvar.lua')



local options = Prefs.GetFromCurrentProfile('TIS') or {
    expOverlay = 1,
    siloOverlay = 1,
    ['EHOffsetCountdown'] = 0,
    ['EVOffsetCountdown'] = -13,
    ['EHOffsetProgress'] = 0,
    ['EVOffsetProgress'] = 15,
    ['NHOffsetCountdown'] = 0,
    ['NVOffsetCountdown'] = -13,
    ['NHOffsetProgress'] = 0,
    ['NVOffsetProgress'] = 15,
    ['NHOffsetCount'] = 0,
    ['NVOffsetCount'] = 0
}

local expOptions = {
    overlay = LazyVar.Create(options.expOverlay or 1),
    eta = {
        offsetX = LazyVar.Create(options['EHOffsetCountdown'] or 0),
        offsetY = LazyVar.Create(options['EVOffsetCountdown'] or -13)
    },
    progress = {
        offsetX = LazyVar.Create(options['EHOffsetProgress'] or 0),
        offsetY = LazyVar.Create(options['EVOffsetProgress'] or 15)
    }
}

local siloOptions = {
    overlay = LazyVar.Create(options.siloOverlay or 1),
    eta = {
        offsetX = LazyVar.Create(options['NHOffsetCountdown'] or 0),
        offsetY = LazyVar.Create(options['NVOffsetCountdown'] or -13)
    },
    progress = {
        offsetX = LazyVar.Create(options['NHOffsetProgress'] or 0),
        offsetY = LazyVar.Create(options['NVOffsetProgress'] or 15)
    },
    count = {
        offsetX = LazyVar.Create(options['NHOffsetCount'] or 0),
        offsetY = LazyVar.Create(options['NVOffsetCount'] or 0)
    }
}

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

local Units
local listeners = {}
local function UpdateUnitsListeners()
    local units = Units.Get()
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
    if exists('/mods/UMT/mod_info.lua') and import('/mods/UMT/mod_info.lua').version >= 4 then
        local GlobalOptions = import('/mods/UMT/modules/GlobalOptions.lua')
        local OptionsUtils = import('/mods/UMT/modules/OptionsWindow.lua')

        if not isReplay then
        end
        Data.init(isReplay)
        Exp.init(isReplay, expOptions)
        Nuke.init(isReplay, siloOptions)
        Units = import('/mods/common/units.lua')
        GlobalOptions.AddOptions('TIS', 'TeamInfo Share',
            { OptionsUtils.Filter('Show exp ovelays', 'expOverlay', expOptions.overlay),
                OptionsUtils.Filter('Show nukes and smds ovelays', 'siloOverlay', siloOptions.overlay),
                OptionsUtils.Title('Nukes and smds', 18, nil, UIUtil.factionTextColor),
                OptionsUtils.Title('Countdown', 12),
                OptionsUtils.Slider('Vertical offset', 'NVOffsetCountdown', -20, 20, 1, siloOptions.eta.offsetY),
                OptionsUtils.Slider('Horizonal offset', 'NHOffsetCountdown', -20, 20, 1, siloOptions.eta.offsetX),
                OptionsUtils.Title('Progress', 12),
                OptionsUtils.Slider('Vertical offset', 'NVOffsetProgress', -20, 20, 1, siloOptions.progress.offsetY),
                OptionsUtils.Slider('Horizonal offset', 'NHOffsetProgress', -20, 20, 1, siloOptions.progress.offsetX),
                OptionsUtils.Title('Silo count', 12),
                OptionsUtils.Slider('Vertical offset', 'NVOffsetCount', -20, 20, 1, siloOptions.count.offsetY),
                OptionsUtils.Slider('Horizonal offset', 'NHOffsetCount', -20, 20, 1, siloOptions.count.offsetX),
                OptionsUtils.Title('EXPs', 18, nil, UIUtil.factionTextColor), OptionsUtils.Title('Countdown', 12),
                OptionsUtils.Slider('Vertical offset', 'EVOffsetCountdown', -20, 20, 1, expOptions.eta.offsetY),
                OptionsUtils.Slider('Horizonal offset', 'EHOffsetCountdown', -20, 20, 1, expOptions.eta.offsetX),
                OptionsUtils.Title('Progress', 12),
                OptionsUtils.Slider('Vertical offset', 'EVOffsetProgress', -20, 20, 1, expOptions.progress.offsetY),
                OptionsUtils.Slider('Horizonal offset', 'EHOffsetProgress', -20, 20, 1, expOptions.progress.offsetX) })
        -- Smd.init(isReplay)
        AddBeatFunction(UpdateUnitsListeners, true)
    else
        ForkThread(function()
            WaitSeconds(4)
            print("TeamInfo Share requires UI mod tools version 4 and higher!!!")
        end)
        return
    end
end
