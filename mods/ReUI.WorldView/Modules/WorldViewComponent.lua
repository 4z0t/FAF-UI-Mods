---@class ReUI.WorldView.Component : IComponent
---@field name string
---@field worldView ReUI.WorldView.WorldView
Component = ReUI.Core.Class()
{
    ---@param self ReUI.WorldView.Component
    ---@param worldView WorldView
    ---@param name string
    __init = function(self, worldView, name)
        self.name = name
        self.worldView = worldView
    end,

    ---@param self ReUI.WorldView.Component
    Init = function(self)
        self:OnInit()
        self:Enable()
    end,

    ---@param self ReUI.WorldView.Component
    Enable = function(self)
        if self.enabled then
            return
        end
        self.enabled = true
        self:OnEnabled()
    end,

    ---@param self ReUI.WorldView.Component
    Disable = function(self)
        if not self.enabled then
            return
        end
        self.enabled = false
        self:OnDisabled()
    end,

    ---Called when component is initialized
    ---@param self ReUI.WorldView.Component
    OnInit = function(self)
    end,

    ---@param self ReUI.WorldView.Component
    OnEnabled = function(self)
    end,

    ---@param self ReUI.WorldView.Component
    OnDisabled = function(self)
    end,

    ---Called when grid worldview receives an event
    ---@param self ReUI.WorldView.Component
    ---@param event KeyEvent
    ---@return boolean
    OnHandleEvent = function(self, event)
        return false
    end,

    ---Called when grid worldview is updated on frame
    ---@param self ReUI.WorldView.Component
    ---@param delta number
    OnFrame = function(self, delta)
    end,

    ---@param self ReUI.WorldView.Component
    OnUpdateCursor = function(self)
    end,

    ---Called when component is destroyed
    ---@param self ReUI.WorldView.Component
    OnDestroy = function(self)
    end,

    ---@param self ReUI.WorldView.Component
    Destroy = function(self)
        self:Disable()
        self:OnDestroy()
        self.worldView = nil
        self.name = nil
    end,
}
