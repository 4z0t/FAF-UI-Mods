local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')


local Utils = import("Utils.lua")
local ArmyViewsContainer = import("ArmyViewsContainer.lua").ArmyViewsContainer
local ArmyViews = import("Views/ArmyView.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor
local LuaQ = UMT.LuaQ



TeamViewsContainer = Class(ArmyViewsContainer)
{

    _InitArmyViews = function(self)

        self._armyViews = {}

        local armiesData = Utils.GetArmiesFormattedTable()

        local teams = armiesData | LuaQ.select(function(armyData) return armyData.teamId end)
            | LuaQ.toSet
            | LuaQ.select.keyvalue(function(id)
                return armiesData
                    | LuaQ.where(function(armyData) return armyData.teamId == id end)
                    | LuaQ.select "id"
            end)

        for team, armies in teams do
            local teamView = ArmyViews.ReplayTeamView(self)
            local teamColor = (armiesData | LuaQ.first(function(armyData) return armyData.teamId == team end)).teamColor
            local rating = armiesData |
                LuaQ.sum(function(_, armyData) if armyData.teamId ~= team then return 0 end return armyData.rating end)

            teamView:SetStaticData(
                team,
                ("Team %d"):format(team),
                rating,
                teamColor,
                armies)

            self._lines[team] = teamView
            self._armyViews[team] = teamView
        end

        self._teams = teams
        self._armyDataCache = armiesData
    end,

    Update = function(self, data)
        if data then
            for i, armyView in self._armyViews do
                armyView:Update(data, self._dataSetup)
            end
        end
    end,
}
