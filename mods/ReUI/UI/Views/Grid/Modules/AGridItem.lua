local Bitmap = ReUI.UI.Controls.Bitmap

local ALazyComponentContainer = import("ECS/ALazyComponentContainer.lua").ALazyComponentContainer

---@class AGridItem : ReUI.UI.Controls.Bitmap, ALazyComponentContainer
---@field _activeComponent string
AGridItem = ReUI.Core.Class(Bitmap, ALazyComponentContainer)
{
    ---@param self AGridItem
    ---@param parent ReUI.UI.Controls.Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)
        self._activeComponent = nil
    end,

    ---@param self AGridItem
    ---@param layouter ReUILayouter
    InitLayout = function(self, layouter)
        layouter(self)
            :Width(0)
            :Height(0)
            :Color("99000000")
    end,

    ---@param self AGridItem
    ---@param name string
    ---@param action string
    ---@param context any
    EnableComponent = function(self, name, action, context)
        self:DisableComponents()
        self:SetActiveComponent(name)
        self:Enable()
        local component = self:GetActiveComponent()
        component:Enable(self, action, context)
    end,

    ---@param self AGridItem
    DisableComponents = function(self)
        local components = self:GetComponents()
        if not components then
            return
        end

        for _, component in components do
            component:Disable(self)
        end
    end,

    ---@param self AGridItem
    OnDisable = function(self)
        self:DisableComponents()
    end,

    ---Returns active component of the item
    ---@param self AGridItem
    ---@return AItemComponent
    GetActiveComponent = function(self)
        return self:GetComponent(self._activeComponent) --[[@as AItemComponent]]
    end,

    ---@param self AGridItem
    ---@param name string
    SetActiveComponent = function(self, name)
        self._activeComponent = name
    end,

    ---@param self AGridItem
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        local component = self:GetActiveComponent()
        if component then
            component:HandleEvent(self, event)
        end
    end,

    ---@param self AGridItem
    ---@param delta number
    OnFrame = function(self, delta)
        local component = self:GetActiveComponent()
        if component then
            component:OnFrame(self, delta)
        end
    end,

    ---@param self AGridItem
    OnDestroy = function(self)
        self:DestroyComponents()
        Bitmap.OnDestroy(self)
    end,
}
