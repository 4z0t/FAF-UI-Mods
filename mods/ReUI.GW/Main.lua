ReUI.Require
{
    "ReUI.Core >= 1.5.0",
    "ReUI.Options >= 1.0.0"
}

function Main(isReplay)

    local function IsGalacticWar()
        if not exists('/lua/ui/gw/ranks.lua') then
            return false
        end
        local ok, module = pcall(import, '/lua/ui/gw/ranks.lua')
        if not ok then
            return false
        end

        return true
    end

    if not IsGalacticWar() then
        return
    end

    local options = ReUI.Options.Mods["ReUI.GW"]

    local Score = ReUI.Exists "ReUI.Score < 1.3.0" --[[@as ReUI.Score?]]
    if Score then
        local Ranks = import("/lua/ui/gw/ranks.lua")
        local data = import("/mods/ReUI.Score/Modules/Utils.lua").GetArmiesFormattedTable()
        local sessionInfo = SessionGetScenarioInfo()
        local ranks = sessionInfo.Options.Ranks


        for _, army in ipairs(data) do
            local nickname = army.nickname
            local rank = ranks[nickname] or 1
            army.rating = rank
            local rankName = Ranks.GetRankName(army.faction, rank)
            if rankName and options.displayRankNames() then
                army.name = ("[%s] %s"):format(rankName, nickname)
            end
        end

    end

end
