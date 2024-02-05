local Bitmap = UMT.Controls.Bitmap
local IComponentable = import("IComponentable.lua").IComponentable
local options = UMT.Options.Mods["AGP"]

local itemSize = options.itemSize:Raw()

---@class Item : UMT.Bitmap, IComponentable
---@field _activeComponent string
---@field _grid ActionsGridPanel
Item = UMT.Class(Bitmap, IComponentable)
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
        if self._activeComponent ~= name then
            self:DisableComponents()
            self:SetActiveComponent(name)
        end
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
    end
}
