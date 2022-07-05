local Group = import('/lua/maui/group.lua').Group
local ArmyViews = import("Views/ArmyView.lua")
local Utils = import("Utils.lua")
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor = LayoutHelpers.ReusedLayoutFor

ScoreBoard = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
    end,

    __post_init = function(self)
        self:_InitArmyViews()
        LayoutFor(self)
            :Width(100)
            :Height(100)
            :Over(GetFrame(0), 1000)
            :AtRightTopIn(GetFrame(0), 0, 20)
    end,

    _InitArmyViews = function(self)
        self._lines = {}
        local armiesData = Utils.GetArmiesFormattedTable()

        -- sorting for better look
        table.sort(armiesData, function(a, b)
            if a.teamId ~= b.teamId then
                return a.teamId < b.teamId
            end
            return a.id < b.id
            --return a.teamId * 16 + a.id > b.teamId * 16 + b.id
        end)


        for i, armyData in armiesData do
            local armyView = ArmyViews.ArmyView(self)
            armyView:SetStaticData(
                armyData.id,
                armyData.name,
                armyData.rating,
                armyData.faction,
                armyData.color,
                armyData.teamColor)
            if i == 1 then
                LayoutFor(armyView)
                    :AtRightTopIn(self)
            else
                LayoutFor(armyView)
                    :AnchorToBottom(self._lines[i - 1])
                    :Right(self.Right)
            end
            self._lines[i] = armyView
        end
    end,

    Update = function(self, data)

    end
}

ReplayScoreBoard = Class(ScoreBoard)
{
    __init = function(self, parent)
        ScoreBoard.__init(self, parent)
    end,

    Update = function(self, data)

    end
}
