local Group = UMT.Controls.Group
import("Views/__Init__.lua")
local Utils = import("Utils.lua")
local ArmyViews = import("ArmyView.lua")
local TitlePanel = import("TitlePanel.lua").TitlePanel
local ObserverPanel = import("ObserverPanel.lua").ObserverPanel
local DataPanel = import("ReplayDataPanel.lua").DataPanel
local ArmyViewsContainer = import("ArmyViewsContainer.lua").ArmyViewsContainer
local TeamViewsContainer = import("TeamViewsContainer.lua").TeamViewsContainer
local LazyVar = import('/lua/lazyvar.lua').Create

local Scores = UMT.LazyImport("/lua/ui/game/score.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor

local animationSpeed = 300

local slideForward = UMT.Animation.Factory.Base
    :OnStart()
    :OnFrame(function(control, delta)
        return control.Right() < control:GetParent().Right() or
            control.Right:Set(control.Right() - delta * control.Layouter:ScaleNumber(animationSpeed))
    end)
    :OnFinish(function(control)
        control.Right:Set(control:GetParent().Right)
    end)
    :Create()


---@class ScoreBoard : UMT.Group
---@field GameSpeed PropertyTable<ScoreBoard, integer>
---@field protected _armyViews table<integer, ArmyView>
---@field protected _title TitlePanel
---@field protected _mode "storage"| "maxstorage"| "income"
---@field protected _focusArmy integer
---@field protected _lines ArmyView[]
---@field protected isHovered boolean
ScoreBoard = UMT.Class(Group)
{
    ---@param self ScoreBoard
    ---@param parent Control
    ---@param isTitle boolean
    __init = function(self, parent, isTitle)
        Group.__init(self, parent)
        self.Layouter = UMT.Layouter.RoundLayouter(LazyVar(1))

        self._focusArmy = GetFocusArmy()
        self._title = false
        self.isHovered = false

        if isTitle then
            self._title = TitlePanel(self)
            self._title:SetQuality(SessionGetScenarioInfo().Options.Quality)
        end
        self:ResetWidthComponents()
        self:_InitArmyViews()
        self._mode = "income"
    end,

    ---@param self ScoreBoard
    ResetWidthComponents = function(self)
        ArmyViews.nameWidth:Set(self.Layouter:ScaleVar(75))
        ArmyViews.armyViewWidth:Set(self.Layouter:Sum(ArmyViews.nameWidth, 80))
        ArmyViews.allyViewWidth:Set(self.Layouter:Sum(ArmyViews.nameWidth, 160))
    end,

    ---@param self ScoreBoard
    ---@param layouter LayouterFunctor
    InitLayout = function(self, layouter)
        if self._title then
            layouter(self._title)
                :AtRightTopIn(self)
        end
        local last
        local first
        for i, armyView in self._lines do
            if i == 1 then
                if self._title then
                    layouter(armyView)
                        :AnchorToBottom(self._title)
                        :Right(self.Right)
                else
                    layouter(armyView)
                        :AtRightTopIn(self)
                end
                first = armyView
            else
                layouter(armyView)
                    :AnchorToBottom(self._lines[i - 1])
                    :Right(self.Right)
            end
            last = armyView
        end
        if last then
            self.Bottom:Set(last.Bottom)
        end
        layouter(self)
            :Width(100)
            :Over(GetFrame(0), 1000)
            :AtRightIn(GetFrame(0))
            :DisableHitTest()
            :NeedsFrameUpdate(true)
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
                armyData.teamColor,
                armyData.division
            )

            self._lines[i] = armyView
            self._armyViews[armyData.id] = armyView
        end

    end,

    ResetArmyData = function(self)
        ArmyViews.nameWidth:Set(self.Layouter:ScaleVar(75))
        for _, armyData in Utils.GetArmiesFormattedTable() do
            self:GetArmyViews()[armyData.id]:SetStaticData(
                armyData.id,
                armyData.name,
                armyData.rating,
                armyData.faction,
                armyData.color,
                armyData.teamColor,
                armyData.division
            )

        end
    end,

    ---comment
    ---@param self ScoreBoard
    ---@return table<integer, ArmyView>
    GetArmyViews = function(self)
        return self._armyViews
    end,

    ---comment
    ---@param self ScoreBoard
    ---@return TitlePanel
    GetTitlePanel = function(self)
        return self._title
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


    GameSpeed = UMT.Property
    {
        get = function(self)

        end,

        set = function(self, value)
            if self._title then
                self._title:Update(false, value)
            end
        end
    },

    ---comment
    ---@param self ScoreBoard
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            self.isHovered = false
        elseif event.Type == 'MouseEnter' then
            self.isHovered = true
        end
    end,

    ---comment
    ---@param self ScoreBoard
    ---@param delta number
    OnFrame = function(self, delta)
        local isCtrl = IsKeyDown("control")
        local update = false
        if not isCtrl and self.isHovered and self._mode ~= "storage" then
            self._mode = "storage"
            update = true
        elseif isCtrl and self._mode ~= "maxstorage" then
            self._mode = "maxstorage"
            update = true
        elseif not isCtrl and not self.isHovered and self._mode ~= "income" then
            self._mode = "income"
            update = true
        end

        if update then
            local data = Scores.GetScoreCache()
            self:UpdateArmiesData(data)
        end
    end,

    InitialAnimation = function(self)
        for _, av in self:GetArmyViews() do
            local w = av.Width()
            av.Right:Set(av:GetParent().Right() + w)
        end
        local sa = UMT.Animation.Sequential(slideForward, 0.25, 1)
        sa:Apply(self:GetArmyViews())
    end,

    ---Displays ping data in scoreboard UI
    ---@param self ScoreBoard
    ---@param pingData PingData
    DisplayPing = function(self, pingData)
        if pingData.Marker or pingData.Renew then return end
        self:GetArmyViews()[pingData.Owner + 1]:DisplayPing(pingData)
    end,

    ---@param self ScoreBoard
    ---@param fn fun(armyId: integer, view: ArmyView)
    ApplyToViews = function(self, fn)
        for armyId, armyView in self:GetArmyViews() do
            fn(armyId, armyView)
        end
    end

}


