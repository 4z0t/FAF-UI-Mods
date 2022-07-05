local isReplay = import("/lua/ui/game/gamemain.lua").GetReplayState()
local sessionInfo = SessionGetScenarioInfo()

local armiesFormattedTable
local teams

function GetSmallFactionIcon(factionIndex)
    return import('/lua/factions.lua').Factions[factionIndex + 1].SmallIcon
end

function GetArmiesFormattedTable()
    if not armiesFormattedTable then
        armiesFormattedTable = {}
        if isReplay then

        else
            reprsl(sessionInfo)
            local focusArmy = GetFocusArmy()
            for armyIndex, armyData in GetArmiesTable().armiesTable do
                if not armyData.civilian and armyData.showScore then
                    local nickname = armyData.nickname
                    local clanTag  = sessionInfo.Options.ClanTags[nickname] or ""
                    local name     = nickname
                    if clanTag ~= "" then
                        name = string.format("[%s] %s", clanTag, nickname)
                    end 
                    local data = {
                        faction = armyData.faction,
                        name = name,
                        color = armyData.color,
                        isAlly = IsAlly(focusArmy, armyIndex),
                        id = armyIndex,
                        rating = sessionInfo.Options.Ratings[nickname] or 0
                    }
                    table.insert(armiesFormattedTable, data)
                end
            end

            teams = {}
            for _, armyData in armiesFormattedTable do
                if table.empty(teams) then
                    armyData.teamColor = armyData.color
                    armyData.teamId = armyData.id
                    table.insert(teams, {armyData})
                else
                    for _, team in teams do
                        if IsAlly(team[1].id, armyData.id) then
                            armyData.teamColor = team[1].teamColor
                            armyData.teamId = team[1].teamId
                            table.insert(team, armyData)
                            break
                        end
                    end
                    if not armyData.teamColor then
                        armyData.teamColor = armyData.color
                        armyData.teamId = armyData.id
                        table.insert(teams, {armyData})
                    end
                end
            end

            reprsl(teams)
            reprsl(armiesFormattedTable)
        end
    end
    return armiesFormattedTable
end


