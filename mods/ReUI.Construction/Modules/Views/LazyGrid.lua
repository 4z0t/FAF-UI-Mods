local BaseGridPanel = ReUI.UI.Views.Grid.BaseGridPanel

---@class LazyGrid : BaseGridPanel
LazyGrid = ReUI.Core.Class(BaseGridPanel)
{
    ---@param self LazyGrid
    Resize = function(self)
        self:ClearGrid()
    end,

    ---@param self LazyGrid
    CheckItems = function(self)
        if not self._items then
            self:CreateItems()
            self:LayoutItems()
        end
    end,

    ---@param self LazyGrid
    ---@param layouter ReUILayouter
    InitLayout = function(self, layouter)

        self:InitSize(layouter)

        local resizeFn = function()
            self:Resize()
        end
        if not self.AutoHeight then
            self.Height.OnDirty = resizeFn
        end
        if not self.AutoWidth then
            self.Width.OnDirty = resizeFn
        end
        self._verticalSpacing.OnDirty = resizeFn
        self._horizontalSpacing.OnDirty = resizeFn
        self._columnWidth.OnDirty = resizeFn
        self._rowHeight.OnDirty = resizeFn
        self._nx.OnDirty = resizeFn
        self._ny.OnDirty = resizeFn

        layouter(self)
            :Color("22ffffff")

        self:Resize()
    end,

    ---@param self LazyGrid
    CreateItems = function(self)
        local layouter = self.Layouter

        local space = layouter:ScaleNumber(self.VerticalSpacing)
        local rowHeight = layouter:ScaleNumber(self.RowHeight)
        local r1 = math.floor((self.Height() + space) / (rowHeight + space))
        local r2 = self._ny()
        if self.AutoHeight then
            self._rows:Set(r2)
        else
            self._rows:Set(r1)
        end

        local space = layouter:ScaleNumber(self.HorizontalSpacing)
        local columnWidth = layouter:ScaleNumber(self.ColumnWidth)
        local c1 = math.floor((self.Width() + space) / (columnWidth + space))
        local c2 = self._nx()
        if self.AutoWidth then
            self._columns:Set(c2)
        else
            self._columns:Set(c1)
        end
        return BaseGridPanel.CreateItems(self)
    end,

    ---@param self LazyGrid
    ---@param func fun(grid:LazyGrid, item:BaseGridItem, row:number, column:number)
    IterateItemsVertically = function(self, func)
        self:CheckItems()
        return BaseGridPanel.IterateItemsVertically(self, func)
    end,

    ---@param self LazyGrid
    ---@param func fun(grid:LazyGrid, item:BaseGridItem, row:number, column:number)
    IterateItemsHorizontally = function(self, func)
        self:CheckItems()
        return BaseGridPanel.IterateItemsHorizontally(self, func)
    end,

    ---@param self LazyGrid
    ---@param row number
    ---@param column number
    ---@return BaseGridItem
    GetItem = function(self, row, column)
        self:CheckItems()
        return BaseGridPanel.GetItem(self, row, column)
    end,
}