---@class ReplayScoreBoard : ScoreBoard
---@field _dataPanel DataPanel
---@field _obs ObserverPanel
---@field _teamsContainer TeamViewsContainer
ReplayScoreBoard = UMT.Class(ScoreBoard)
{
    __init = function(self, parent, isTitle)
        ScoreBoard.__init(self, parent, isTitle)

        self._obs = ObserverPanel(self)
        self._dataPanel = DataPanel(self)
    end,

    _InitArmyViews = function (self)
        self._armiesContainer = ArmyViewsContainer(self)
        self._teamsContainer = TeamViewsContainer(self)
    end,

    InitLayout = function(self)
        if self._title then
            LayoutFor(self._title)
                :AtRightTopIn(self)
            LayoutFor(self._armiesContainer)
                :AnchorToBottom(self._title)
                :Right(self.Right)
        else
            LayoutFor(self._armiesContainer)
                :Top(self.Top)
                :Right(self.Right)
        end


        LayoutFor(self._obs)
            :Right(self.Right)
            :Top(self._armiesContainer.Bottom)
            :Width(self.Width)

        LayoutFor(self._teamsContainer)
            :Right(self.Right)
            :Top(self._obs.Bottom)

        LayoutFor(self._dataPanel)
            :Right(self.Right)
            :Top(self._teamsContainer.Bottom)


        LayoutFor(self)
            :Width(self._armiesContainer.Width)
            :Bottom(self._dataPanel.Bottom)
            :Over(GetFrame(0), 1000)
            :AtRightIn(GetFrame(0))
            :DisableHitTest()
    end,

    GameSpeed = UMT.Property
    {
        get = function(self)
        end,
        set = function(self, value)
            ScoreBoard.GameSpeed.set(self, value)
            self._obs:SetGameSpeed(value)
        end
    },


    ---@param self ReplayScoreBoard
    ---@param data any
    UpdateArmiesData = function(self, data)
        self._armiesContainer:Update(data)
        self._teamsContainer:Update(data)
        if self._focusArmy ~= GetFocusArmy() then
            self._focusArmy = GetFocusArmy()
            ScoreBoard.ApplyToViews(self, function(id, view)
                view:ResetFont()
            end)
        end
    end,

    SortArmies = function(self, func, direction)
        self._armiesContainer:Sort(nil, func, direction)
    end,

    SetDataSetup = function(self, setup)
        self._armiesContainer:Setup(setup)
        self._teamsContainer:Setup(setup)
    end,

    Expand = function(self, id)
        self._armiesContainer:Expand(id)
        self._teamsContainer:Expand(id)
    end,

    Contract = function(self, id)
        self._armiesContainer:Contract(id)
        self._teamsContainer:Contract(id)
    end,

    ResetArmyData = function(self)
        ScoreBoard.ResetArmyData(self)
        self._teamsContainer:SetStaticData()
    end,

    GetArmyViews = function(self)
        return self._armiesContainer._armyViews
    end,

    HandleEvent = function(self, event)
        return false
    end,


    ---@param self ReplayScoreBoard
    ---@param fn fun(armyId: integer, view: ArmyView)
    ApplyToViews = function(self, fn)
        ScoreBoard.ApplyToViews(self, fn)
        for teamId, teamView in self._teamsContainer._armyViews do
            fn(teamId, teamView)
        end
    end
}
