local Group = import('/lua/maui/group.lua').Group
local ArmyViews = import("Views/ArmyView.lua")
local Utils = import("Utils.lua")
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local LayoutFor = LayoutHelpers.ReusedLayoutFor
local TitlePanel = import("TitlePanel.lua").TitlePanel
local ObserverPanel = import("ObserverPanel.lua").ObserverPanel
local DataPanel = import("ReplayDataPanel.lua").DataPanel
local ArmyViewsContainer = import("ArmyViewsContainer.lua").ArmyViewsContainer
local InfoPanel = import("InfoPanel.lua").InfoPanel


ScoreBoard = Class(Group)
{
    __init = function(self, parent, isTitle)
        Group.__init(self, parent)

        if isTitle then
            self._title = TitlePanel(self)
            self._title:SetQuality(SessionGetScenarioInfo().Options.Quality)
            self._info = InfoPanel(self)
            self._info:Setup()
        end
    end,

    __post_init = function(self)
        if self._title then
            LayoutFor(self._title)
                :AtRightTopIn(self)

            LayoutFor(self._info)
                :Right(self.Right)
                :AnchorToBottom(self._title)
        end
        self:_InitArmyViews()
        self:_Layout()
        LayoutFor(self)
            :Width(100)
            :Height(100)
            :Over(GetFrame(0), 1000)
            :AtRightTopIn(GetFrame(0), 0, 20)
            :DisableHitTest()

        self._mode = "income"
        self:SetNeedsFrameUpdate(true)
    end,

    _Layout = function(self)
        local last
        for i, armyView in self._lines do
            if i == 1 then
                if self._title then
                    LayoutFor(armyView)
                        :AnchorToBottom(self._info)
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
        self:UpdateArmiesData(data)
    end,
    UpdateArmiesData = function(self, data)
        if data then
            local mode = self._mode
            for i, armyView in self._armyViews do
                armyView:Update(data[i], mode)
            end
        end
    end,


    UpdateGameSpeed = function(self, gameSpeed)
        if self._title then
            self._title:Update(false, gameSpeed)
        end
    end,

    OnFrame = function(self, delta)
        local isShift = IsKeyDown("shift")
        local isCtrl = IsKeyDown("control")
        local update = false
        if isShift and not isCtrl and self._mode ~= "storage" then
            self._mode = "storage"
            update = true
        elseif isCtrl and not isShift and self._mode ~= "maxstorage" then
            self._mode = "maxstorage"
            update = true
        elseif not isCtrl and not isShift and self._mode ~= "income" then
            self._mode = "income"
            update = true
        end

        if update then
            local data = import("/lua/ui/game/score.lua").GetScoreCache()
            self:UpdateArmiesData(data)
        end
    end

}

ReplayScoreBoard = Class(ScoreBoard)
{
    __init = function(self, parent, isTitle)
        ScoreBoard.__init(self, parent, isTitle)

        self._armiesContainer = ArmyViewsContainer(self)
        self._obs = ObserverPanel(self)
        self._dataPanel = DataPanel(self)
    end,


    __post_init = function(self)
        self:_Layout()
    end,

    _Layout = function(self)
        if self._title then
            LayoutFor(self._title)
                :AtRightTopIn(self)
            LayoutFor(self._info)
                :Right(self.Right)
                :AnchorToBottom(self._title)
            LayoutFor(self._armiesContainer)
                :AnchorToBottom(self._info)
                :Right(self.Right)
        else
            LayoutFor(self._armiesContainer)
                :Top(self.Top)
                :Right(self.Right)
        end


        LayoutFor(self._obs)
            :Right(self.Right)
            :Top(self._armiesContainer.Bottom)

        LayoutFor(self._dataPanel)
            :Right(self.Right)
            :Top(self._obs.Bottom)

        LayoutFor(self)
            :Width(100)
            :Bottom(self._dataPanel.Bottom)
            :Over(GetFrame(0), 1000)
            :AtRightTopIn(GetFrame(0), 0, 20)
            :DisableHitTest()
    end,

    UpdateGameSpeed = function(self, gameSpeed)
        ScoreBoard.UpdateGameSpeed(self, gameSpeed)
        self._obs:SetGameSpeed(gameSpeed)
    end,

    UpdateArmiesData = function(self, data)
        self._armiesContainer:Update(data)
    end,

    SortArmies = function(self, func, direction)
        self._armiesContainer:Sort(nil, func, direction)
    end,

    SetDataSetup = function(self, setup)
        self._armiesContainer:Setup(setup)
    end,

    Expand = function(self, id)
        self._armiesContainer:Expand(id)
    end,

    Contract = function(self, id)
        self._armiesContainer:Contract(id)
    end,




}
