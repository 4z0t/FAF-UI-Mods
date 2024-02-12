local Bitmap = UMT.Controls.Bitmap
local ILazyComponentable = import("ILazyComponentable.lua").ILazyComponentable
local options = UMT.Options.Mods["AGP"]

local itemSize = options.itemSize:Raw()

---@class Item : UMT.Bitmap, IComponentable
---@field _activeComponent string
---@field _grid ActionsGridPanel
Item = UMT.Class(Bitmap, ILazyComponentable)
{

    ---@param self Item
    __init = function(self, parent)
        Bitmap.__init(self, parent)
        self._activeComponent = nil
        self._grid = parent
    end,

    ---@param self Item
    UpdatePanel = function(self)
        ForkThread(self._grid.Update, self._grid)
    end,

    ---@param self Item
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)
        layouter(self)
            :Width(itemSize)
            :Height(itemSize)
            :Color("99000000")
    end,

    ---@param self Item
    ---@param name string
    ---@param action string
    EnableComponent = function(self, name, action)
        self:DisableComponents()
        self:SetActiveComponent(name)
        self:Enable()
        local component = self:GetActiveComponent()
        component:Enable(self)
        component:SetAction(action)
    end,

    ---@param self Item
    DisableComponents = function(self)
        local components = self:GetComponents()
        if not components then
            return
        end

        for _, component in components do
            component:Disable(self)
        end
    end,

    ---@param self Item
    OnDisable = function(self)
        self:DisableComponents()
    end,

    ---@param self Item
    ---@return IItemComponent
    GetActiveComponent = function(self)
        return self:GetComponent(self._activeComponent)
    end,

    ---@param self Item
    ---@param name string
    SetActiveComponent = function(self, name)
        self._activeComponent = name
    end,

    ---@param self Item
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        local component = self:GetActiveComponent()
        component:HandleEvent(self, event)
    end,

    ---@param self Item
    OnDestroy = function(self)
        Bitmap.OnDestroy(self)
        self:DestroyComponents()
        self._grid = nil
    end,

    ---@generic T
    ---@param self Item
    ---@return table<string, T>
    GetClassProvider = function(self)
        return self._grid:GetExtensionComponentClasses()
    end,
}

---@class DebugItem : Item
---@field text UMT.Text
DebugItem = UMT.Class(Item)
{
    ---@param self DebugItem
    __init = function(self, parent)
        Item.__init(self, parent)
        self.text = UMT.Controls.Text(self)
        self.text:SetFont('Arial', 16)
    end,

    ---@param self DebugItem
    ---@param layouter UMT.Layouter
    InitLayout = function(self, layouter)
        Item.InitLayout(self, layouter)

        layouter(self.text)
            :AtRightTopIn(self, 1, 1)
            :Over(self, 10)
            :DisableHitTest()
    end,

    ---@param self DebugItem
    DisableComponents = function(self)
        Item.DisableComponents(self)
        self.text:SetText(table.getsize(self:GetComponents()))
    end,
}
