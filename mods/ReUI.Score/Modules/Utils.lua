local MathAbs = math.abs
local StringFormat = string.format

local Text = ReUI.UI.Controls.Text

---Returns small faction icon file path
---@param factionIndex Faction
---@return FileName
function GetFactionIcon(factionIndex)
    return import('/lua/factions.lua').Factions[factionIndex + 1].LargeIcon
end

---Returns small faction icon file path
---@param factionIndex Faction
---@return FileName
function GetWhiteFactionIcon(factionIndex)
    local icons = {
        "/mods/ReUI.Score/Icons/uef_ico.dds",
        "/mods/ReUI.Score/Icons/aeon_ico.dds",
        "/mods/ReUI.Score/Icons/cybran_ico.dds",
        "/mods/ReUI.Score/Icons/seraphim_ico.dds",
    }
    return icons[factionIndex + 1]
end

---@param name string
---@return string
function ShortAIName(name)
    return (string.gsub(name, '^(%S+) %((AI[Xx]?): .+%)$', '%1 (%2)'))
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


local armiesFormattedTable

---Drops the cached army data so the next GetArmiesFormattedTable call rebuilds it
---with the current alliances (teams can change mid-game).
function ResetArmiesFormattedTable()
    armiesFormattedTable = nil
end

---@type integer[]
local scoreArmyIds

---Ids of all armies shown in the scoreboard. These never change during a game.
---@return integer[]
local function GetScoreArmyIds()
    if not scoreArmyIds then
        scoreArmyIds = ReUI.LINQ.Enumerate(GetArmiesFormattedTable())
            :Select "id"
            :ToArray()
        table.sort(scoreArmyIds)
    end
    return scoreArmyIds
end

---Returns a string describing the current alliance between every pair of armies shown in the scoreboard.
---It changes whenever two of them become allies or enemies mid-game
---(team swaps done by sim mods, unlocked teams diplomacy).
---@return string
function GetAllianceKey()
    local ids = GetScoreArmyIds()
    local n = table.getn(ids)
    local key = {}
    for i = 1, n - 1 do
        local a = ids[i]
        for j = i + 1, n do
            table.insert(key, IsAlly(a, ids[j]) and "1" or "0")
        end
    end
    return table.concat(key)
end

---returns army data
---@return ArmyData[]
function GetArmiesFormattedTable()
    if armiesFormattedTable then
        return armiesFormattedTable
    end

    armiesFormattedTable = {}

    local options = ReUI.Options.Mods["ReUI.Score"]
    local sessionInfo = SessionGetScenarioInfo()
    local focusArmy = GetFocusArmy()
    for armyIndex, armyData in GetArmiesTable().armiesTable do
        if not armyData.civilian and armyData.showScore then
            local nickname = armyData.nickname
            local clanTag  = sessionInfo.Options.ClanTags[nickname] or ""
            local name     = nickname
            if options.shortenAINickName() then
                name = ShortAIName(name)
            end
            if clanTag ~= "" then
                name = ("[%s] %s"):format(clanTag, nickname)
            end
            local data = {
                faction = armyData.faction,
                name = name,
                nickname = nickname,
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

    return armiesFormattedTable
end

---Formats number as large one
---@param n number | nil
---@return string
function FormatNumber(n)
    if n == nil then return "" end

    local an = MathAbs(n)
    if an < 1000 then
        return StringFormat("%01.0f", n)
    elseif an < 10000 then
        return StringFormat("%01.1fk", n / 1000)
    elseif an < 1000000 then
        return StringFormat("%01.0fk", n / 1000)
    else
        return StringFormat("%01.1fm", n / 1000000)
    end
end

---Formats number as ratio one
---@param n number | nil
---@return string
function FormatRatioNumber(n)
    if n == nil then return "" end

    if MathAbs(n) < 10 then
        return StringFormat("%01.2f", n)
    end

    return FormatNumber(n)
end

---returns width of string with given font family and size
---@param str string
---@param font string
---@param size integer
---@return number
function TextWidth(parent, str, font, size)
    local dummy = Text(parent)
    dummy:Hide()
    dummy:SetFont(font, size)
    dummy:SetText(str)
    local width = dummy.Width()
    dummy:Destroy()
    return width
end
