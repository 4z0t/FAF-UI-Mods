local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent

---@class ConstructionItemComponent : AItemComponent
ConstructionItemComponent = ReUI.Core.Class(AItemComponent)
{
    ---Called when grid item receives an event
    ---@param self ConstructionItemComponent
    ---@param item ReUI.Construction.Grid.Item
    ---@param event KeyEvent
    HandleEvent = function(self, item, event)
        if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
            return self:OnClick(event.Modifiers)
        elseif event.Type == "MouseEnter" then
            return self:OnRollOver("enter")
        elseif event.Type == "MouseExit" then
            return self:OnRollOver("exit")
        end
    end,

    ---@param self ConstructionItemComponent
    ---@param modifiers EventModifiers
    OnClick = function(self, modifiers)
    end,

    ---@param self ConstructionItemComponent
    ---@param state "enter"|"exit"
    OnRollOver = function(self, state)
    end
}
