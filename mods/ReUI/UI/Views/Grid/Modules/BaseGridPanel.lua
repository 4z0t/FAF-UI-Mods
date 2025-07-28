local Bitmap = ReUI.UI.Controls.Bitmap
local LF = ReUI.UI.LayoutFunctions

local LazyVar = import('/lua/lazyvar.lua').Create

---@diagnostic disable-next-line:different-requires
local BaseGridItem = import("BaseGridItem.lua").BaseGridItem

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

---@class BaseGridPanel : ReUI.UI.Controls.Bitmap
---@field _suppressResize boolean
---@field _verticalSpacing LazyNumber
---@field _horizontalSpacing LazyNumber
---@field _columnWidth LazyNumber
---@field _rowHeight LazyNumber
---@field _nx LazyNumber
---@field _ny LazyNumber
---@field _rows LazyNumber
---@field _columns LazyNumber
---@field _prevRows number
---@field _prevColumns number
---@field _items BaseGridItem[][]
BaseGridPanel = ReUI.Core.Class(Bitmap)
{
    ItemClass = BaseGridItem,

    AutoWidth = true,
    AutoHeight = true,

    ---@param self BaseGridPanel
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)

        self._supressResize = true
        self._verticalSpacing = LazyVar(0)
        self._horizontalSpacing = LazyVar(0)
        self._columnWidth = LazyVar(1)
        self._rowHeight = LazyVar(1)

        self._nx = LazyVar(1)
        self._ny = LazyVar(1)

        self._rows = LazyVar(1)
        self._columns = LazyVar(1)

        self._prevRows = 0
        self._prevColumns = 0
    end,

    ---@type LazyOrValue<number>
    Rows = ReUI.Core.Property
    {
        ---@param self BaseGridPanel
        get = function(self)
            return self._rows()
        end,
        ---@param self BaseGridPanel
        set = function(self, value)
            self._ny:Set(value)
        end,
    },

    ---@type LazyOrValue<number>
    Columns = ReUI.Core.Property
    {
        ---@param self BaseGridPanel
        get = function(self)
            return self._columns()
        end,
        ---@param self BaseGridPanel
        set = function(self, value)
            self._nx:Set(value)
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

    ---@param self BaseGridPanel
    ---@param layouter ReUILayouter
    InitLayout = function(self, layouter)
        self._suppressResize = true
        local resizeFn = function()
            if self._suppressResize then
                return
            end
            self:Resize()
        end

        self._rows.OnDirty = resizeFn
        self._columns.OnDirty = resizeFn

        self._rows:Set(function()
            local space = layouter:ScaleNumber(self.VerticalSpacing)
            local rowHeight = layouter:ScaleNumber(self.RowHeight)
            local r1 = math.floor((self.Height() + space) / (rowHeight + space))
            local r2 = self._ny()
            if self.AutoHeight then
                return r2
            else
                return r1
            end
        end)
        self._columns:Set(function()
            local space = layouter:ScaleNumber(self.HorizontalSpacing)
            local columnWidth = layouter:ScaleNumber(self.ColumnWidth)
            local c1 = math.floor((self.Width() + space) / (columnWidth + space))
            local c2 = self._nx()
            if self.AutoWidth then
                return c2
            else
                return c1
            end
        end)

        self:InitSize(layouter)

        layouter(self)
            :Color("22ffffff")

        self:Resize()
        self._suppressResize = false
    end,

    ---@param self BaseGridPanel
    ---@param layouter ReUILayouter
    InitSize = function(self, layouter)
        if self.AutoWidth then
            layouter(self)
                :Width(SizeFn(layouter, self._nx, self._columnWidth, self._horizontalSpacing))
        end
        if self.AutoHeight then
            layouter(self)
                :Height(SizeFn(layouter, self._ny, self._rowHeight, self._verticalSpacing))
        end
    end,

    ---@param self BaseGridPanel
    Resize = function(self)
        if self._prevRows ~= self.Rows or self._prevColumns ~= self.Columns then
            self:ClearGrid()
            self:CreateItems()
        end
        self:LayoutItems()
        self:OnResized()
    end,

    ---@param self BaseGridPanel
    ---@param row number
    ---@param column number
    ---@return BaseGridItem
    CreateItem = function(self, row, column)
        return self.ItemClass(self)
    end,

    ---@param self BaseGridPanel
    CreateItems = function(self)
        local ncolumns = self.Columns
        local nrows = self.Rows

        self._prevRows = nrows
        self._prevColumns = ncolumns

        local componentClasses = self:GetItemComponentClasses()

        self._items = {}
        for x = 1, nrows do
            self._items[x] = {}
            for y = 1, ncolumns do
                local item = self:CreateItem(x, y)

                item.ComponentClasses = componentClasses

                self._items[x][y] = item
            end
        end
    end,

    ---@param self BaseGridPanel
    LayoutItems = function(self)
        self:IterateItemsVertically(self.PositionItem)
    end,

    ---@param self BaseGridPanel
    ---@param item AGridItem
    ---@param row number
    ---@param column number
    PositionItem = function(self, item, row, column)
        local layouter = self.Layouter
        layouter(item)
            :AtLeftIn(self, OffsetFn(layouter, column - 1, self._columnWidth, self._horizontalSpacing))
            :AtTopIn(self, OffsetFn(layouter, row - 1, self._rowHeight, self._verticalSpacing))
    end,

    ---@param self BaseGridPanel
    ---@param func fun(grid:BaseGridPanel, item:BaseGridItem, row:number, column:number)
    IterateItemsVertically = function(self, func)
        for ix, row in self._items do
            for iy, item in row do
                func(self, item, ix, iy)
            end
        end
    end,

    ---@param self BaseGridPanel
    ---@param func fun(grid:BaseGridPanel, item:BaseGridItem, row:number, column:number)
    IterateItemsHorizontally = function(self, func)
        local ncolumns = self.Columns
        local nrows = self.Rows

        for iy = 1, ncolumns do
            for ix = 1, nrows do
                func(self, self:GetItem(ix, iy), ix, iy)
            end
        end
    end,

    ---@param self BaseGridPanel
    ---@param name string
    ---@param class fun(instance:BaseGridItem):AItemComponent
    AddItemComponent = function(self, name, class)
        self:IterateItemsVertically(function(grid, item, row, column)
            item:AddComponent(name, class)
        end)
    end,

    ---@param self BaseGridPanel
    DisableItems = function(self)
        self:IterateItemsVertically(function(grid, item, row, column)
            item:Disable()
        end)
    end,

    ---@param self BaseGridPanel
    OnResized = function(self)
        self:DisableItems()
    end,

    ---@param self BaseGridPanel
    ClearGrid = function(self)
        if not self._items then return end

        self:IterateItemsVertically(function(grid, item, row, column)
            item:Destroy()
        end)

        self._items = nil
    end,

    ---@param self BaseGridPanel
    ---@param row number
    ---@param column number
    ---@return BaseGridItem
    GetItem = function(self, row, column)
        return self._items[row][column]
    end,

    ---@param self BaseGridPanel
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
        self._nx:Destroy()
        self._nx = nil
        self._ny:Destroy()
        self._ny = nil
        self._rows:Destroy()
        self._rows = nil
        self._columns:Destroy()
        self._columns = nil
        Bitmap.OnDestroy(self)
    end,

    ---@param self BaseGridPanel
    Refresh = function(self)
    end,

    ---@param self BaseGridPanel
    ---@return table<string, fun(instance: BaseGridItem):AItemComponent>
    GetItemComponentClasses = function(self)
        return {}
    end,
}
