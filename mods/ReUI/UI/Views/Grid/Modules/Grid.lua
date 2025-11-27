local MathFloor = math.floor

local Bitmap = ReUI.UI.Controls.Bitmap
local LF = ReUI.UI.LayoutFunctions

local LazyVar = import('/lua/lazyvar.lua').Create

---@class LazyNumber : LazyVar
---@operator call:number


---@param layouter ReUILayouter
---@param n LazyOrValue<number>
---@param size LazyOrValue<number>
---@param space LazyOrValue<number>
---@return LazyOrValue<number>
local function OffsetFn(layouter, n, size, space)
    return LF.Sum(
        LF.Mult(n, layouter:ScaleVar(size)),
        LF.Mult(n, layouter:ScaleVar(space))
    )
end

---@param layouter ReUILayouter
---@param n LazyOrValue<number>
---@param size LazyOrValue<number>
---@param space LazyOrValue<number>
---@return LazyOrValue<number>
local function SizeFn(layouter, n, size, space)
    return LF.Sum(
        LF.Mult(n, layouter:ScaleVar(size)),
        LF.Mult(LF.Diff(n, 1), layouter:ScaleVar(space))
    )
end

---@class ReUI.UI.Views.Grid.Grid : ReUI.UI.Controls.Bitmap
---@field _suppressResize boolean
---@field _verticalSpacing LazyNumber
---@field _horizontalSpacing LazyNumber
---@field _columnWidth LazyNumber
---@field _rowHeight LazyNumber
---@field _rows LazyNumber
---@field _columns LazyNumber
---@field _prevRows number
---@field _prevColumns number
---@field _resizeFn fun()
---@field _items ReUI.UI.Controls.Control[][]
Grid = ReUI.Core.Class(Bitmap)
{
    ---Automatically computes Grid's width based on number of items
    AutoWidth = true,

    ---Automatically computes Grid's height based on number of items
    AutoHeight = true,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)

        self._verticalSpacing = LazyVar(0)
        self._horizontalSpacing = LazyVar(0)
        self._columnWidth = LazyVar(1)
        self._rowHeight = LazyVar(1)

        self._prevRows = 0
        self._prevColumns = 0

        self._rows = LazyVar(1)
        self._columns = LazyVar(1)

        self._suppressResize = true
        self._resizeFn = function()
            if self._suppressResize then
                return
            end
            self:Resize()
        end

        self._rows.OnDirty = self._resizeFn
        self._columns.OnDirty = self._resizeFn
    end,

    ---@type LazyOrValue<number>
    Rows = ReUI.Core.Property
    {
        ---@param self ReUI.UI.Views.Grid.Grid
        get = function(self)
            return self._prevRows
        end,
        ---@param self ReUI.UI.Views.Grid.Grid
        set = function(self, value)
            self._rows:Set(value)
        end,
    },

    ---@type LazyOrValue<number>
    Columns = ReUI.Core.Property
    {
        ---@param self ReUI.UI.Views.Grid.Grid
        get = function(self)
            return self._prevColumns
        end,
        ---@param self ReUI.UI.Views.Grid.Grid
        set = function(self, value)
            self._columns:Set(value)
        end,
    },

    ---@type LazyOrValue<number>
    ColumnWidth = ReUI.Core.Property
    {
        get = function(self)
            return self._columnWidth()
        end,
        set = function(self, value)
            self._columnWidth:Set(value)
        end,
    },

    ---@type LazyOrValue<number>
    RowHeight = ReUI.Core.Property
    {
        get = function(self)
            return self._rowHeight()
        end,
        set = function(self, value)
            self._rowHeight:Set(value)
        end,
    },

    ---@type LazyOrValue<number>
    HorizontalSpacing = ReUI.Core.Property
    {
        get = function(self)
            return self._horizontalSpacing()
        end,
        set = function(self, value)
            self._horizontalSpacing:Set(value)
        end,
    },

    ---@type LazyOrValue<number>
    VerticalSpacing = ReUI.Core.Property
    {
        get = function(self)
            return self._verticalSpacing()
        end,
        set = function(self, value)
            self._verticalSpacing:Set(value)
        end,
    },

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param layouter ReUILayouter
    InitLayout = function(self, layouter)
        self._suppressResize = true

        self:InitSize(layouter)

        layouter(self)
            :Color("22ffffff")

        self:Resize()

        self._suppressResize = false
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param layouter ReUILayouter
    InitSize = function(self, layouter)
        if self.AutoWidth then
            self.Width.OnDirty = nil
            layouter(self)
                :Width(SizeFn(layouter, self._columns, self._columnWidth, self._horizontalSpacing))
        else
            self.Width.OnDirty = self._resizeFn
        end
        if self.AutoHeight then
            self.Height.OnDirty = nil
            layouter(self)
                :Height(SizeFn(layouter, self._rows, self._rowHeight, self._verticalSpacing))
        else
            self.Height.OnDirty = self._resizeFn
        end
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@return number
    ComputeRows = function(self)
        if self.AutoHeight then
            return self._rows()
        end
        local layouter = self.Layouter
        local space = layouter:ScaleNumber(self.VerticalSpacing)
        local rowHeight = layouter:ScaleNumber(self.RowHeight)
        return MathFloor((self.Height() + space) / (rowHeight + space))
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@return number
    ComputeColumns = function(self)
        if self.AutoWidth then
            return self._columns()
        end
        local layouter = self.Layouter
        local space = layouter:ScaleNumber(self.HorizontalSpacing)
        local columnWidth = layouter:ScaleNumber(self.ColumnWidth)
        return MathFloor((self.Width() + space) / (columnWidth + space))
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    Resize = function(self)
        local rows = self:ComputeRows()
        local columns = self:ComputeColumns()
        if self._prevRows ~= rows or self._prevColumns ~= columns then
            self:ClearGrid()
            self:CreateItems(rows, columns)
        end
        self:LayoutItems()
        self:OnResized()
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param row number
    ---@param column number
    ---@return ReUI.UI.Controls.Control
    CreateItem = function(self, row, column)
        error("Grid.CreateItem not implemented")
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param columns number
    ---@param rows number
    CreateItems = function(self, rows, columns)
        self._prevRows = rows
        self._prevColumns = columns

        self._items = {}
        for x = 1, rows do
            self._items[x] = {}
            for y = 1, columns do
                self._items[x][y] = self:CreateItem(x, y)
            end
        end
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    LayoutItems = function(self)
        self:IterateItemsVertically(self.PositionItem)
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param item AGridItem
    ---@param row number
    ---@param column number
    PositionItem = function(self, item, row, column)
        local layouter = self.Layouter
        layouter(item)
            :AtLeftIn(self, OffsetFn(layouter, column - 1, self._columnWidth, self._horizontalSpacing))
            :AtTopIn(self, OffsetFn(layouter, row - 1, self._rowHeight, self._verticalSpacing))
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param func fun(grid:ReUI.UI.Views.Grid.Grid , item:ReUI.UI.Controls.Control, row:number, column:number)
    IterateItemsVertically = function(self, func)
        local items = self:GetItems()
        local ncolumns = self.Columns
        local nrows = self.Rows

        for ix = 1, nrows do
            for iy = 1, ncolumns do
                func(self, items[ix][iy], ix, iy)
            end
        end
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param func fun(grid:ReUI.UI.Views.Grid.Grid , item:ReUI.UI.Controls.Control, row:number, column:number)
    IterateItemsHorizontally = function(self, func)
        local items = self:GetItems()
        local ncolumns = self.Columns
        local nrows = self.Rows

        for iy = 1, ncolumns do
            for ix = 1, nrows do
                func(self, items[ix][iy], ix, iy)
            end
        end
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    OnResized = function(self)
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ClearGrid = function(self)
        if not self._items then return end

        self:IterateItemsVertically(function(grid, item, row, column)
            item:Destroy()
        end)

        self._prevRows = 0
        self._prevColumns = 0

        self._items = nil
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@return ReUI.UI.Controls.Control[][]
    GetItems = function(self)
        return self._items
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    ---@param row number
    ---@param column number
    ---@return ReUI.UI.Controls.Control
    GetItem = function(self, row, column)
        return self:GetItems()[row][column]
    end,

    ---@param self ReUI.UI.Views.Grid.Grid
    OnDestroy = function(self)
        self:ClearGrid()
        self._verticalSpacing:Destroy()
        self._verticalSpacing = nil
        self._horizontalSpacing:Destroy()
        self._horizontalSpacing = nil
        self._columnWidth:Destroy()
        self._columnWidth = nil
        self._rowHeight:Destroy()
        self._rowHeight = nil
        self._rows:Destroy()
        self._rows = nil
        self._columns:Destroy()
        self._columns = nil
        Bitmap.OnDestroy(self)
    end,

}
