local Group = import('/lua/maui/group.lua').Group
local ArmyViews = import("ArmyView.lua")
local Utils = import("Utils.lua")
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import("/lua/maui/text.lua").Text
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local TitlePanel = import("TitlePanel.lua").TitlePanel
local ObserverPanel = import("ObserverPanel.lua").ObserverPanel
local DataPanel = import("ReplayDataPanel.lua").DataPanel
local ArmyViewsContainer = import("ArmyViewsContainer.lua").ArmyViewsContainer
local TeamViewsContainer = import("TeamViewsContainer.lua").TeamViewsContainer
local InfoPanel = import("InfoPanel.lua").InfoPanel


local LazyImport = UMT.LazyImport
local Scores = LazyImport("/lua/ui/game/score.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor

local animationSpeed = LayoutHelpers.ScaleNumber(300)

local slideForward = UMT.Animation.Factory.Base
    :OnStart()
    :OnFrame(function(control, delta)
        return control.Right() < control:GetParent().Right() or
            control.Right:Set(control.Right() - delta * animationSpeed)
    end)
    :OnFinish(function(control)
        control.Right:Set(control:GetParent().Right)
    end)
    :Create()


---@class ScoreBoard : Group
---@field GameSpeed PropertyTable<ScoreBoard, integer>
---@field protected _armyViews table<integer, ArmyView>
---@field protected _title TitlePanel
---@field protected _mode "storage"| "maxstorage"| "income"
---@field protected _focusArmy integer
---@field protected _lines ArmyView[]
ScoreBoard = UMT.Class(Group, UMT.Interfaces.ILayoutable)
{
    __init = function(self, parent, isTitle)
        Group.__init(self, parent)

        self._focusArmy = GetFocusArmy()
        self._title = false

        if isTitle then
            self._title = TitlePanel(self)
            self._title:SetQuality(SessionGetScenarioInfo().Options.Quality)
        end


    end,

    __post_init = function(self)

        self:_InitArmyViews()
        self:_Layout()

        self._mode = "income"
    end,

    _Layout = function(self)
        if self._title then
            LayoutFor(self._title)
                :AtRightTopIn(self)
        end
        local last
        local first
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
                first = armyView
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

        LayoutFor(self)
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
                armyData.teamColor
            )

            self._lines[i] = armyView
            self._armyViews[armyData.id] = armyView
        end

    end,

    ResetArmyData = function(self)
        ArmyViews.nameWidth:Set(0)
        for _, armyData in Utils.GetArmiesFormattedTable() do
            self:GetArmyViews()[armyData.id]:SetStaticData(
                armyData.id,
                armyData.name,
                armyData.rating,
                armyData.faction,
                armyData.color,
                armyData.teamColor
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
    end

}


---@class ReplayScoreBoard : ScoreBoard
ReplayScoreBoard = UMT.Class(ScoreBoard)
{
    __init = function(self, parent, isTitle)
        ScoreBoard.__init(self, parent, isTitle)

        self._armiesContainer = ArmyViewsContainer(self)
        self._teamsContainer = TeamViewsContainer(self)
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

    UpdateArmiesData = function(self, data)
        self._armiesContainer:Update(data)
        self._teamsContainer:Update(data)
        if self._focusArmy ~= GetFocusArmy() then
            self._focusArmy = GetFocusArmy()
            self:ResetArmyData()
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
}
