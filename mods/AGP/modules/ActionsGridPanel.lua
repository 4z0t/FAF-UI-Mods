local Bitmap  = UMT.Controls.Bitmap
local Item    = import("Item.lua").Item
local LazyVar = import('/lua/lazyvar.lua').Create

local options = UMT.Options.Mods["AGP"]

---@class LazyNumber : LazyVar
---@operator call:number

local LayoutFuncs = UMT.Layouter.Functions

local space = options.space:Raw()
local itemSize = options.itemSize:Raw()

local function OffsetFn(n, l)
    return LayoutFuncs.Sum(
        LayoutFuncs.Mult(n, l),
        LayoutFuncs.Mult(LayoutFuncs.Sum(n, 1), space)
    )
end

---@class ActionsGridPanel : UMT.Bitmap
---@field _nx LazyNumber
---@field _ny LazyNumber
---@field _items Item[][]
ActionsGridPanel = UMT.Class(Bitmap)
{
    ItemClass = Item,

    ---@param self ActionsGridPanel
    __init = function(self, parent)
        Bitmap.__init(self, parent)

        local nx = LazyVar()
        local ny = LazyVar()
        nx:Set(options.columns:Raw())
        ny:Set(options.rows:Raw())

        local resizeFn = function()
            self:Resize()
        end

        nx.OnDirty = resizeFn
        ny.OnDirty = resizeFn

        self._nx = nx
        self._ny = ny

        self:Resize()
    end,

    ---@param self ActionsGridPanel
    ---@param func fun(grid:ActionsGridPanel, item:Item, row:number, column:number)
    IterateItems = function(self, func)
        for ix, row in self._items do
            for iy, item in row do
                func(self, item, ix, iy)
            end
        end
    end,

    ---@param self ActionsGridPanel
    ---@param name string
    ---@param class fun(instance:Item):IItemComponent
    AddItemComponent = function(self, name, class)
        self:IterateItems(function(grid, item, row, column)
            item:AddComponent(name, class)
        end)
    end,

    ---@param self ActionsGridPanel
    DisableItems = function(self)
        self:IterateItems(function(grid, item, row, column)
            item:Disable()
        end)
    end,

    ---@param self ActionsGridPanel
    OnResized = function(self)
        self:DisableItems()
    end,

    ---@param self ActionsGridPanel
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)

        layouter(self._border)
            :FillFixedBorder(self, -5)
            :Under(self)
            :DisableHitTest(true)

        layouter(self)
            :Width(OffsetFn(self._nx, itemSize))
            :Height(OffsetFn(self._ny, itemSize))
            :Color("22ffffff")
        self:LayoutItems()
    end,

    ---@param self ActionsGridPanel
    LayoutItems = function(self)
        self:IterateItems(self.PositionItem)
    end,

    ---@param self ActionsGridPanel
    ---@param item Item
    ---@param row number
    ---@param column number
    PositionItem = function(self, item, row, column)
        self.Layouter(item)
            :AtTopIn(self, OffsetFn(row - 1, itemSize))
            :AtLeftIn(self, OffsetFn(column - 1, itemSize))
    end,

    ---@param self ActionsGridPanel
    ClearGrid = function(self)
        if not self._items then return end

        self:IterateItems(function(grid, item, row, column)
            item:Destroy()
        end)

        self._items = nil
    end,

    ---@param self ActionsGridPanel
    Resize = function(self)
        self:ClearGrid()

        local ncolumns = self._nx()
        local nrows = self._ny()

        self._items = {}
        for x = 1, nrows do
            self._items[x] = {}
            for y = 1, ncolumns do
                self._items[x][y] = self.ItemClass(self)
            end
        end
        self:LayoutItems()
        self:OnResized()
    end,


    ---@param self ActionsGridPanel
    OnDestroy = function(self)
        Bitmap.OnDestroy(self)
        self:ClearGrid()
        self._nx:Destroy()
        self._ny:Destroy()
        self._nx = nil
        self._ny = nil
    end,

    ---@param self ActionsGridPanel
    Update = function(self)
    end,

    ---@generic T
    ---@param self ActionsGridPanel
    ---@return table<string,T>
    GetExtensionComponentClasses = function(self)
    end,
}
