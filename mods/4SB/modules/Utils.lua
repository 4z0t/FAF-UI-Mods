local MathAbs = math.abs

local Text = import("/lua/maui/text.lua").Text

local isReplay = import("/lua/ui/game/gamemain.lua").GetReplayState()
local sessionInfo = SessionGetScenarioInfo()

local armiesFormattedTable

---Returns small faction icon file path
---@param factionIndex Faction
---@return FileName
function GetSmallFactionIcon(factionIndex)
    return import('/lua/factions.lua').Factions[factionIndex + 1].SmallIcon
end

---@class ArmyData
---@field faction Faction
---@field name string
---@field nickname string
---@field color string
---@field isAlly boolean
---@field id integer
---@field rating number
---@field teamColor string
---@field teamId integer
---@field division string

---returns army data
---@return ArmyData[]
function GetArmiesFormattedTable()
    if not armiesFormattedTable then
        armiesFormattedTable = {}
        -- if isReplay then

        -- else
        local focusArmy = GetFocusArmy()
        for armyIndex, armyData in GetArmiesTable().armiesTable do
            if not armyData.civilian and armyData.showScore then
                local nickname = armyData.nickname
                local clanTag  = sessionInfo.Options.ClanTags[nickname] or ""
                local name     = nickname
                if clanTag ~= "" then
                    name = ("[%s] %s"):format(clanTag, nickname)
                end
                local data = {
                    faction = armyData.faction,
                    name = name,
                    nickname = armyData.nickname,
                    color = armyData.color,
                    isAlly = not IsObserver() and IsAlly(focusArmy, armyIndex),
                    id = armyIndex,
                    rating = sessionInfo.Options.Ratings[nickname] or 0,
                    division = sessionInfo.Options.Divisions[nickname] or ""
                }
                table.insert(armiesFormattedTable, data)
            end
        end

        local teams = {}
        for _, armyData in armiesFormattedTable do
            if table.empty(teams) then
                armyData.teamColor = armyData.color
                armyData.teamId = armyData.id
                table.insert(teams, { armyData })
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
                    table.insert(teams, { armyData })
                end
            end
        end
        --end
    end
    return armiesFormattedTable
end

---Formats number as large one
---@param n number | nil
---@return string
function FormatNumber(n)
    if n == nil then return "" end

    if MathAbs(n) < 1000 then
        return ("%01.0f"):format(n)
    elseif MathAbs(n) < 10000 then
        return ("%01.1fk"):format(n / 1000)
    elseif MathAbs(n) < 1000000 then
        return ("%01.0fk"):format(n / 1000)
    else
        return ("%01.1fm"):format(n / 1000000)
    end
end

---Formats number as ratio one
---@param n number | nil
---@return string
function FormatRatioNumber(n)
    if n == nil then return "" end

    if MathAbs(n) < 10 then
        return ("%01.2f"):format(n)
    end

    return FormatNumber(n)
end

---returns width of string with given font family and size
---@param str string
---@param font string
---@param size integer
---@return number
function TextWidth(str, font, size)
    local dummy = Text(GetFrame(0))
    dummy:Hide()
    dummy:SetFont(font, size)
    dummy:SetText(str)
    local width = dummy.Width()
    dummy:Destroy()
    return width
end
