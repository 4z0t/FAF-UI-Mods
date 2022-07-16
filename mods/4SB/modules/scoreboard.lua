local Group = import('/lua/maui/group.lua').Group
local ArmyViews = import("Views/ArmyView.lua")
local Utils = import("Utils.lua")
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor = LayoutHelpers.ReusedLayoutFor
local TitlePanel = import("TitlePanel.lua").TitlePanel
local ObserverPanel = import("ObserverPanel.lua").ObserverPanel


ScoreBoard = Class(Group)
{
    __init = function(self, parent, isTitle)
        Group.__init(self, parent)

        if isTitle then
            self._title = TitlePanel(self)
            self._title:SetQuality(SessionGetScenarioInfo().Options.Quality)
        end
    end,

    __post_init = function(self)
        if self._title then
            LayoutFor(self._title)
                :AtRightTopIn(self)
        end
        self:_InitArmyViews()
        self:_Layout()
        LayoutFor(self)
            :Width(100)
            :Height(100)
            :Over(GetFrame(0), 1000)
            :AtRightTopIn(GetFrame(0), 0, 20)
            :DisableHitTest()
    end,

    _Layout = function(self)
        local last
        for i, armyView in self._lines do
            if i == 1 then
                if self._title then
                    LayoutFor(armyView)
                        :AnchorToBottom(self._title)
                        :Right(self.Right)
                else
                    LayoutFor(armyView)
                        :AtRightTopIn(self)
                end
            else
                LayoutFor(armyView)
                    :AnchorToBottom(self._lines[i - 1])
                    :Right(self.Right)
            end
            last = armyView
        end
        if last then
            self.Bottom:Set(last.Bottom)
        end
    end,

    _InitArmyViews = function(self)
        self._lines = {}
        self._armyViews = {}
        local armiesData = Utils.GetArmiesFormattedTable()

        -- sorting for better look
        table.sort(armiesData, function(a, b)
            if a.isAlly and b.isAlly then
                return a.id < b.id
            end
            if a.isAlly then
                return true
            end
            if b.isAlly then
                return false
            end
            if a.teamId ~= b.teamId then
                return a.teamId < b.teamId
            end
            return a.id < b.id
        end)


        local isObserver = IsObserver()
        for i, armyData in armiesData do
            local armyView
            if armyData.isAlly or isObserver then
                armyView = ArmyViews.AllyView(self)
            else
                armyView = ArmyViews.ArmyView(self)
            end
            armyView:SetStaticData(
                armyData.id,
                armyData.name,
                armyData.rating,
                armyData.faction,
                armyData.color,
                armyData.teamColor)

            self._lines[i] = armyView
            self._armyViews[armyData.id] = armyView
        end

    end,

    Update = function(self, data)
        if self._title then
            self._title:Update(data)
        end
        if data then
            for i, armyView in self._armyViews do
                armyView:Update(data[i])
            end
            -- for i, armyData in data do
            --     if self._armyViews[i] then
            --         self._armyViews[i]:Update(armyData.resources)
            --     end
            -- end
        end
    end,


    UpdateGameSpeed = function(self, gameSpeed)
        if self._title then
            self._title:Update(false, gameSpeed)
        end
    end

}

ReplayScoreBoard = Class(ScoreBoard)
{
    __init = function(self, parent, isTitle)
        ScoreBoard.__init(self, parent, isTitle)

        self._obs = ObserverPanel(self)
    end,

    _InitArmyViews = function(self)
        self._lines = {}
        self._armyViews = {}
        local armiesData = Utils.GetArmiesFormattedTable()

        -- sorting for better look
        table.sort(armiesData, function(a, b)
            if a.teamId ~= b.teamId then
                return a.teamId < b.teamId
            end
            return a.id < b.id
        end)


        for i, armyData in armiesData do
            local armyView = ArmyViews.ReplayArmyView(self)

            armyView:SetStaticData(
                armyData.id,
                armyData.name,
                armyData.rating,
                armyData.faction,
                armyData.color,
                armyData.teamColor)

            self._lines[i] = armyView
            self._armyViews[armyData.id] = armyView
        end

    end,

    _Layout = function(self)
        ScoreBoard._Layout(self)
        LayoutFor(self._obs)
            :Right(self.Right)
            :Top(self.Bottom)
    end,

    UpdateGameSpeed = function(self, gameSpeed)
        ScoreBoard.UpdateGameSpeed(self, gameSpeed)
        self._obs:SetGameSpeed(gameSpeed)
    end

    -- Update = function(self, data)

    -- end
}
