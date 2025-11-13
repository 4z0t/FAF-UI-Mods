ReUI.Require
{
    "ReUI.Core >= 1.5.0",
    "ReUI.Options >= 1.0.0"
}

function Main(isReplay)

    local function IsGalacticWar()
        if not exists('/lua/ui/ability_panel/abilities.lua') then
            return false
        end
        local ok, module = pcall(import, '/lua/ui/ability_panel/abilities.lua')
        if not ok then
            return false
        end

        return true
    end

    if not IsGalacticWar() then
        return
    end

    local Score = ReUI.Exists "ReUI.Score >= 1.2.0" --[[@as ReUI.Score?]]
    if Score then
        local rankNames = {
            [0] = { "Private", "Corporal", "Sergeant", "Captain", "Major", "Colonel", "General", "Supreme Commander" },
            [1] = { "Paladin", "Legate", "Priest", "Centurion", "Crusader", "Evaluator", "Avatar-of-War", "Champion" },
            [2] = { "Drone", "Node", "Ensign", "Agent", "Inspector", "Starshina", "Commandarm", "Elite Commander" },
            [3] = { "Su", "Sou", "Soth", "Ithem", "YthiIs", "Ythilsthe", "YthiThuum", "Suythel Cosethuum" },
        }

        local data = import("/mods/ReUI.Score/Modules/Utils.lua").GetArmiesFormattedTable()
        local sessionInfo = SessionGetScenarioInfo()
        local ranks = sessionInfo.Options.Ranks

        for _, army in ipairs(data) do
            local nickname = army.nickname
            local rank = ranks[nickname] or 1
            army.rating = rank
            local rankName = rankNames[army.faction][rank]
            if rankName then
                army.name = ("[%s] %s"):format(rankName, nickname)
            end
        end

    end

end
