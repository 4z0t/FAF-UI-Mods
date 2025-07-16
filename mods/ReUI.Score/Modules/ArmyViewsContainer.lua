--#region Header
--#region Upvalues
local TableEmpty = table.empty
--#endregion

--#region Base Lua imports

--#endregion

--#region ReUI modules / classes
local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap
local Text = ReUI.UI.Controls.Text
local Enumerate = ReUI.LINQ.Enumerate
--#endregion

--#region Local Modules
local ArmyViews = import("ArmyView.lua")
local Utils = import("Utils.lua")

--#endregion

--#region Local Variables
local options = ReUI.Options.Mods["ReUI.Score"]

local inTeamSort = false

options.teamScoreSort:Bind(function(var)
    inTeamSort = var()
end)

local scoreFunction = function(score)
    return score.general.score
end
--#endregion
--#endregion


---@alias ScoreSortType
--- | "Ascending"
--- | "Descending"
--- | "Team"

---@return fun(lines:ArmyView[], data:table<integer, number>, sortType:ScoreSortType)
local function MakeScoreSorter()
    local TableSort = table.sort

    ---@type table<integer, number>
    local _data

    local Ascending = function(a, b)
        local data1 = _data[a.id]
        local data2 = _data[b.id]
        if data1 == data2 then
            return a.id < b.id
        end
        return data1 > data2
    end

    local Descending = function(a, b)
        local data1 = _data[a.id]
        local data2 = _data[b.id]
        if data1 == data2 then
            return a.id < b.id
        end
        return data1 < data2
    end

    local Team = function(a, b)
        if a.teamId == b.teamId then
            local data1 = _data[a.id]
            local data2 = _data[b.id]
            if data1 == data2 then
                return a.id < b.id
            end
            return data1 > data2
        end
        return a.teamId < b.teamId
    end

    ---@param lines ArmyView[]
    ---@param data table<integer, number>
    ---@param sortType ScoreSortType
    return function(lines, data, sortType)
        _data = data

        if sortType == "Ascending" then
            TableSort(lines, Ascending)
        elseif sortType == "Descending" then
            TableSort(lines, Descending)
        elseif sortType == "Team" then
            TableSort(lines, Team)
        end
    end
end

local sorter = MakeScoreSorter()

---@class ArmyViewsContainer : ReUI.UI.Controls.Group
---@field _lines ArmyView[]
---@field _armyViews table<integer, ArmyView>
---@field _armyDataCache ArmyData[]
---@field _sortDirection number
---@field _dataSetup number[]
---@field _sortFunc fun(data: ArmyData):number
ArmyViewsContainer = ReUI.Core.Class(Group)
{
    ---@param self ArmyViewsContainer
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self._armyDataCache = false

        self._lines = {}
        self._armyViews = false

        self._top = nil
        self._bottom = nil

        self._sortFunc = false
        self._sortDirection = false

        self._dataSetup = { 1, 1, 1, 1, 1 }
        self:_InitArmyViews()
    end,

    ---@param self ArmyViewsContainer
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)

        local last
        local first
        for i, armyView in self._lines do
            if i == 1 then
                layouter(armyView)
                    :AtRightTopIn(self)
                first = armyView
            else
                layouter(armyView)
                    :AnchorToBottom(self._lines[i - 1])
                    :Right(self.Right)
            end
            last = armyView
        end

        if not first then
            layouter(self)
                :Height(0)
                :Width(0)
                :DisableHitTest()
            return
        end

        if last then
            self.Bottom:Set(last.Bottom)
        end

        self._top = self._lines[1]
        self._bottom = last

        layouter(self)
            :Width(self._top.Width)
            :DisableHitTest()
    end,

    ---@param self ArmyViewsContainer
    _InitArmyViews = function(self)

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
                armyData.teamColor,
                armyData.division
            )
            armyView.teamId = armyData.teamId
            self._lines[i] = armyView
            self._armyViews[armyData.id] = armyView
        end

        self._armyDataCache = armiesData
    end,

    ---@param self ArmyViewsContainer
    ---@param data ArmyData[]?
    Update = function(self, data)
        if data then
            for i, armyView in self._armyViews do
                armyView:Update(data[i], self._dataSetup)
            end
        end
        self:Sort()
    end,

    ---@param self ArmyViewsContainer
    ---@param scoreData? ArmyData[]
    ---@param sortFunc? fun(data:ArmyData):number
    ---@param direction? number
    Sort = function(self, scoreData, sortFunc, direction)

        self._sortFunc = sortFunc or self._sortFunc
        if not self._sortFunc then
            if not inTeamSort then
                return
            end
            self._sortFunc = scoreFunction
        end

        direction = direction or self._sortDirection
        self._sortDirection = direction

        ---@type ScoreSortType?
        local sortType
        if direction == 1 then
            sortType = "Ascending"
        elseif direction == -1 then
            sortType = "Descending"
        elseif inTeamSort then
            sortType = "Team"
        end

        if sortType then
            local scoreCache = scoreData or import("/lua/ui/game/score.lua").GetScoreCache()
            local _sortFunc  = self._sortFunc

            ---@type table<integer, number>
            local dataTable = Enumerate(self._armyViews, next)
                :Select(function(value, armyId) return _sortFunc(scoreCache[armyId]) end)
                :ToTable()

            sorter(self._lines, dataTable, sortType)
        else
            --reset to default
            self._sortFunc = false
            for i, armyData in self._armyDataCache do
                self._lines[i] = self._armyViews[armyData.id]
            end
        end

        self:Layout()
    end,

    ---@param self ArmyViewsContainer
    ---@param id number
    Expand = function(self, id)
        for _, armyView in self._armyViews do
            armyView:ExpandData(id)
        end
    end,

    ---@param self ArmyViewsContainer
    ---@param id number
    Contract = function(self, id)
        for _, armyView in self._armyViews do
            armyView:ContractData(id)
        end
    end,

    ---@param self ArmyViewsContainer
    ---@param setup number[]
    Setup = function(self, setup)
        self._dataSetup = setup
        local scoreCache = import("/lua/ui/game/score.lua").GetScoreCache()

        if TableEmpty(scoreCache) then
            return
        end

        self:Update(scoreCache)
    end
}
