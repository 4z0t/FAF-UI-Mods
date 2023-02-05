local Utils = import("Utils.lua")
local ArmyViewsContainer = import("ArmyViewsContainer.lua").ArmyViewsContainer
local ArmyViews = import("ArmyView.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor
local LuaQ = UMT.LuaQ


---@class TeamViewsContainer : ArmyViewsContainer
TeamViewsContainer = Class(ArmyViewsContainer)
{

    _InitArmyViews = function(self)

        self._armyViews = {}

        local armiesData = Utils.GetArmiesFormattedTable()

        local teams = armiesData | LuaQ.select "teamId" | LuaQ.toSet

        self._armyDataCache = armiesData
        if teams | LuaQ.count.keyvalue == armiesData | LuaQ.count then return end

        teams = teams | LuaQ.select.keyvalue(function(id)
            return {
                id = id,
                name = ("Team %d"):format(id),
                armies = armiesData
                    | LuaQ.where(function(armyData) return armyData.teamId == id end)
                    | LuaQ.select "id",
                color = (armiesData | LuaQ.first(function(armyData) return armyData.teamId == id end)).teamColor,
                rating = armiesData |
                    LuaQ.sum(function(armyData) return armyData.teamId == id and armyData.rating or 0 end)
            }
        end)

        for team, _ in teams do
            local teamView = ArmyViews.ReplayTeamView(self)
            table.insert(self._lines, teamView)
            self._armyViews[team] = teamView
        end
        self._teams = teams
        self:SetStaticData()
    end,

    SetStaticData = function(self)
        if not self._teams then return end

        for team, data in self._teams do
            local teamView = self._armyViews[team]
            teamView:SetStaticData(
                data.id,
                data.name,
                data.rating,
                data.color,
                data.armies
            )
        end
    end,

    Update = function(self, data)
        if not data then return end

        for i, armyView in self._armyViews do
            armyView:Update(data, self._dataSetup)
        end
    end,
}
