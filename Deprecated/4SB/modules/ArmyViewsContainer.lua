local Group = UMT.Controls.Group
local Options = import("Options.lua")

local Utils = import("Utils.lua")
local ArmyViews = import("ArmyView.lua")

local LayoutFor = UMT.Layouter.ReusedLayoutFor
local LuaQ = UMT.LuaQ




local inTeamSort = Options.teamScoreSort()

Options.teamScoreSort.OnChange = function(var)
    inTeamSort = var()
end


local scoreFunction = function(score)
    return score.general.score
end

---@class ArmyViewsContainer : UMT.Group
ArmyViewsContainer = UMT.Class(Group)
{
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

    Update = function(self, data)
        if data then
            for i, armyView in self._armyViews do
                armyView:Update(data[i], self._dataSetup)
            end
        end
        self:Sort()
    end,

    Sort = function(self, scoreData, sortFunc, direction)
        self._sortFunc = sortFunc or self._sortFunc
        if not self._sortFunc then
            if not inTeamSort then return end
            self._sortFunc = scoreFunction
        end
        self._sortDirection = direction or self._sortDirection
        local scoreCache    = scoreData or import("/lua/ui/game/score.lua").GetScoreCache()


        local dataTable = self._armyViews
            | LuaQ.select.keyvalue(function(armyId) return self._sortFunc(scoreCache[armyId]) end)

        if self._sortDirection == 1 then
            table.sort(self._lines, function(a, b)
                local data1 = dataTable[a.id]
                local data2 = dataTable[b.id]
                if data1 == data2 then
                    return a.id < b.id
                end
                return data1 > data2
            end)
        elseif self._sortDirection == -1 then
            table.sort(self._lines, function(a, b)
                local data1 = dataTable[a.id]
                local data2 = dataTable[b.id]
                if data1 == data2 then
                    return a.id < b.id
                end
                return data1 < data2
            end)
        elseif inTeamSort then
            table.sort(self._lines, function(a, b)
                if a.teamId == b.teamId then
                    local data1 = dataTable[a.id]
                    local data2 = dataTable[b.id]
                    if data1 == data2 then
                        return a.id < b.id
                    end
                    return data1 > data2
                end
                return a.teamId < b.teamId
            end)
        else

            --reset to default
            self._sortFunc = false
            for i, armyData in self._armyDataCache do
                self._lines[i] = self._armyViews[armyData.id]
            end
        end

        self:Layout()
    end,

    Expand = function(self, id)
        for _, armyView in self._armyViews do
            armyView:ExpandData(id)
        end
    end,

    Contract = function(self, id)
        for _, armyView in self._armyViews do
            armyView:ContractData(id)
        end
    end,

    Setup = function(self, setup)
        self._dataSetup = setup
        local scoreCache = import("/lua/ui/game/score.lua").GetScoreCache()

        if table.empty(scoreCache) then return end

        self:Update(scoreCache)
    end
}
