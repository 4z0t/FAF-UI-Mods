do
    local _WorldViewHandleEvent = WorldView.HandleEvent
    WorldView = Class(WorldView) {
        ---@param self WorldView
        ---@param event KeyEvent
        HandleEvent = function(self, event)
            return _WorldViewHandleEvent(self, event)
        end
    }
end
