local GetUnits = import("/mods/UMT/modules/units.lua").Get
local AddBeatFunction = import("/lua/ui/game/gamemain.lua").AddBeatFunction

local categoryMex = categories.MASSEXTRACTION * categories.STRUCTURE

local beerOpen = 4
local beerPour = 3

local sodaOpen = 3
local sodaPour = 4

local function PlayOpenSound()
    if math.random(1, 2) == 1 then
        PlaySound(Sound { Bank = 'Beer', Cue = 'Soda_Open_' .. tostring(math.random(1, sodaOpen)) })
    else
        PlaySound(Sound { Bank = 'Beer', Cue = 'Beer_Open_' .. tostring(math.random(1, beerOpen)) })
    end
end

local function PlayPoursound()
    if math.random(1, 2) == 1 then
        PlaySound(Sound { Bank = 'Beer', Cue = 'Soda_Pour_' .. tostring(math.random(1, sodaPour)) })
    else
        PlaySound(Sound { Bank = 'Beer', Cue = 'Beer_Pour_' .. tostring(math.random(1, beerPour)) })
    end
end

local function Update()
    local mexes = GetUnits(categoryMex)

    for _, mex in mexes do
        mex.wasUpgraderBeer = mex.isUpgraderBeer
        mex.wasUpgradedBeer = mex.isUpgradedBeer

        mex.isUpgradedBeer = false
        mex.isUpgraderBeer = false
    end

    for _, mex in mexes do
        local f = mex:GetFocus()
        if f ~= nil and f:IsInCategory("STRUCTURE") then
            mex.isUpgraderBeer = true
            f.isUpgradedBeer   = true
            if f.wasUpgradedBeer == nil then
                --print("mex started upgrade")
                PlayOpenSound()
                f.wasUpgradedBeer = true
            end
        end
    end


    for _, mex in mexes do
        if mex.wasUpgradedBeer and not mex.isUpgradedBeer then
            --print("mex completed upgrade")
            PlayPoursound()
        end
    end
end

function Main(isReplay)
    AddBeatFunction(Update, true)
end
