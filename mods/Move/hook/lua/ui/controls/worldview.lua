do
    local _WorldViewHandleEvent = WorldView.HandleEvent
    local MoveOnly = import "/mods/Move/modules/Main.lua"
    WorldView = Class(WorldView) {
        ---@param self WorldView
        ---@param event KeyEvent
        HandleEvent = function(self, event)
            if event.Modifiers.Right and MoveOnly.IsLocked() then
                MoveOnly.Toggle(true)
            end
            _WorldViewHandleEvent(self, event)
        end
    }
end
