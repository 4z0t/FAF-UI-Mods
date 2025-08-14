local math = math
local table = table
local TableSort = table.sort
local TableInsert = table.insert
local GetSelectedUnits = GetSelectedUnits

local BaseGridPanel = ReUI.UI.Views.Grid.BaseGridPanel
local BaseGridItem = ReUI.UI.Views.Grid.BaseGridItem

---@class ActionInfo
---@field handler string
---@field action any
---@field id number
---@field context any

---@class ActionsGridItem : BaseGridItem
---@field _grid  ActionsGrid
ActionsGridItem = ReUI.Core.Class(BaseGridItem)
{
    ---@param self ActionsGridItem
    ---@param parent ActionsGrid
    __init = function(self, parent)
        BaseGridItem.__init(self, parent)
        self._grid = parent
    end,

    ---@param self ActionsGridItem
    UpdatePanel = function(self)
        ForkThread(self._grid.Refresh, self._grid)
    end,

    ---@param self ActionsGridItem
    OnDestroy = function(self)
        self._grid = nil
        BaseGridItem.OnDestroy(self)
    end,
}

---@class ActionsGrid : BaseGridPanel
---@field _selectionHandlers table<string, ASelectionHandler>
---@field _componentClasses table<string, fun(item:ActionsGridItem):AItemComponent>
---@field _sorter fun(action1:ActionInfo, action2:ActionInfo):boolean
---@field _extensions table<string, ExtensionInfo>
---@field _currentTop number
---@field _maxRows number
---@field _border ReUI.UI.Views.GlowBorder
---@field _rowCountText ReUI.UI.Controls.Text
ActionsGrid = ReUI.Core.Class(BaseGridPanel)
{
    ItemClass = ActionsGridItem,

    ---@param self ActionsGrid
    __init = function(self, parent)
        BaseGridPanel.__init(self, parent)

        self._extensions = {}
        self._currentTop = 1
        self._maxRows = 1
        self._border = ReUI.UI.Views.WindowFrame(self)
        self._rowCountText = ReUI.UI.Controls.Text(self)
    end,

    ---@type table<string, ExtensionInfo>
    Extensions = ReUI.Core.Property
    {
        get = function(self)
            return self._extensions
        end,
    },

    ---@param self ActionsGrid
    ---@param layouter ReUILayouter
    InitLayout = function(self, layouter)
        BaseGridPanel.InitLayout(self, layouter)
        layouter(self._border)
            :FillFixedBorder(self, -10)
            :Under(self)
            :DisableHitTest(true)

        layouter(self._rowCountText)
            :Above(self, 5)
            :DropShadow(true)

        self._rowCountText:SetFont("Arial", 12)
    end,

    ---@param self ActionsGrid
    ---@param extensions table<string, ExtensionInfo>
    LoadExtensions = function(self, extensions)
        self._selectionHandlers = {}
        self._componentClasses = {}
        local order = {}

        local i = 0
        for name, info in pairs(extensions) do
            if info.enabled then
                local handler                 = info.class(self)
                self._selectionHandlers[name] = handler
                order[name]                   = i
                self._componentClasses[name]  = handler.ComponentClass
            end
            i = i + 1
        end

        self._sorter = function(a, b)
            local oa = order[a.handler]
            local ob = order[b.handler]
            if oa == ob then
                return a.id < b.id
            end
            return oa < ob
        end

        self._extensions = extensions
    end,

    ---@param self ActionsGrid
    ReloadExtensions = function(self)
        self:LoadExtensions(self._extensions)

        local componentClasses = self:GetItemComponentClasses()
        self:IterateItemsVertically(function(grid, item, row, column)
            item.ComponentClasses = componentClasses
        end)
    end,

    ---@param self ActionsGrid
    ---@param selection UserUnit[]?
    ---@return ActionInfo[]
    GetActions = function(self, selection)
        ---@type ActionInfo[]
        local actions = {}

        for name, handler in pairs(self._selectionHandlers) do
            local _actions, _context = handler:Update(selection)
            if not _actions then continue end

            for i, action in _actions do
                TableInsert(actions, {
                    handler = name,
                    action = action,
                    context = _context,
                    id = i,
                })
            end
        end

        TableSort(actions, self._sorter)
        return actions
    end,

    ---@param self ActionsGrid
    ---@param selection UserUnit[]?
    OnSelectionChanged = function(self, selection)
        local actions = self:GetActions(selection)

        if table.empty(actions) then
            self:DisableItems()
            self:Hide()
            return
        end

        self:Show()

        ---@diagnostic disable-next-line:deprecated
        local numberActions = table.getn(actions)
        self._maxRows = math.ceil(numberActions / self.Columns)
        local maxTop = math.max(1, self._maxRows - self.Rows + 1)
        local currentTop = math.min(self._currentTop, maxTop)

        self._rowCountText:SetText(("%d / %d"):format(currentTop, maxTop))

        local index = (currentTop - 1) * self.Columns + 1
        self:IterateItemsVertically(function(grid, item, row, column)
            local actionInfo = actions[index]
            if actionInfo == nil then item:Disable() return end

            item:EnableComponent(actionInfo.handler, actionInfo.action, actionInfo.context)

            index = index + 1
        end)
    end,

    ---@param self ActionsGrid
    ---@param item BaseGridItem
    ---@param row number
    ---@param column number
    PositionItem = function(self, item, row, column)
        BaseGridPanel.PositionItem(self, item, row, column)
        local layouter = self.Layouter
        layouter(item)
            :Width(layouter:ScaleVar(self._columnWidth))
            :Height(layouter:ScaleVar(self._rowHeight))
    end,

    ---@param self ActionsGrid
    OnResized = function(self)
        self:DestroyHandlers()
        self:ReloadExtensions()
        self:Refresh()
    end,

    ---@param self ActionsGrid
    DestroyHandlers = function(self)
        if not self._selectionHandlers then
            return
        end

        for name, handler in self._selectionHandlers do
            handler:Destroy()
        end

        self._selectionHandlers = nil
    end,

    ---@param self ActionsGrid
    Refresh = function(self)
        self:OnSelectionChanged(GetSelectedUnits())
    end,


    ---@param self ActionsGrid
    ---@return table<string, fun(instance: BaseGridItem):AItemComponent>
    GetItemComponentClasses = function(self)
        return self._componentClasses
    end,

    ---@param self ActionsGrid
    ---@param delta number
    OnScroll = function(self, delta)
        local newTop = math.max(1, math.min(self._maxRows - self.Rows + 1, self._currentTop + delta))
        if newTop ~= self._currentTop then
            self._currentTop = newTop
            self:Refresh()
        end
    end,

    ---@param self ActionsGrid
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            self:OnScroll(event.WheelRotation > 0 and -1 or 1)
            return true
        end
        return false
    end,

    ---@param self ActionsGrid
    OnDestroy = function(self)
        self:DestroyHandlers()
        self._sorter = nil
        self._border = nil
        self._rowCountText = nil
        BaseGridPanel.OnDestroy(self)
    end,
}
